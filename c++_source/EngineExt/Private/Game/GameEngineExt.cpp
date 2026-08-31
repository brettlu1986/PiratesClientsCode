// Fill out your copyright notice in the Description page of Project Settings.

#include "GameEngineExt.h"
#include "EngineExt.h"
#include "WorldObjectMap.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Engine/StreamableManager.h"
#include "Engine/WorldComposition.h"
#include "Loading/WorldCompositionData.h"

DEFINE_LOG_CATEGORY(LogGameEngineExt);

UGameEngineExt::UGameEngineExt(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)    
    , KMDelegateManager(nullptr)
    , EngineConfig(nullptr)
	, LevelPrecache(nullptr)
{
    OnHandleSystemErrorHandle = FCoreDelegates::OnHandleSystemError.AddUObject(this, &UGameEngineExt::ProcessOnCrash);
}

UGameEngineExt::~UGameEngineExt()
{
    FCoreDelegates::OnHandleSystemError.Remove(OnHandleSystemErrorHandle);
    OnHandleSystemErrorHandle.Reset();
}

static FWorldObjectMap& GetGameWorldObjectMap()
{
    static FWorldObjectMap* g_GameMap = new FWorldObjectMap();
    return *g_GameMap;
}

UObject* UGameEngineExt::GetGame(const UObject* WorldContextObject)
{
    return GetGameWorldObjectMap().GetObject(WorldContextObject);
}

UGameEngineExt* UGameEngineExt::Get(const UObject* WorldContextObject)
{
    return Cast<UGameEngineExt>(GetGame(WorldContextObject));
}

UWorld* UGameEngineExt::GetWorld() const
{
    auto Outer = GetOuter();
    return Outer ? Outer->GetWorld() : nullptr;
}

void UGameEngineExt::ProcessOnCrash()
{
}

void UGameEngineExt::Init()
{
    GetGameWorldObjectMap().AddObject(this, this);
    UClass* KMDelegateManagerClass = GetKMDelegateManagerClass();
    if (!KMDelegateManagerClass)
    {
        UE_LOG(LogGameEngineExt, Error, TEXT("KMDelegateManagerClass is null !!!"));
        return;
    }
    KMDelegateManager = NewObject<UKMDelegateManager>(this, KMDelegateManagerClass);
    if (!KMDelegateManager)
    {
        UE_LOG(LogGameEngineExt, Error, TEXT("KMDelegateManager new failed !!!"));
        return;
    }

    KMDelegateManager->Init();
    GameAssetLoader.Init(KMDelegateManager);

	EngineConfig = NewObject<UKMEngineConfig>(this);
	EngineConfig->Load();
	EngineConfig->OnLoadFinish();

	//yangjingzhao add level package precache
	LevelPrecache = NewObject<UKMLevelPackagePrecache>(this);
}

void UGameEngineExt::PostInit()
{
}

void UGameEngineExt::Start()
{
	//yangjingzhao if in PIE, do not need to bind this again
	if (!GetWorld()->IsPlayInEditor())
	{
		FCoreUObjectDelegates::OnCollectingWorldComposition.BindUObject(this, &UGameEngineExt::OnWorldCompositionCollecting);
		PrecacheWorldCompositionData();
	}
	//end
}

void UGameEngineExt::Shutdown()
{
    StopTick();

	//yangjingzhao
	if (!GetWorld()->IsPlayInEditor())
	{
		FCoreUObjectDelegates::OnCollectingWorldComposition.Unbind();
	}
}

void UGameEngineExt::Uninit()
{
    GameAssetLoader.Uninit();
    GetGameWorldObjectMap().RemoveObject(this);
}

void UGameEngineExt::StartTick()
{
    if (!TickHandle.IsValid())
    {
        TickHandle = FTicker::GetCoreTicker().AddTicker(FTickerDelegate::CreateUObject(this, &UGameEngineExt::Tick));
    }
}

void UGameEngineExt::StopTick()
{
    if (TickHandle.IsValid())
    {
        FTicker::GetCoreTicker().RemoveTicker(TickHandle);
        TickHandle.Reset();
    }
}

bool UGameEngineExt::Tick(float DeltaTime)
{
    TickImplement(DeltaTime);
    return true;
}

void UGameEngineExt::TickImplement(float DeltaTime)
{
    GameAssetLoader.Tick(DeltaTime);
}

bool UGameEngineExt::Exec(const TCHAR* Cmd, FOutputDevice& Ar)
{
	auto Manager = GetKMDelegateManager();
	if (Manager)
	{
		auto Delegate = Manager->OnExecCommand;
		if (Delegate.IsBound())
		{
			FString Command(Cmd);
			if (Delegate.Execute(Command))
			{
				return true;
			}
		}
	}
	return false;
}

bool UGameEngineExt::LoadAssetAsync(const FString& AssetName)
{
    return GameAssetLoader.LoadAssetAsync(AssetName);
}

bool UGameEngineExt::LoadMultiAssetsAsync(const TArray<FString>& AssetNames, FOnMultiAssetsLoaded Callback)
{
    return GameAssetLoader.LoadMultiAssetsAsync(AssetNames, Callback);
}

