#include "Network/OpenSSLHelper.h"
#include "Common.h"
#include "GamePlatformMisc.h"

#if PLATFORM_HAS_BSD_SOCKET_FEATURE_WINSOCKETS
#include "Windows/WindowsHWrapper.h"
#include "Windows/AllowWindowsPlatformTypes.h"

#include <winsock2.h>
#include <ws2tcpip.h>

typedef int32 SOCKLEN;

#include "Windows/HideWindowsPlatformTypes.h"
#else
#if PLATFORM_SWITCH
#include "Switch/SwitchSocketApiWrapper.h"
#else
#include <unistd.h>
#include <sys/socket.h>
#if PLATFORM_HAS_BSD_SOCKET_FEATURE_IOCTL
#include <sys/ioctl.h>
#endif
#include <netinet/in.h>
#include <arpa/inet.h>
#if PLATFORM_HAS_BSD_SOCKET_FEATURE_GETHOSTNAME
#include <netdb.h>
#endif

#define ioctlsocket ioctl
#endif

#define SOCKET_ERROR -1
#define INVALID_SOCKET -1

typedef socklen_t SOCKLEN;
typedef int32 SOCKET;
typedef sockaddr_in SOCKADDR_IN;
typedef struct timeval TIMEVAL;

#endif

#if PLATFORM_WINDOWS
#include "Windows/WindowsHWrapper.h"
#include "Windows/AllowWindowsPlatformTypes.h"
#endif

#define UI UI_ST
THIRD_PARTY_INCLUDES_START
#include "openssl/crypto.h"
#include "openssl/x509.h"
#include "openssl/pem.h"
#include "openssl/ssl.h"
#include "openssl/err.h"
#include "openssl/ocsp.h"
THIRD_PARTY_INCLUDES_END
#undef UI

#if PLATFORM_WINDOWS
#include "Windows/HideWindowsPlatformTypes.h"
#endif

DEFINE_LOG_CATEGORY_STATIC(LogOpenSSL, Log, All)

#define USE_OCSP 1

struct FOpenSSLHelper::FImplement
{
    SSL* ssl;
    SSL_CTX* ctx;
    char host_name[512];
    EOpenSSLState connection_state;
#if USE_OCSP
    bool has_recved_ocsp_result;
#endif

