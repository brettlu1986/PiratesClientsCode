#include "Network/Http/HttpHelper.h"
#include "Common.h"
#include "Http.h"
#include "Network/Http/DefaultHttpRequest.h"

DEFINE_LOG_CATEGORY_STATIC(HttpHelperLog, Log, All)

bool UHttpHelper::SendGetRequest(const FString& URL, FOnHttpRequestCompletedDelegate Callback)
{
    bool Ret = false;
    TSharedPtr<FDefaultHttpRequest> HttpRequestPtr = MakeShareable(new FDefaultHttpRequest());
    auto& HttpModule = FHttpModule::Get();
    check(HttpModule.IsHttpEnabled());
    auto Request = HttpModule.CreateRequest();
    HttpRequestPtr->Request = Request;
    HttpRequestPtr->OnHttpRequestCompletedDelegate = Callback;
    Request->SetVerb("Get");
    Request->SetURL(URL);
    Request->OnProcessRequestComplete().BindSP(HttpRequestPtr.ToSharedRef(), &FDefaultHttpRequest::OnProcessRequestComplete);
    if (!Request->ProcessRequest())
    {
        UE_LOG(HttpHelperLog, Error, TEXT("FAILED to process get request."));
    }
    else
    {
        Ret = true;
        HttpRequestMap.Add(HttpRequestPtr.Get(), HttpRequestPtr);
        HttpRequestPtr->OnFinished.BindUObject(this, &UHttpHelper::OnHttpRequestFinished);
    }
    return Ret;
}

bool UHttpHelper::SendGetRequestWithHeader(const FString& URL, const FString& HeaderName, const FString& HeaderValue, const FString& ResponseHeader, 
    FOnHttpRequestWithHeaderCompletedDelegate Callback)
{
    bool Ret = false;
    TSharedPtr<FDefaultHttpRequest> HttpRequestPtr = MakeShareable(new FDefaultHttpRequest());
    auto& HttpModule = FHttpModule::Get();
    check(HttpModule.IsHttpEnabled());
    auto Request = HttpModule.CreateRequest();
    HttpRequestPtr->Request = Request;
    HttpRequestPtr->OnHttpRequestWithHeaderCompletedDelegate = Callback;
    Request->SetVerb("Get");
    Request->SetURL(URL);
    if (!HeaderName.IsEmpty() && !HeaderValue.IsEmpty())
    {
        Request->SetHeader(HeaderName, HeaderValue);
    }
    if (!ResponseHeader.IsEmpty())
    {
        HttpRequestPtr->AddResponseHeader(ResponseHeader);
    }
    else
    {
        HttpRequestPtr->AddResponseHeader(HeaderName);
    }
    Request->OnProcessRequestComplete().BindSP(HttpRequestPtr.ToSharedRef(), &FDefaultHttpRequest::OnProcessRequestComplete);
    if (!Request->ProcessRequest())
    {
        UE_LOG(HttpHelperLog, Error, TEXT("FAILED to process get request."));
    }
    else
    {
        Ret = true;
        HttpRequestMap.Add(HttpRequestPtr.Get(), HttpRequestPtr);
        HttpRequestPtr->OnFinished.BindUObject(this, &UHttpHelper::OnHttpRequestFinished);
    }
    return Ret;
}

bool UHttpHelper::SendPostRequest(const FString& HeaderName, const FString& HeaderValue, const FString& URL,
    const FString& Content, FOnHttpRequestCompletedDelegate Callback)
{
    bool Ret = false;
    TSharedPtr<FDefaultHttpRequest> HttpRequestPtr = MakeShareable(new FDefaultHttpRequest());
    auto& HttpModule = FHttpModule::Get();
    check(HttpModule.IsHttpEnabled());
    auto Request = HttpModule.CreateRequest();
    HttpRequestPtr->Request = Request;
    HttpRequestPtr->OnHttpRequestCompletedDelegate = Callback;
    Request->SetHeader(HeaderName, HeaderValue);
    Request->SetURL(URL);
    Request->SetVerb("POST");
    Request->SetContentAsString(Content);
    Request->OnProcessRequestComplete().BindSP(HttpRequestPtr.ToSharedRef(), &FDefaultHttpRequest::OnProcessRequestComplete);
    if (!Request->ProcessRequest())
    {
        UE_LOG(HttpHelperLog, Error, TEXT("FAILED to process post request."));
    }
    else
    {
        Ret = true;
        HttpRequestMap.Add(HttpRequestPtr.Get(), HttpRequestPtr);
        HttpRequestPtr->OnFinished.BindUObject(this, &UHttpHelper::OnHttpRequestFinished);
    }
    return Ret;
}

FString UHttpHelper::UrlEncode(const FString& InString)
{
    return FPlatformHttp::UrlEncode(InString);
}

void UHttpHelper::CancelAllRequests()
{
    for (auto Iter = HttpRequestMap.CreateIterator(); Iter; ++Iter)
    {
        TSharedPtr<FDefaultHttpRequest>& HttpRequestPtr = Iter->Value;
        HttpRequestPtr->OnFinished.Unbind();
        if (HttpRequestPtr->Request.IsValid())
        {
            HttpRequestPtr->Request->CancelRequest();
        }        
    }

    HttpRequestMap.Empty();
}

void UHttpHelper::OnHttpRequestFinished(FDefaultHttpRequest* const HttpRequestPtr)
{
    TWeakObjectPtr<UHttpHelper> ThisProxy(this);
    GetWorld()->GetTimerManager().SetTimerForNextTick([ThisProxy, HttpRequestPtr] {
        if (ThisProxy.IsValid())
        {
            UE_LOG(HttpHelperLog, Log, TEXT("remove http request."));
            ThisProxy->HttpRequestMap.Remove(HttpRequestPtr);
        }
    });
}