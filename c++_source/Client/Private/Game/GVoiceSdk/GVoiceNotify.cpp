// Fill out your copyright notice in the Description page of Project Settings.
#ifdef WITH_GVOICESDK
#include "Game/GVoiceSdk/GVoiceNotify.h"
#include <stdlib.h>
#include <string>
#include "Client.h"
#include "ClientShell.h"
#include "Game/Delegates/ClientDelegateManager.h"
#include "Game/Delegates/GVoiceSdkNotifyDelegate.h"

FGVoiceNotify::FGVoiceNotify()
{
}

FGVoiceNotify::~FGVoiceNotify()
{
}

void FGVoiceNotify::OnJoinRoom(gcloud_voice::GCloudVoiceCompleteCode code, const char *roomName, int memberID)
{
    check(IsInGameThread());
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
    FString fRoomName(roomName);
    Delegate->OnJoinRoom.ExecuteIfBound(code, fRoomName, memberID);
}

void FGVoiceNotify::OnStatusUpdate(gcloud_voice::GCloudVoiceCompleteCode code, const char *roomName, int memberID)
{
    
    check(IsInGameThread());
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
    FString fRoomName(roomName);
    Delegate->OnStatusUpdate.ExecuteIfBound(fRoomName, memberID);
}

void FGVoiceNotify::OnQuitRoom(gcloud_voice::GCloudVoiceCompleteCode code, const char *roomName)
{
    
    check(IsInGameThread());
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
    FString fRoomName(roomName);
    Delegate->OnQuitRoom.ExecuteIfBound(code, fRoomName);
}

void FGVoiceNotify::OnMemberVoice(const unsigned int *members, int count)
{
    check(IsInGameThread());
    FString msg = "OnMemberVoice";
    msg.Append("\nCount: ");
    msg.AppendInt(count);
    TArray<unsigned int> memberStateArray;
    for(int i = 0; i < count*2-1; i+=2){
        msg.Append("Member: ");
        msg.AppendInt(members[i]);
        msg.Append("\nStatus: ");
        msg.AppendInt(members[i+1]);
        msg.Append("\n");
        memberStateArray.Add(members[i]);
        memberStateArray.Add(members[i + 1]);
    }
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
    Delegate->OnMemberVoiceDetail.ExecuteIfBound(memberStateArray, count);
}

void FGVoiceNotify::OnMemberVoice(const char *roomName, unsigned int member, int status)
{
    check(IsInGameThread());
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
    FString fRoomName(roomName);
    Delegate->OnMemberVoice.ExecuteIfBound(fRoomName, member, status);
}

void FGVoiceNotify::OnUploadFile(gcloud_voice::GCloudVoiceCompleteCode code, const char *filePath, const char *fileID)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnDownloadFile(gcloud_voice::GCloudVoiceCompleteCode code, const char *filePath, const char *fileID)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnPlayRecordedFile(gcloud_voice::GCloudVoiceCompleteCode code,const char *filePath)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnApplyMessageKey(gcloud_voice::GCloudVoiceCompleteCode code)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnSpeechToText(gcloud_voice::GCloudVoiceCompleteCode code, const char *fileID, const char *result)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnRecording(const unsigned char* pAudioData, unsigned int nDataLength)
{
    FString msg = "OnRecording";
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
    Delegate->OnRecording.ExecuteIfBound(nDataLength);
}

void FGVoiceNotify::OnStreamSpeechToText(gcloud_voice::GCloudVoiceCompleteCode code, int error, const char *result, const char *voicePath)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnRoleChanged(gcloud_voice::GCloudVoiceCompleteCode code, const char *roomName, int memberID, int role)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnEvent(gcloud_voice::GCloudVoiceEvent eventCode, const char * info)
{
    check(IsInGameThread());
    const FString eventInfo(info);
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
    Delegate->OnEvent.ExecuteIfBound(eventCode, eventInfo);
}

void FGVoiceNotify::OnMuteSwitchResult(int nState)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnReportPlayer(gcloud_voice::GCloudVoiceCompleteCode code, const char* cszInfo)
{
    check(IsInGameThread());
}


void FGVoiceNotify::OnSaveRecFileIndex(GCloudVoiceCompleteCode code, const char *fileid, int fileindex)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnRoomMemberInfo(GCloudVoiceCompleteCode code, const char* roomName, int memid, const char* openID)
{
    check(IsInGameThread());
    FString fRoomName(roomName);
    FString fOpenId(openID);
    auto Delegate = UClientShell::GetClient(GWorld)->GetClientDelegateManager()->GVoiceSdkNotifyDelegate;
    Delegate->OnRoomMemberInfo.ExecuteIfBound(code, memid, fRoomName, fOpenId);
}

void FGVoiceNotify::OnSpeechTranslate(GCloudVoiceCompleteCode nCode, const char* srcText, const char* targetText, const char* targetFileID, int srcFileDuration)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnRSTS(GCloudVoiceCompleteCode nCode, SpeechLanguageType srcLang, SpeechLanguageType targetLang, const char* srcText, const char* targetText, const char* targetFileID, int srcFileDuration)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnQueryUserInfo(GCloudVoiceCompleteCode code, const char* roomName, WXMemberInfo *member)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnWXMemberVoice(const char* roomName, unsigned int *members, int count)
{
}

void FGVoiceNotify::OnQueryWXMembers(GCloudVoiceCompleteCode code, const char* roomName, WXMemberInfo *members, int count)
{
    check(IsInGameThread());
}

void FGVoiceNotify::OnUpdateUserInfo(GCloudVoiceCompleteCode code, const char* roomName, unsigned int memberID)
{
    check(IsInGameThread());
}

FString FGVoiceNotify::CompleteCodeToStr(int code)
{
    FString completeCodes[] = {"", "GV_ON_JOINROOM_SUCC", "GV_ON_JOINROOM_TIMEOUT", "GV_ON_JOINROOM_SVR_ERR", "GV_ON_JOINROOM_UNKNOWN", "GV_ON_NET_ERR",
        "GV_ON_QUITROOM_SUCC", "GV_ON_MESSAGE_KEY_APPLIED_SUCC", "GV_ON_MESSAGE_KEY_APPLIED_TIMEOUT", "GV_ON_MESSAGE_KEY_APPLIED_SVR_ERR", "GV_ON_MESSAGE_KEY_APPLIED_UNKNOWN",
        "GV_ON_UPLOAD_RECORD_DONE", "GV_ON_UPLOAD_RECORD_ERROR", "GV_ON_DOWNLOAD_RECORD_DONE", "GV_ON_DOWNLOAD_RECORD_ERROR", "GV_ON_STT_SUCC", "GV_ON_STT_TIMEOUT",
        "GV_ON_STT_APIERR", "GV_ON_RSTT_SUCC", "GV_ON_RSTT_TIMEOUT", "GV_ON_RSTT_APIERR", "GV_ON_PLAYFILE_DONE", "GV_ON_ROOM_OFFLINE", "GV_ON_UNKNOWN", "GV_ON_ROLE_SUCC",
        "GV_ON_ROLE_TIMEOUT", "GV_ON_ROLE_MAX_AHCHOR", "GV_ON_ROLE_NO_CHANGE", "GV_ON_ROLE_SVR_ERROR", "GV_ON_RSTT_RETRY",
    };
    
    int len = sizeof(completeCodes)/sizeof(completeCodes[0]);
    if(code < 1 || code > len){
        code = 0;
    }
    
    return completeCodes[code];
}
#endif