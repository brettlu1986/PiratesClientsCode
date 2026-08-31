// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/GameCommon.h"
#include "Common.h"
#include "Game/Input/InputManager.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "OceanNavGridManager.h"
#include "LandNavMeshDataManager.h"
#include "Network/Http/HttpHelper.h"
#include "Network/RPCNetworkManager.h"
#include "Game/Delegates/GameModeDelegate.h"
#include "Game/PathNode/PathNodeFinder.h"
#include "Util/FatalLogCatcher.h"
#include "Misc/GameLimitedTimeTaskManager.h"
#include "Game/Battle/PiratesAreaTriggerManager.h"
#include "Game/Battle/PiratesActorTriggerGroupManager.h"

#include "Game/Battle/PiratesPlayerGrid.h"
#include "CharacterManager.h"
//#include "Game/Battle/PiratesGridTriggerManager.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "ExtendBlueprintFunctions.h"
#include "AI/AICoverPointsManager.h"
#include "Game/Battle/TemplateActorDataManager.h"
#include "Game/Battle/PiratesActorWeaponInhibitManager.h"
#include "Util/LogReport.h"
#include "AI/DestructibleObject/AIDestructibleObjectManagerRoot.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "AI/Vehicle/AIVehicleManager.h"
#include "AI/OceanGrid/AIOceanGridManagerRoot.h"
#include "AI/Smoke/AISmokeManager.h"

#if ENABLE_U4LUA
#include "Game/Lua/GameLuaRoot.h"
#else
#include "GameLuaManager.h"
#endif

DEFINE_LOG_CATEGORY_STATIC(GameCommonLog, Log, All)