    FImplement()
        : ssl(nullptr)
        , ctx(nullptr)
        , connection_state(EOpenSSLState::NotConnected)
#if USE_OCSP
        , has_recved_ocsp_result(false)
#endif
    {
        memset(host_name, 0, sizeof(host_name));
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 下面都是抄 curl 7.65.1 的，然后不用的地方注掉了
#if PLATFORM_HAS_BSD_IPV6_SOCKETS || PLATFORM_IOS
#define ENABLE_IPV6
#endif

#if PLATFORM_WINDOWS
#define temp_strdup _strdup
#else
#define temp_strdup strdup
#endif

    typedef enum
    {
        CURL_HOST_MATCH = 0,
        CURL_HOST_NOMATCH,
    } ECurlMatchReturnCode;

    typedef enum
    {
        CURLE_OK = 0,
        CURLE_PEER_FAILED_VERIFICATION,
        CURLE_SSL_INVALIDCERTSTATUS,
        NO_OCSP,
    } ECurlReturnCode;

    typedef enum
    {
        SSL_TRUE = 1,
        SSL_FALSE = 0,
    } ETrueOrFalse;

    char raw_toupper(char in)
    {
        if (in >= 'a' && in <= 'z')
            return (char)('A' + in - 'a');
        return in;
    }

    int strncasecompare(const char *first, const char *second, size_t max)
    {
        while (*first && *second && max) {
            if (raw_toupper(*first) != raw_toupper(*second)) {
                break;
            }
            max--;
            first++;
            second++;
        }
        if (0 == max)
            return 1; /* they are equal this far */

        return raw_toupper(*first) == raw_toupper(*second);
    }

    int strcasecompare(const char *first, const char *second)
    {
        while (*first && *second) {
            if (raw_toupper(*first) != raw_toupper(*second))
                /* get out of the loop as soon as they don't match */
                break;
            first++;
            second++;
        }
        /* we do the comparison here (possibly again), just to make sure that if the
           loop above is skipped because one of the strings reached zero, we must not
           return this as a successful match */
        return (raw_toupper(*first) == raw_toupper(*second));
    }

    /*
 * Match a hostname against a wildcard pattern.
 * E.g.
 *  "foo.host.com" matches "*.host.com".
 *
 * We use the matching rule described in RFC6125, section 6.4.3.
 * https://tools.ietf.org/html/rfc6125#section-6.4.3
 *
 * In addition: ignore trailing dots in the host names and wildcards, so that
 * the names are used normalized. This is what the browsers do.
 *
 * Do not allow wildcard matching on IP numbers. There are apparently
 * certificates being used with an IP address in the CN field, thus making no
 * apparent distinction between a name and an IP. We need to detect the use of
 * an IP address and not wildcard match on such names.
 *
 * NOTE: hostmatch() gets called with copied buffers so that it can modify the
 * contents at will.
 */

    int hostmatch(char *hostname, char *pattern)
    {
        const char *pattern_label_end, *pattern_wildcard, *hostname_label_end;
        int wildcard_enabled;
        size_t prefixlen, suffixlen;
        struct in_addr ignored;
#ifdef ENABLE_IPV6
        struct sockaddr_in6 si6;
#endif

        /* normalize pattern and hostname by stripping off trailing dots */
        size_t len = strlen(hostname);
        if (hostname[len - 1] == '.')
            hostname[len - 1] = 0;
        len = strlen(pattern);
        if (pattern[len - 1] == '.')
            pattern[len - 1] = 0;

        pattern_wildcard = strchr(pattern, '*');
        if (pattern_wildcard == NULL)
            return strcasecompare(pattern, hostname) ?
            CURL_HOST_MATCH : CURL_HOST_NOMATCH;

        /* detect IP address as hostname and fail the match if so */
        if (inet_pton(AF_INET, hostname, &ignored) > 0)
            return CURL_HOST_NOMATCH;
#ifdef ENABLE_IPV6
        if (inet_pton(AF_INET6, hostname, &si6.sin6_addr) > 0)
            return CURL_HOST_NOMATCH;
#endif

        /* We require at least 2 dots in pattern to avoid too wide wildcard
           match. */
        wildcard_enabled = 1;
        pattern_label_end = strchr(pattern, '.');
        if (pattern_label_end == NULL || strchr(pattern_label_end + 1, '.') == NULL ||
            pattern_wildcard > pattern_label_end ||
            strncasecompare(pattern, "xn--", 4)) {
            wildcard_enabled = 0;
        }
        if (!wildcard_enabled)
            return strcasecompare(pattern, hostname) ?
            CURL_HOST_MATCH : CURL_HOST_NOMATCH;

        hostname_label_end = strchr(hostname, '.');
        if (hostname_label_end == NULL ||
            !strcasecompare(pattern_label_end, hostname_label_end))
            return CURL_HOST_NOMATCH;

        /* The wildcard must match at least one character, so the left-most
           label of the hostname is at least as large as the left-most label
           of the pattern. */
        if (hostname_label_end - hostname < pattern_label_end - pattern)
            return CURL_HOST_NOMATCH;

        prefixlen = pattern_wildcard - pattern;
        suffixlen = pattern_label_end - (pattern_wildcard + 1);
        return strncasecompare(pattern, hostname, prefixlen) &&
            strncasecompare(pattern_wildcard + 1, hostname_label_end - suffixlen,
                suffixlen) ?
            CURL_HOST_MATCH : CURL_HOST_NOMATCH;
    }

    int Curl_cert_hostcheck(const char *match_pattern, const char *hostname)
    {
        int res = 0;
        if (!match_pattern || !*match_pattern ||
            !hostname || !*hostname) /* sanity check */
            ;
        else {
            char *matchp = temp_strdup(match_pattern);
            if (matchp) {
                char *hostp = temp_strdup(hostname);
                if (hostp) {
                    if (hostmatch(hostp, matchp) == CURL_HOST_MATCH)
                        res = 1;
                    free(hostp);
                }
                free(matchp);
            }
        }

        return res;
    }

#if USE_OCSP
    static int ocsp_resp_cb(SSL *s, void *arg)
    {
        auto This = (FOpenSSLHelper::FImplement*)arg;
        This->has_recved_ocsp_result = true;
        return 1;
    }

    int ossl_verify_ocsp_status()
    {
        int i, ocsp_status;
        unsigned char *status;
        const unsigned char *p;
        ECurlReturnCode result = CURLE_OK;

        OCSP_RESPONSE *rsp = NULL;
        OCSP_BASICRESP *br = NULL;
        X509_STORE     *st = NULL;
        STACK_OF(X509) *ch = NULL;

        long len = SSL_get_tlsext_status_ocsp_resp(ssl, &status);

        if (!status) {
            UE_LOG(LogOpenSSL, Log, TEXT("No OCSP response received"));
            result = NO_OCSP;
            goto end;
        }
        p = status;
        rsp = d2i_OCSP_RESPONSE(NULL, &p, len);
        if (!rsp) {
            UE_LOG(LogOpenSSL, Warning, TEXT("Invalid OCSP response"));
            result = CURLE_SSL_INVALIDCERTSTATUS;
            goto end;
        }

        ocsp_status = OCSP_response_status(rsp);
        if (ocsp_status != OCSP_RESPONSE_STATUS_SUCCESSFUL) {
            UE_LOG(LogOpenSSL, Warning, TEXT("Invalid OCSP response status: %s (%d)"),
                ANSI_TO_TCHAR(OCSP_response_status_str(ocsp_status)), ocsp_status);
            result = CURLE_SSL_INVALIDCERTSTATUS;
            goto end;
        }

        br = OCSP_response_get1_basic(rsp);
        if (!br) {
            UE_LOG(LogOpenSSL, Warning, TEXT("Invalid OCSP response"));
            result = CURLE_SSL_INVALIDCERTSTATUS;
            goto end;
        }

        ch = SSL_get_peer_cert_chain(ssl);
        //st = SSL_CTX_get_cert_store(ctx);

#if ((OPENSSL_VERSION_NUMBER <= 0x1000201fL) /* Fixed after 1.0.2a */ || \
     (defined(LIBRESSL_VERSION_NUMBER) &&                               \
      LIBRESSL_VERSION_NUMBER <= 0x2040200fL))
        /* The authorized responder cert in the OCSP response MUST be signed by the
           peer cert's issuer (see RFC6960 section 4.2.2.2). If that's a root cert,
           no problem, but if it's an intermediate cert OpenSSL has a bug where it
           expects this issuer to be present in the chain embedded in the OCSP
           response. So we add it if necessary. */

           /* First make sure the peer cert chain includes both a peer and an issuer,
              and the OCSP response contains a responder cert. */
        if (sk_X509_num(ch) >= 2 && sk_X509_num(br->certs) >= 1) {
            X509 *responder = sk_X509_value(br->certs, sk_X509_num(br->certs) - 1);

            /* Find issuer of responder cert and add it to the OCSP response chain */
            for (i = 0; i < sk_X509_num(ch); i++) {
                X509 *issuer = sk_X509_value(ch, i);
                if (X509_check_issued(issuer, responder) == X509_V_OK) {
                    if (!OCSP_basic_add1_cert(br, issuer)) {
                        UE_LOG(LogOpenSSL, Warning, TEXT("Could not add issuer cert to OCSP response"));
                        result = CURLE_SSL_INVALIDCERTSTATUS;
                        goto end;
                    }
                }
            }
        }
#endif
        // 因为store的验证放到了各平台的native代码里，所以这里就不做store的验证了，只验证revoke
        //if (OCSP_basic_verify(br, ch, st, 0) <= 0) {
        //    UE_LOG(LogOpenSSL, Warning, TEXT("OCSP response verification failed"));
        //    result = CURLE_SSL_INVALIDCERTSTATUS;
        //    goto end;
        //}

        for (i = 0; i < OCSP_resp_count(br); i++) {
            int cert_status, crl_reason;
            OCSP_SINGLERESP *single = NULL;

            ASN1_GENERALIZEDTIME *rev, *thisupd, *nextupd;

            single = OCSP_resp_get0(br, i);
            if (!single)
                continue;

            cert_status = OCSP_single_get0_status(single, &crl_reason, &rev,
                &thisupd, &nextupd);

            if (!OCSP_check_validity(thisupd, nextupd, 300L, -1L)) {
                UE_LOG(LogOpenSSL, Warning, TEXT("OCSP response has expired"));
                result = CURLE_SSL_INVALIDCERTSTATUS;
                goto end;
            }

            UE_LOG(LogOpenSSL, Log, TEXT("SSL certificate status: %s (%d)\n"),
                ANSI_TO_TCHAR(OCSP_cert_status_str(cert_status)), cert_status);

            switch (cert_status) {
            case V_OCSP_CERTSTATUS_GOOD:
                break;

            case V_OCSP_CERTSTATUS_REVOKED:
                result = CURLE_SSL_INVALIDCERTSTATUS;

                UE_LOG(LogOpenSSL, Warning, TEXT("SSL certificate revocation reason: %s (%d)"),
                    ANSI_TO_TCHAR(OCSP_crl_reason_str(crl_reason)), crl_reason);
                goto end;

            case V_OCSP_CERTSTATUS_UNKNOWN:
                result = CURLE_SSL_INVALIDCERTSTATUS;
                goto end;
            }
        }

    end:
        if (br) OCSP_BASICRESP_free(br);
        OCSP_RESPONSE_free(rsp);

        return result;
    }
#endif

