// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "DataSdkManager.generated.h"

UCLASS(config = Game)
class CLIENT_API UDataSdkManager : public UObject
{
    GENERATED_UCLASS_BODY()
public:
    void Init();
    UFUNCTION()
    void OnAccountLogin(const FString& AccountId);						//账号登录
    UFUNCTION()
    void OnAccountLogout();												//账号退出
    UFUNCTION()
    void OnRoleLogin(const FString& JsonData);							//角色登录
    UFUNCTION()
    void OnRoleLogout();													//角色退出
    UFUNCTION()
    void OnRoleLevelUp(const FString& RoleLevel);						//角色升级
    UFUNCTION()
    void OnPayFinish(const FString& JsonData);							//支付完成
    UFUNCTION()
    void OnEvent(const FString& EventId, const FString& EventDesc);		//自定义事件
    UFUNCTION()
    void OnCustomEvent(const FString& JsonData);						    //自定义事件
    UFUNCTION()
    void Ping(const FString& Host);										//测试网络延迟
    UFUNCTION()
    void OnMissionBegin(const FString& JsonData);						//关卡开始
    UFUNCTION()
    void OnMissionSuccess(const FString& JsonData);						//关卡成功完成
    UFUNCTION()
    void OnMissionFail(const FString& JsonData);							//关卡失败
    UFUNCTION()
    void OnVirtualCurrencyGain(const FString& JsonData);					//获得虚拟货币
    UFUNCTION()
    void OnVirtualCurrencyGainForPurchased(const FString& JsonData);		//充值购买虚拟货币
    UFUNCTION()
    void OnVirtualCurrencyConsume(const FString& JsonData);				//消耗虚拟货币
    UFUNCTION()
    void OnItemGain(const FString& JsonData);							//获得物品
    UFUNCTION()
    void OnItemConsume(const FString& JsonData);							//消耗物品
    UFUNCTION()
    void OnGameLoadResource();											//标准事件
    UFUNCTION()
    void OnGameLoadConfig();												//标准事件
    UFUNCTION()
    void OnOpenAnnouncement();											//标准事件
    UFUNCTION()
    void OnCloseAnnouncement();											//标准事件
    UFUNCTION()
    void OnNewUserMission();												//标准事件
    UFUNCTION()
    void OnPrivateFunCodeUse(const FString& JsonData);					//私有功能码
    UFUNCTION()
    void OnPublicFunCodeUse(const FString& JsonData);					//公有功能码
};

