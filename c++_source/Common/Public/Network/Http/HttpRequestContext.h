#pragma once

#include "HttpRequestContext.generated.h"

DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnHttpRequestCompletedDelegate, int32, RetCode, const FString&, Content);
DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnHttpRequestWithHeaderCompletedDelegate, int32, RetCode, const FString&, Content, const FString&, ResponseHeaderValue);

UCLASS()
class UHttpRequestContext : public UObject
{
    GENERATED_BODY()
};