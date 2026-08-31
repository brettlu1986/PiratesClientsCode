// Fill out your copyright notice in the Description page of Project Settings.

#include "GameServer.h"
#include "Server.h"
#include "SocketNetworkManager.h"
#include "Network/DungeonNetHandler.h"
#include "ServerShell.h"
#include "DungeonShell.h"
#include "DMSDataModels.h"
#include "DungeonInfoTabFile.h"
#include "HAL/PlatformApplicationMisc.h"
#include "HAL/PlatformProcess.h"
#include "IpNetDriver.h"
#include "GameMapsSettings.h"
#include "DMS.h"
#include "HistoryService.h"
#include "Analytics.h"
#include "AI/AIGameCoreProxy/AIGameCoreProxyClient.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/GameModeDelegate.h"
#include "KMGameMode.h"
#include "RPCNetworkManager.h"
#include "GPerf/GPerfReporterManagerServer.h"
#include "HAL/PlatformOutputDevices.h"
#include "HAL/FileManager.h"
#include "Misc/OutputDeviceFile.h"

#if ENABLE_U4LUA
#include "GameLuaRoot.h"
#else
#include "GameLuaManager.h"
#endif


#if PLATFORM_LINUX
#include <sys/resource.h>
#endif

DEFINE_LOG_CATEGORY_STATIC(GameServerLog, Log, All)

