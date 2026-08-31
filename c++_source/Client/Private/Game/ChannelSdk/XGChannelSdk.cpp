#include "Game/ChannelSdk/XGChannelSdk.h"
#include "Client.h"
#include "Shell/ClientShell.h"
#include "Game/Delegates/ClientDelegateManager.h"
#include "Game/Delegates/ClientSdkDelegate.h"
#include "HydraClient.h"
#include "Game/ChannelSdk/ChannelSdkManager.h"
#include "Serialization/JsonWriter.h"

#ifdef WITH_XGSDK
#include "XGSdkApi.h"

DEFINE_LOG_CATEGORY_STATIC(XGChannelSdk, Log, All)

FXGChannelSdk::~FXGChannelSdk()
{

}

void FXGChannelSdk::Init()
{
    UE_LOG(XGChannelSdk, Log, TEXT("FXGChannelSdk::Init()"));
    FString SDKName = GetName();
    FXGSdkApi::OnLoginDelegate.BindLambda([SDKName](const FString& AuthInfo)
    {
        UE_LOG(XGChannelSdk, Log, TEXT(" OnLogin() %s"), *AuthInfo);
        FString JsonOutput;
        TSharedRef<TJsonWriter<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>> Writer = TJsonWriterFactory<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>::Create(&JsonOutput);
        Writer->WriteObjectStart();
        Writer->WriteValue(TEXT("name"), *SDKName);
        Writer->WriteValue(TEXT("auth_info"), *AuthInfo);
        Writer->WriteObjectEnd();
        Writer->Close();
        UE_LOG(XGChannelSdk, Log, TEXT(" js data is %s"), *JsonOutput);
        auto ChannelSdkManager = UClientShell::GetClient(GWorld)->GetChannelSdkManager();
        //ChannelSdkManager->OnXGSdkLogin.ExecuteIfBound(AuthInfo);
        ChannelSdkManager->OnSdkLogin.ExecuteIfBound(JsonOutput);
    });

    FXGSdkApi::OnLoginFailDelegate.BindLambda([]()
    {
        UE_LOG(XGChannelSdk, Log, TEXT(" OnLoginFail()"));
        auto ChannelSdkManager = UClientShell::GetClient(GWorld)->GetChannelSdkManager();
        ChannelSdkManager->OnSdkLoginFail.ExecuteIfBound();
    });

    FXGSdkApi::OnLogoutFinishDelegate.BindLambda([]()
    {
        UE_LOG(XGChannelSdk, Log, TEXT("OnLogoutFinish()"));
        auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
        Delegate->OnLogout.ExecuteIfBound();
    });

    FXGSdkApi::OnExitDelegate.BindLambda([]()
    {
        UE_LOG(XGChannelSdk, Log, TEXT(" OnExit()"));
        auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
        Delegate->OnExit.ExecuteIfBound();
    });
    FXGSdkApi::OnNoChannelExitDelegate.BindLambda([]()
    {
        UE_LOG(XGChannelSdk, Log, TEXT(" OnNoChannelExit()"));
        auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
        Delegate->OnNoChannelExit.ExecuteIfBound();
    });
}

const FString FXGChannelSdk::GetName() const
{
    return FXGSdkApi::GetName();
}

bool FXGChannelSdk::IsValidSdk() const
{
    return true;
}

void FXGChannelSdk::LoginSdk(const FString& CustomParams) const
{
    FXGSdkApi::LoginSdk();
}

bool FXGChannelSdk::IsLoginSdkSuccessful() const
{
    return FXGSdkApi::IsLoginSdkSuccessful();
}

void FXGChannelSdk::Login() const
{
    FXGSdkApi::Login();
}

void FXGChannelSdk::LoginSdkAndGame(const FString& CustomParams) const
{
    FXGSdkApi::LoginSdkAndGame();
}

void FXGChannelSdk::Logout(const FString& CustomParams) const
{
    FXGSdkApi::Logout();
}

void FXGChannelSdk::CustomEvent(const FString& EventData) const
{
    FXGSdkApi::CustomEvent(EventData);
}

bool FXGChannelSdk::IsBindAccount() const
{
    return false;
}

void FXGChannelSdk::Exit(const FString& CustomParams) const
{
    FXGSdkApi::Exit();
}

bool FXGChannelSdk::Pay(const FString& PayInfo) const
{
    //FXGSdkApi::Pay(ProductId, nPayAmount, nTotalAmount, nProductQuantity, nUnitPrice);
    return true;
}

void FXGChannelSdk::SwitchAccount(const FString& CustomParams) const
{
    FXGSdkApi::SwitchAccount();
}

void FXGChannelSdk::OnCreateRole(const FString& RoleInfo) const
{
    FXGSdkApi::OnCreateRole(RoleInfo);
}

void FXGChannelSdk::OnRoleLevelup(int32 nLevel) const
{
    FXGSdkApi::OnRoleLevelup(nLevel);
}

void FXGChannelSdk::OnEnterGame() const
{
    FXGSdkApi::OnEnterGame();
}

void FXGChannelSdk::OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal) const
{
    FXGSdkApi::OnEvent(EventId, EventDesc, EventVal);
}

void FXGChannelSdk::OnLoginSuccessfully(const FString& UserData) const
{
    FXGSdkApi::OnLoginSuccessfully(UserData);
}

void FXGChannelSdk::SetRoleIdAndName(const FString& RoleId, const FString& RoleName) const
{
    FXGSdkApi::SetRoleIdAndName(RoleId, RoleName);
}

void FXGChannelSdk::SetRoleLevel(const FString& RoleLevel) const
{
    FXGSdkApi::SetRoleLevel(RoleLevel);
}

void FXGChannelSdk::SetServerIDAndName(const FString& ServerID, const FString& ServerName) const
{
    FXGSdkApi::SetServerIDAndName(ServerID, ServerName);
}

bool FXGChannelSdk::OpenFAQWeb() const
{
    return false;
}

bool FXGChannelSdk::OpenHrefWeb(const FString& Url) const
{
    return false;
}

bool FXGChannelSdk::ShowScoreDialog()const
{
    return false;
}

bool FXGChannelSdk::OpenUCenter() const
{
    return false;
}

bool FXGChannelSdk::AssociaAccount() const
{
    return false;
}

bool FXGChannelSdk::ShowBindTipsView() const
{
    return false;
}

FString FXGChannelSdk::GetChannel() const
{
    return FXGSdkApi::GetChannelName();
}
#endif
