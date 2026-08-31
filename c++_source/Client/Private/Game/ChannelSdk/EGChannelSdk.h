#pragma once

#include "Game/ChannelSdk/ChannelSdkBase.h"

class FEGChannelSdk : public IChannelSdkBase
{
public:

    virtual ~FEGChannelSdk();

    virtual void Init() override;

    virtual const FString GetName() const override;

    virtual bool IsValidSdk() const override;

    virtual void LoginSdk(const FString& CustomParams) const override;

    virtual bool IsLoginSdkSuccessful() const override;

    virtual void Login() const override;

    virtual void LoginSdkAndGame(const FString& CustomParams) const override;

    virtual void Logout(const FString& CustomParams) const override;

    virtual void CustomEvent(const FString& EventId) const override;

    virtual void Exit(const FString& CustomParams) const override;

    virtual bool Pay(const FString& PayInfo) const override;

    virtual void SwitchAccount(const FString& CustomParams) const override;

    virtual bool IsBindAccount() const override;

    virtual void OnCreateRole(const FString& RoleInfo) const override;

    virtual void OnRoleLevelup(int32 nLevel) const override;

    virtual void OnEnterGame() const override;

    virtual void OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal) const override;

    virtual void OnLoginSuccessfully(const FString& UserData) const override;

    virtual void SetRoleIdAndName(const FString& RoleId, const FString& RoleName) const override;

    virtual void SetRoleLevel(const FString& RoleLevel) const override;

    virtual void SetServerIDAndName(const FString& ServerID, const FString& ServerName) const override;

    virtual bool OpenFAQWeb() const override;

    virtual bool OpenHrefWeb(const FString& Url) const override;

    virtual bool ShowScoreDialog()const override;

    virtual bool OpenUCenter() const override;

    virtual bool AssociaAccount() const override;

    virtual bool ShowBindTipsView() const override;

    virtual FString GetChannel() const override;
};


