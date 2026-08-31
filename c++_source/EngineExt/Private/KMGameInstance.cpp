// Fill out your copyright notice in the Description page of Project Settings.

#include "KMGameInstance.h"
#include "EngineExt.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Shell/EngineExtActorShell.h"
#include "Game/Delegates/LevelDelegate.h"
#include "KMLevelScriptActor.h"
#include "GameModule.h"
#include "Game/GameEngineExt.h"
#include "Engine/WorldComposition.h"
#include "Game/EngineExtSetting.h"
#include "VisualLogger/VisualLogger.h"
#include "Game/Delegates/KMDelegateManager.h"

#if WITH_EDITOR
    #include "UnrealEd.h"
#endif

DEFINE_LOG_CATEGORY_CLASS(UKMGameInstance, KMGameInstanceLog);

const FString UKMGameInstance::EmptyMapNameSuffix = TEXT("EmptyMap");
const FName UKMGameInstance::EmptyMapURL = FName(TEXT("/Game/Maps/EmptyMap"));

struct UKMGameInstance::FImplement
{
    UKMGameInstance *Owner;
    bool bIsRunning; // 是否正在运行中，默认false，Init后设为true，Shutdown后设为false
    //bool bForceDelayStartScriptLogic;

    IGameModule* GameModule;
    FDelegateHandle OnWorldCleanupHandle;
    FDelegateHandle LevelAddedToWorldHandle;
    FDelegateHandle LevelRemovedFromWorldHandle;
	FDelegateHandle NetworkFailureHandle;

    //FDelegateHandle OnPreLoadMapHandle;
    FDelegateHandle OnPostLoadMapHandle;

    FImplement(UKMGameInstance *Parent) 
        : Owner(Parent)
        , bIsRunning(false)
        , GameModule(nullptr)
        //, bForceDelayStartScriptLogic(false)
    {
    }

    void InitGameModule()
    {
        bool IsDedicatedServer = Owner->IsDedicatedServerInstance();
        if (IsDedicatedServer)
        {
            GameModule = FModuleManager::LoadModulePtr<IGameModule>(TEXT("Server"));
        }
        else
        {
            GameModule = FModuleManager::LoadModulePtr<IGameModule>(TEXT("Client"));
        }
        check(GameModule);
        UE_LOG(KMGameInstanceLog, Log, TEXT("GameModule OnGameInstanceInit start"));
        GameModule->OnGameInstanceInit(Owner);        
        UE_LOG(KMGameInstanceLog, Log, TEXT("GameModule OnGameInstanceInit end"));
    }

    void StartGameModule()
    {
        check(GameModule);
        UE_LOG(KMGameInstanceLog, Log, TEXT("GameModule OnGameInstanceStart start"));
        GameModule->OnGameInstanceStart(Owner);
        UE_LOG(KMGameInstanceLog, Log, TEXT("GameModule OnGameInstanceStart end"));
    }

    void ShutdownGameModule()
    {
        check(GameModule);
        GameModule->OnGameInstanceShutdown(Owner);
    }

    void PostShutdownGameModule()
    {
        if (GameModule != nullptr)
        {
            GameModule->OnGameInstancePostShutdown(Owner);
            GameModule = nullptr;
        }
    }

	void Init()
	{
        InitGameModule();
        RegisterWorldEvent();
		RegisterNetWorkEvent();
        bIsRunning = true;
	}

    void Start()
    {
        StartGameModule();
    }

	void RegisterNetWorkEvent()
	{
		UnregisterNetWorkEvent();
		NetworkFailureHandle = GEngine->OnNetworkFailure().AddRaw(this, &UKMGameInstance::FImplement::ProcessNetworkFailure);
	}

	void UnregisterNetWorkEvent()
	{
		GEngine->OnNetworkFailure().Remove(NetworkFailureHandle);
	}

	void ProcessNetworkFailure(UWorld* InWorld, UNetDriver* InNetDriver, ENetworkFailure::Type FailureType, const FString& ErrorString)
	{
		Owner->OnNetworkFailureWithString.ExecuteIfBound(FailureType, ErrorString);
		Owner->HandleNetworkErrorWithString(FailureType, ErrorString);
	}