UGameCommon::UGameCommon(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , InputManager(nullptr)
    , CharacterManager(nullptr)
    , HttpHelper(nullptr)
    , AreaTriggerManager(nullptr)
    , RPCNetworkManager(nullptr)
    , OceanNavGridManager(nullptr)
    , LandNavMeshDataManager(nullptr)
    , PathNodeFinder(nullptr)
	, PiratesPlayerGrid(nullptr)   
    , TaskManager(nullptr)
    , GameStatus(EPiratesGameStatus::NONE)
    , AICoverPointsManager(nullptr)
    , TemplateActorManager(nullptr)
    , LogReport(nullptr)
    , AIDestructibleObjectManager(nullptr)
    , AIVehicleManager(nullptr)
    , AIOceanGridManager(nullptr)
    , AISmokeManager(nullptr)
#if ENABLE_U4LUA
    , LuaRoot(nullptr)
#else
    , GameLuaManager(nullptr)    
#endif
    , EnableGM(true)
    , PreloadMap(false)
    , LastSpawnActorFrame(0)
{
}

void UGameCommon::Init()
{
    Super::Init();

    InputManager = NewUObjectAndInit<UInputManager>();
    CharacterManager = NewUObjectAndInit<UCharacterManager>();
    OceanNavGridManager = NewUObjectAndInit<UOceanNavGridManager>();
    RPCNetworkManager = NewUObjectAndInit<URPCNetworkManager>();
    HttpHelper = NewObject<UHttpHelper>(this);
    LandNavMeshDataManager = NewUObjectAndInit<ULandNavMeshDataManager>();
    PathNodeFinder = NewObject<UPathNodeFinder>(this);
    TaskManager = NewUObjectAndInit<UGameLimitedTimeTaskManager>();
    //GridTriggerManager = NewUObjectAndInit<UPiratesGridTriggerManager>();
	GridTypeManager = NewUObjectAndInit<UPiratesGridTypeManager>();
    AICoverPointsManager = NewUObjectAndInit<UAICoverPointsManager>();
    LogReport = NewUObjectAndInit<ULogReport>();
 	AIDestructibleObjectManager = NewUObjectAndInit<UAIDestructibleObjectManagerRoot>();
    AIVehicleManager = NewUObjectAndInit<UAIVehicleManager>();
    AIOceanGridManager = NewUObjectAndInit<UAIOceanGridManagerRoot>();
    AISmokeManager = NewObject<UAISmokeManager>(this);
 	
    auto GameDelegateMgr = GetGameDelegateManager();
    AreaTriggerManager = NewUObjectAndInit<UPiratesAreaTriggerManager>(GameDelegateMgr->GameMisc, GameDelegateMgr->Actor);
	if (FFatalLogCatcher::Get())
    {
        GError = FFatalLogCatcher::Get();
    }

    InitLua();
    PostInitLua();
}

void UGameCommon::PostInit()
{
    Super::PostInit();
    
#if ENABLE_U4LUA
    if (LuaRoot)
    {
        LuaRoot->GetLib()->DoFile(LuaInitScriptName);
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->DoFile(LuaInitScriptName);
    }
#endif
}

void UGameCommon::Start()
{
    Super::Start();

#if ENABLE_U4LUA
    if (LuaRoot)
    {
        LuaRoot->GetLib()->DoFile(LuaStartScriptName);
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->DoFile(LuaStartScriptName);
    }
#endif
}



void UGameCommon::Shutdown()
{
    UninitLua();

    SAVE_UNINIT(AreaTriggerManager);
    SAVE_CLEAR(LandNavMeshDataManager);
    SAVE_CLEAR(ActorTriggerGroupManager);
    SAVE_CLEAR(OceanNavGridManager);
    SAVE_CLEAR(PiratesPlayerGrid);
    SAVE_CLEAR(TemplateActorManager);
    SAVE_CLEAR(AIDestructibleObjectManager);

    SAVE_UNINIT(AIVehicleManager);
    SAVE_UNINIT(AIOceanGridManager);
    SAVE_UNINIT(TaskManager);
    //SAVE_UNINIT(GridTriggerManager);
    SAVE_UNINIT(LogReport);
    
    Super::Shutdown();
}

UGameCommon* UGameCommon::Get(const UObject* WorldContextObject)
{
    return Cast<UGameCommon>(GetGame(WorldContextObject));
}

void UGameCommon::TickImplement(float DeltaTime)
{
    Super::TickImplement(DeltaTime);

    SAVE_UPDATE(AreaTriggerManager, DeltaTime);
    SAVE_UPDATE(ActorTriggerGroupManager, DeltaTime);
    SAVE_UPDATE(PiratesPlayerGrid, DeltaTime);
    //SAVE_UPDATE(GridTriggerManager, DeltaTime);
    SAVE_UPDATE(GridTypeManager, DeltaTime);
    SAVE_UPDATE(TemplateActorManager, DeltaTime);
    SAVE_UPDATE(AICoverPointsManager, DeltaTime);
    SAVE_TICK(RPCNetworkManager, DeltaTime);
    SAVE_UPDATE(PiratesActorWeaponInhibitManager, DeltaTime);
    SAVE_TICK(AISmokeManager, DeltaTime);
}

void UGameCommon::InitLua()
{
#if !ENABLE_U4LUA
    if (!IsU4LuaEnabled())
    {
        GameLuaManager = NewObject<UGameLuaManager>(this);
        GameLuaManager->Init(FPaths::ProjectContentDir(), LuaPathCacheFile);
        GameLuaManager->AddSearchPath(TEXT("Scripts/Base/"));
        GameLuaManager->AddSearchPath(TEXT("Scripts/Common/"));
    }
#endif
}

static FString s_RemoteLuaRepository;
void UGameCommon::PostInitLua()
{
#if ENABLE_U4LUA
    if (LuaRoot)
    {
        FString RemoteRepositoryURL;
        FParse::Value(FCommandLine::Get(), TEXT("RemoteLuaRepository="), RemoteRepositoryURL);
        if (RemoteRepositoryURL.Len() > 0 || s_RemoteLuaRepository.Len() > 0)
        {
            LuaRoot->SetHttpRemoteRepository(RemoteRepositoryURL.Len() > 0 ? RemoteRepositoryURL : s_RemoteLuaRepository);
        }

        auto Lib = LuaRoot->GetLib();
        Lib->SetGlobalTableNewIndexEnabled(true);
        Lib->DoFile(LuaGlobalTableDefineScriptName);
        Lib->SetGlobalTableNewIndexEnabled(false);
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->SetGlobalTableNewIndexEnabled(true);
        GameLuaManager->DoFile(LuaGlobalTableDefineScriptName);
        GameLuaManager->SetGlobalTableNewIndexEnabled(false);
    }
#endif
}

void UGameCommon::UninitLua()
{
    GetGameDelegateManager()->GameMisc->OnUninitLua.ExecuteIfBound();

#if ENABLE_U4LUA
    if (LuaRoot)
    {
        LuaRoot->Uninit();
        LuaRoot->MarkPendingKill();
        LuaRoot = nullptr;
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->Uninit();
        GameLuaManager = nullptr;
    }
#endif
}

void UGameCommon::OnWorldChanged(UWorld* NewWorld)
{
    Super::OnWorldChanged(NewWorld);

#if ENABLE_U4LUA
    if (LuaRoot)
    {
        LuaRoot->OnCurrentWorldChanged(NewWorld);
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->OnWorldChanged(NewWorld);
    }
#endif

    if (GridTypeManager)
    {
        GridTypeManager->OnWorldChanged(NewWorld);
    }
}

void UGameCommon::OnWorldCleanup(UWorld* World)
{
    if (LuaRoot)
    {
        LuaRoot->OnCurrentWorldChanged(nullptr);
    }

    Super::OnWorldCleanup(World);
}

UGameDelegateManager* UGameCommon::GetGameDelegateManager() const
{
    return Cast<UGameDelegateManager>(GetKMDelegateManager());
}

UClass* UGameCommon::GetKMDelegateManagerClass()
{
    return UGameDelegateManager::StaticClass();
}

ULogReport* UGameCommon::GetLogReport()
{
    return LogReport;
}

UHttpHelper* UGameCommon::GetHttpHelper()
{
    return HttpHelper;
}

UPiratesPlayerGrid* UGameCommon::GetPiratesPlayerGrid()
{
	if (PiratesPlayerGrid == nullptr)
	{
		PiratesPlayerGrid = NewObject<UPiratesPlayerGrid>(this);
	}
	return PiratesPlayerGrid;
}

UPiratesActorTriggerGroupManager* UGameCommon::GetActorTriggerGroupManager()
{
    if (ActorTriggerGroupManager == nullptr)
    {
        ActorTriggerGroupManager = NewObject<UPiratesActorTriggerGroupManager>(this);
        ActorTriggerGroupManager->SetDelegate(GetGameDelegateManager()->GameMisc);
    }
    return ActorTriggerGroupManager;
}

UPiratesActorWeaponInhibitManager* UGameCommon::GetActorWeaponInhibitManager()
{
    if (PiratesActorWeaponInhibitManager == nullptr)
    {
        PiratesActorWeaponInhibitManager = NewObject<UPiratesActorWeaponInhibitManager>(this);
        PiratesActorWeaponInhibitManager->SetDelegate(GetGameDelegateManager()->GameMisc);
    }
    return PiratesActorWeaponInhibitManager;
}

UPiratesGridTypeManager* UGameCommon::GetGridTypeManager()
{
	return GridTypeManager;
}

FString UGameCommon::ApproveLogin(const FString& Options)
{
    auto DelegateManager = GetKMDelegateManager()->GameMode;
    if (DelegateManager->OnApproveLogin.IsBound())
    {
        return DelegateManager->OnApproveLogin.Execute(Options);
    }
    return TEXT("");
}

void UGameCommon::PlayerControllerUpdate(class APiratesPlayerController* PC)
{

}

float UGameCommon::GetConnectionTimeout()
{
    UWorld*  World = GetWorld();
    if (World == nullptr)
    {
        UE_LOG(GameCommonLog, Error, TEXT("Get NetDriver ConnectTimeout failed: no World"));
        return 0;
    }

    UNetDriver* NetDriver = World->GetNetDriver();
    if (NetDriver != nullptr)
    {   
        return NetDriver->ConnectionTimeout;
    }
    else
    {
        UE_LOG(GameCommonLog, Error, TEXT("Get NetDriver ConnectTimeout failed: no NetDriver"));
        return 0;
    }
}


UAudioComponent* UGameCommon::PlaySoundInClient(USoundBase* Sound, uint8 SoundType, const FVector& Location, AActor* SoundSource)
{
    UWorld*  World = GetWorld();
    if (World == nullptr)
        return nullptr;

    return UExtendBlueprintFunctions::PlaySoundInClient(World, Sound, SoundType, Location, SoundSource);
}

UAICoverPointsManager* UGameCommon::GetAICoverPointsManager() const
{
    return AICoverPointsManager;
}

#if !ENABLE_U4LUA
static bool UseU4Lua = true;
#endif

void UGameCommon::SetUseU4LuaEnabled(bool Enabled)
{    
#if ENABLE_U4LUA
    UE_LOG(GameCommonLog, Error, TEXT("U4Lua can not be disabled."));
#else
    UseU4Lua = Enabled;
#endif
}

bool UGameCommon::IsU4LuaEnabled()
{
#if ENABLE_U4LUA
    return true;
#else
    return UseU4Lua;
#endif    
}

bool UGameCommon::IsGMEnabled() const
{
    return EnableGM;
}

bool UGameCommon::IsPreloadMap() const
{
    return PreloadMap;
}

void UGameCommon::OnLowMemoryWarning()
{
#if ENABLE_U4LUA
    if (LuaRoot)
    {
        LuaRoot->CollectGarbage();
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->CollectGarbage();
    }
#endif
}

void UGameCommon::SetRemoteLuaRepository(const FString& URL)
{
    s_RemoteLuaRepository = URL;
}

void UGameCommon::RecordSpawnActorFrameCounter()
{
    LastSpawnActorFrame = GFrameCounter;
}

uint64 UGameCommon::GetLastSpawnActorFrameCounter()
{
    return LastSpawnActorFrame;
}

#if WITH_EDITOR
bool UGameCommon::DoLuaStringInEditor(const TArray<FString>& Paths, const FString& Script, FString& OutReturn, FString& OutError)
{
#if ENABLE_U4LUA
    auto TempLuaRoot = NewObject<UGameLuaRoot>(GetTransientPackage());
    TempLuaRoot->Init();
    TempLuaRoot->SetIsDedicatedServer(true);
    TempLuaRoot->GetLib()->SetSearchPath(Paths);
    bool Ret = TempLuaRoot->GetLib()->DoString(Script, OutReturn, OutError);
    TempLuaRoot->Uninit();
    TempLuaRoot->MarkPendingKill();
    return Ret;

#else
    auto TempLuaManager = NewObject<UGameLuaManager>(GetTransientPackage());
    TempLuaManager->Init(FPaths::ProjectContentDir());
    TempLuaManager->OnWorldChanged(GWorld);
    for (int ii=0; ii<Paths.Num(); ii++)
    {
        TempLuaManager->AddSearchPath(Paths[ii]);
    }
    
    bool Ret = TempLuaManager->DoString(Script, OutReturn, OutError);
    TempLuaManager->Uninit();
    TempLuaManager->MarkPendingKill();
    return Ret;
#endif
}
#endif