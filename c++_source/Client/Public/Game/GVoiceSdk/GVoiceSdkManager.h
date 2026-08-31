// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#ifdef WITH_GVOICESDK
#include "GVoiceNotify.h"
#include "GVoice/GCloudVoice.h"
#include "GVoice/GCloudVoiceExtension.h"
#include "GVoice/GCloudVoiceErrno.h"
#endif
#include "GVoiceEnum.h"
#include "GVoiceSdkManager.generated.h"

DECLARE_DYNAMIC_DELEGATE_ThreeParams(FGetMemberInfoDelegate, int, errorCode, TArray<int>, memberIdArr, TArray<FString>, MemberOpenId);

UCLASS(config = Game)
class CLIENT_API UGVoiceSdkManager : public UObject
{
    GENERATED_UCLASS_BODY()
public:
    void Init();
    UFUNCTION()
    bool InitEngine();
    UFUNCTION()
    bool SetAppInfo(const FString& AppID, const FString& AppKey, const FString& OpenID);
    UFUNCTION()
    bool SetMode(GVoiceViceMode VoiceMode);
    UFUNCTION()
    bool SetNotify();
    UFUNCTION()
    void Poll();
    UFUNCTION()
    int JoinTeamRoom(const FString& RoomName);
    UFUNCTION()
    int JoinRangeRoom(const FString& RoomName);
    UFUNCTION()
    int QuitRoom(const FString& RoomName);
    UFUNCTION()
    int TestMic();
    UFUNCTION()
    int OpenMic();
    UFUNCTION()
    int CloseMic();
    UFUNCTION()
    int OpenSpeaker();
    UFUNCTION()
    int CloseSpeaker();
    UFUNCTION()
    int ForbidMemberVoice(int Member, bool Enable, const FString& RoomName);
    UFUNCTION()
    int EnableMultiRoom(bool Enable);
    UFUNCTION()
    int EnableRoomMicrophone(const FString& RoomName, bool Enable);
    UFUNCTION()
    int EnableRoomSpeaker(const FString& RoomName, bool Enable);
    UFUNCTION()
    int SetMicVolume(int vol);
    UFUNCTION()
    int SetSpeakerVolume(int vol);
    UFUNCTION()
    int GetSpeakerLevel();
    UFUNCTION()
    int GetRoomMembers(const FString& RoomName, const int len);
    UFUNCTION()
    bool IsSpeaking()const;
    UFUNCTION()
    int GetMicLevel(bool bFadeOut);
    UFUNCTION()
    int SetBitRate(int Rate);
    UPROPERTY()
    FGetMemberInfoDelegate OnGetMemberInfo;
private:
#ifdef WITH_GVOICESDK
    gcloud_voice::IGCloudVoiceEngine* mVoiceEngine;
    FGVoiceNotify *mNotify;
#endif
};

