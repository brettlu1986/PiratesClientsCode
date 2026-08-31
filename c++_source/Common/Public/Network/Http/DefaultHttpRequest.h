#pragma once

#include "Interfaces/IHttpRequest.h"
#include "Network/Http/HttpRequestContext.h"

class FDefaultHttpRequest
{
public:
    void OnProcessRequestComplete(FHttpRequestPtr Req, FHttpResponsePtr Resp, bool SuccessConnected);

    TSharedPtr<IHttpRequest> Request;
    FOnHttpRequestCompletedDelegate OnHttpRequestCompletedDelegate;
    FOnHttpRequestWithHeaderCompletedDelegate OnHttpRequestWithHeaderCompletedDelegate;

    DECLARE_DELEGATE_OneParam(FOnFinishedDelegate, FDefaultHttpRequest* const);
    FOnFinishedDelegate OnFinished;
    
    void   AddResponseHeader(const FString& Header);
private:
    FString  ResponseHeader;
};
