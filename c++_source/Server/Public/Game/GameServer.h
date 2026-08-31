// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Game/GameCommon.h"
#include "Networking.h"
#include "StressTest/StressTestManager.h"
#include "ServerTabFileManager.h"
#include "GameServer.generated.h"


class USocketNetworkManager;
class UDungeonNetHandler;
class UAIGameCoreProxyClient;

UCLASS()
class SERVER_API UGameServer : public UGameCommon
{
	GENERATED_UCLASS_BODY()

public:
    static UGameServer* Get(const UObject* WorldContextObject);

    virtual void Init() override;
    virtual void Start() override;
    virtual void Shutdown() override;
    virtual void TickImplement(float DeltaTime) override;
    virtual void InitLua() override;
    virtual void UninitLua() override;


    USocketNetworkManager* GetDungeonNetManager() const { return DungeonNetManager; }

    // if true, dungeon server will connect to hub server actively
    // if false, dungeon server may need mock data for debug
    bool IsDungeonWithHub();

    bool ShouldTriggerCrashDueToLuaError();

    bool SetDumpPolicy(bool bCore);

    FIPv4Address& GetDungeonServerAddress();
    int32 GetDungeonServerUdpPort();
    FString GetTicket();
    int32 GetDungeonTemplateId();
    FString GetDungeonInitData();
    class UHistoryService* GetHistoryService();

    bool KickPlayer(APlayerController* PlayerController);
    int32 KickAllPlayers();
    void StartGame(const struct FDMSDungeonRequest& DMSDungeonRequest);
    void EndGame();

    // Stress Test
    bool IsStressTest();

    UAIGameCoreProxyClient* GetAIGameCoreProxy() const;
    void RedirectLogBySession(const FString& SessionId);

private:
    void SetTicket(const FString &InTicket);
    void SetDungeonTemplateId(int32 InDungeonTemplateId);
    bool StartDungeonInstance(int TemplateId);
    void EndGameImpl();
    void AutoLaunchDungeon();
    void RestartServerLua();

    // stat
    void Stat(bool IsFirstLaunch);
    void StartStat();
    void StopStat();

    bool LoadMap(bool DefaultMap, int DungeonTemplateId);
    bool Restart(bool DefaultMap, int DungeonTemplateId, bool RestartLua = true, bool NotifyStart = true, bool bLoadMap = false);
    void FinishSessionLog();
    const FString GetDefaultAnalyticsLogFilename() const;
    const FString GetFilenameWithSessionId(const FString& OrginalFilename, const FString& SessionId) const;

private:
    UPROPERTY()
    USocketNetworkManager* DungeonNetManager;
    UPROPERTY()
    UDungeonNetHandler* DungeonNetHandler;

    UPROPERTY()
    UAIGameCoreProxyClient* AIGameCoreProxy;

    UPROPERTY()
    class UDMSClient* DMSClient;

    UPROPERTY()
    class UGPerfReporterManagerServer* GPerfReporterManager;

    UPROPERTY()
    class UHistoryService* HistoryService;

    FIPv4Address DungeonServerAddress;
    int32 ProcessId;
    FServerTabFileManager TabFileManager;

    bool bDungeonMode;
    bool bValidateMode;
    bool bTriggerCrashDueToLuaError;
    int32 AutoLaunchTemplateId;
    int32 AutoLaunchGameInitDataId;
	bool AutoLaunchFirstLaunch;
    bool bGaming;
    bool bStat;
    bool bFork;
    
    FString Ticket;
    int32 DungeonTemplateId;
    bool EndGameInNextTick;
    FString DungeonInitData;
    int32 PreloadMapId;
	bool SkipReloadMapOnReset;
    FString CurrentSessionId;

    FStressTestManager StressTestManager;
};