    void RegisterWorldEvent()
    {
        UnregisterWorldEvent();
        // prevent to show default loading slate at bottom right corner.
        GEngine->BeginStreamingPauseDelegate = nullptr;
        GEngine->EndStreamingPauseDelegate = nullptr;
        OnWorldCleanupHandle = FWorldDelegates::OnWorldCleanup.AddRaw(this, &UKMGameInstance::FImplement::ProcessOnWorldCleanup);
        LevelAddedToWorldHandle = FWorldDelegates::LevelAddedToWorld.AddRaw(this, &UKMGameInstance::FImplement::ProcessLevelAddedToWorld);
        LevelRemovedFromWorldHandle = FWorldDelegates::LevelRemovedFromWorld.AddRaw(this, &UKMGameInstance::FImplement::OnLevelRemovedFromWorld);
        //OnPreLoadMapHandle = FCoreUObjectDelegates::PreLoadMap.AddRaw(this, &UKMGameInstance::FImplement::ProcessOnPreLoadMap);   // 这个开出去有风险， 编辑器模式下判不出来是哪个world
        OnPostLoadMapHandle = FCoreUObjectDelegates::PostLoadMapWithWorld.AddRaw(this, &UKMGameInstance::FImplement::ProcessOnPostLoadMap);
    }

    void UnregisterWorldEvent()
    {
        FWorldDelegates::OnWorldCleanup.Remove(OnWorldCleanupHandle);
        FWorldDelegates::LevelAddedToWorld.Remove(LevelAddedToWorldHandle);
        FWorldDelegates::LevelRemovedFromWorld.Remove(LevelRemovedFromWorldHandle);
        //FCoreUObjectDelegates::PreLoadMap.Remove(OnPreLoadMapHandle);
        FCoreUObjectDelegates::PostLoadMapWithWorld.Remove(OnPostLoadMapHandle);

        OnWorldCleanupHandle.Reset();
        LevelAddedToWorldHandle.Reset();
        LevelRemovedFromWorldHandle.Reset();
        //OnPreLoadMapHandle.Reset();
        OnPostLoadMapHandle.Reset();
    }

	void Shutdown()
	{
        if (bIsRunning)
        {
			UnregisterNetWorkEvent();
            UnregisterWorldEvent();
            ShutdownGameModule();
            bIsRunning = false;
        }
	}

    void EnsureShutdown()
    {
        Shutdown();
    }

    void OnWorldChanged(UWorld* OldWorld, UWorld* CurrentWorld)
    {
        auto CurrentWorldContext = Owner->GetWorldContext();
        check(CurrentWorldContext != nullptr);
        auto CurrentGame = UGameEngineExt::Get(Owner);

        // 由于事件是注册到static delegate上，因此需要使用GameInstance实际拥有的World，避免被编辑器干扰
        if (CurrentWorldContext->World() == CurrentWorld && CurrentGame) // 如果不相等，表面此次回调与本GameInstance无关
        {
            if (CurrentWorld != nullptr && CurrentWorldContext->WorldType == EWorldType::PIE)
            {
                UPackage* WorldPackage = CurrentWorld->GetOutermost();
                auto PIEInstance = CurrentWorldContext->PIEInstance;
                if (WorldPackage->PIEInstanceID != PIEInstance ||
                    CurrentWorld->StreamingLevelsPrefix.IsEmpty())
                {
                    // 编辑器模式下，非SeamlessTravel时会在LoadMap中调用
                    // 但是在SeamlessTravel时，此函数没有被调用，需要在此补上
                    // 否则导致StreamingLevel列表没有添加到World上
                    CurrentWorld->RenameToPIEWorld(PIEInstance);
                }
            }

            CurrentGame->OnWorldChanged(CurrentWorld);
            if (CurrentWorld != nullptr)
            {
                UE_LOG(KMGameInstanceLog, Log, TEXT("BroadcastOnWorldCreation in ChangeWorld[%s]:%s UniqueId:%u"), Owner->IsDedicatedServerInstance() ? TEXT("Server") : TEXT("Client"), *CurrentWorld->GetName(), CurrentWorld->GetUniqueID());
                BroadcastOnWorldCreation(CurrentWorld);
            }
            CurrentGame->GetKMDelegateManager()->OnCurrentWorldChanged.Broadcast(
                CurrentWorld ? CurrentWorld->GetUniqueID() : INDEX_NONE);
        }
    }