    EOpenSSLState ossl_connect(int fd, const char* hostname)
    {
        check(!ssl);
        const SSL_METHOD* meth = TLSv1_2_client_method();
        ctx = SSL_CTX_new(meth);
        check(ctx);

        SSL_CTX_set_default_verify_paths(ctx);

        ssl = SSL_new(ctx);
        check(ssl);        

#if PLATFORM_WINDOWS
        strcpy_s(host_name, sizeof(host_name), hostname);
#else
        strcpy(host_name, hostname);
#endif
        if (!SSL_set_tlsext_host_name(ssl, host_name))
        {
            UE_LOG(LogOpenSSL, Warning, TEXT("Unable to set TLS servername: %s"), ANSI_TO_TCHAR(hostname));
            Close();
            return EOpenSSLState::NotConnected;
        }

        /* Try building a chain using issuers in the trusted store first to avoid
        problems with server-sent legacy intermediates.
        Newer versions of OpenSSL do alternate chain checking by default which
        gives us the same fix without as much of a performance hit (slight), so we
        prefer that if available.
        https://rt.openssl.org/Ticket/Display.html?id=3621&user=guest&pass=guest
        */
        //X509_STORE_set_flags(SSL_CTX_get_cert_store(ctx),
        //    X509_V_FLAG_TRUSTED_FIRST);

        /* SSL always tries to verify the peer, this only says whether it should
       * fail to connect if the verification fails, or if it should continue
       * anyway. In the latter case the result of the verification is checked with
       * SSL_get_verify_result() below. */
        SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, NULL);

#if USE_OCSP
        has_recved_ocsp_result = false;
        SSL_set_tlsext_status_type(ssl, TLSEXT_STATUSTYPE_ocsp);
		#pragma warning(push )
		#pragma warning(disable : 4191)
        SSL_CTX_set_tlsext_status_cb(ctx, ocsp_resp_cb);
		#pragma warning(pop)
        SSL_CTX_set_tlsext_status_arg(ctx, this);
#endif

