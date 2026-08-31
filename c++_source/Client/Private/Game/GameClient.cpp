// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/GameClient.h"
#include "Client.h"
#include "Shell/ClientShell.h"
#include "Shell/GameDungeonShell.h"
#include "Game/Input/InputManager.h"
#include "PiratesLocalPlayer.h"
#include "Network/SocketNetworkManager.h"
#include "PiratesPlayerController.h"
#include "Game/SaveGame/SaveGameManager.h"
#include "OceanNavGridManager.h"
#include "KMGameInstance.h"
#include "Loading/KMLevelLoadingVolume.h"
#include "Game/PersistentTimer/PersistentTimer.h"

#include "Hydra.h"
#include "Game/ChannelSdk/ChannelSdkManager.h"
#include "Game/GVoiceSdk/GVoiceSdkManager.h"
#include "Game/DataSdk/DataSdkManager.h"
#include "Game/Delegates/ClientDelegateManager.h"
#include "Game/SensitiveWords/SensitiveWordManager.h"
#include "Util/LogReport.h"
#include "Network/GameIpConnection.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"

// performance optimization, setting static mesh lod model
// memory optimization, render target pool
#include "RenderExtendBlueprintFunctions.h"
#include "ExtendBlueprintFunctions.h"

//#include "MoviePlayer.h"

#include "Game/EngineExtSetting.h"
#include "Game/Delegates/LevelDelegate.h"

#include "Loading/KMMaterialPrecompiling.h"
#include "RenderSettingsManager.h"
#include "Game/SystemInfo/SystemInfoManager.h"
#include "StartupPackageConfig.h"

#if ENABLE_U4LUA
#include "Game/Lua/GameLuaRoot.h"
#else
#include "GameLuaManager.h"
#endif

#include "GPerfReporters/GPerfReporterManager.h"

//for world composition
//#include "WorldCompositionData.h"

DEFINE_LOG_CATEGORY_STATIC(GameClientLog, Log, All)