UGameServer::UGameServer(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , DungeonNetManager(nullptr)
    , DungeonNetHandler(nullptr)
    , AIGameCoreProxy(nullptr)
    , DMSClient(nullptr)
    , HistoryService(nullptr)
    , ProcessId(0)
    , bDungeonMode(false)
    , bValidateMode(false)
    , bTriggerCrashDueToLuaError(false)
    , AutoLaunchTemplateId(-1)
    , AutoLaunchGameInitDataId(-1)
	, AutoLaunchFirstLaunch(true)
    , bGaming(false)
    , bStat(false)
    , bFork(false)
    , Ticket(TEXT(""))
    , DungeonTemplateId(-1)
    , EndGameInNextTick(false)    
    , DungeonInitData(TEXT(""))
    , PreloadMapId(-1)
	, SkipReloadMapOnReset(false)
{
	LuaInitScriptName = TEXT("ServerMain");
	LuaStartScriptName = TEXT("ServerStartGame");
    LuaGlobalTableDefineScriptName = TEXT("GlobalTableDefine");
}

UGameServer* UGameServer::Get(const UObject* WorldContextObject)
{
    return Cast<UGameServer>(GetGame(WorldContextObject));
}

void UGameServer::Init()
{
    TabFileManager.Init();

    Super::Init();
    
    RPCNetworkManager->SetLimitPacketProcessingEnabled(false);

    EndGameInNextTick = false;
    bDungeonMode = FParse::Param(FCommandLine::Get(), TEXT("dungeon"));
    bValidateMode = FParse::Param(FCommandLine::Get(), TEXT("validate"));
    bTriggerCrashDueToLuaError = FParse::Param(FCommandLine::Get(), TEXT("triggercrashduetoluaerror"));
    if (!FParse::Value(FCommandLine::Get(), TEXT("autolaunchtemplateid="), AutoLaunchTemplateId))
    {
        AutoLaunchTemplateId = -1;
    }
    bStat = FParse::Param(FCommandLine::Get(), TEXT("stat"));
    EnableGM = FParse::Param(FCommandLine::Get(), TEXT("gm"));
	SkipReloadMapOnReset = FParse::Param(FCommandLine::Get(), TEXT("skip-reload-map-on-reset"));
#if PLATFORM_UNIX
    bFork = FParse::Param(FCommandLine::Get(), TEXT("fork"));
#endif    
    UE_LOG(GameServerLog, Log, TEXT("Game server init with %s && %s && %s && %s mode. Trigger crash due to lua error flag is set to %s. EnableGM is set to %s."),
        bDungeonMode ? TEXT("DUNGEON") : TEXT("NON-DUNGEON"),
        bValidateMode ? TEXT("VALIDATE") : TEXT("NON-VALIDATE"),
        bStat ? TEXT("STAT") : TEXT("NON-STAT"),
		SkipReloadMapOnReset ? TEXT("SKIP-RELOAD-MAP-ON-RESET") : TEXT("RELOAD-MAP-ON-RESET"),
        bTriggerCrashDueToLuaError ? TEXT("TRUE") : TEXT("FALSE"),
        EnableGM ? TEXT("TRUE") : TEXT("FALSE"));

    if (!FParse::Value(FCommandLine::Get(), TEXT("autolaunchgameinitdataid="), AutoLaunchGameInitDataId))
    {
        AutoLaunchGameInitDataId = -1;
    }

    if (FParse::Value(FCommandLine::Get(), TEXT("preload-map-id="), PreloadMapId))
    {
        PreloadMap = true;
    }
    else 
    {
        PreloadMap = false;
    }
    UE_LOG(GameServerLog, Log, TEXT("Game server PreloadMap set to %d, PreloadMapId: %d"), PreloadMap, PreloadMapId);

    if (bDungeonMode)
    {
        FString PublicIp("127.0.0.1");
        FParse::Value(FCommandLine::Get(), TEXT("publicip="), PublicIp);
        FIPv4Address::Parse(*PublicIp, DungeonServerAddress);

        DungeonNetManager = NewObject<USocketNetworkManager>(this);
        DungeonNetManager->Init();

        DungeonNetHandler = NewObject<UDungeonNetHandler>(this);
        DungeonNetHandler->InitializeNetwork(DungeonNetManager);

        DMSClient = NewObject<UDMSClient>(this);
    }

    HistoryService = NewObject<UHistoryService>(this);
    HistoryService->Init();
    StressTestManager.Init();

    AIGameCoreProxy = NewUObjectAndInit<UAIGameCoreProxyClient>();

    // Analytics
    FAnalyticsApi::Instance().Init(GetDefaultAnalyticsLogFilename());
    FAnalyticsLuaApi::Instance().Init(TEXT("GameDataGenerated/protos/dungeon_analytics.pb"));
}

void UGameServer::Start()
{
    Super::Start();

    ProcessId = FPlatformProcess::GetCurrentProcessId();
    UE_LOG(GameServerLog, Log, TEXT("Game server start. Process id: %d"), ProcessId);

    // Skip starting DMS logic in validate mode.
    if (DMSClient != nullptr && !bValidateMode)
    {
        if (PreloadMap) 
        {
            Restart(false, PreloadMapId, true, true, true);
        }

        DMSClient->OnDMSStartGame.AddUObject(
            this,
            &UGameServer::StartGame);

        FString InstanceId("INSTANCE1");
        FParse::Value(FCommandLine::Get(), TEXT("instanceid="), InstanceId);
        int32 Port = GetDungeonServerUdpPort();
        DMSClient->DMSInit(InstanceId, Port, PreloadMapId, this);
        DMSClient->DMSStart();
    }

    StartTick();
}

void UGameServer::Shutdown()
{
//#ifdef WITH_GPERF
    if (GPerfReporterManager)
    {
        GPerfReporterManager->Uninit();
    }
//#endif
	EndGameInNextTick = false;
    StopTick();
    if (DungeonNetManager)
    {
        DungeonNetManager->Uninit();
    }
    if (AIGameCoreProxy)
    {
        AIGameCoreProxy->Uninit();
    }
    TabFileManager.Uninit();
    FAnalyticsLuaApi::Instance().Uninit();
    FAnalyticsApi::Instance().Uninit();
    StopStat();
    

    Super::Shutdown();
}

FIPv4Address& UGameServer::GetDungeonServerAddress()
{
    return DungeonServerAddress;
}

int32 UGameServer::GetDungeonServerUdpPort()
{
    auto World = GetWorld();
    auto NetDriver = (UIpNetDriver*)World->GetNetDriver();
    if (NetDriver != nullptr)
    {
        int32 Port = 0;
        NetDriver->LocalAddr->GetPort(Port);
        return Port;
    }

    return 0;
}

void UGameServer::TickImplement(float DeltaTime)
{
    Super::TickImplement(DeltaTime);
    SAVE_TICK(DungeonNetManager, DeltaTime);    

    bool bIsEndGame = EndGameInNextTick;
    if (EndGameInNextTick)
    {
        EndGameImpl();
    }

    Stat(!bIsEndGame);
    AutoLaunchDungeon();
    StressTestManager.Tick();
    SAVE_UPDATE(AIGameCoreProxy, DeltaTime);    
}

void UGameServer::InitLua()
{
    Super::InitLua();

#if ENABLE_U4LUA
    if (IsU4LuaEnabled())
    {
        LuaRoot = NewObject<UGameLuaRoot>(this);
        LuaRoot->Init();
        LuaRoot->SetIsDedicatedServer(true);
        LuaRoot->GetLib()->SetSearchPath({
            TEXT("Scripts/Base/"),
            TEXT("Scripts/Common/"),
            TEXT("Scripts/BattleServer/"),
            TEXT("GameDataGenerated/"),
            });
        LuaRoot->GetLib()->RegistGlobalFunction("logevent", &FAnalyticsLuaApi::LogEvent);
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->SetIsDedicatedServer(true);
        GameLuaManager->AddSearchPath(TEXT("GameDataGenerated/"));
        GameLuaManager->AddSearchPath(TEXT("Scripts/BattleServer/"));

        // Analytics
        GameLuaManager->RegistGlobalFunction("logevent", &FAnalyticsLuaApi::LogEvent);
    }
#endif

    //#ifdef WITH_GPERF
    GPerfReporterManager = NewObject<UGPerfReporterManagerServer>();
    GPerfReporterManager->Init(this);
    //#endif
}

void UGameServer::UninitLua()
{
    if (GPerfReporterManager)
    {
        GPerfReporterManager->Uninit();
    }
    Super::UninitLua();
}

bool UGameServer::IsDungeonWithHub()
{
    return bDungeonMode;
}

bool UGameServer::ShouldTriggerCrashDueToLuaError()
{
    return bTriggerCrashDueToLuaError;
}

bool UGameServer::SetDumpPolicy(bool bCore)
{
#if PLATFORM_LINUX
    if (FPlatformApplicationMisc::ShouldIncreaseProcessLimits())
    {
        rlimit Limit;
        Limit.rlim_cur = bCore ? RLIM_INFINITY : 0;
        if (setrlimit(RLIMIT_CORE, &Limit) != 0)
        {
            UE_LOG(GameServerLog, Warning, TEXT("Failed to set dump policy %d."), bCore);
            return false;
        }
        UE_LOG(GameServerLog, Log, TEXT("Set dump policy to %d."), bCore);
        return true;
    }
#endif
    UE_LOG(GameServerLog, Log, TEXT("Skip SetDumpPolicy: %d. Unsupported platform."), bCore);
    return false;
}

void UGameServer::SetTicket(const FString &InTicket)
{
    Ticket = InTicket;
}

FString UGameServer::GetTicket()
{
    return Ticket;
}

void UGameServer::SetDungeonTemplateId(int32 InDungeonTemplateId)
{
    DungeonTemplateId = InDungeonTemplateId;
}

int32 UGameServer::GetDungeonTemplateId()
{
    return DungeonTemplateId;
}

FString UGameServer::GetDungeonInitData()
{
    return DungeonInitData;
}

UHistoryService* UGameServer::GetHistoryService()
{
    return HistoryService;
}

void UGameServer::EndGame()
{
    EndGameInNextTick = true;
}

bool UGameServer::KickPlayer(APlayerController* PlayerController)
{
    if (PlayerController != nullptr)
    {
        // 这里如果调用原生的kick，会先把pawn删了，然后tick时在删controller，但在这之间还有可能收到rpc包
        //auto World = GetWorld();
        //if (World != nullptr)
        //{
        //    auto GameMode = World->GetAuthGameMode();
        //    if (GameMode != nullptr && GameMode->GameSession != nullptr)
        //    {
        //        return GameMode->GameSession->KickPlayer(PlayerController, FText());
        //    }
        //}
        // 这里如果是正常连接的玩家，那么先把connection close掉，然后tick里destroy加logout

        return PlayerController->DestroyNetworkActorHandled();
		/* 
		CleanUp有几个点需要注意下: 
		1. 不能在c2d的时候同步调用，这样就相当于NetConnection内部清理自己。
		2. CleanUp内部会触发Logout，Lua代码里要协调好(FFA最后一个人观战机器人时被顶号，如果触发Logout的话会执行副本回收，顶号那个人会报错)。
		先回滚到原来的代码，等实现得了解清楚了再改下这块。
		UNetConnection* PlayerConnection = PlayerController->GetNetConnection();
		if (PlayerConnection)
		{
			PlayerConnection->CleanUp();
			return true;
		}
		*/
    }
    return false;
}

int32 UGameServer::KickAllPlayers()
{
    int32 Count = 0;
    auto World = GetWorld();
    if (World != nullptr)
    {
        auto GameMode = World->GetAuthGameMode();
        if (GameMode != nullptr && GameMode->GameSession != nullptr)
        {
            for (auto Iterator = World->GetPlayerControllerIterator(); Iterator; ++Iterator)
            {
                APlayerController* PlayerController = Iterator->Get();
                if (PlayerController && PlayerController->DestroyNetworkActorHandled())
                {
                    // Destruction is latent. It occurs at the end of the tick. Please refer to Actor::Destroy comments.
                    //GameMode->GameSession->KickPlayer(PlayerController, FText()) ? ++Count : true;
                    ++Count;
                }
            }
        }
    }
    return Count;
}

void UGameServer::StartGame(const FDMSDungeonRequest& DMSDungeonRequest)
{
    UE_LOG(GameServerLog, Log, TEXT("UGameServer::StartGame %d, %d, %d"), PreloadMap, PreloadMapId, DMSDungeonRequest.dungeon_type);
    if (EndGameInNextTick)
    {
        EndGameImpl();
    }

    DungeonInitData = DMSDungeonRequest.init_data;

    int32 TemplateId = PreloadMap ? PreloadMapId : DMSDungeonRequest.dungeon_type;
    if (!StartDungeonInstance(TemplateId))
    {
        UE_LOG(GameServerLog, Error, TEXT("StartGame failed. Dungeon_type: %d"), DMSDungeonRequest.dungeon_type);
        EndGameImpl();
    }
    else
    {
        bGaming = true;
        SetDungeonTemplateId(TemplateId);
        SetTicket(DMSDungeonRequest.ticket);
        for (const FDMSHubInfo& HubInfo : DMSDungeonRequest.hub_list)
        {
            static int32 s_SocketId = 0;
            int32 NewSocketId = ++s_SocketId;
            FString Endpoint = FString::Printf(TEXT("%s:%d"), *HubInfo.ip, HubInfo.port);;
            if (DungeonNetManager->CreateSocket(NewSocketId, Endpoint))
            {
                DungeonNetManager->Connect(NewSocketId, Endpoint);
            }
            else
            {
                UE_LOG(GameServerLog, Error, TEXT("Create socket failed. Dungeon_type: %d, %s"), DMSDungeonRequest.dungeon_type, *Endpoint);
            }
        }

        UServerShell::GetServer(this)->OnReadyToBeConnected.ExecuteIfBound();
    }
}

bool UGameServer::LoadMap(bool DefaultMap, int TemplateId) {
    UE_LOG(GameServerLog, Log, TEXT("UGameServer::LoadMap %d, %d"), DefaultMap, TemplateId);
    UGameInstance* GameInstance = nullptr;
    UWorld* World = GetWorld();
    if (World)
    {
        GameInstance = World->GetGameInstance();
    }

    if (!GameInstance)
    {
        return false;
    }

    FString PackageName = UGameMapsSettings::GetGameDefaultMap();
    if (!DefaultMap)
    {
        const FDungeonInfoTabFileData* DungeonInfo = FDungeonInfoTabFile::GetSingleton().Find(TemplateId);
        checkf(DungeonInfo != nullptr, TEXT("Dungeon template id not found. %d"), TemplateId);
        int DungeonMode = 0;
        FString SceneMap = DungeonInfo->GetSceneMap(DungeonMode);
        FString MapOptions = FString::Printf(TEXT("?DungeonId=%d?DungeonMode=%d"), TemplateId, DungeonMode);
        PackageName = SceneMap + MapOptions;
    }

    FURL DefaultURL;
    DefaultURL.LoadURLConfig(TEXT("DefaultPlayer"), GGameIni);

    FURL URL(&DefaultURL, *PackageName, TRAVEL_Partial);
    FString Error;
    GEngine->LoadMap(*GameInstance->GetWorldContext(), URL, NULL, Error);
    UE_LOG(GameServerLog, Log, TEXT("Load map %s"), *URL.ToString());
    return true;
}

bool UGameServer::Restart(bool DefaultMap, int TemplateId, bool RestartLua, bool NotifyStart, bool bLoadMap)
{
    UE_LOG(GameServerLog, Log, TEXT("UGameServer::Restart %d, %d, %d, %d"), DefaultMap, TemplateId, RestartLua, NotifyStart);
    if (RestartLua)
    {
        RestartServerLua();
    }

    if (NotifyStart) 
    {
        UServerShell::GetServer(this)->OnStartDungeon.ExecuteIfBound(TemplateId);
    }

    bool bSuccessLoad = true;
    if (bLoadMap)
    {
        bSuccessLoad = LoadMap(DefaultMap, TemplateId);
    }
    return bSuccessLoad;
}

bool UGameServer::StartDungeonInstance(int TemplateId)
{
    UE_LOG(GameServerLog, Log, TEXT("UGameServer::StartDungeonInstance %d"), TemplateId);
    UGameInstance* GameInstance = nullptr;
    UWorld* World = GetWorld();
    if (World)
    {
        GameInstance = World->GetGameInstance();
    }

    if (!GameInstance)
    {
        return false;
    }

    if (!PreloadMap) 
    {
        Restart(false, TemplateId, true, true, !SkipReloadMapOnReset);
    }
    else
    {
        auto GameMode = Cast<AKMGameMode>(World->GetAuthGameMode());
        if (GameMode && GetGameDelegateManager())
        {
            GetGameDelegateManager()->GameMode->OnStartGameModeManually.ExecuteIfBound(GameMode, GameMode->OptionsString);
        }
    }

    return true;
}

void UGameServer::EndGameImpl()
{
    UServerShell::GetServer(this)->OnStopDungeon.ExecuteIfBound();

    bGaming = false;
    EndGameInNextTick = false;
    Ticket = TEXT("");
    DungeonTemplateId = 0;
    DungeonInitData = TEXT("");

    auto KickCount = KickAllPlayers();
    UE_LOG(GameServerLog, Log, TEXT("UGameServer::EndGameImpl Player kicked count: %d"), KickCount);
    if (DungeonNetManager != nullptr)
    {
        DungeonNetManager->DestroyAllSockets();
    }

    UninitLua();

    if (DMSClient != nullptr)
    {
        UE_LOG(GameServerLog, Log, TEXT("UGameServer::EndGameImpl DMSReset"));
        DMSClient->DMSReset();
    }

    FinishSessionLog();
    
    UGameInstance* GameInstance = nullptr;
    UWorld* World = GetWorld();
    if (World && World->GetGameInstance())
    {
        bool bLoadMap = PreloadMap && !bFork && !SkipReloadMapOnReset;
        Restart(!PreloadMap, PreloadMapId, PreloadMap, PreloadMap, bLoadMap);
    }
}

static FString GetAutoLaunchInitData(int GameInitDataId) 
{
    return FString::FromInt(GameInitDataId);
}

void UGameServer::AutoLaunchDungeon()
{
    if (!bGaming && AutoLaunchTemplateId >= 0)
    {
        FDMSDungeonRequest Request;
        Request.dungeon_type = AutoLaunchTemplateId;
        Request.init_data = GetAutoLaunchInitData(AutoLaunchGameInitDataId);
        UE_LOG(GameServerLog, Log, TEXT("AutoLaunchDungeon %d, %d===========%s"), AutoLaunchTemplateId, AutoLaunchGameInitDataId, *Request.init_data);
        
		bool OrignialSkipReloadMapOnReset = SkipReloadMapOnReset;
		if (AutoLaunchFirstLaunch) {
			// TODO 强制退出游戏，不管 bGaming。临时解决 ServerMain.lua 中 InitManagerRoot StartDungeon 的问题
			EndGameImpl();

			AutoLaunchFirstLaunch = false;
			// Do NOT skip loading map in first starting game.
			SkipReloadMapOnReset = false;
		}
		StartGame(Request);
		SkipReloadMapOnReset = OrignialSkipReloadMapOnReset;

		// Set the same handle process as PreloadMap. Do it after first launch.
		PreloadMap = true;
		PreloadMapId = AutoLaunchTemplateId;
    }
}

void UGameServer::RestartServerLua()
{
    UninitLua();
    InitLua();
    PostInitLua();

#if ENABLE_U4LUA
    if (LuaRoot)
    {
        LuaRoot->GetLib()->DoFile(LuaInitScriptName);
        LuaRoot->GetLib()->DoFile(LuaStartScriptName);
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->DoFile(LuaInitScriptName);
        GameLuaManager->DoFile(LuaStartScriptName);
    }
#endif
}

bool UGameServer::IsStressTest()
{
    return AutoLaunchTemplateId >= 0;
}

void UGameServer::Stat(bool IsFirstLaunch)
{
    if (!bGaming)
    {
        if (IsFirstLaunch)
        {
            StartStat();
        }
        else
        {
            StopStat();
        }
    }
}

void UGameServer::StartStat()
{
    if (bStat)
    {
        GEngine->Exec(nullptr, TEXT("stat startfile"));
    }
}

void UGameServer::StopStat()
{
    if (bStat)
    {
        GEngine->Exec(nullptr, TEXT("stat stopfile"));
    }
}

UAIGameCoreProxyClient* UGameServer::GetAIGameCoreProxy() const
{
    return AIGameCoreProxy;
}

void UGameServer::RedirectLogBySession(const FString& SessionId)
{
    FOutputDeviceFile* OutputDevice = static_cast<FOutputDeviceFile*>(FPlatformOutputDevices::GetLog());
    OutputDevice->TearDown();

    IFileManager& FileManager = IFileManager::Get();
    FString Filename = FPlatformOutputDevices::GetAbsoluteLogFilename();
    if (FileManager.FileExists(*Filename))
    {
        // rename       
        FString NewFilename = GetFilenameWithSessionId(Filename, SessionId);
        FileManager.Move(*NewFilename, *Filename);
        
        OutputDevice->SetFilename(*NewFilename);
        OutputDevice->SetAppendIfExists(true);
    }

    CurrentSessionId = SessionId;
    
    FAnalyticsApi::Instance().RenameFile(
        GetFilenameWithSessionId(GetDefaultAnalyticsLogFilename(), SessionId));
}

void UGameServer::FinishSessionLog()
{
    if (CurrentSessionId.Len() == 0)
    {
        return;        
    }

    // reset analytics log
    FAnalyticsApi::Instance().Uninit();
    FAnalyticsApi::Instance().Init(GetDefaultAnalyticsLogFilename());

    // restore original values
    FOutputDeviceFile* OutputDevice = static_cast<FOutputDeviceFile*>(FPlatformOutputDevices::GetLog());
    OutputDevice->SetFilename(TEXT(""));    // 里面会自动TearDown
    OutputDevice->SetAppendIfExists(false);
    CurrentSessionId.Empty();
}

const FString UGameServer::GetDefaultAnalyticsLogFilename() const
{
    FString AnalyticsLogFile(FPaths::ProjectLogDir() / TEXT("analytics.log"));
    FParse::Value(FCommandLine::Get(), TEXT("analyticslog="), AnalyticsLogFile);
    return AnalyticsLogFile;
}

const FString UGameServer::GetFilenameWithSessionId(const FString& OrginalFilename, const FString& SessionId) const
{
    FString Name, Extension;
    OrginalFilename.Split(TEXT("."), &Name, &Extension, ESearchCase::CaseSensitive, ESearchDir::FromEnd);
    return FString::Printf(TEXT("%s-%s.%s"), *Name, *SessionId, *Extension);
}