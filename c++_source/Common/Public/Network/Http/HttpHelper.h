#pragma once

#include "KMObject.h"
#include "HttpRequestContext.h"
#include "HttpHelper.generated.h"

UCLASS()
class COMMON_API UHttpHelper : public UKMObject
{
    GENERATED_BODY()
public:
    UFUNCTION(BlueprintCallable, Category = "HttpHelper")
    bool SendGetRequest(const FString& URL, FOnHttpRequestCompletedDelegate Callback);

    UFUNCTION(BlueprintCallable, Category = "HttpHelper")
    bool SendPostRequest(const FString& HeaderName, const FString& HeaderValue, const FString& URL, 
        const FString& Content, FOnHttpRequestCompletedDelegate Callback);

    // send a get request with param HeaderName and param HeaderValue in headers, and get the content of param ResponseHeader in response headers.
    UFUNCTION(BlueprintCallable, Category = "HttpHelper")
    bool SendGetRequestWithHeader(const FString& URL, const FString& HeaderName, const FString& HeaderValue,
        const FString& ResponseHeader, FOnHttpRequestWithHeaderCompletedDelegate Callback);

    UFUNCTION(BlueprintPure, Category = "HttpHelper")
    static FString UrlEncode(const FString& InString);

    UFUNCTION(BlueprintCallable, Category = "HttpHelper")
    void CancelAllRequests();

private:
    UPROPERTY()
    FOnHttpRequestCompletedDelegate OnHttpRequestCompletedDelegateSignature;

    UPROPERTY()
    FOnHttpRequestWithHeaderCompletedDelegate OnHttpRequestWithHeaderCompletedDelegateSignature;

    TMap<class FDefaultHttpRequest* const, TSharedPtr<class FDefaultHttpRequest>> HttpRequestMap;
    void OnHttpRequestFinished(FDefaultHttpRequest* const HttpRequestPtr);
};