    void BroadcastOnWorldCreation(UWorld *World)
    {
        if (Owner->GetWorld() != World)
        {
            return;
        }

        auto CurrentGame = UGameEngineExt::Get(Owner);
        if (!World->GetMapName().EndsWith(EmptyMapNameSuffix) && CurrentGame)
        {
            UE_LOG(KMGameInstanceLog, Log, TEXT("OnWorldCreation[%s]:%s UniqueId:%u"), Owner->IsDedicatedServerInstance() ? TEXT("Server") : TEXT("Client"), *World->GetName(), World->GetUniqueID());
            auto LevelActor = Cast<AKMLevelScriptActor>(World->PersistentLevel->GetLevelScriptActor());
            uint32 LevelActorUniqueId = INDEX_NONE;
            FString ScriptType = TEXT("");
            if (IsValid(LevelActor))
            {
                LevelActorUniqueId = LevelActor->GetUniqueID();
                ScriptType = LevelActor->GetScriptType();
            }
            CurrentGame->GetKMDelegateManager()->Level->OnWorldCreation.Broadcast(World, World->GetUniqueID(), LevelActor, LevelActorUniqueId, ScriptType);
        }        
    }

    void ProcessOnWorldCleanup(UWorld* World, bool bSessionEnded, bool bCleanupResources)
    {
        // 由于事件是注册到static delegate上，因此只需要处理与本GameInstance相关的事件
        auto CurrentGame = UGameEngineExt::Get(Owner);
        if (Owner->GetWorld() == World && IsValid(World) && CurrentGame)
        {
            UE_LOG(KMGameInstanceLog, Log, TEXT("ProcessOnWorldCleanup[%s]:%s UniqueId:%u"), Owner->IsDedicatedServerInstance() ? TEXT("Server") : TEXT("Client"), *World->GetName(), World->GetUniqueID());
            if (!World->GetMapName().EndsWith(EmptyMapNameSuffix))
            {
                auto LevelScriptActor = World->PersistentLevel->GetLevelScriptActor();
                CurrentGame->GetKMDelegateManager()->Level->OnWorldCleanup.Broadcast(World->GetUniqueID());
            }

            CurrentGame->OnWorldCleanup(World);
        }
#if ENABLE_VISUAL_LOG
        FVisualLogger::Get().Cleanup(nullptr);
#endif // ENABLE_VISUAL_LOG	
    }

    //void ProcessOnPreLoadMap(const FString&)
    //{
    //    auto MapName = Owner->GetWorld()->GetMapName();
    //    if (!MapName.EndsWith(EmptyMapNameSuffix))
    //    {
    //        UGameEngineExt::Get(Owner)->GetKMDelegateManager()->Level->OnPreLoadMap.Broadcast();
    //    }
    //}

	//LV_ level is loaded
    void ProcessOnPostLoadMap(UWorld* CurrentWorld)
    {
		//if (Cast<UKMGameInstance>(CurrentWorld->GetGameInstance())->IsAsyncLoadingMap)
		//{
		//	return;
		//}
        
        if (!IsValid(CurrentWorld) || Owner->GetWorld() != CurrentWorld)
        {
            return;
        }

        auto CurrentGame = UGameEngineExt::Get(Owner);
        auto MapName = CurrentWorld->GetMapName();
        if (!MapName.EndsWith(EmptyMapNameSuffix) && CurrentGame)
        {
            CurrentGame->GetKMDelegateManager()->Level->OnPostLoadMap.Broadcast();
        }

		//by yangjingzhao
		//clear t.LevelRoutFlag to 0
		FString LevelName = CurrentWorld->GetMapName();
		if (!LevelName.Equals(FString(TEXT("LV_Caribbean"))))
		{
			GEngine->Exec(CurrentWorld, TEXT("t.LevelRoutFlag 0"));
		}
    }