        SSL_set_fd(ssl, fd);

        // 不能判错误码，第一次调用必是SSL_ERROR_SYSCALL
        connection_state = EOpenSSLState::Connecting;
        SSL_connect(ssl);
        return connection_state;
    }

    EOpenSSLState ossl_verify_state()
    {
        if (!ssl)
        {
            connection_state = EOpenSSLState::NotConnected;
        }
        else if (connection_state == Connecting)
        {
            int err = SSL_connect(ssl);      
            if (err == 1)
            {
#if USE_OCSP
                if (has_recved_ocsp_result)
#endif
                {
                    if (ossl_verify_cert(host_name))
                    {
                        connection_state = EOpenSSLState::ConnectSuccessed;
                    }
                    else
                    {
                        connection_state = EOpenSSLState::ConnectFailed;
                    }
                }
            }
            else
            {
                if (ossl_verify_error(err, TEXT("verify state failed")))
                {
                    connection_state = EOpenSSLState::Connecting;
                }
                else
                {
                    connection_state = EOpenSSLState::ConnectFailed;
                }
            }
        }

        return connection_state;
    }

    void ossl_close()
    {
        if (ssl)
        {
            SSL_shutdown(ssl);
            SSL_free(ssl);
            ssl = nullptr;
        }
        if(ctx)
        {
            SSL_CTX_free(ctx);            
            ctx = nullptr;
        }
        connection_state = EOpenSSLState::NotConnected;
        memset(host_name, 0, sizeof(host_name));
#if USE_OCSP
        has_recved_ocsp_result = false;
#endif
    }

    int ossl_verifyhost(X509 *server_cert, const char* hostname)
    {
        bool matched = SSL_FALSE;
        int target = GEN_DNS; /* target type, GEN_DNS or GEN_IPADD */
        size_t addrlen = 0;
        //struct Curl_easy *data = conn->data;
        STACK_OF(GENERAL_NAME) *altnames;
#ifdef ENABLE_IPV6
        struct in6_addr addr;
#else
        struct in_addr addr;
#endif
        ECurlReturnCode result = CURLE_OK;
        bool dNSName = SSL_FALSE; /* if a dNSName field exists in the cert */
        bool iPAddress = SSL_FALSE; /* if a iPAddress field exists in the cert */
        //const char * const hostname = SSL_IS_PROXY() ? conn->http_proxy.host.name :
        //    conn->host.name;
        //const char * const dispname = SSL_IS_PROXY() ?
        //    conn->http_proxy.host.dispname : conn->host.dispname;

#ifdef ENABLE_IPV6
        if (inet_pton(AF_INET6, hostname, &addr)) {
            target = GEN_IPADD;
            addrlen = sizeof(struct in6_addr);
        }
        else
#endif
            if (inet_pton(AF_INET, hostname, &addr)) {
                target = GEN_IPADD;
                addrlen = sizeof(struct in_addr);
            }

        /* get a "list" of alternative names */
        altnames = (STACK_OF(GENERAL_NAME)*)X509_get_ext_d2i(server_cert, NID_subject_alt_name, NULL, NULL);

        if (altnames) {
            int numalts;
            int i;
            bool dnsmatched = SSL_FALSE;
            bool ipmatched = SSL_FALSE;

            /* get amount of alternatives, RFC2459 claims there MUST be at least
               one, but we don't depend on it... */
            numalts = sk_GENERAL_NAME_num(altnames);

            /* loop through all alternatives - until a dnsmatch */
            for (i = 0; (i < numalts) && !dnsmatched; i++) {
                /* get a handle to alternative name number i */
                const GENERAL_NAME *check = sk_GENERAL_NAME_value(altnames, i);

                if (check->type == GEN_DNS)
                    dNSName = SSL_TRUE;
                else if (check->type == GEN_IPADD)
                    iPAddress = SSL_TRUE;

                /* only check alternatives of the same type the target is */
                if (check->type == target) {
                    /* get data and length */
                    const char *altptr = (char *)ASN1_STRING_data(check->d.ia5);
                    size_t altlen = (size_t)ASN1_STRING_length(check->d.ia5);

                    switch (target) {
                    case GEN_DNS: /* name/pattern comparison */
                      /* The OpenSSL man page explicitly says: "In general it cannot be
                         assumed that the data returned by ASN1_STRING_data() is null
                         terminated or does not contain embedded nulls." But also that
                         "The actual format of the data will depend on the actual string
                         type itself: for example for and IA5String the data will be ASCII"

                         Gisle researched the OpenSSL sources:
                         "I checked the 0.9.6 and 0.9.8 sources before my patch and
                         it always 0-terminates an IA5String."
                      */
                        if ((altlen == strlen(altptr)) &&
                            /* if this isn't true, there was an embedded zero in the name
                               string and we cannot match it. */
                            //subj_alt_hostcheck(data, altptr, hostname, dispname)
                            Curl_cert_hostcheck(altptr, hostname)) {                            
                            dnsmatched = SSL_TRUE;
                        }
                        break;

                    case GEN_IPADD: /* IP address comparison */
                      /* compare alternative IP address if the data chunk is the same size
                         our server IP address is */
                        if ((altlen == addrlen) && !memcmp(altptr, &addr, altlen)) {
                            ipmatched = SSL_TRUE;
                            //infof(data,
                            //    " subjectAltName: host \"%s\" matched cert's IP address!\n",
                            //    dispname);
                        }
                        break;
                    }
                }
            }
            GENERAL_NAMES_free(altnames);

            if (dnsmatched || ipmatched)
                matched = SSL_TRUE;
        }

        if (matched)
            /* an alternative name matched */
            ;
        else if (dNSName || iPAddress) {
            UE_LOG(LogOpenSSL, Log, TEXT("subjectAltName does not match %s"), ANSI_TO_TCHAR(hostname));
            UE_LOG(LogOpenSSL, Warning, TEXT("SSL: no alternative certificate subject name matches, target host name '%s'"), ANSI_TO_TCHAR(hostname));
            result = CURLE_PEER_FAILED_VERIFICATION;
        }
        else {
            /* we have to look to the last occurrence of a commonName in the
               distinguished one to get the most significant one. */
            int j, i = -1;

            /* The following is done because of a bug in 0.9.6b */

            unsigned char *nulstr = (unsigned char *)"";
            unsigned char *peer_CN = nulstr;

            X509_NAME *name = X509_get_subject_name(server_cert);
            if (name)
                while ((j = X509_NAME_get_index_by_NID(name, NID_commonName, i)) >= 0)
                    i = j;

            /* we have the name entry and we will now convert this to a string
               that we can use for comparison. Doing this we support BMPstring,
               UTF8 etc. */

            if (i >= 0) {
                ASN1_STRING *tmp =
                    X509_NAME_ENTRY_get_data(X509_NAME_get_entry(name, i));

                /* In OpenSSL 0.9.7d and earlier, ASN1_STRING_to_UTF8 fails if the input
                   is already UTF-8 encoded. We check for this case and copy the raw
                   string manually to avoid the problem. This code can be made
                   conditional in the future when OpenSSL has been fixed. Work-around
                   brought by Alexis S. L. Carvalho. */
                if (tmp) {
                    if (ASN1_STRING_type(tmp) == V_ASN1_UTF8STRING) {
                        j = ASN1_STRING_length(tmp);
                        if (j >= 0) {
                            peer_CN = (unsigned char*)OPENSSL_malloc(j + 1);
                            if (peer_CN) {
                                memcpy(peer_CN, ASN1_STRING_data(tmp), j);
                                peer_CN[j] = '\0';
                            }
                        }
                    }
                    else /* not a UTF8 name */
                        j = ASN1_STRING_to_UTF8(&peer_CN, tmp);

                    if (peer_CN && ((int)(strlen((char *)peer_CN)) != j)) {
                        /* there was a terminating zero before the end of string, this
                           cannot match and we return failure! */
                        UE_LOG(LogOpenSSL, Warning, TEXT("SSL: illegal cert name field"));
                        result = CURLE_PEER_FAILED_VERIFICATION;
                    }
                }
            }

            bool is_utf8 = false;
            if (peer_CN == nulstr)
                peer_CN = NULL;
            else {
                /* convert peer_CN from UTF8 */
                const ANSICHAR* old = (const ANSICHAR*)peer_CN;
                size_t len = strlen(TCHAR_TO_UTF8(ANSI_TO_TCHAR(old)));
                peer_CN = (unsigned char*)OPENSSL_malloc(len + 1);
#if PLATFORM_WINDOWS
                strcpy_s((char*)peer_CN, len+1, (const char*)(TCHAR_TO_UTF8(ANSI_TO_TCHAR(old))));
#else
                strcpy((char*)peer_CN, (const char*)(TCHAR_TO_UTF8(ANSI_TO_TCHAR(old))));
#endif
                peer_CN[len] = '\0';
                OPENSSL_free((char*)old);
                is_utf8 = true;

                //CURLcode rc = Curl_convert_from_utf8(data, (char *)peer_CN,
                //    strlen((char *)peer_CN));
                ///* Curl_convert_from_utf8 calls failf if unsuccessful */
                //if (rc) {
                //    OPENSSL_free(peer_CN);
                //    return rc;
                //}
            }

            if (result)
                /* error already detected, pass through */
                ;
            else if (!peer_CN) {
                UE_LOG(LogOpenSSL, Warning,
                    TEXT("SSL: unable to obtain common name from peer certificate"));
                result = CURLE_PEER_FAILED_VERIFICATION;
            }
            else if (!Curl_cert_hostcheck((const char *)peer_CN, hostname)) {
                UE_LOG(LogOpenSSL, Warning, TEXT("SSL: certificate subject name '%s' does not match, target host name '%s'"), 
                    is_utf8 ? UTF8_TO_TCHAR(peer_CN) : ANSI_TO_TCHAR((const ANSICHAR*)peer_CN), ANSI_TO_TCHAR((const ANSICHAR*)hostname));
                result = CURLE_PEER_FAILED_VERIFICATION;
            }
            else {
                UE_LOG(LogOpenSSL, Log, TEXT(" common name: %s (matched)\n"), is_utf8 ? UTF8_TO_TCHAR(peer_CN) : ANSI_TO_TCHAR((const ANSICHAR*)peer_CN));
            }
            if (peer_CN)
                OPENSSL_free(peer_CN);
        }

        return result;
    }

    bool ossl_verify_cert(const char* hostname)
    {        
        X509* server_cert = SSL_get_peer_certificate(ssl);
        check(server_cert);

        class AutoRelease
        {
        public:
            AutoRelease(X509* incert)
                : cert(incert)
            {}
            ~AutoRelease()
            {
                X509_free(cert);
            }
            X509* cert;
        } r(server_cert);

        if (CURLE_OK != ossl_verifyhost(server_cert, hostname))
        {
            return false;
        }

#if USE_OCSP
        auto ocsp_result = ossl_verify_ocsp_status();
        if (ocsp_result != CURLE_OK && ocsp_result != NO_OCSP)
        {
            return false;
        }
#endif
         
        STACK_OF(X509) *sk = SSL_get_peer_cert_chain(ssl);
        if (!sk)
        {
            UE_LOG(LogOpenSSL, Warning, TEXT("SSL_get_peer_cert_chain failed"));
            return false;
        }
        
        TArray<TKeyValuePair<uint8*, int32> > CertChain;
        int cert_num = sk_X509_num(sk);
        CertChain.Reserve(cert_num);

        for (int ii = 0; ii < cert_num; ii++)
        {            
            X509* c = sk_X509_value(sk, ii);
            uint8* der_format_data = nullptr;
            int32 len = i2d_X509(c, &der_format_data);
            CertChain.Add(TKeyValuePair<uint8*, int32>(der_format_data, len));
        }

        bool result = FGamePlatformMisc::VerifyCertification(CertChain);

        for (int ii = 0; ii < cert_num; ii++)
        {
            OPENSSL_free(CertChain[ii].Key);
        }

        return result;
    }

    bool ossl_verify_error(int errorCode, const TCHAR* desc)
    {
        bool ret = false;
        int detail = SSL_get_error(ssl, errorCode);
        if (SSL_ERROR_WANT_READ == detail)
        {
            ret = true;
        }
        else if (SSL_ERROR_WANT_WRITE == detail)
        {
            ret = true;
        }
        else
        {            
            //char error_buffer[128];
            //ERR_error_string_n(ERR_get_error(), error_buffer, sizeof(error_buffer));
            UE_LOG(LogOpenSSL, Warning, TEXT("%s, ssl error: %d, other error: %d"), desc, detail, ERR_get_error());
        }
        return ret;
    }

    //////////////////////////////////////////////////////////////////////////
    bool Init()
    {
        OpenSSL_add_ssl_algorithms();
        SSL_load_error_strings();
        return true;
    }

    void Uninit()
    {
        Close();
    }

    bool Connect(int fd, const TCHAR* HostName)
    {
        check(ssl == nullptr);
        ossl_connect(fd, TCHAR_TO_ANSI(HostName));

        if (connection_state == EOpenSSLState::ConnectFailed)
        {
            ossl_close();
            return false;
        }

        return true;
    }

    EOpenSSLState VerifyState()
    {
        return ossl_verify_state();
    }

    void Close()
    {
        ossl_close();
    }

    bool Send(const uint8* Data, int32 BufferSize, int32& BytesSent)
    {
        bool ret = false;
        BytesSent = 0;

        int sentOrError = SSL_write(ssl, (void*)Data, BufferSize);
        if (sentOrError > 0)
        {
            BytesSent = sentOrError;
            ret = true;
        }
        else
        {
            ret = ossl_verify_error(sentOrError, TEXT("send failed"));
        }

        return ret;
    }

    bool Recv(uint8* Data, int32 BufferSize, int32& BytesRead)
    {
        bool ret = false;
        BytesRead = 0;

        int readOrError = SSL_read(ssl, (void*)Data, BufferSize);
        if (readOrError > 0)
        {
            BytesRead = readOrError;
            ret = true;
        }
        else
        {
            ret = ossl_verify_error(readOrError, TEXT("recv failed"));
        }

        return ret;
    }
};

FOpenSSLHelper::FOpenSSLHelper()
    : Impl(MakeShareable(new FOpenSSLHelper::FImplement()))
{
}

bool FOpenSSLHelper::Init()
{
    return Impl->Init();
}

void FOpenSSLHelper::Uninit()
{
    Impl->Uninit();
}

bool FOpenSSLHelper::Connect(int fd, const TCHAR* HostName)
{
    return Impl->Connect(fd, HostName);
}

void FOpenSSLHelper::Close()
{
    Impl->Close();
}

EOpenSSLState FOpenSSLHelper::VerifyState()
{
    return Impl->VerifyState();
}

bool FOpenSSLHelper::Send(const uint8* Data, int32 BufferSize, int32& BytesSent)
{
    return Impl->Send(Data, BufferSize, BytesSent);
}

bool FOpenSSLHelper::Recv(uint8* Data, int32 BufferSize, int32& BytesRead)
{
    return Impl->Recv(Data, BufferSize, BytesRead);
}
