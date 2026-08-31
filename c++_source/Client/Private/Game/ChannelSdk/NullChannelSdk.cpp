#include "Game/ChannelSdk/NullChannelSdk.h"
#include "Client.h"
#include "Shell/ClientShell.h"
#include "Game/Delegates/ClientDelegateManager.h"
#include "Game/Delegates/ClientSdkDelegate.h"


FNullChannelSdk::~FNullChannelSdk()
{

}

void FNullChannelSdk::Init()
{

}

const FString FNullChannelSdk::GetName() const
{
    FString channelName = TEXT("NULLSDK");
    return channelName;
}

bool FNullChannelSdk::IsValidSdk() const
{
    return false;
}

void FNullChannelSdk::LoginSdk(const FString& CustomParams) const
{

}

bool FNullChannelSdk::IsLoginSdkSuccessful() const
{
    return true;
}

void FNullChannelSdk::Login() const
{
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
    Delegate->OnLogin.ExecuteIfBound();
}

void FNullChannelSdk::LoginSdkAndGame(const FString& CustomParams) const
{

}

void FNullChannelSdk::Logout(const FString& CustomParams) const
{

}

void FNullChannelSdk::CustomEvent(const FString& EventId) const
{

}

void FNullChannelSdk::Exit(const FString& CustomParams) const
{
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->SdkDelegate;
    Delegate->OnNoChannelExit.ExecuteIfBound();
}

bool FNullChannelSdk::Pay(const FString& PayInfo) const
{
    return false;
}

void FNullChannelSdk::SwitchAccount(const FString& CustomParams) const
{

}

bool FNullChannelSdk::IsBindAccount() const
{
    return true;
}

void FNullChannelSdk::OnCreateRole(const FString& RoleInfo) const
{

}

void FNullChannelSdk::OnRoleLevelup(int32 nLevel) const
{

}

void FNullChannelSdk::OnEnterGame() const
{

}

void FNullChannelSdk::OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal) const
{

}

void FNullChannelSdk::OnLoginSuccessfully(const FString& UserData) const
{

}

void FNullChannelSdk::SetRoleIdAndName(const FString& RoleId, const FString& RoleName) const
{

}

void FNullChannelSdk::SetRoleLevel(const FString& RoleLevel) const
{

}

void FNullChannelSdk::SetServerIDAndName(const FString& ServerID, const FString& ServerName) const
{

}

FString FNullChannelSdk::GetChannel() const
{
    return TEXT("NULL");
}