UGameClient::UGameClient(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , NetworkManager(nullptr)
    , HydraClient(nullptr)
    , SaveGameManager(nullptr)
    , PersistentTimer(nullptr)
    , ChannelSdkManager(nullptr)
    , GVoiceSdkManager(nullptr)
    , DataSdkManager(nullptr)
    , SensitiveWordManager(nullptr)
    , RenderSettingsManager(nullptr)
    , SystemInfoManager(nullptr)
    , AllowNetAsyncLoading(true)
    , bIpConnectionTimeout(false)
    , LastTickRealTime(0.f)
    , ClientConnectionTimeout(0.f)
{
    LuaInitScriptName = TEXT("ClientMain");
    LuaStartScriptName = TEXT("ClientStartGame");
    LuaGlobalTableDefineScriptName = TEXT("GlobalTableDefine");
//    LuaPathCacheFile = TEXT("GameDataGenerated/client/luaSearchPath/luafiles.json");
}

UGameClient* UGameClient::Get(const UObject* WorldContextObject)
{
    return Cast<UGameClient>(GetGame(WorldContextObject));
}

void UGameClient::Init()
{
    GEngine->Exec(GetWorld(), *FString::Printf(TEXT("net.AllowAsyncLoading %d"), AllowNetAsyncLoading ? 1 : 0), *GLog);

    TabFileManager.Init();
    SaveGameManager = NewUObjectAndInit<USaveGameManager>();

    Super::Init();

#ifdef WITH_GPERF
    GPerfReporterManager = NewUObjectAndInit<UGPerfReporterManager>(this);    
#endif

    NetworkManager = NewUObjectAndInit<USocketNetworkManager>();
    NetworkManager->CreateSocket(0, TEXT("Client HubServer Connection"));

    HydraClient = NewObject<UHydraClient>(this);
    PersistentTimer = NewUObjectAndInit<UPersistentTimer>();
    ChannelSdkManager = NewUObjectAndInit<UChannelSdkManager>();    
    SensitiveWordManager = NewObject<USensitiveWordManager>(this);
    SystemInfoManager = NewUObjectAndInit<USystemInfoManager>();

#ifdef WITH_GVOICESDK
    GVoiceSdkManager = NewUObjectAndInit<UGVoiceSdkManager>();    
#endif
    DataSdkManager = NewUObjectAndInit<UDataSdkManager>();
    if (FApp::CanEverRender())
    {
        RenderSettingsManager = NewUObjectAndInit<URenderSettingsManager>();        
    }

	//yangjingzhao for cache game asset cross level
	AssetsCache = NewUObjectAndInit<UGameAssetCache>();	

	// liujun, startup packages will not considered by gc
	UStartupPackageConfig::LoadStartupPackage(this);
}

void UGameClient::Start()
{
    Super::Start();
    StartTick();
}

void UGameClient::Shutdown()
{
#ifdef WITH_GPERF
    SAVE_UNINIT(GPerfReporterManager);
#endif

    Super::Shutdown();

    SAVE_UNINIT(PersistentTimer);
    SAVE_UNINIT(NetworkManager);
    SAVE_UNINIT(SystemInfoManager);    
    TabFileManager.Uninit();
    SAVE_CLEAR(RenderSettingsManager);

    ReferencedObjects.Empty();

	// cleanup for sure
	UStartupPackageConfig::Shutdown();	
	
	//clear refrence for assets
	SAVE_UNINIT(AssetsCache);
	// end
}

void UGameClient::VerifyIpConnectionTimeout(float DeltaTime)
{
    UWorld* World = GetWorld();
    if (World == nullptr)
        return;

    UNetDriver* NetDriver = World->GetNetDriver();
    if (!NetDriver)
    {
        LastTickRealTime = FPlatformTime::Seconds();
        return;
    }

    UIpConnection* IpConnection = (UIpConnection*)(NetDriver->ServerConnection);
    if (!IpConnection)
    {
        LastTickRealTime = FPlatformTime::Seconds();
        return;
    }

    const double CurrentRealTime = FPlatformTime::Seconds();
    const float DeltaRealTime = CurrentRealTime - LastTickRealTime;
    LastTickRealTime = CurrentRealTime;
    
    if (((IpConnection->Driver->GetElapsedTime() - IpConnection->LastReceiveTime) > ClientConnectionTimeout) || (DeltaRealTime > ClientConnectionTimeout))
    {
        if (!bIpConnectionTimeout)
        {
            bIpConnectionTimeout = true;

            GetClientDelegateManager()->GameMisc->OnIpConnectionTimeout.ExecuteIfBound(bIpConnectionTimeout);
        }
    }
    else if (bIpConnectionTimeout)
    {
        bIpConnectionTimeout = false;

        GetClientDelegateManager()->GameMisc->OnIpConnectionTimeout.ExecuteIfBound(bIpConnectionTimeout);
    }

}

void UGameClient::TickImplement(float DeltaTime)
{
    if (GEngine->GameViewport == nullptr)
    {
        return;
    }

    Super::TickImplement(DeltaTime);

    SAVE_TICK(NetworkManager, DeltaTime);
    SAVE_TICK(PersistentTimer, DeltaTime);
    SAVE_UPDATE(RenderSettingsManager, DeltaTime);
    
    VerifyIpConnectionTimeout(DeltaTime);
}

static int EmptyLogEvent(lua_State* L)
{
    return 0;
}

void UGameClient::InitLua()
{
    Super::InitLua();

#if ENABLE_U4LUA
    if (IsU4LuaEnabled())
    {
        LuaRoot = NewObject<UGameLuaRoot>(this);
        LuaRoot->Init();
        LuaRoot->GetLib()->SetSearchPath({
            TEXT("Scripts/Base/"),
            TEXT("Scripts/Common/"),
            TEXT("Scripts/Client/"),
            TEXT("GameDataGenerated/"),
            });
        LuaRoot->GetLib()->RegistGlobalFunction("logevent", &EmptyLogEvent);
    }
#else
    if (GameLuaManager)
    {
        GameLuaManager->SetIsDedicatedServer(false);
        GameLuaManager->AddSearchPath(TEXT("GameDataGenerated/"));
        GameLuaManager->AddSearchPath(TEXT("Scripts/Client/"));

        // See UGameServer::InitLua()
        GameLuaManager->RegistGlobalFunction("logevent", &EmptyLogEvent);
    }
#endif
}

void UGameClient::UninitLua()
{
    Super::UninitLua();
}

bool UGameClient::Exec(const TCHAR* Cmd, FOutputDevice& Ar)
{
    return Super::Exec(Cmd, Ar);
}

void UGameClient::ClientTravel(const FString& URL, bool bIsSmoothTravel)
{
    UWorld* World = GetWorld();
    if (World)
    {
        auto LocalPlayer = Cast<UPiratesLocalPlayer>(World->GetFirstLocalPlayerFromController());
        if (!bIsSmoothTravel)
        {
            UE_LOG(GameClientLog, Log, TEXT("UGameClient::ClientTravel. Start non smooth travel."));
            if (LocalPlayer)
            {
                LocalPlayer->SetSmoothTravel(false);
            }
        }
        else if (LocalPlayer)
        {
            UE_LOG(GameClientLog, Log, TEXT("UGameClient::ClientTravel. Start smooth travel."));
            LocalPlayer->SetSmoothTravel(true);
        }
        else
        {
            UE_LOG(GameClientLog, Warning, TEXT("UGameClient::ClientTravel. Smooth travel failed. Try non smooth travel."));
        }

        auto PlayerController = World->GetFirstPlayerController();
        PlayerController->ClientTravel(URL, ETravelType::TRAVEL_Relative);
    }
    else
    {
        UE_LOG(GameClientLog, Error, TEXT("FAILED to travel to %s, cannot find World!"), *URL);
    }
}

void UGameClient::PlayerControllerUpdate(APiratesPlayerController* PC)
{
    if (IsValid(InputManager))
    {
        InputManager->SetPlayerController(PC);
    }
}

bool UGameClient::IsInSmoothTravel()
{
    UWorld* World = GetWorld();
    if (World)
    {
        auto LocalPlayer = Cast<UPiratesLocalPlayer>(World->GetFirstLocalPlayerFromController());
        if (LocalPlayer)
        {
            return LocalPlayer->InSmoothTravel();
        }
    }
    return false;
}

UHydraClient* UGameClient::GetHydraClient()
{
    return HydraClient;
}

void UGameClient::OpenLevelAsync(const FString& URL)
{
    FString Error;
    UGameplayStatics::OpenLevel(this, UKMGameInstance::EmptyMapURL);
    PendingURL = URL;
    HoldingWorld = nullptr;
    OnPostLoadMapHandle = FCoreUObjectDelegates::PostLoadMapWithWorld.AddUObject(this, &UGameClient::OnPostLoadMap);

    double TimeSecomdes = FPlatformTime::Seconds();
    UE_LOG(GameClientLog, Log, TEXT("******* ****** OpenLevelAsync Open Empty Map time: %s"), *FString::SanitizeFloat(TimeSecomdes));

    Cast<UKMGameInstance>(GetWorld()->GetGameInstance())->IsAsyncLoadingMap = true;
}

void UGameClient::OnPostLoadMap(UWorld* CurrentWorld)
{
    UWorld* TempWorld = GetWorld();
    if (TempWorld != CurrentWorld)
    {
        return;
    }

    if (CurrentWorld->GetMapName().EndsWith(UKMGameInstance::EmptyMapNameSuffix))
    {
        CurrentWorld->GetTimerManager().SetTimerForNextTick([this] {
            auto WorldPackage = FindPackage(nullptr, *PendingURL);
            auto URLName = FName(*PendingURL);
            if (!WorldPackage || !WorldPackage->HasAnyPackageFlags(PKG_ContainsMap))
            {
                auto Context = GEngine->GetWorldContextFromWorld(GetWorld());
                UWorld::WorldTypePreLoadMap.FindOrAdd(URLName) = Context->WorldType;
                LoadPackageAsync(PendingURL,
                    FLoadPackageAsyncDelegate::CreateUObject(this, &UGameClient::LoadPackageAsyncCallback),
                    0,
                    (GetWorld()->WorldType == EWorldType::PIE ? PKG_PlayInEditor : PKG_None),
                    Context->PIEInstance
                );

                double TimeSecomdes = FPlatformTime::Seconds();

                UE_LOG(GameClientLog, Log, TEXT("******* ****** Load Package Aync When Loading Empty Map Finished! time: %s"), *FString::SanitizeFloat(TimeSecomdes));
            }
            else
            {
                auto World = UWorld::FindWorldInPackage(WorldPackage);
                if (!World)
                {
                    World = UWorld::FollowWorldRedirectorInPackage(WorldPackage);
                }
                HoldingWorld = World;
                if (World)
                {
                    // 此句可能导致点击SubLevel时崩溃，先注释掉
                    // World->WorldType = EWorldType::Inactive;
                    UGameplayStatics::OpenLevel(this, URLName, false);
                }
                else
                {
                    UE_LOG(GameClientLog, Error, TEXT("Cannot find World in a valid WorldPackage that with PKG_ContainMap flag. PackageName:%s, PackageFlag:%d"), *WorldPackage->GetName(), WorldPackage->GetPackageFlags());
                }
            }
        });
    }
    else
    {
        double TimeSecomdes1 = FPlatformTime::Seconds();
        UE_LOG(GameClientLog, Log, TEXT("******* ****** Finally open level success! time: %s"), *FString::SanitizeFloat(TimeSecomdes1));

        auto Context = GEngine->GetWorldContextFromWorld(CurrentWorld);
        if (Context->WorldType == EWorldType::PIE)
        {
            // 异步加载的World的WorldComposition的Tiles为空，需要Rescan
            //modified by yangjingzhao:这部分问题较多；PIE切换到非当前Editor中的关卡时才会出现LevelStreaming为空的问题
            //目前PIE中LoadMap的时候会走CreatePIEWorldByDuplication，会自动重新把复制的world中的levelstreaming序列化
            //此处不需要做重新初始化levelstreaming的操作
            //为避免错误，发现为0的时候强制初始化一次
            if (CurrentWorld->GetStreamingLevels().Num() == 0)
            {
                CurrentWorld->RenameToPIEWorld(Context->PIEInstance);
            }
        }
        //else
        //{
        //	//yangjingzhao add在此处理加载levelstreaming完成的notify，美术的主levelstreaming加载完成后上层再开始做逻辑
        //	for (int32 LevelIndex = 0; LevelIndex < CurrentWorld->StreamingLevels.Num(); LevelIndex++)
        //	{
        //		FString LevelName = CurrentWorld->StreamingLevels[LevelIndex]->GetWorldAssetPackageName();
        //		if (LevelName.Contains(FString(TEXT("Map_"))) && !LevelName.Contains(FString(TEXT("_HD"))))
        //		{
        //			OnLevelStreamingLoaded.BindUFunction(this, FName(TEXT("OnLevelStreamingPostLoaded")));
        //			CurrentWorld->StreamingLevels[LevelIndex]->OnLevelLoaded.Add(OnLevelStreamingLoaded);
        //		}

        //	}

        //}


        HoldingWorld = nullptr;
        FCoreUObjectDelegates::PostLoadMapWithWorld.Remove(OnPostLoadMapHandle);

        // for simple shadow utility
        //SetupSimpleShadow(); // move to script by zuokun
        //~end

        // memory report
        // liujun: show the memory stats when a level loading is complete.
        //GEngine->Exec(NULL, TEXT(/*"SHOWMEMSTATS"*/"NO"));
        // ~

        // memory optimization, render target pool
        // liujun
        //URenderExtendBlueprintFunctions::ReleaseUnusedRenderTargetPool();
        // ~
    }
}

void UGameClient::LoadPackageAsyncCallback(const FName& PackageName, UPackage* LevelPackage, EAsyncLoadingResult::Type Result)
{

    double TimeSecomdes = FPlatformTime::Seconds();
    UE_LOG(GameClientLog, Log, TEXT("******* ****** Load Map Aync Finshed, Try to Open this Level! time : %s"), *FString::SanitizeFloat(TimeSecomdes));

    UWorld* World = nullptr;
    if (LevelPackage)
    {
        World = UWorld::FindWorldInPackage(LevelPackage);
        if (!World)
        {
            World = UWorld::FollowWorldRedirectorInPackage(LevelPackage);
        }
        HoldingWorld = World;
    }
    if (World)
    {
        World->WorldType = EWorldType::Inactive;
    }
    else
    {
        UE_LOG(GameClientLog, Error, TEXT("FAILED to LoadPackageAsync, PackageName:%s, LevelPackage:%p, Result:%d"), *PackageName.ToString(), LevelPackage, (int32)Result);
    }
    UWorld::WorldTypePreLoadMap.Remove(PackageName);

    //FLoadingScreenAttributes LoadingScreen;
    //LoadingScreen.bAutoCompleteWhenLoadingCompletes = true;
    //LoadingScreen.WidgetLoadingScreen = FLoadingScreenAttributes::NewTestLoadingScreenWidget();

    //GetMoviePlayer()->SetupLoadingScreen(LoadingScreen);


    UGameplayStatics::OpenLevel(this, PackageName, false);
}

void UGameClient::OnLevelStreamingPostLoaded()
{
    if (Cast<UKMGameInstance>(GetWorld()->GetGameInstance())->IsAsyncLoadingMap)
    {
        Cast<UKMGameInstance>(GetWorld()->GetGameInstance())->IsAsyncLoadingMap = false;
    }

    OnLevelStreamingLoaded.Unbind();

    UGameEngineExt::Get(this)->GetKMDelegateManager()->Level->OnPostLoadMap.Broadcast();
}

void UGameClient::InitiallyLoadLevelStreaming()
{

    UWorld* World = GetWorld();
    if (!World)
    {
        return;
    }

    TArray<AActor*> Actors;
    //PIE的时候存在子关卡已经load成功；但actor的owningworld并未标记成当前persistent关卡的情况；这种情况下 无法取到actor
    //UGameplayStatics::GetAllActorsOfClass(World, AKMLevelLoadingVolume::StaticClass(), Actors);

    //故换成这种方式去取actor
    TArray<ULevel*> Levels = World->GetLevels();
    for (int32 LevelIndex = 0; LevelIndex < Levels.Num(); ++LevelIndex)
    {
        TArray<AActor*> TempActors = Levels[LevelIndex]->Actors;

        for (int32 ActorIndex = 0; ActorIndex < TempActors.Num(); ++ActorIndex)
        {
            if (TempActors[ActorIndex] && TempActors[ActorIndex]->IsA(AKMLevelLoadingVolume::StaticClass()))
            {
                Cast<AKMLevelLoadingVolume>(TempActors[ActorIndex])->InitialyLoadLevelStreaming();
            }
        }
    }


    //for (int32 Index = 0; Index < Actors.Num(); ++ Index)
    //{
    //	if (Actors[Index] && Actors[Index]->IsA(AKMLevelLoadingVolume::StaticClass()))
    //	{
    //		Cast<AKMLevelLoadingVolume>(Actors[Index])->InitialyLoadLevelStreaming();
    //           // for setting static mesh lod model
    //           Cast<AKMLevelLoadingVolume>(Actors[Index])->
    //               SetStaticMeshLODModel.BindUObject(this, &UGameClient::SetStaticMeshLODBias);
    //           //~end
    //	}
    //}

}

void UGameClient::ToggleSceneRendering(bool InFlag)
{
	//yangjingzhao
	//modified from Exec(GWorld, TEXT("ShowFlag.Rendering 1")); this can't run on shipping
	if (GEngine && GEngine->GameViewport)
	{
		int32 FlagIndex = FEngineShowFlags::FindIndexByName(TEXT("Rendering"));

		if (FlagIndex != -1)
		{
			GEngine->GameViewport->EngineShowFlags.SetSingleFlag(FlagIndex, InFlag);
		}
	}
}

UTexture2D* UGameClient::CreateTexture2DByBitmapData(int32 Width, int32 Height, TArray<FColor>& BitmapData)
{
    // Create the texture
    UTexture2D* ReturnTexture = UTexture2D::CreateTransient(Width, Height, PF_B8G8R8A8);

    // Lock the checkerboard texture so it can be modified
    //FColor* MipData = static_cast<FColor*>(ReturnTexture->PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE));
	FTexture2DMipMap& Mip = ReturnTexture->PlatformData->Mips[0];
	void* MipData = Mip.BulkData.Lock(LOCK_READ_WRITE);

	check(BitmapData.Num() * sizeof(FColor) == Mip.BulkData.GetBulkDataSize());
	FMemory::Memcpy(MipData, BitmapData.GetData(), Mip.BulkData.GetBulkDataSize());
	Mip.BulkData.Unlock();
    ReturnTexture->UpdateResource();

    return ReturnTexture;
}

UClientDelegateManager* UGameClient::GetClientDelegateManager() const
{
    return Cast<UClientDelegateManager>(GetKMDelegateManager());
}

UClass* UGameClient::GetKMDelegateManagerClass()
{
    return UClientDelegateManager::StaticClass();
}

void UGameClient::SerializeMatShaderAfterUpdate()
{
    UKMMaterialPrecompiling* Precompiling = NewObject<UKMMaterialPrecompiling>(GetTransientPackage(), UKMMaterialPrecompiling::StaticClass());

    if (!Precompiling)
    {
        return;
    }

    Precompiling->GatherMaterialsToSerialize();
}

void UGameClient::SetPlayerPawn(AActor* Player)
{
    PlayerActor = TWeakObjectPtr<AActor>(Player);
}

TWeakObjectPtr<AActor> UGameClient::GetPlayerPawn()
{
    return PlayerActor;
}

void UGameClient::AddReferencedObject(UObject* Object)
{
    if (Object)
    {
        ReferencedObjects.AddUnique(Object);
    }
}

void UGameClient::RemoveReferencedObject(UObject* Object)
{
    if (Object)
    {
        ReferencedObjects.Remove(Object);
    }
}

UGameAssetCache* UGameClient::GetAssetCache()
{
	return AssetsCache;
}

void UGameClient::SetClientConnectionTimeout(float Value)
{
    ClientConnectionTimeout = Value;
}

float UGameClient::GetClientConnectionTimeout()
{
    return ClientConnectionTimeout;
}

void UGameClient::DumpReferencedObject()
{
#if !UE_BUILD_SHIPPING

    UE_LOG(GameClientLog, Error, TEXT("refrenced objects by client-----------------------"));

    for (const UObject* Object: ReferencedObjects)
    {
        UE_LOG(GameClientLog, Error, TEXT("path %s"), *GetFullNameSafe(Object));
    }

#endif
}
