#pragma once

#include "ClientSdkDelegate.generated.h"


UCLASS()
class CLIENT_API UClientSdkDelegate : public UObject
{
    GENERATED_BODY()

	DECLARE_DYNAMIC_DELEGATE(FOnLogin);
    DECLARE_DYNAMIC_DELEGATE(FOnLogout);
    DECLARE_DYNAMIC_DELEGATE(FOnExit);
    DECLARE_DYNAMIC_DELEGATE(FOnBindSuccess);
    DECLARE_DYNAMIC_DELEGATE(FOnBackToLogin);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnPayResult, int32, code, const FString&, tradeNo);
    //DECLARE_DYNAMIC_DELEGATE(FOnPayResult);
    

public:
    UPROPERTY()
    FOnLogin OnLogin;

    UPROPERTY()
    FOnLogout OnLogout;

    UPROPERTY()
    FOnBindSuccess OnBindAccountSuccess;

    UPROPERTY()
    FOnExit OnExit;

    UPROPERTY()
    FOnExit OnNoChannelExit;

    UPROPERTY()
    FOnPayResult OnPayResult;

    UPROPERTY()
    FOnBackToLogin OnBackToLogin;
};