void UGameEngineExt::UpdatePendingLoadLevelPriority(UWorld* InWorld, const FVector& InLoc)
{
	LevelPrecache->UpdatePendingLoadLevelPriority(InWorld, InLoc, AsyncLoadHighPriority);
}

void UGameEngineExt::UpdatePendingLoadLevelPriority(UWorld* InWorld, FString& Packagename, TAsyncLoadPriority InPriority)
{
	LevelPrecache->UpdatePendingLoadLevelPriority(InWorld, Packagename, InPriority);
}

void UGameEngineExt::PreLoadLevelStreamingPackageForPoint(UWorld* InWorld, const FVector& InLoc)
{
	LevelPrecache->PreLoadLevelStreamingPackageForPoint(InWorld, InLoc);
}

//add for clean cached package, avoiding error of GC(when level transilation)
void UGameEngineExt::OnWorldCleanup(UWorld* World)
{
	LevelPrecache->CleanCachedLevelPackage();
}

void UGameEngineExt::PrecacheWorldCompositionData()
{
	//temprary fix crash
	//load sublevel from persistent level root 
	if (!IsInGameThread())
	{
		UE_LOG(LogGameEngineExt, Error, TEXT("PrecacheWorldCompositionData Not In Game thread !!!"));
		return;
	}

	const UWorldCompositionConfig* DefaultWCConfig = GetDefault<UWorldCompositionConfig>();

	UClass* WCDataClass = nullptr;
#if WITH_EDITORONLY_DATA
	//if use local path load new file from local
	if (DefaultWCConfig->UseLocalPath)
	{
		WCDataClass = DefaultWCConfig->WCDataLocalPath.Get();
	}
#endif

	if (!WCDataClass)
	{
		const UWorldCompositionData* WCDataTemp = GetDefault<UWorldCompositionData>();
		FString WCDataClassPath = WCDataTemp->WCDataClassPath;
		WCDataClass = StaticLoadClass(UWorldCompositionData::StaticClass(), nullptr, *WCDataClassPath, nullptr, LOAD_None);
	}

	if (!WCDataClass)
	{
		UE_LOG(LogGameEngineExt, Error, TEXT("Can not find World Composition Config !!!"));
		return;
	}

	WCData = WCDataClass->GetDefaultObject<UWorldCompositionData>();
}

void UGameEngineExt::OnWorldCompositionCollecting(const FString& PersistentName, TArray<FString>& WorldRoots)
{
	if (!WCData)
	{
		UE_LOG(LogGameEngineExt, Error, TEXT("PrecacheWorldCompositionData WCData is invalid"));
		return;
	}

	TArray<FString> UsedSubLevelPathList;
	const FString& ConfigPath = FPaths::Combine(FPaths::GeneratedConfigDir(), TEXT("WorldComposition.ini"));
	UE_LOG(LogGameEngineExt, Log, TEXT("[WorldComposition] Config path: %s"), *ConfigPath);
	GConfig->GetArray(TEXT("WorldCompositionConfig"), TEXT("UsedSubLevelPathList"), UsedSubLevelPathList, ConfigPath);
	for (auto& SubLevelPath : UsedSubLevelPathList)
	{
		UE_LOG(LogGameEngineExt, Log, TEXT("[WorldComposition] Used sub level path: %s"), *SubLevelPath);
	}
	auto CheckSubLevelIsUsed = [&UsedSubLevelPathList](const FWorldCompositionSubLevel& SublevelItemData)
	{
		if ((UsedSubLevelPathList.Num() > 0) && !UsedSubLevelPathList.Contains(SublevelItemData.DirectoryPath))
		{
			UE_LOG(LogGameEngineExt, Log, TEXT("[WorldComposition] Filter sub level by WorldComposition.ini : %s"), *SublevelItemData.DirectoryPath);
			return false;
		}
		return SublevelItemData.IsUsed;
	};

	for (auto WCIt = WCData->WorldCompositions.CreateConstIterator(); WCIt; ++WCIt)
	{
		const FWorldCompositionPair& Persistentdata = *WCIt;
		if (Persistentdata.PersistentName.Equals(PersistentName))
		{
			for (auto SubLevelIt = Persistentdata.Roots.CreateConstIterator(); SubLevelIt; ++SubLevelIt)
			{
				const FWorldCompositionSubLevel& SublevelItemData = *SubLevelIt;

				//don't add server only path
				if (!GIsServer && SublevelItemData.IsServerOnly)
				{
					continue;
				}

				//if is used , add path to roots
				if (CheckSubLevelIsUsed(SublevelItemData))
				{
					WorldRoots.AddUnique(FPaths::ProjectContentDir() + SublevelItemData.DirectoryPath);
				}
			}

			break;
		}
	}
}

