#pragma once

class IChannelSdkInterface
{

public:

    virtual ~IChannelSdkInterface() {};

    virtual void Init() = 0;

    virtual const FString GetName() const = 0;

    virtual bool IsValidSdk() const = 0;

    virtual void LoginSdk() const = 0;

    virtual bool IsLoginSdkSuccessful() const = 0;

    virtual void Login() const = 0;

    virtual void LoginSdkAndGame() const = 0;

    virtual void Logout() const = 0;

    virtual void CustomEvent(const FString& EventId) const = 0;

    virtual void Exit() const = 0;

    virtual void SwitchAccount() const = 0;

    virtual bool IsBindAccount() const = 0;

    virtual bool Pay(const FString& PayInfo) const = 0;
    
    virtual void OnCreateRole() const = 0;

    virtual void OnRoleLevelup(int32 nLevel) const = 0;
    
    virtual void OnEnterGame() const = 0;

    virtual void OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal) const = 0;

    virtual void OnLoginSuccessfully(const FString& UserData) const = 0;

    virtual void SetRoleIdAndName(const FString& RoleId, const FString& RoleName) const = 0;

    virtual void SetRoleLevel(const FString& RoleLevel) const = 0;

    virtual void SetServerIDAndName(const FString& ServerID, const FString& ServerName) const = 0;

    virtual bool OpenUCenter() const = 0;

    virtual bool OpenFAQWeb() const = 0;

    virtual bool OpenHrefWeb(const FString& Url) const = 0;

    virtual bool ShowScoreDialog() const = 0;

    virtual bool AssociaAccount() const = 0;

    virtual bool ShowBindTipsView() const = 0;

    virtual FString GetChannel() const = 0;
};
