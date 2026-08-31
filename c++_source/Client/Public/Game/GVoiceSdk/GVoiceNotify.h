// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#ifdef WITH_GVOICESDK
#include "CoreMinimal.h"
#include "GVoice/GCloudVoice.h"
using namespace gcloud_voice;

class CLIENT_API FGVoiceNotify : public gcloud_voice::IGCloudVoiceNotify
{
public:
	//GVoiceNotify(FString &logStr);
    FGVoiceNotify();
	~FGVoiceNotify();
    
public:
    virtual void OnJoinRoom(gcloud_voice::GCloudVoiceCompleteCode code, const char *roomName, int memberID);
    
    virtual void OnStatusUpdate(gcloud_voice::GCloudVoiceCompleteCode status, const char *roomName, int memberID);
    
    virtual void OnQuitRoom(gcloud_voice::GCloudVoiceCompleteCode code, const char *roomName);
    
    virtual void OnMemberVoice(const unsigned int *members, int count);
    
    virtual void OnMemberVoice(const char *roomName, unsigned int member, int status);
    
    virtual void OnUploadFile(gcloud_voice::GCloudVoiceCompleteCode code, const char *filePath, const char *fileID);
   
    virtual void OnDownloadFile(gcloud_voice::GCloudVoiceCompleteCode code, const char *filePath, const char *fileID);
    
    virtual void OnPlayRecordedFile(gcloud_voice::GCloudVoiceCompleteCode code,const char *filePath);
    
    virtual void OnApplyMessageKey(gcloud_voice::GCloudVoiceCompleteCode code);
    
    virtual void OnSpeechToText(gcloud_voice::GCloudVoiceCompleteCode code, const char *fileID, const char *result);
    
    virtual void OnRecording(const unsigned char* pAudioData, unsigned int nDataLength);
    
    virtual void OnStreamSpeechToText(gcloud_voice::GCloudVoiceCompleteCode code, int error, const char *result, const char *voicePath);
    
    virtual void OnRoleChanged(gcloud_voice::GCloudVoiceCompleteCode code, const char *roomName, int memberID, int role);
    
    virtual void OnEvent(gcloud_voice::GCloudVoiceEvent event, const char * info);
    
    virtual void OnMuteSwitchResult(int nState);
    
    virtual void OnReportPlayer(gcloud_voice::GCloudVoiceCompleteCode code, const char* cszInfo);

    virtual void OnSaveRecFileIndex(GCloudVoiceCompleteCode code, const char *fileid, int fileindex);

    virtual void OnRoomMemberInfo(GCloudVoiceCompleteCode code, const char* roomName, int memid, const char* openID);

    virtual void OnSpeechTranslate(GCloudVoiceCompleteCode nCode, const char* srcText, const char* targetText, const char* targetFileID, int srcFileDuration);
    virtual void OnRSTS(GCloudVoiceCompleteCode nCode, SpeechLanguageType srcLang, SpeechLanguageType targetLang, const char* srcText, const char* targetText, const char* targetFileID, int srcFileDuration);

    virtual void OnQueryUserInfo(GCloudVoiceCompleteCode code, const char* roomName, WXMemberInfo *member);

    virtual void OnWXMemberVoice(const char* roomName, unsigned int *members, int count);

    virtual void OnQueryWXMembers(GCloudVoiceCompleteCode code, const char* roomName, WXMemberInfo *members, int count);

    virtual void OnUpdateUserInfo(GCloudVoiceCompleteCode code, const char* roomName, unsigned int memberID);
    
private:
    FString CompleteCodeToStr(int code);
};
#endif