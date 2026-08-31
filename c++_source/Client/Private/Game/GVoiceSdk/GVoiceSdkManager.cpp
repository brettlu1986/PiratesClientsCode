#include "Game/GVoiceSdk/GVoiceSdkManager.h"
#include "Client.h"
#include "Shell/ClientShell.h"
#include "Game/Delegates/ClientDelegateManager.h"
#include "Game/Delegates/GVoiceSdkNotifyDelegate.h"
DEFINE_LOG_CATEGORY_STATIC(GVoiceSdkManager, Log, All)

UGVoiceSdkManager::UGVoiceSdkManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

void UGVoiceSdkManager::Init()
{
#ifdef WITH_GVOICESDK
    mVoiceEngine = gcloud_voice::GetVoiceEngine();
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("Get GVoice Engine meets some error, please try again."));
    }
    mNotify = new FGVoiceNotify();
#endif
}

bool UGVoiceSdkManager::InitEngine()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return false;
    }
    int ret = mVoiceEngine->Init();
    FString mLogStr;
    if (ret != 0) {
        mLogStr = "Init meets some error, error code is: ";
        mLogStr.AppendInt(ret);
        UE_LOG(GVoiceSdkManager, Log, TEXT("%s"), *mLogStr);
        return false;
    }
    ret = mVoiceEngine->SetNotify(mNotify);
    mLogStr = "";
    if (ret != 0) {
        mLogStr = "SetNotify meets some error, error code is: ";
        mLogStr.AppendInt(ret);
        UE_LOG(GVoiceSdkManager, Log, TEXT("%s"), *mLogStr);
        return false;
    }
#endif
    return true;
}

bool UGVoiceSdkManager::SetAppInfo(const FString& AppID, const FString& AppKey, const FString& OpenID)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return false;
    }
    int ret = mVoiceEngine->SetAppInfo(TCHAR_TO_ANSI(*AppID), TCHAR_TO_ANSI(*AppKey), TCHAR_TO_ANSI(*OpenID));
    if (ret != 0) {
        FString mLogStr = "SetAppInfo meets some error, error code is: ";
        mLogStr.AppendInt(ret);
        UE_LOG(GVoiceSdkManager, Log, TEXT("%s"), *mLogStr);
        return false;
    }
#endif
    return true;
}

bool UGVoiceSdkManager::SetMode(GVoiceViceMode VoiceMode)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return false;
    }
    int ret = mVoiceEngine->SetMode(gcloud_voice::GCloudVoiceMode::RealTime);
    if (ret != 0) {
        FString mLogStr = "SetMode to RealTime meets some error, error code is: ";
        mLogStr.AppendInt(ret);
        UE_LOG(GVoiceSdkManager, Log, TEXT("%s"), *mLogStr);
        return false;
    }
#endif
    return true;
}

bool UGVoiceSdkManager::SetNotify()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return false;
    }
#endif
    return true;
}

void UGVoiceSdkManager::Poll()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine != nullptr) {
        mVoiceEngine->Poll();
    }
#endif
}

