#pragma once

#include "Protobuf.h"
#include "Networking.h"
#include "OpenSSLHelper.h"
#include "TcpSocket.generated.h"

UCLASS()
class COMMON_API UTcpSocket : public UObject
{
    GENERATED_UCLASS_BODY()
public:

    //UTcpSocket(FSocket* ConnectedSocket);

    //virtual ~UTcpSocket();

    // Interfaces
public:

    void Init(int32 InSocketID,
        const FString& InDescription,
        ProtobufCodec* InCodec,
        int32 InSocketSendBufferSize,
        int32 InSocketRecvBufferSize,
        float InConnectTimeout);

    // Connect asynchronously, returns:
    //  false if Endpoint is invalid or some error occurs.
    //  true if connection is in-progress.
    // Because we are using non-blocking sockets,
    // the actual connection state is polled in Tick(float DeltaTime) until connected or reached ConnectTimeout seconds.
    // Endpoint format: [ip]:[port]
    bool Connect(const FString& Endpoint);
    bool Connect(const FString& DomainName, uint32 Port, bool InUseOpenSSL);    // support ipv6    
    bool Connect(const FInternetAddr& Addr);

    // 当域名解析不了但又要用openssl，那么使用此函数
    bool ConnectIPWithOpenSSL(const FString& Endpoint, const FString& InDomainName);

    bool IsConnected() const { return State == ETcpSocketState::Connected; }

    void Close();

    // Serialize the message and send it through the underlying TCP socket.
    bool Send(const google::protobuf::Message& Message);

    void Tick(float DeltaTime);
    // Properties
public:

    int32 GetSocketID() const { return SocketID; }
    void SetIgnoreSpecificError(bool bIgnore) { IgnoreSpecificError = bIgnore; }

    // Events
public:
    
    // Callback for connection events
    DECLARE_DELEGATE_OneParam(FTcpSocketDelegate, UTcpSocket&)

    // Params: 
    // SocketID: int32
    // MessageID: uint16
    // Data: uint8*
    // Size: int32
    DECLARE_DELEGATE_FourParams(FTcpSocketDispatchDelegate, int32, uint16, const uint8*, int32)

    // Called when a connect operation is complete (either successful or failed)
    // Call IsConnected() to get the connection result.
    FTcpSocketDelegate& OnConnectResultDelegate() { return ConnectResultDelegate; }

    // Called when the socket becomes disconnected from connected state.
    FTcpSocketDelegate& OnDisconnect() { return DisconnectDelegate; }

    FTcpSocketDispatchDelegate& OnDispatch() { return DispatchDelegate; }


private:
    FSocket* CreateSocket() const;

    // Poll connection state, because we are using non-blocking socket.
    // Return: If still connecting
    void PollConnectionState(float DeltaTime);

    // Receive and dispatch all available messages, returns false if error occurs.
    //
    // Note:
    // Normally we would return a buffer that holds the message to the caller, and it's up to the caller to decode and dispatch it.
    // however this requires additional memory allocation and copying, so we inject ProtobufCodec and ProtobufDispatcher into the TcpSocket to avoid that.
    void Recv();
    
    void Send();
    bool Send(const uint8* Buffer, int32 BufferSize, int32& TotalBytesSent); 
    void Dispatch(uint16 MessageID, const uint8* Data, int32 Size);
    void VerifyNetState(float DeltaTime);

private:
    bool SendRaw(const uint8* Data, int32 BufferSize, int32& BytesSent);
    bool RecvRaw(uint8* Data, int32 BufferSize, int32& BytesRead);

private:
    enum class ETcpSocketState
    {
        NotConnected = 0,
        Connecting,
        Connected,
    };

    class FBuffer
    {
    public:
        FBuffer()
            : Buffer(nullptr)
            , BufferSize(0)
            , Head(0)
            , Tail(0)
        {
        }
        ~FBuffer()
        {
            Uninit();
        }
        inline void Init(int32 Size) 
        {
            check(Buffer == nullptr);
            check(Size > 0);
            BufferSize = Size;
            Buffer = (uint8*)FMemory::Malloc(BufferSize);
        }
        inline void Uninit()
        {
            if (Buffer) 
            { 
                FMemory::Free(Buffer);
            }
            Buffer = nullptr;
            Head = 0;
            Tail = 0;
        }
        inline void Reorganize()
        {
            int32 UsedSize = GetUsedSize();
            if (UsedSize > 0)
            {
                FMemory::Memmove(Buffer, Buffer + Head, UsedSize);
            }
            Head = 0;
            Tail = UsedSize;
        }
        inline void Pop(int32 Size)
        {
            Head += Size; 
            check(Head <= Tail);
            if (GetUsedSize() == 0)
            {
                Reset();
            }
            else if (GetUnusedSize() == 0)
            {
                Reorganize();
            }
        }
        inline void Push(int32 Size)
        { 
            Tail += Size; 
            check(Tail <= BufferSize);
        }
        inline void Push(const uint8* SrcBuffer, int32 Size)
        {
            check(GetUnusedSize() >= Size);
            FMemory::Memcpy(GetUnusedBuffer(), SrcBuffer, Size);
            Push(Size);
        }
        inline void Reset() { Head = 0; Tail = 0; }
        inline uint8* GetUnusedBuffer() const { return Buffer + Tail; }
        inline int32 GetUnusedSize() const { return BufferSize - Tail; }
        inline const uint8* GetUsedBuffer() const { return Buffer + Head; }
        inline const int32 GetUsedSize() const { return Tail - Head; }
        
    private:
        uint8* Buffer;
        int32 BufferSize;
        int32 Head;
        int32 Tail;
    };


private:
    FTcpSocketDelegate ConnectResultDelegate;
    FTcpSocketDelegate DisconnectDelegate;
    FTcpSocketDispatchDelegate DispatchDelegate;

private:
    int32 SocketID;
    FString Description;
    ProtobufCodec* Codec;
    int32 SocketSendBufferSize;
    int32 SocketRecvBufferSize;
    float ConnectTimeout;
    float TimeSinceConnectBegin;
    float CheckNetStateTime;
    TUniquePtr<FSocket> Socket;
    ETcpSocketState State;
    bool IgnoreSpecificError;
    FString ConnectionInfo;
    uint32 ConnectionPort;
    FString DomainName;
    bool UseOpenSSL;

    FBuffer RecvBuffer;
    FBuffer SendBuffer;    
    FOpenSSLHelper OpenSSLHelper;
};