    void ProcessLevelAddedToWorld(ULevel* Level, UWorld* World)
    {
        // 由于事件是注册到static delegate上，因此只需要处理与本GameInstance相关的事件
        auto CurrentGame = UGameEngineExt::Get(Owner);
        if (Owner->GetWorld() == World && (Level) && IsValid(World) && CurrentGame)
        {
            UE_LOG(KMGameInstanceLog, Log, TEXT("ProcessLevelAddedToWorld[%s]:WorldName:%s UniqueId:%u LevelName:%s"), Owner->IsDedicatedServerInstance() ? TEXT("Server") : TEXT("Client"), *World->GetName(), World->GetUniqueID(), *Level->GetName());
            UGameEngineExt::Get(Owner)->GetKMDelegateManager()->Level->OnLevelAddedToWorld.Broadcast(Level, Level->GetPathName(), Level->IsPersistentLevel());
        }


        //现在不用与计算可见性了; 暂时注掉, 况且:
        //GetWorldSettings 会有潜在的crash
        //(服务器同步worldsetting 发现所在level尚未visible的时候可能会把world setting的指针置空,导致GetWorldSetting中check崩溃)
		//bool IsAlwaysLoad = false;
		//FString Levelpath = Level->GetPathName();
		//for (int32 LIndex = 0; LIndex < World->GetStreamingLevels().Num(); LIndex ++)
		//{
		//	FString StreamingLevelName = World->GetStreamingLevels()[LIndex]->GetWorldAsset().GetAssetName();
		//	if (Levelpath.Contains(StreamingLevelName))
		//	{
		//		IsAlwaysLoad = World->GetStreamingLevels()[LIndex]->ShouldBeAlwaysLoaded();
		//		break;
		//	}
		//}

		//if (Level->GetWorldSettings()->bPrecomputeVisibility && IsAlwaysLoad)
		//{
		//	Level->PrecomputedVisibilityHandler.UpdateScene(World->Scene);
		//	Level->PrecomputedVolumeDistanceField.UpdateScene(World->Scene);

		//	//
		//	UE_LOG(KMGameInstanceLog, Log, TEXT("Try to Get precomputed visibility** :%s, %d"), *Level->GetPathName(), Level->GetWorldSettings()->bPrecomputeVisibility);
		//}
    }

    void OnLevelRemovedFromWorld(ULevel* Level, UWorld* World)
    {
        // 由于事件是注册到static delegate上，因此只需要处理与本GameInstance相关的事件
        auto CurrentGame = UGameEngineExt::Get(Owner);
        if (Owner->GetWorld() == World && IsValid(Level) && IsValid(World) && CurrentGame)
        {
            auto Name = World ? World->GetName() : "";
            if (Name == "NewWorld")
            {
                Owner->OnLevelEndPlay.Broadcast(Name, EEndPlayReason::RemovedFromWorld, true);
            }
            auto LevelActor = Level->GetLevelScriptActor();
            if (IsValid(LevelActor))
            {
                UE_LOG(KMGameInstanceLog, Log, TEXT("OnLevelRemovedFromWorld[%s]:WorldName:%s UniqueId:%u LevelName:%s UniqueId:%u"), Owner->IsDedicatedServerInstance() ? TEXT("Server") : TEXT("Client"), *World->GetName(), World->GetUniqueID(), *Level->GetName(), LevelActor->GetUniqueID());
                CurrentGame->GetKMDelegateManager()->Level->OnLevelRemovedFromWorld.Broadcast(LevelActor->GetUniqueID(), World->GetUniqueID());
            }
        }
    }
};

