#include "Game/ChannelSdk/ChannelSdkManager.h"
#include "Client.h"
#include "Game/ChannelSdk/NullChannelSdk.h"

#ifdef WITH_XGSDK
#include "Game/ChannelSdk/XGChannelSdk.h"
#endif // WITH_XGSDK
#ifdef WITH_EGSDK
#include "Game/ChannelSdk/EGChannelSdk.h"
#endif
#ifdef WITH_SGSDK
#include "Game/ChannelSdk/SGChannelSdk.h"
#endif

UChannelSdkManager::UChannelSdkManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

void UChannelSdkManager::Init()
{
#ifdef WITH_XGSDK
    CurrentSdk = TUniquePtr<IChannelSdkBase>(new FXGChannelSdk());
#endif

#ifdef WITH_EGSDK
    CurrentSdk = TUniquePtr<IChannelSdkBase>(new FEGChannelSdk());
#endif

#ifdef WITH_SGSDK
    CurrentSdk = TUniquePtr<IChannelSdkBase>(new FSGChannelSdk());
#endif

    if(!CurrentSdk.IsValid())
    {
        CurrentSdk = TUniquePtr<IChannelSdkBase>(new FNullChannelSdk());
    }

    CurrentSdk->Init();
}

const FString UChannelSdkManager::GetChannelName()
{
    return CurrentSdk->GetName();
}

bool UChannelSdkManager::IsValidSdk()
{
    return CurrentSdk->IsValidSdk();
}

void UChannelSdkManager::LoginSdk()
{
    CurrentSdk->LoginSdk();
}

bool UChannelSdkManager::IsLoginSdkSuccessful()
{
    return CurrentSdk->IsLoginSdkSuccessful();
}

void UChannelSdkManager::Login()
{
    CurrentSdk->Login();
}

void UChannelSdkManager::LoginSdkAndGame()
{
    CurrentSdk->LoginSdkAndGame();
}

void UChannelSdkManager::Logout()
{
    CurrentSdk->Logout();
}

void UChannelSdkManager::CustomEvent(const FString& EventData)
{
    CurrentSdk->CustomEvent(EventData);
}

void UChannelSdkManager::Exit()
{
    CurrentSdk->Exit();
}

bool UChannelSdkManager::Pay(const FString& PayInfo)
{
    return CurrentSdk->Pay(PayInfo);
}

void UChannelSdkManager::SwitchAccount()
{
    CurrentSdk->SwitchAccount();
}

bool UChannelSdkManager::IsBindAccount()
{
    return CurrentSdk->IsBindAccount();
}

void UChannelSdkManager::OnCreateRole(const FString& RoleInfo)
{
    CurrentSdk->OnCreateRole(RoleInfo);
}

void UChannelSdkManager::OnRoleLevelup(int nNewLevel)
{
    CurrentSdk->OnRoleLevelup(nNewLevel);
}

void UChannelSdkManager::OnEnterGame()
{
    CurrentSdk->OnEnterGame();
}

void UChannelSdkManager::OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal)
{

}

void UChannelSdkManager::OnLoginSuccessfully(const FString& UserData)
{
    CurrentSdk->OnLoginSuccessfully(UserData);
}

void UChannelSdkManager::SetRoleIdAndName(const FString& RoleId, const FString& RoleName)
{
    CurrentSdk->SetRoleIdAndName(RoleId, RoleName);
}

void UChannelSdkManager::SetRoleLevel(const FString& RoleLevel)
{
    CurrentSdk->SetRoleLevel(RoleLevel);
}

void UChannelSdkManager::SetServerIDAndName(const FString& ServerID, const FString& ServerName)
{
    CurrentSdk->SetServerIDAndName(ServerID, ServerName);
}

bool UChannelSdkManager::OpenFAQWeb()
{
    return CurrentSdk->OpenFAQWeb();
}

bool UChannelSdkManager::OpenHrefWeb(const FString& Url)
{
    return CurrentSdk->OpenHrefWeb(Url);
}

bool UChannelSdkManager::ShowScoreDialog()
{
    return CurrentSdk->ShowScoreDialog();
}

bool UChannelSdkManager::OpenUCenter()
{
    return CurrentSdk->OpenUCenter();
}

bool UChannelSdkManager::AssociaAccount()
{
    return CurrentSdk->AssociaAccount();
}

bool UChannelSdkManager::ShowBindTipsView()
{
    return CurrentSdk->ShowBindTipsView();
}

FString UChannelSdkManager::GetChannel()
{
    return CurrentSdk->GetChannel();
}