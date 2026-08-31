#pragma once

class IChannelSdkBase
{

public:

    virtual ~IChannelSdkBase() {};

    virtual void Init() = 0;

    virtual const FString GetName() const = 0;

    virtual bool IsValidSdk() const = 0;

    virtual void LoginSdk(const FString& CustomParams = TEXT("")) const = 0;

    virtual bool IsLoginSdkSuccessful() const = 0;

    virtual void Login() const = 0;

    virtual void LoginSdkAndGame(const FString& CustomParams = TEXT("")) const = 0;

    virtual void Logout(const FString& CustomParams = TEXT("")) const = 0;

    virtual void CustomEvent(const FString& EventId) const = 0;

    virtual void Exit(const FString& CustomParams = TEXT("")) const = 0;

    virtual void SwitchAccount(const FString& CustomParams = TEXT("")) const = 0;

    virtual bool IsBindAccount() const = 0;

    virtual bool Pay(const FString& PayInfo) const = 0;
    
    virtual void OnCreateRole(const FString& RoleInfo = TEXT("")) const = 0;

    virtual void OnRoleLevelup(int32 nLevel) const = 0;
    
    virtual void OnEnterGame() const = 0;

    virtual void OnEvent(const FString& EventId, const FString& EventDesc, const FString& EventVal) const = 0;

    virtual void OnLoginSuccessfully(const FString& UserData) const = 0;

    virtual void SetRoleIdAndName(const FString& RoleId, const FString& RoleName) const = 0;

    virtual void SetRoleLevel(const FString& RoleLevel) const = 0;

    virtual void SetServerIDAndName(const FString& ServerID, const FString& ServerName) const = 0;

    virtual bool OpenUCenter() const { return false; }

    virtual bool OpenFAQWeb() const { return false; }

    virtual bool OpenHrefWeb(const FString& Url) const { return false; }

    virtual bool ShowScoreDialog() const { return false; }

    virtual bool AssociaAccount() const { return false; }

    virtual bool ShowBindTipsView() const { return false; }

    virtual FString GetChannel() const { return TEXT(""); }

    virtual bool setUserCallBack() const { return false; }

    virtual bool releaseResource() const { return false; }
    
    virtual bool onCreateRole() const { return false; }
    
    virtual bool openAnnounce() const { return false; }
    
    virtual bool bindAccount() const { return false; }

    virtual int getUserState() const { return -1; }

    virtual bool isMethodSupport() const { return false; }

    virtual bool hasPackedChannel() const { return false; }

    virtual bool setConfigProperties() const { return false; }

    virtual bool bindSGAcount() const { return false; }

    virtual bool getSGRealNameInfo() const { return false; }

    virtual bool callSGMethod() const { return false; }

    virtual bool onMissionBegin() const { return false; }

    virtual bool onMissionSuccess() const { return false; }

    virtual bool onMissionFail() const { return false; }

    virtual bool onVirtualCurrencyPurchase() const { return false; }

    virtual bool onVirtualCurrencyReward() const { return false; }

    virtual bool onVirtualCurrencyConsume() const { return false; }

    virtual bool setPingServer() const { return false; }

    virtual bool onPayFinish() const { return false; }

    virtual bool onGameLoadResource() const { return false; }

    virtual bool onGameLoadConfig() const { return false; }

    virtual bool onOpenAnnouncement() const { return false; }

    virtual bool onCloseAnnouncement() const { return false; }

    virtual bool onNewUserMission() const { return false; }

    virtual bool onPrivateFunCodeUse() const { return false; }

    virtual bool onPublicFunCodeUse() const { return false; }

    virtual bool addCommonAttribute() const { return false; }

};