UKMGameInstance::UKMGameInstance(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
    //, Impl(MakeShareable(new FImplement(this)))
{
    if (!PRIVATE_GIsRunningCommandlet)
    {
        #if WITH_EDITOR == 0
        if (IsDedicatedServerInstance())
        #endif    
        {
            Impl = MakeShareable(new FImplement(this));
        }
    }
}

void UKMGameInstance::StartGameInstance()
{
    Super::StartGameInstance();
    if (Impl.IsValid())
    {
        Impl->Start();
    }    
}

void UKMGameInstance::OnWorldChanged(UWorld* OldWorld, UWorld* NewWorld)
{
    Super::OnWorldChanged(OldWorld, NewWorld);
    if (Impl.IsValid())
    {
        Impl->OnWorldChanged(OldWorld, NewWorld);
    }
}

#if WITH_EDITOR
bool UKMGameInstance::IsPlayFromHereInEditor()
{
    if (GUnrealEd && GUnrealEd->GetPlayInEditorSessionInfo().IsSet())
    {
        return GUnrealEd->GetPlayInEditorSessionInfo()->OriginalRequestParams.HasPlayWorldPlacement();
    }
    return false;
}

void UKMGameInstance::GetPlayFromHereTransform(FVector& Location, FRotator& Rotation)
{
    UEditorEngine* const EditorEngine = CastChecked<UEditorEngine>(GetEngine());
    if (EditorEngine->GetPlayInEditorSessionInfo().IsSet())
    {
        auto& Params = GEditor->GetPlayInEditorSessionInfo()->OriginalRequestParams;
        Location = *Params.StartLocation;
        Rotation = *Params.StartRotation;
    }
}

FGameInstancePIEResult UKMGameInstance::InitializeForPlayInEditor(int32 PIEInstanceIndex, const FGameInstancePIEParameters& Params)
{
    auto Ret = Super::InitializeForPlayInEditor(PIEInstanceIndex, Params);
    //if (Ret.bSuccess)
    //{ 
    //    // PlayerStartFromHere时为true
    //    //Impl->bForceDelayStartScriptLogic = GUnrealEd->bHasPlayWorldPlacement;
    //    //Impl->IsPlayFromHereInEditor = GUnrealEd->bHasPlayWorldPlacement;
    //    //auto World = GetWorld();
    //    //Impl->ProcessOnCurrentWorldChanged(World);
    //}
    return Ret;
}

FGameInstancePIEResult UKMGameInstance::StartPlayInEditorGameInstance(ULocalPlayer* LocalPlayer, const FGameInstancePIEParameters& Params)
{
    auto EditorEngine = Cast<UUnrealEdEngine>(GetEngine());
    const ULevelEditorPlaySettings* PlayInSettings = GetDefault<ULevelEditorPlaySettings>();
    FString AdditionalServerGameOptions;
    // 如果没有配置ServerGameOptions，使用Config中的配置
    if (!PlayInSettings->GetAdditionalServerGameOptions(AdditionalServerGameOptions) || AdditionalServerGameOptions.Len() == 0)
    {
        if (IsValid(EditorEngine))
        {
            EditorEngine->UserEditedPlayWorldURL = PIEWorldURL;
        }
    }
    else
    {
        EditorEngine->UserEditedPlayWorldURL = AdditionalServerGameOptions;
    }
	auto Ret = Super::StartPlayInEditorGameInstance(LocalPlayer, Params);
    if (Impl.IsValid())
    {
        Impl->Start();
    }
	return Ret;
}
#endif

void UKMGameInstance::Init()
{
	Super::Init();
    if (Impl.IsValid())
    {
        Impl->Init();
    }	
}

void UKMGameInstance::Shutdown()
{
    if (Impl.IsValid())
    {
        OnShutdown.Broadcast();
        Impl->Shutdown();
    }

	Super::Shutdown();

    if (Impl.IsValid())
    {
        Impl->PostShutdownGameModule();
    }
}

//bool UKMGameInstance::IsForceDelayStartScriptLogic()
//{
//    return Impl->bForceDelayStartScriptLogic;
//}

void UKMGameInstance::BeginDestroy()
{
    if (Impl.IsValid())
    {
        Impl->EnsureShutdown();
    }    
    Super::BeginDestroy();
}

UKMGameInstance* UKMGameInstance::GetKMGameInstance(UObject* WorldContextObject)
{
	UKMGameInstance *Ret = nullptr;
	UWorld *World = GWorld;
	if (IsValid(WorldContextObject))
	{
		World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
		if (!IsValid(World))
		{
			World = GWorld;
		}
	}
	else
	{
		UE_LOG(KMGameInstanceLog, Warning, TEXT("Invalid WorldContextObject in UKMGameInstance::GetKMGameInstance."));
	}

	if (IsValid(World))
	{
		UKMGameInstance *GameInstance = Cast<UKMGameInstance>(World->GetGameInstance());
		if (IsValid(GameInstance))
		{
			Ret = GameInstance;
		}
	}
	return Ret;
}
void UKMGameInstance::RecreateGame()
{
    UE_LOG(KMGameInstanceLog, Log, TEXT("UKMGameInstance::RecreateGame, call Destroy game"));
    DestroyGame();
    UE_LOG(KMGameInstanceLog, Log, TEXT("UKMGameInstance::RecreateGame."));
    Impl = MakeShareable(new FImplement(this));
    Impl->Init();
    Impl->Start();
}

void UKMGameInstance::DestroyGame()
{    
    if (Impl.IsValid())
    {
        UE_LOG(KMGameInstanceLog, Log, TEXT("UKMGameInstance::DestroyGame."));
        OnShutdown.Broadcast();
        Impl->Shutdown();
        Impl->PostShutdownGameModule();
        Impl.Reset();
        GEngine->ForceGarbageCollection(true);
    }
    else
    {
        UE_LOG(KMGameInstanceLog, Log, TEXT("UKMGameInstance::DestroyGame, but is Invalid"));
    }
}

void UKMGameInstance::ExitGame()
{
    UE_LOG(KMGameInstanceLog, Log, TEXT("UKMGameInstance::QuitGame."));
    UKismetSystemLibrary::QuitGame(GetWorld(), nullptr, EQuitPreference::Quit, true);
}

//yangjingzhao
void UKMGameInstance::PrintLoadedPackages()
{
	FOutputDevice& Ar = *GLog;

	TGuardValue<ELogTimes::Type> DisableLogTimes(GPrintLogTimes, ELogTimes::None);

	struct FPackageInfo
	{
		FString Name;
		float LoadTime;
		UClass* AssetType;

		FPackageInfo(UPackage* InPackage)
		{
			Name = InPackage->GetPathName();
			LoadTime = InPackage->GetLoadTime();
			AssetType = nullptr;
		}
	};

	TArray<FPackageInfo> Packages;

	TArray<UObject*> ObjectsInPackageTemp;

	for (TObjectIterator<UPackage> It; It; ++It)
	{
		UPackage* Package = *It;

		const bool bIsARootPackage = Package->GetOuter() == nullptr;

		if (bIsARootPackage == true)
		{
			const int32 NewIndex = Packages.Emplace(Package);

			// Determine the contained asset type
			ObjectsInPackageTemp.Reset();
			GetObjectsWithOuter(Package, /*out*/ ObjectsInPackageTemp, /*bIncludeNestedObjects=*/ false);

			UClass* AssetType = nullptr;
			for (UObject* Object : ObjectsInPackageTemp)
			{
				if (!Object->IsA(UMetaData::StaticClass()) && !Object->IsA(UClass::StaticClass()) && !Object->HasAnyFlags(RF_ClassDefaultObject))
				{
					AssetType = Object->GetClass();
					break;
				}
			}

			Packages[NewIndex].AssetType = AssetType;
		}
	}

	// Sort by name
	Packages.Sort([](const FPackageInfo& A, const FPackageInfo& B) { return A.Name < B.Name; });

	Ar.Logf(TEXT("List of all loaded packages"));
	Ar.Logf(TEXT("Name,Type,LoadTime"), Packages.Num());
	for (const FPackageInfo& Info : Packages)
	{
		Ar.Logf(TEXT("%s,%s,%f"), *Info.Name, (Info.AssetType != nullptr) ? *Info.AssetType->GetName() : TEXT("unknown"), Info.LoadTime);
	}

	Ar.Logf(TEXT("Total Number Of Packages Loaded: %i "), Packages.Num());

	return;
}

void UKMGameInstance::PrintPackageRefrence(FString InPackageName)
{
	StaticExec(GetWorld(), *FString::Printf(TEXT("OBJ REFS NAME=%s"), *InPackageName));
}