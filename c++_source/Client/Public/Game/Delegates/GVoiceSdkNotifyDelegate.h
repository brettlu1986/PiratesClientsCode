#pragma once
#include "GVoiceSdkNotifyDelegate.generated.h"

UCLASS()
class CLIENT_API UGVoiceSdkNotifyDelegate : public UObject
{
    GENERATED_BODY()

        DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnJoinRoom, int, completeCode, const FString, roomName, int, memberID);
        DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnStatusUpdate, const FString, roomName, int, memberID);
        DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnQuitRoom, int, completeCode, const FString, roomName);
        DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnMemberVoice, const FString, roomName, unsigned int, member, int, status);
        DECLARE_DYNAMIC_DELEGATE_OneParam(FOnRecording, unsigned int , nDataLength);
        DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnMemberVoiceDetail, TArray<unsigned int>, stateArray, int, count);
        DECLARE_DYNAMIC_DELEGATE_FourParams(FOnRoomMemberInfo, int, completeCode, int, memId, const FString, roomName, const FString, openId);
        DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnEvent, int, eventCode, const FString, eventInfo);
        DECLARE_DYNAMIC_DELEGATE_ThreeParams(FGetMemberInfo, int, errorCode, TArray<int>, memberIdArr, TArray<FString>, MemberOpenId);

    public:
        UPROPERTY()
        FOnJoinRoom OnJoinRoom;

        UPROPERTY()
        FOnStatusUpdate OnStatusUpdate;

        UPROPERTY()
        FOnQuitRoom OnQuitRoom;

        UPROPERTY()
        FOnMemberVoice OnMemberVoice;

        UPROPERTY()
        FOnRecording OnRecording;

        UPROPERTY()
        FOnMemberVoiceDetail OnMemberVoiceDetail;

        UPROPERTY()
        FOnRoomMemberInfo OnRoomMemberInfo;

        UPROPERTY()
        FOnEvent OnEvent;

        UPROPERTY()
        FGetMemberInfo GetMemberInfo;
};