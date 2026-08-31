// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Shell/CommonShell.h"
#include "ServerShell.generated.h"

class UDungeonShell;

/**
* Expose interfaces of UGameServer to Lua/Blueprint
*/
UCLASS()
class SERVER_API UServerShell : public UCommonShell
{
	GENERATED_UCLASS_BODY()
	
public:
    UFUNCTION()
    static UServerShell* GetServer(UObject* WorldContextObject);

    virtual void Init() override;

    UFUNCTION()
    void CancelPendingNetGame(UObject* WorldContextObject);

    UFUNCTION()
    class USocketNetworkManager* GetDungeonNetManager();

    UFUNCTION()
    bool IsDungeonWithHub();

    UFUNCTION()
    bool ShouldTriggerCrashDueToLuaError();

    UFUNCTION()
    bool SetDumpPolicy(bool bCore);

    UFUNCTION()
    UDungeonShell* GetDungeonShell();

    UFUNCTION()
    bool KickPlayer(APlayerController *PlayerController);

    UFUNCTION()
    int32 KickAllPlayers();

    UFUNCTION()
    FString GetDungeonInitData();

    UFUNCTION()
    FString GetHistoryServiceSavePlayerStatsUrl();

    UFUNCTION()
    FString GetHistoryServiceSaveTeamRankUrl();

    UFUNCTION()
    bool IsStressTest();

    UFUNCTION(BlueprintPure, Category = "Server")
    class UAIGameCoreProxyClient* GetAIGameCoreProxy() const;

    UFUNCTION()
    void RedirectLogBySession(const FString& SessionId);

public:
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnStartDungeon, int, DungoenId);
    DECLARE_DYNAMIC_DELEGATE(FOnStopDungeon);
    DECLARE_DYNAMIC_DELEGATE(FOnReadyToBeConnected);

    UPROPERTY()
    FOnStartDungeon OnStartDungeon;
    UPROPERTY()
    FOnStopDungeon OnStopDungeon;
    UPROPERTY()
    FOnReadyToBeConnected OnReadyToBeConnected;

private:
    UPROPERTY()
    UDungeonShell* DungeonShell;

};
