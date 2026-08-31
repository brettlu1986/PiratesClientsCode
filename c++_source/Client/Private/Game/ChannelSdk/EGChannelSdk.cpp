#include "Game/ChannelSdk/EGChannelSdk.h"
#include "Client.h"
#include "Shell/ClientShell.h"
#include "Game/Delegates/ClientDelegateManager.h"
#include "Game/Delegates/ClientSdkDelegate.h"
#include "HydraClient.h"
#include "Game/ChannelSdk/ChannelSdkManager.h"
#include "Serialization/JsonWriter.h"

#ifdef WITH_EGSDK
#include "EGSdkApi.h"

DEFINE_LOG_CATEGORY_STATIC(EGChannelSdk, Log, All)

FEGChannelSdk::~FEGChannelSdk()
{

}

void FEGChannelSdk::Init()
{
    UE_LOG(EGChannelSdk, Log, TEXT("FEGChannelSdk::Init()"));
    FString SDKName = GetName();
    UEGSdkApi::OnLoginDelegate.BindLambda([SDKName](const FString& UserId, const FString& AccessToken)
    {
        UE_LOG(EGChannelSdk, Log, TEXT(" OnLogin()"));
        FString JsonOutput;
        TSharedRef<TJsonWriter<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>> Writer = TJsonWriterFactory<TCHAR, TCondensedJsonPrintPolicy<TCHAR>>::Create(&JsonOutput);
        Writer->WriteObjectStart();
        Writer->WriteValue(TEXT("name"), *SDKName);
        Writer->WriteValue(TEXT("uid"), *UserId);
        Writer->WriteValue(TEXT("token"), *AccessToken);
        Writer->WriteObjectEnd();
        Writer->Close();
        UE_LOG(EGChannelSdk, Log, TEXT(" js data is %s"), *JsonOutput);
        auto ChannelSdkManager = UClientShell::GetClient(GWorld)->GetChannelSdkManager();
        ChannelSdkManager->OnSdkLogin.ExecuteIfBound(JsonOutput);
    });

    UEGSdkApi::OnLoginFailDelegate.BindLambda([]()
    {
        UE_LOG(EGChannelSdk, Log, TEXT(" OnLoginFail()"));
        auto ChannelSdkManager = UClientShell::GetClient(GWorld)->GetChannelSdkManager();
        ChannelSdkManager->OnSdkLoginFail.ExecuteIfBound();
    });

    UEGSdkApi::OnLogoutFinishDelegate.BindLambda([]()
     {
         UE_LOG(EGChannelSdk, Log, TEXT("OnLogoutFinish()"));
         auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
         Delegate->OnLogout.ExecuteIfBound();
     });

    UEGSdkApi::OnBindAccountSuccessDelegate.BindLambda([]()
    {
        UE_LOG(EGChannelSdk, Log, TEXT("OnBindAccountSuccess"));
        auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
        Delegate->OnBindAccountSuccess.ExecuteIfBound();
    });

    UEGSdkApi::OnPayResultDelegate.BindLambda([](int32 code)
    {
        UE_LOG(EGChannelSdk, Log, TEXT("OnPayResult"));
        auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
        Delegate->OnPayResult.ExecuteIfBound(code, TEXT(""));
    });

     UEGSdkApi::OnBackToLoginDelegate.BindLambda([]()
     {
         UE_LOG(EGChannelSdk, Log, TEXT("Change Account In Game Back To Login"));
         auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
         Delegate->OnBackToLogin.ExecuteIfBound();
     });
     /*
     UEGSdkApi::OnNoChannelExit.BindLambda([]()
     {
         UE_LOG(EGChannelSdk, Log, TEXT(" OnNoChannelExit()"));
         auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
         Delegate->OnNoChannelExit.ExecuteIfBound();
     });*/

    UEGSdkApi::Init();
}

const FString FEGChannelSdk::GetName() const
{
    return UEGSdkApi::GetName();
}

bool FEGChannelSdk::IsValidSdk() const
{
    return true;
}

void FEGChannelSdk::LoginSdk(const FString& CustomParams) const
{
    UEGSdkApi::LoginSdk();
}

bool FEGChannelSdk::IsLoginSdkSuccessful() const
{
    return UEGSdkApi::IsLoginSdkSuccessful();
}

void FEGChannelSdk::Login() const
{
    UEGSdkApi::Login();
}

void FEGChannelSdk::LoginSdkAndGame(const FString& CustomParams) const
{
    UEGSdkApi::LoginSdkAndGame();
}

void FEGChannelSdk::Logout(const FString& CustomParams) const
{
    UEGSdkApi::Logout();
}

void FEGChannelSdk::CustomEvent(const FString& EventId) const
{
    UEGSdkApi::CustomEvent(EventId);
}

void FEGChannelSdk::Exit(const FString& CustomParams) const
{
    UEGSdkApi::Exit();
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
    Delegate->OnNoChannelExit.ExecuteIfBound();
}

bool FEGChannelSdk::Pay(const FString& PayInfo) const
{
    UEGSdkApi::Pay(PayInfo);
    return true;
}

void FEGChannelSdk::SwitchAccount(const FString& CustomParams) const
{
    UEGSdkApi::SwitchAccount();
}

bool FEGChannelSdk::IsBindAccount() const
{
    return UEGSdkApi::IsBindAccount();
}

void FEGChannelSdk::OnCreateRole(const FString& RoleInfo) const
{
    UEGSdkApi::OnCreateRole();
}

void FEGChannelSdk::OnRoleLevelup(int32 nLevel) const
{
    UEGSdkApi::OnRoleLevelup(nLevel);
}

void FEGChannelSdk::OnEnterGame() const
{
    UEGSdkApi::OnEnterGame();
}

void FEGChannelSdk::OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal) const
{
    UEGSdkApi::OnEvent(EventId, EventDesc, EventVal);
}

void FEGChannelSdk::OnLoginSuccessfully(const FString& UserData) const
{
    UEGSdkApi::OnLoginSuccessfully(UserData);
}

void FEGChannelSdk::SetRoleIdAndName(const FString& RoleId, const FString& RoleName) const
{
    UEGSdkApi::SetRoleIdAndName(RoleId, RoleName);
}

void FEGChannelSdk::SetRoleLevel(const FString& RoleLevel) const
{
    UEGSdkApi::SetRoleLevel(RoleLevel);
}

void FEGChannelSdk::SetServerIDAndName(const FString& ServerID, const FString& ServerName) const
{
    UEGSdkApi::SetServerIDAndName(ServerID, ServerName);
}

bool FEGChannelSdk::OpenFAQWeb() const
{
    UEGSdkApi::OpenFAQWeb();
    return true;
}

bool FEGChannelSdk::OpenHrefWeb(const FString& Url) const
{
    UEGSdkApi::OpenHrefWeb(Url);
    return true;
}

bool FEGChannelSdk::ShowScoreDialog()const
{
    UEGSdkApi::ShowScoreDialog();
    return true;
}

bool FEGChannelSdk::OpenUCenter() const
{
    UEGSdkApi::OpenUCenter();
    return true;
}

bool FEGChannelSdk::AssociaAccount() const
{
    UEGSdkApi::AssociaAccount();
    return true;
}

bool FEGChannelSdk::ShowBindTipsView() const
{
    UEGSdkApi::ShowBindTipsView();
    return true;
}

FString FEGChannelSdk::GetChannel() const
{
    return UEGSdkApi::GetChannel();
}
#endif