int UGVoiceSdkManager::JoinTeamRoom(const FString& RoomName)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->JoinTeamRoom(TCHAR_TO_ANSI(*RoomName), 10000);
    FString mLogStr;
    if (ret != 0) {
        mLogStr = "JoinTeamRoom meets some error, error code is: ";
        mLogStr.AppendInt(ret);
        UE_LOG(GVoiceSdkManager, Log, TEXT("%s"), *mLogStr);
    }
    else {
        mLogStr = "JoinTeamRoom success";
        UE_LOG(GVoiceSdkManager, Log, TEXT("%s"), *mLogStr);
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::JoinRangeRoom(const FString& RoomName)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->JoinRangeRoom(TCHAR_TO_ANSI(*RoomName), 10000);
    FString mLogStr;
    if (ret != 0) {
        mLogStr = "JoinTeamRoom meets some error, error code is: ";
        mLogStr.AppendInt(ret);
        UE_LOG(GVoiceSdkManager, Log, TEXT("%s"), *mLogStr);
    }
    else {
        mLogStr = "JoinTeamRoom success";
        UE_LOG(GVoiceSdkManager, Log, TEXT("%s"), *mLogStr);
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::QuitRoom(const FString& RoomName)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->QuitRoom(TCHAR_TO_ANSI(*RoomName));
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("QuitRoom meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("QuitRoom success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::TestMic()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->TestMic();
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("TestMic meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("TestMic success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::OpenMic()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->OpenMic();
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("OpenMic meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("OpenMic success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::CloseMic()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->CloseMic();
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("CloseMic meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("CloseMic success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::OpenSpeaker()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->OpenSpeaker();
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("OpenSpeaker meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("OpenSpeaker success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::CloseSpeaker()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->CloseSpeaker();
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("CloseSpeaker meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("CloseSpeaker success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::ForbidMemberVoice(int Member, bool Enable, const FString& RoomName)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->ForbidMemberVoice(Member, Enable, TCHAR_TO_ANSI(*RoomName));
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("ForbidMemberVoice meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("ForbidMemberVoice success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::EnableMultiRoom(bool enable)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->EnableMultiRoom(enable);
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("EnableMultiRoom meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("EnableMultiRoom success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::EnableRoomMicrophone(const FString& RoomName, bool Enable)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->EnableRoomMicrophone(TCHAR_TO_ANSI(*RoomName), Enable);
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("EnableRoomMicrophone meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("EnableRoomMicrophone success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::EnableRoomSpeaker(const FString& RoomName, bool Enable)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->EnableRoomSpeaker(TCHAR_TO_ANSI(*RoomName), Enable);
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("EnableRoomSpeaker meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("EnableRoomSpeaker success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::SetMicVolume(int vol)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->SetMicVolume(vol);
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("SetMicVolume meets some error, error code is: %d"), ret);
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("SetMicVolume success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::SetSpeakerVolume(int vol)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    int ret = mVoiceEngine->SetSpeakerVolume(vol);
    if (ret != 0) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("SetSpeakerVolume meets some error, error code is: %d"), ret);
}
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("SetSpeakerVolume success"));
    }
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::GetSpeakerLevel()
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    return mVoiceEngine->GetSpeakerLevel();
#else
    return 0;
#endif
}

int UGVoiceSdkManager::GetRoomMembers(const FString& RoomName, const int len)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return -1;
    }
    RoomMembers members[4];
    int ret =  mVoiceEngine->GetRoomMembers(TCHAR_TO_ANSI(*RoomName), members ,len);
    if (ret == -1) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("GetRoomMembers meets some error, error code is: -1"));
    }
    else {
        UE_LOG(GVoiceSdkManager, Log, TEXT("SetSpeakerVolume success room num count : %d"), ret);
        RoomMembers memberInfo;
        TArray<int> memberIds;
        TArray<FString> memberOpenIds;
        int memberLen = ret;
        for (int i = 0;i < memberLen; i++)
        {
            memberInfo = members[i];
            int memberid = memberInfo.memberid;
            UE_LOG(GVoiceSdkManager, Log, TEXT("memberInfo.memberid : %d"), memberid);
            FString fOpenid(memberInfo.openid);
            UE_LOG(GVoiceSdkManager, Log, TEXT("memberInfo.openid : %s"), *fOpenid);
            memberIds.Add(memberid);
            memberOpenIds.Add(fOpenid);
        }
        /*auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
        Delegate->GetMemberInfo.ExecuteIfBound(ret, memberIds, memberOpenIds);*/
        OnGetMemberInfo.ExecuteIfBound(ret, memberIds, memberOpenIds);
    }
    return ret;
#else
    return -1;
#endif
}

bool UGVoiceSdkManager::IsSpeaking() const
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return false;
    }
    bool ret = mVoiceEngine->IsSpeaking();
    //UE_LOG(GVoiceSdkManager, Log, TEXT("IsSpeaking mic volume : %d"), ret);
    return ret;
#else
    return false;
#endif
}

int UGVoiceSdkManager::GetMicLevel(bool bFadeOut)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return 0;
    }
    int ret = mVoiceEngine->GetMicLevel(bFadeOut);
    //UE_LOG(GVoiceSdkManager, Log, TEXT("GetMicLevel mic level : %d"), ret);
    return ret;
#else
    return 0;
#endif
}

int UGVoiceSdkManager::SetBitRate(int Rate)
{
#ifdef WITH_GVOICESDK
    if (mVoiceEngine == nullptr) {
        UE_LOG(GVoiceSdkManager, Log, TEXT("VoiceEngine is Null."));
        return 0;
    }
    int ret = mVoiceEngine->SetBitRate(Rate);
    UE_LOG(GVoiceSdkManager, Log, TEXT("SetBitRate rate : %d"), Rate);
    return ret;
#else
    return 0;
#endif
}