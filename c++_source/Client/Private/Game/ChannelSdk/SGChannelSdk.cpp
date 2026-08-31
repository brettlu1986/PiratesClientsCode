#include "Game/ChannelSdk/SGChannelSdk.h"
#include "Client.h"
#include "Shell/ClientShell.h"
#include "Game/Delegates/ClientDelegateManager.h"
#include "Game/Delegates/ClientSdkDelegate.h"
#include "HydraClient.h"
#include "Game/ChannelSdk/ChannelSdkManager.h"
#include "Serialization/JsonWriter.h"

#ifdef WITH_SGSDK
#include "SGSDKApi.h"

DEFINE_LOG_CATEGORY_STATIC(SGChannelSdk, Log, All)

FSGChannelSdk::~FSGChannelSdk()
{

}

void FSGChannelSdk::Init()
{
    UE_LOG(SGChannelSdk, Log, TEXT("FSGChannelSdk::Init()"));
    
    USGSDKApi::SetUserCallBack();
    FString SDKName = GetName();
    USGSDKApi::OnLoginDelegate.BindLambda([SDKName](const FString& UId, const FString& Token)
    {
        UE_LOG(SGChannelSdk, Log, TEXT(" OnLogin() %s"), *UId);
        FString JsonOutput;
        TSharedRef<TJsonWriter<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>> Writer = TJsonWriterFactory<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>::Create(&JsonOutput);
        Writer->WriteObjectStart();
        Writer->WriteValue(TEXT("name"), *SDKName);
        Writer->WriteValue(TEXT("uid"), *UId);
        Writer->WriteValue(TEXT("token"), *Token);
        Writer->WriteObjectEnd();
        Writer->Close();
        UE_LOG(SGChannelSdk, Log, TEXT(" js data is %s"), *JsonOutput);
        auto ChannelSdkManager = UClientShell::GetClient(GWorld)->GetChannelSdkManager();
        //ChannelSdkManager->OnSGSdkLogin.ExecuteIfBound(UId, Token);
        ChannelSdkManager->OnSdkLogin.ExecuteIfBound(JsonOutput);
    });

    USGSDKApi::OnLoginFailDelegate.BindLambda([]()
    {
        UE_LOG(SGChannelSdk, Log, TEXT(" OnLoginFail()"));
        auto ChannelSdkManager = UClientShell::GetClient(GWorld)->GetChannelSdkManager();
        ChannelSdkManager->OnSdkLoginFail.ExecuteIfBound();
    });

    USGSDKApi::OnLogoutFinishDelegate.BindLambda([]()
    {
        UE_LOG(SGChannelSdk, Log, TEXT("OnLogoutFinish()"));
        auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
        Delegate->OnLogout.ExecuteIfBound();
    });

    USGSDKApi::OnNoChannelExitDelegate.BindLambda([]()
    {
        UE_LOG(SGChannelSdk, Log, TEXT(" OnNoChannelExit()"));
        auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
        Delegate->OnNoChannelExit.ExecuteIfBound();
    });
}

const FString FSGChannelSdk::GetName() const
{
    return USGSDKApi::GetName();
}

bool FSGChannelSdk::IsValidSdk() const
{
    return true;
}

void FSGChannelSdk::LoginSdk(const FString& CustomParams) const
{
    USGSDKApi::LoginSdk(CustomParams);
}

bool FSGChannelSdk::IsLoginSdkSuccessful() const
{
    return USGSDKApi::IsLoginSdkSuccessful();
}

void FSGChannelSdk::Login() const
{
    USGSDKApi::Login();
}

void FSGChannelSdk::LoginSdkAndGame(const FString& CustomParams) const
{
    USGSDKApi::LoginSdkAndGame(CustomParams);
}

void FSGChannelSdk::Logout(const FString& CustomParams) const
{
    USGSDKApi::Logout(CustomParams);
}

void FSGChannelSdk::CustomEvent(const FString& EventId) const
{
    
}

bool FSGChannelSdk::IsBindAccount() const
{
    return false;
}

void FSGChannelSdk::Exit(const FString& CustomParams) const
{
    USGSDKApi::Exit(CustomParams);
}

bool FSGChannelSdk::Pay(const FString& PayInfo) const
{
    USGSDKApi::Pay(PayInfo);
    return true;
}

void FSGChannelSdk::SwitchAccount(const FString& CustomParams) const
{
    USGSDKApi::SwitchAccount(CustomParams);
}

void FSGChannelSdk::OnCreateRole(const FString& RoleInfo) const
{
    USGSDKApi::OnCreateRole(RoleInfo);
}

void FSGChannelSdk::OnRoleLevelup(int32 nLevel) const
{
    USGSDKApi::OnRoleLevelup(nLevel);
}

void FSGChannelSdk::OnEnterGame() const
{
    USGSDKApi::OnEnterGame();
}

void FSGChannelSdk::OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal) const
{
    USGSDKApi::OnEvent(EventId, EventDesc, EventVal);
}

void FSGChannelSdk::OnLoginSuccessfully(const FString& UserData) const
{
    USGSDKApi::OnLoginSuccessfully(UserData);
}

void FSGChannelSdk::SetRoleIdAndName(const FString& RoleId, const FString& RoleName) const
{
    
}

void FSGChannelSdk::SetRoleLevel(const FString& RoleLevel) const
{
    
}

void FSGChannelSdk::SetServerIDAndName(const FString& ServerID, const FString& ServerName) const
{
    
}

FString FSGChannelSdk::GetChannel() const
{
    return USGSDKApi::GetChannel();
}

//virtual bool setUserCallBack() const override;
//
//virtual bool setUserCallBack() const override;
//
//virtual bool releaseResource() const override;
//
//virtual bool onCreateRole() const override;
//
//virtual bool openAnnounce() const override;
//
//virtual bool setUserCallBack() const override;
//
//virtual bool bindAccount() const override;
//
//virtual int getUserState() const override;
//
//virtual bool isMethodSupport() const override;
//
//virtual bool hasPackedChannel() const override;
//
//virtual bool setConfigProperties() const override;
//
//virtual bool bindSGAcount() const override;
//
//virtual bool getSGRealNameInfo() const override;
//
//virtual bool callSGMethod() const override;
//
//virtual bool onMissionBegin() const override;
//
//virtual bool onMissionSuccess() const override;
//
//virtual bool onMissionFail() const override;
//
//virtual bool onVirtualCurrencyPurchase() const override;
//
//virtual bool onVirtualCurrencyReward() const override;
//
//virtual bool onVirtualCurrencyConsume() const override;
//
//virtual bool setPingServer() const override;
//
//virtual bool onPayFinish() const override;
//
//virtual bool onGameLoadResource() const override;
//
//virtual bool onGameLoadConfig() const override;
//
//virtual bool onOpenAnnouncement() const override;
//
//virtual bool onCloseAnnouncement() const override;
//
//virtual bool onNewUserMission() const override;
//
//virtual bool onPrivateFunCodeUse() const override;
//
//virtual bool onPublicFunCodeUse() const override;
//
//virtual bool addCommonAttribute() const override;
#endif
