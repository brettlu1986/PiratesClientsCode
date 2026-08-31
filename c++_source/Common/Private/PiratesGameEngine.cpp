// Fill out your copyright notice in the Description page of Project Settings.

#include "PiratesGameEngine.h"
#include "Common.h"
#include "PiratesLocalPlayer.h"
#include "KMLevelScriptActor.h"
#include "GameEngineExt.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Game/Delegates/LevelDelegate.h"
#include "Engine.h"
#include "Game/GameCommon.h"
#include "Game/Lua/GameLuaManager.h"
#include "GameFramework/GameNetworkManager.h"

DEFINE_LOG_CATEGORY_STATIC(PiratesGameEngineLog, Log, All)

UPiratesGameEngine::UPiratesGameEngine(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
    , LowMemoryWarning(false)
{

}

void UPiratesGameEngine::BroadcastOnWorldRestart(UWorld *World)
{
    auto CurrentGameInstance = World->GetGameInstance();
    UE_LOG(PiratesGameEngineLog, Log, TEXT("OnWorldRestart[%s]:%s UniqueId:%u"), CurrentGameInstance->IsDedicatedServerInstance() ? TEXT("Server") : TEXT("Client"), *World->GetName(), World->GetUniqueID());
    auto LevelActor = Cast<AKMLevelScriptActor>(World->PersistentLevel->GetLevelScriptActor());
    uint32 LevelActorUniqueId = INDEX_NONE;
    FString ScriptType = TEXT("");
    if (IsValid(LevelActor))
    {
        LevelActorUniqueId = LevelActor->GetUniqueID();
        ScriptType = LevelActor->GetScriptType();
    }
    UGameEngineExt::Get(World)->GetKMDelegateManager()->Level->OnWorldRestart.Broadcast(World, World->GetUniqueID(), LevelActor, LevelActorUniqueId, ScriptType);
}

bool UPiratesGameEngine::LoadMap(FWorldContext& WorldContext, FURL URL, class UPendingNetGame* Pending, FString& Error)
{
    Error = TEXT("");

    bool bSameMapContext = false;
    bool bIsSeamlessTravel = false;
    FString CurWorldMap = UWorld::StripPIEPrefixFromPackageName(WorldContext.World()->URL.Map, WorldContext.World()->StreamingLevelsPrefix);
    FString PendingWorldMap = UWorld::StripPIEPrefixFromPackageName(URL.Map, WorldContext.PIEPrefix);

    if (CurWorldMap == PendingWorldMap)
        bSameMapContext = true;

    UPiratesLocalPlayer* LocalPlayer = Cast<UPiratesLocalPlayer>(WorldContext.World()->GetGameInstance()->GetFirstGamePlayer());

    if (LocalPlayer != nullptr)
    {
        bIsSeamlessTravel = LocalPlayer->InSmoothTravel();
    }

    if (!bSameMapContext || !bIsSeamlessTravel)
    {
        if (LocalPlayer
            && LocalPlayer->PlayerController
            && LocalPlayer->PlayerController->GetPawn())
        {
            WorldContext.World()->DestroyActor(LocalPlayer->PlayerController->GetPawn(), true);
        }
        return Super::LoadMap(WorldContext, URL, Pending, Error);
    }

    // play a load map movie if specified in ini
    bStartedLoadMapMovie = false;

    // Unload the current world
    auto OldWorld = WorldContext.World();
    if (OldWorld)
    {
        for (TActorIterator<AKMLevelScriptActor> ActorIt(WorldContext.World()); ActorIt; ++ActorIt)
        {
            AActor* LevelScriptActor = *ActorIt;
            if (LevelScriptActor != nullptr)
            {
                //Need changed the Authority for UScriptActorComponent::OnActorChannelOpen
                LevelScriptActor->SetRole(ROLE_SimulatedProxy);
            }
        }

        // Clean up networking
        ShutdownWorldNetDriver(OldWorld);
        auto OldGameMode = OldWorld->GetAuthGameMode();
        if (IsValid(OldGameMode))
        {
            OldGameMode->Destroy(true);
        }
        auto OldGameState = OldWorld->GetGameState();
        if (IsValid(OldGameState))
        {
            OldGameState->Destroy(true);
        }
        OldWorld->CopyGameState(nullptr, nullptr);
        auto OldNetworkManager = Cast<AActor>(OldWorld->NetworkManager);
        if (IsValid(OldNetworkManager))
        {
            OldNetworkManager->Destroy(true);
        }
        OldWorld->NetworkManager = nullptr;
    }

    // If you need destroy PlayerControllers, you can do here.

    // If you need to reset some World's status, you can do here.

    // Handle pending level.
    if (Pending)
    {
        check(Pending == WorldContext.PendingNetGame);
        MovePendingLevel(WorldContext);
    }
    else
    {
        check(!WorldContext.World()->GetNetDriver());
    }

    WorldContext.World()->SetGameMode(URL);

    // Listen for clients.
    if (Pending == NULL && (!GIsClient || URL.HasOption(TEXT("Listen"))))
    {
        if (!WorldContext.World()->Listen(URL))
        {
            UE_LOG(LogNet, Error, TEXT("LoadMap: failed to Listen(%s)"), *URL.ToString());
        }
    }

    // Remember the URL. Put this before spawning player controllers so that
    // a player controller can get the map name during initialization and
    // have it be correct
    WorldContext.LastURL = URL;

    if (WorldContext.World()->GetNetMode() == NM_Client)
    {
        WorldContext.LastRemoteURL = URL;
    }

    BroadcastOnWorldRestart(WorldContext.World());

    // Successfully started local level.
    return true;
}

extern ENGINE_API double GLastMemoryWarningTime;
static void PirateEngineMemoryWarningHandler(const FGenericMemoryWarningContext& GenericContext)
{
    FPlatformMemoryStats Stats = FPlatformMemory::GetStats();

    FPlatformMisc::LowLevelOutputDebugStringf(TEXT("PirateEngineMemoryWarningHandler: Mem Used %.2f MB, Texture Memory %.2f MB, Render Target memory %.2f MB, OS Free %.2f MB\n"),
        Stats.UsedPhysical / 1048576.0f,
        GCurrentTextureMemorySize / 1024.f,
        GCurrentRendertargetMemorySize / 1024.f,
        Stats.AvailablePhysical / 1048576.0f);

#if !UE_BUILD_SHIPPING && !UE_BUILD_TEST
    static const auto OOMMemReportVar = IConsoleManager::Get().FindTConsoleVariableDataInt(TEXT("Debug.OOMMemReport"));
    const int32 OOMMemReport = OOMMemReportVar ? OOMMemReportVar->GetValueOnAnyThread() : false;
    if (OOMMemReport)
    {
        GEngine->Exec(NULL, TEXT("OBJ LIST"));
        GEngine->Exec(NULL, TEXT("MEM FROMREPORT"));
    }
#endif

    GLastMemoryWarningTime = FPlatformTime::Seconds();

    UPiratesGameEngine* GameEngine = Cast<UPiratesGameEngine>(GEngine);
    if (GameEngine)
    {
        GameEngine->LowMemoryWarning = true;
    }
}

void UPiratesGameEngine::Init(IEngineLoop* InEngineLoop)
{
    Super::Init(InEngineLoop);

    UKismetSystemLibrary::ControlScreensaver(false);
    FPlatformMisc::SetMemoryWarningHandler(PirateEngineMemoryWarningHandler);
}

void UPiratesGameEngine::Start()
{
	Super::Start();

//	//used for
//	UE_LOG(PiratesGameEngineLog, Log, TEXT("*******UGameEngineExt:: try to start precompile shader cache  Pirates_1"));
//	//yangjingzhao
//	//for precompile shader cache in first run.
//	FString AppVersion;
//#if PLATFORM_ANDROID
//	GConfig->GetString(TEXT("/Script/AndroidRuntimeSettings.AndroidRuntimeSettings"), TEXT("VersionDisplayName"), AppVersion, GEngineIni);
//#elif PLATFORM_IOS
//	GConfig->GetString(TEXT("/Script/IOSRuntimeSettings.IOSRuntimeSettings"), TEXT("VersionInfo"), AppVersion, GEngineIni);
//#else
//	AppVersion = FString(TEXT("1.0"));
//#endif
//	FString SavedGameVerPath = FString(FPaths::Combine(*FPaths::ProjectSavedDir(), TEXT("/GameVersion.ini")));
//	FString ProjSavedVersion;
//	bool bMatchedVersion = false;
//	if (IFileManager::Get().FileExists(*SavedGameVerPath))
//	{
//		FFileHelper::LoadFileToString(ProjSavedVersion, *SavedGameVerPath);
//		if (AppVersion.Equals(ProjSavedVersion))
//		{
//			bMatchedVersion = true;
//		}
//	}
//
//	if (!bMatchedVersion)
//	{
//		UE_LOG(PiratesGameEngineLog, Log, TEXT("*******UGameEngineExt::start precompile shader cache and save game version"));
//
//		ProjSavedVersion = AppVersion;
//		FFileHelper::SaveStringToFile(ProjSavedVersion, *SavedGameVerPath);
//
//		// Now our shader code main library is opened, kick off the precompile.
//		FString PipelineCachename = FString(TEXT("Pirates_1"));
//		FShaderPipelineCache::OpenPipelineFileCache(PipelineCachename, GMaxRHIShaderPlatform);
//	}
	//--<end

}

void UPiratesGameEngine::Tick(float DeltaSeconds, bool bIdleMode)
{
    Super::Tick(DeltaSeconds, bIdleMode);

    if (LowMemoryWarning)
    {
        LowMemoryWarning = false;
        auto GameCommon = UGameCommon::Get(this);
        if (GameCommon)
        {
            GameCommon->OnLowMemoryWarning();
        }
        ForceGarbageCollection(true);
    }
}

void UPiratesGameEngine::CleanUp()
{
    FlushAsyncLoading();

    CleanupGameViewport();

    // Clean up each world individually
    TArray<UWorld*> WorldsBeingCleanedUp;

    for (int32 WorldIdx = WorldList.Num() - 1; WorldIdx >= 0; --WorldIdx)
    {
        FWorldContext &ThisContext = WorldList[WorldIdx];

        //
        {
            if (ThisContext.World())
            {
                WorldsBeingCleanedUp.Add(ThisContext.World());
            }

            //CleanUp World
            CleanUpWorldContext(ThisContext);

            // Remove world list after online has shutdown in case any async actions require the world context
            WorldList.RemoveAt(WorldIdx);
        }
    }

    // mark everything contained in the PIE worlds to be deleted
    for (UWorld* World : WorldsBeingCleanedUp)
    {
        // Occasionally during seamless travel the Levels array won't yet be populated so mark this world first
        // then pick up the sub-levels via the level iterator
        World->MarkObjectsPendingKill();

        // Because of the seamless travel the world might still be in the root set too, so also clear that 无缝切换时生成的World始终在列表中，需要移除
        World->RemoveFromRoot();

        for (auto LevelIt(World->GetLevelIterator()); LevelIt; ++LevelIt)
        {
            if (const ULevel* Level = *LevelIt)
            {
                // We already picked up the persistent level with the top level mark objects
                if (Level->GetOuter() != World)
                {
                    CastChecked<UWorld>(Level->GetOuter())->MarkObjectsPendingKill();
                }
            }
        }
    }

    for (TObjectIterator<UGameInstance> It; It; ++It)
    {
        auto MarkObjectPendingKill = [](UObject* Object)
        {
            Object->MarkPendingKill();
        };
        ForEachObjectWithOuter(*It, MarkObjectPendingKill, true, RF_NoFlags, EInternalObjectFlags::PendingKill);
    }

    CollectGarbage(GARBAGE_COLLECTION_KEEPFLAGS);
}

void UPiratesGameEngine::CleanUpWorldContext(FWorldContext &WorldContext)
{
    UWorld* PlayWorld = WorldContext.World();

    GWorld = PlayWorld;

    // Clean up all streaming levels
    PlayWorld->bIsLevelStreamingFrozen = false;
    PlayWorld->SetShouldForceUnloadStreamingLevels(true);
    PlayWorld->FlushLevelStreaming();

    // Go through and let all the PlayWorld Actor's know they are being destroyed
    for (FActorIterator ActorIt(PlayWorld); ActorIt; ++ActorIt)
    {
        ActorIt->RouteEndPlay(EEndPlayReason::RemovedFromWorld);
    }

    WorldContext.OwningGameInstance->Shutdown();

    // Clean up the temporary play level.
    PlayWorld->CleanupWorld();

    // Remove from root (Seamless travel may have done this)
    PlayWorld->RemoveFromRoot();

    PlayWorld = NULL;

    GWorld = nullptr;
}
