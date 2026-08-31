#include "Network/Http/DefaultHttpRequest.h"
#include "Common.h"
#include "Interfaces/IHttpResponse.h"

void FDefaultHttpRequest::OnProcessRequestComplete(FHttpRequestPtr Req, FHttpResponsePtr Resp, bool SuccessConnected)
{
    if (SuccessConnected && Resp.IsValid())
    {
        if (!ResponseHeader.IsEmpty())
        {
            FString HeaderContent = Resp->GetHeader(ResponseHeader);

            OnHttpRequestWithHeaderCompletedDelegate.ExecuteIfBound(Resp->GetResponseCode(), Resp->GetContentAsString(),
                HeaderContent);
        }
        else
        {
            OnHttpRequestCompletedDelegate.ExecuteIfBound(Resp->GetResponseCode(), Resp->GetContentAsString());
        }
    }
    else
    {
        if (!ResponseHeader.IsEmpty())
        {
            OnHttpRequestWithHeaderCompletedDelegate.ExecuteIfBound(-1, TEXT(""), TEXT(""));
        }
        else
        {
            OnHttpRequestCompletedDelegate.ExecuteIfBound(-1, TEXT(""));
        }
        
    }
    OnFinished.ExecuteIfBound(this);
}

void FDefaultHttpRequest::AddResponseHeader(const FString& Header)
{
    ResponseHeader = Header;
}