void UGameEngineExt::CollectWorldComposition_Editor(const FString& PersistentName, TArray<FString>& WorldRoots, bool IsServer)
{
	//temprary fix crash
	//load sublevel from persistent level root 
	if (!IsInGameThread())
	{
		UE_LOG(LogGameEngineExt, Error, TEXT("Not In Game thread !!!"));
		return;
	}

	const UWorldCompositionConfig* DefaultWCConfig = GetDefault<UWorldCompositionConfig>();

	UClass* WCDataClass = nullptr;
#if WITH_EDITORONLY_DATA
	//if use local path load new file from local
	if (DefaultWCConfig->UseLocalPath)
	{
		WCDataClass = DefaultWCConfig->WCDataLocalPath.Get();
	}
#endif

	if (!WCDataClass)
	{
		const UWorldCompositionData* WCDataTemp = GetDefault<UWorldCompositionData>();
		 FString WCDataClassPath = WCDataTemp->WCDataClassPath;
		 WCDataClass = StaticLoadClass(UWorldCompositionData::StaticClass(), nullptr, *WCDataClassPath, nullptr, LOAD_None);
	}

	if (!WCDataClass)
	{
		UE_LOG(LogGameEngineExt, Error, TEXT("Can not find World Composition Config !!!"));
		return;
	}

	UWorldCompositionData* TempWCData = WCDataClass->GetDefaultObject<UWorldCompositionData>();
	for (auto WCIt = TempWCData->WorldCompositions.CreateConstIterator(); WCIt; ++WCIt)
	{
		const FWorldCompositionPair& Persistentdata = *WCIt;
		if (Persistentdata.PersistentName.Equals(PersistentName))
		{
			for (auto SubLevelIt = Persistentdata.Roots.CreateConstIterator(); SubLevelIt; ++SubLevelIt)
			{
				const FWorldCompositionSubLevel& SublevelItemData = *SubLevelIt;

				//don't add server only path
				if (!IsServer && SublevelItemData.IsServerOnly)
				{
					continue;
				}

				//if is used , add path to roots
				if (SublevelItemData.IsUsed)
				{
					WorldRoots.AddUnique(FPaths::ProjectContentDir() + SublevelItemData.DirectoryPath);
				}
			}

			break;
		}
	}
}

void UGameEngineExt::LoadLevelsImmediatelyByLocation(FVector InLoc)
{
	if (!GetWorld() || !GetWorld()->WorldComposition)
	{
		return;
	}

	GetWorld()->WorldComposition->UpdateStreamingState(InLoc);
	GetWorld()->FlushLevelStreaming();
}

TArray<FString> UGameEngineExt::CheckWorldCompositionAndGetSubleves(const FPrimaryAssetId& PrimaryAssetID)
{
	TArray<FString> AssetIds;
	//temprary fix crash
	//load sublevel from persistent level root 
	if (!IsInGameThread())
	{
		UE_LOG(LogGameEngineExt, Error, TEXT("Not In Game thread !!!"));
		return AssetIds;
	}

	const UWorldCompositionConfig* DefaultWCConfig = GetDefault<UWorldCompositionConfig>();

	UClass* WCDataClass = nullptr;
#if WITH_EDITORONLY_DATA
	//if use local path load new file from local
	if (DefaultWCConfig->UseLocalPath)
	{
		WCDataClass = DefaultWCConfig->WCDataLocalPath.Get();
	}
#endif

	if (!WCDataClass)
	{
		const UWorldCompositionData* WCDataTemp = GetDefault<UWorldCompositionData>();
		FString WCDataClassPath = WCDataTemp->WCDataClassPath;
		WCDataClass = StaticLoadClass(UWorldCompositionData::StaticClass(), nullptr, *WCDataClassPath, nullptr, LOAD_None);
	}

	if (!WCDataClass)
	{
		UE_LOG(LogGameEngineExt, Error, TEXT("Can not find World Composition Config !!!"));
		return AssetIds;
	}

	UWorldCompositionData* TempWCData = WCDataClass->GetDefaultObject<UWorldCompositionData>();
	for (auto WCIt = TempWCData->WorldCompositions.CreateConstIterator(); WCIt; ++WCIt)
	{
		const FWorldCompositionPair& Persistentdata = *WCIt;
		//match name
		FString AssetNameStr = PrimaryAssetID.ToString();
		if (!AssetNameStr.Contains(Persistentdata.PersistentName))
		{
			continue;
		}

		for (int32 RootIndex = 0; RootIndex < WCIt->Roots.Num(); RootIndex++)
		{
			if (!WCIt->Roots[RootIndex].IsUsed || WCIt->Roots[RootIndex].IsServerOnly)
			{
				continue;
			}

			//get root directory
			FString RootDir = WCIt->Roots[RootIndex].DirectoryPath;

			TArray<FString> FilePaths;
			
			FString AssetFullPath = FPaths::ProjectContentDir() + RootDir;
			IFileManager::Get().FindFilesRecursive(FilePaths, *AssetFullPath, TEXT("*.umap"), true, false, false);

			//
			FString ProjContentStr = FPaths::ProjectContentDir();
			for (int32 PathIdx =0; PathIdx < FilePaths.Num(); PathIdx ++)
			{
				FilePaths[PathIdx].ReplaceInline(*ProjContentStr, TEXT("/Game/"));
				FilePaths[PathIdx].ReplaceInline(TEXT(".umap"), TEXT(""));
			}

			AssetIds.Append(FilePaths);

		}
	}

	return AssetIds;
}
