// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Game/ChannelSdk/ChannelSdkBase.h"
#include "ChannelSdkManager.generated.h"

DECLARE_DYNAMIC_DELEGATE(FSdkLoginFailDelegate);
DECLARE_DYNAMIC_DELEGATE_OneParam(FSdkLoginDelegate, const FString&, jsData);

UCLASS(config = Game)
class CLIENT_API UChannelSdkManager : public UObject
{
    GENERATED_UCLASS_BODY()

public:
    void Init();

    UFUNCTION()
    const FString GetChannelName();

    UFUNCTION()
    bool IsValidSdk();

    UFUNCTION()
    void LoginSdk();                    //登录sdk

    UFUNCTION()
    bool IsLoginSdkSuccessful();

    UFUNCTION()
    void Login();                       //登录游戏

    UFUNCTION()
    void LoginSdkAndGame();             //先登录sdk，成功后直接登录游戏

    UFUNCTION()
    void Logout();

    UFUNCTION()
    void CustomEvent(const FString& EventData);

    UFUNCTION()
    void Exit();

    UFUNCTION()
    bool Pay(const FString& PayInfo);

    UFUNCTION()
    void SwitchAccount();
    
    UFUNCTION()
    bool IsBindAccount();

    UFUNCTION()
    void OnCreateRole(const FString& RoleInfo);

    UFUNCTION()
    void OnRoleLevelup(int nNewLevel);

    UFUNCTION()
    void OnEnterGame();

    UFUNCTION()
    void OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal);

    UFUNCTION()
    void OnLoginSuccessfully(const FString& UserData);

    UFUNCTION()
    void SetRoleIdAndName(const FString& RoleId, const FString& RoleName);

    UFUNCTION()
    void SetRoleLevel(const FString& RoleLevel);

    UFUNCTION()
    void SetServerIDAndName(const FString& ServerID, const FString& ServerName);

    UFUNCTION()
    bool OpenFAQWeb();

    UFUNCTION()
    bool OpenHrefWeb(const FString& Url);

    UFUNCTION()
    bool ShowScoreDialog();

    UFUNCTION()
    bool OpenUCenter();

    UFUNCTION()
    bool AssociaAccount();

    UFUNCTION()
    bool ShowBindTipsView();

    UFUNCTION()
    FString GetChannel();

    UPROPERTY()
    FSdkLoginFailDelegate OnSdkLoginFail;

    UPROPERTY()
    FSdkLoginDelegate OnSdkLogin;
private:
    TUniquePtr<IChannelSdkBase> CurrentSdk;
};

