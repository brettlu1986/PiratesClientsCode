#include "Game/DataSdk/DataSdkManager.h"
#ifdef WITH_DATASDK
#include "DataSDKApi.h"
#endif
UDataSdkManager::UDataSdkManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

void UDataSdkManager::Init()
{
#ifdef WITH_DATASDK
    UDataSDKApi::Init();
#endif
}

void UDataSdkManager::OnAccountLogin(const FString& AccountId)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnAccountLogin(AccountId);
#endif
}

void UDataSdkManager::OnAccountLogout()
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnAccountLogout();
#endif
}

void UDataSdkManager::OnRoleLogin(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnRoleLogin(JsonData);
#endif
}

void UDataSdkManager::OnRoleLogout()
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnRoleLogout();
#endif
}

void UDataSdkManager::OnRoleLevelUp(const FString& RoleLevel)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnRoleLevelUp(RoleLevel);
#endif
}

void UDataSdkManager::OnPayFinish(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnPayFinish(JsonData);
#endif
}

void UDataSdkManager::OnEvent(const FString& EventId, const FString& EventDesc)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnEvent(EventId, EventDesc);
#endif
}

void UDataSdkManager::OnCustomEvent(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnCustomEvent(JsonData);
#endif
}

void UDataSdkManager::Ping(const FString& Host)
{
#ifdef WITH_DATASDK
    UDataSDKApi::Ping(Host);
#endif
}

void UDataSdkManager::OnMissionBegin(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnMissionBegin(JsonData);
#endif
}

void UDataSdkManager::OnMissionSuccess(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnMissionSuccess(JsonData);
#endif
}

void UDataSdkManager::OnMissionFail(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnMissionFail(JsonData);
#endif
}

void UDataSdkManager::OnVirtualCurrencyGain(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnVirtualCurrencyGain(JsonData);
#endif
}

void UDataSdkManager::OnVirtualCurrencyGainForPurchased(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnVirtualCurrencyGainForPurchased(JsonData);
#endif
}

void UDataSdkManager::OnVirtualCurrencyConsume(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnVirtualCurrencyConsume(JsonData);
#endif
}

void UDataSdkManager::OnItemGain(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnItemGain(JsonData);
#endif
}

void UDataSdkManager::OnItemConsume(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnItemConsume(JsonData);
#endif
}

void UDataSdkManager::OnGameLoadResource()
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnGameLoadResource();
#endif
}

void UDataSdkManager::OnGameLoadConfig()
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnGameLoadConfig();
#endif
}

void UDataSdkManager::OnOpenAnnouncement()
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnOpenAnnouncement();
#endif
}

void UDataSdkManager::OnCloseAnnouncement()
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnCloseAnnouncement();
#endif
}

void UDataSdkManager::OnNewUserMission()
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnNewUserMission();
#endif
}

void UDataSdkManager::OnPrivateFunCodeUse(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnPrivateFunCodeUse(JsonData);
#endif
}

void UDataSdkManager::OnPublicFunCodeUse(const FString& JsonData)
{
#ifdef WITH_DATASDK
    UDataSDKApi::OnPublicFunCodeUse(JsonData);
#endif
}
