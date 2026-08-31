#include "Loading/KMLevelPackagePrecache.h"
#include "EngineExt.h"
#include "Engine/World.h"
#include "Game/GameEngineExt.h"
#include "Engine/WorldComposition.h"

static int32 GPirAllowSublevelPreload = 1;
static FAutoConsoleVariableRef CVarPirAllowSublevelPreload(
	TEXT("pir.allowSublevelPreload"),
	GPirAllowSublevelPreload,
	TEXT("1: allow level streaming preload  0:not.")
);

UKMLevelPackagePrecache::UKMLevelPackagePrecache(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{

}

/************************************************************************/
/*  for change level streaming's loading priority              */
/************************************************************************/

void UKMLevelPackagePrecache::AddListenForPendingLoadSubLevel(UObject* WorldContextObject)
{
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World != nullptr)
	{
		World->OnSubLevelPendingLoad.AddUObject(this, &UKMLevelPackagePrecache::OnSubLevelLoaded);
	}
	LoadedLevelNames.Empty();
}

void UKMLevelPackagePrecache::RemoveListenForPendingLoadSubLevel(UObject* WorldContextObject)
{
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World != nullptr)
	{
		World->OnSubLevelPendingLoad.RemoveAll(this);
	}

	LoadedLevelNames.Empty();
}

//delegate for sublevel loaded event, used to modify priority of levelstreaming
void UKMLevelPackagePrecache::OnSubLevelLoaded(FString InPackageName)
{
	FString Flag = FString(TEXT("Town"));
	if (!InPackageName.Contains(Flag))
	{
		return;
	}

	LoadedLevelNames.Add(InPackageName);

	/*Test use for update level streaming priority*/
	if (LoadedLevelNames.Num() > 0)
	{
		UpdatePendingLoadLevelPriority(this->GetWorld(), LoadedLevelNames[0], UGameEngineExt::AsyncLoadMidPriority);
	}
}

void UKMLevelPackagePrecache::UpdatePendingLoadLevelPriority(UWorld* InWorld, FString& Packagename, TAsyncLoadPriority InPriority)
{
	if (!LoadedLevelNames.Num())
	{
		return;
	}

	TArray<ULevelStreaming*> Streamings = InWorld->GetStreamingLevels();

	for (int32 SIndex = 0; SIndex < Streamings.Num(); ++SIndex)
	{
		if (Streamings[SIndex]->PackageNameToLoad.ToString().Equals(Packagename))
		{
			Streamings[SIndex]->SetPriority(InPriority);
			break;
		}
	}
}

void UKMLevelPackagePrecache::UpdatePendingLoadLevelPriority(UWorld* InWorld, const FVector& InLoc, TAsyncLoadPriority InPriority)
{
	if (GIsPlayInEditorWorld)
	{
		UE_LOG(LogGameEngineExt, Display, TEXT("The Editor is currently in a play mode."));
		return;
	}

	if (!InWorld->GetWorldSettings()->bEnableWorldComposition)
	{
		return;
	}

	if (GPirAllowSublevelPreload <= 0)
	{
		return;
	}

	//get tiles from worldcomposition
	auto& Tiles = InWorld->WorldComposition->GetTilesList();
	FIntPoint WorldOriginLocationXY = FIntPoint(InWorld->OriginLocation.X, InWorld->OriginLocation.Y);

	LevelsNameforPreLoad.Empty();

	//find if tile is ignored
	int32 TileIndex = 0;
	for (auto It = Tiles.CreateIterator(); It; ++It)
	{
		bool IsTileIgnored = false;

		TArray<FString> PreloadExclude = UGameEngineExt::Get(GetWorld())->GetEngineConfig()->PreLoadExcludeMaps;
		for (int32 ExIndex = 0; ExIndex < PreloadExclude.Num(); ExIndex++)
		{
			FString TilePackageName = It->PackageName.ToString();

			//set priority only for towns
			if (TilePackageName.Contains(PreloadExclude[ExIndex]))
			{
				IsTileIgnored = true;
				break;
			}
		}

		if (IsTileIgnored)
		{
			continue;
		}

		//calc level bounds in world & is point inside level bound
		FIntPoint LevelPositionXY = FIntPoint(It->Info.AbsolutePosition.X, It->Info.AbsolutePosition.Y);
		FIntPoint LevelOffsetXY = LevelPositionXY - WorldOriginLocationXY;
		FBox LevelBounds = It->Info.Bounds.ShiftBy(FVector(LevelOffsetXY));

		LevelBounds.Min.Z = -WORLD_MAX;
		LevelBounds.Max.Z = WORLD_MAX;

		int LevelLODPreload = -1;
		//ignor levle lod 1; too many streaming levles
		/*float LODStreamingDis = It->Info.GetStreamingDistance(0);
		bool IsInsideBox = FMath::SphereAABBIntersection(InLoc, FMath::Square(LODStreamingDis), LevelBounds);
		if (IsInsideBox)
		{
			LevelLODPreload = 1;
		}*/
		float StreamingDis = It->Info.GetStreamingDistance(-1);
		bool IsInsideBox = FMath::SphereAABBIntersection(InLoc, FMath::Square(StreamingDis), LevelBounds);
		if (IsInsideBox)
		{
			LevelLODPreload = 0;
		}

		if (LevelLODPreload >= 0)
		{
			if (LevelLODPreload == 0)
			{
				FString Packagename = It->PackageName.ToString();
				LevelsNameforPreLoad.Add(Packagename);
			}
			else if (LevelLODPreload == 1)
			{
				FString LODPackagename = It->LODPackageNames[0].ToString();
				LevelsNameforPreLoad.Add(LODPackagename);
			}

			ULevelStreaming* TileStreaming = InWorld->WorldComposition->TilesStreaming[TileIndex];
			TileStreaming->SetPriority(InPriority);
		}

		TileIndex++;
	}
}


/************************************************************************/
/*  for preload level streamings from a point ; 
	and hold the package asset , until the sublevel is unloaded            */
/************************************************************************/

void ULevelUnloadOperation::OnLevelUnload()
{
	UE_LOG(LogGameEngineExt, Display, TEXT("[xsjme]*****ULevelUnloadOperation::OnLevelUnload  %s"), *LevelPackageName);
	if (SavedLevel.IsValid())
	{
		SavedLevel->OnLevelUnloaded.RemoveAll(this);
	}
	PreloadUnload.ExecuteIfBound(LevelPackageName);
}


void UKMLevelPackagePrecache::PreLoadLevelStreamingPackageForPoint(UWorld* InWorld, const FVector& InLoc)
{
	if (GIsPlayInEditorWorld)
	{
		UE_LOG(LogGameEngineExt, Display, TEXT("The Editor is currently in a play mode."));
		return;
	}

	if (GPirAllowSublevelPreload <= 0)
	{
		return;
	}

	//get tiles from worldcomposition
	auto& Tiles = InWorld->WorldComposition->GetTilesList();
	FIntPoint WorldOriginLocationXY = FIntPoint(InWorld->OriginLocation.X, InWorld->OriginLocation.Y);

	LevelsNameforPreLoad.Empty();

	//find if tile is ignored
	int32 TileIndex = 0;
	for (auto It = Tiles.CreateIterator(); It; ++It)
	{
		bool IsTileIgnored = false;

		TArray<FString> PreloadExclude = UGameEngineExt::Get(GetWorld())->GetEngineConfig()->PreLoadExcludeMaps;
		for (int32 ExIndex = 0; ExIndex < PreloadExclude.Num(); ExIndex++)
		{
			FString TilePackageName = It->PackageName.ToString();

			//set priority only for towns
			if (TilePackageName.Contains(PreloadExclude[ExIndex]))
			{
				IsTileIgnored = true;
				break;
			}
		}

		if (IsTileIgnored)
		{
			continue;
		}

		//calc level bounds in world & is point inside level bound
		FIntPoint LevelPositionXY = FIntPoint(It->Info.AbsolutePosition.X, It->Info.AbsolutePosition.Y);
		FIntPoint LevelOffsetXY = LevelPositionXY - WorldOriginLocationXY;
		FBox LevelBounds = It->Info.Bounds.ShiftBy(FVector(LevelOffsetXY));

		LevelBounds.Min.Z = -WORLD_MAX;
		LevelBounds.Max.Z = WORLD_MAX;

		int LevelLODPreload = -1;

		float StreamingDis = It->Info.GetStreamingDistance(-1);
		bool IsInsideBox = FMath::SphereAABBIntersection(InLoc, FMath::Square(StreamingDis), LevelBounds);
		if (IsInsideBox)
		{
			LevelLODPreload = 0;
		}
		
		if (LevelLODPreload >= 0)
		{

			if (LevelLODPreload == 0)
			{
				FString Packagename = It->PackageName.ToString();
				LevelsNameforPreLoad.Add(Packagename);
			}
			else if (LevelLODPreload == 1)
			{
				FString LODPackagename = It->LODPackageNames[0].ToString();
				LevelsNameforPreLoad.Add(LODPackagename);
			}

			ULevelStreaming* TileStreaming = InWorld->WorldComposition->TilesStreaming[TileIndex];

			ULevelUnloadOperation* UnloadListen = NewObject<ULevelUnloadOperation>(this);
			UnloadListen->LevelPackageName = LevelsNameforPreLoad[LevelsNameforPreLoad.Num() - 1];
			UnloadListen->SavedLevel = TileStreaming;
			UnloadListen->PreloadUnload.BindUObject(this, &UKMLevelPackagePrecache::OnLevelStreamingUnload);
			TScriptDelegate<FWeakObjectPtr> Delegate;
			Delegate.BindUFunction(UnloadListen, FName(TEXT("OnLevelUnload")));
			TileStreaming->OnLevelUnloaded.Add(Delegate); 
			UnloadListeners.Add(UnloadListen);

			//precache package just added
			PrecacheLevelPackage(LevelsNameforPreLoad[LevelsNameforPreLoad.Num() - 1]);
		}
		
		TileIndex++;
	}

}

void UKMLevelPackagePrecache::OnLevelStreamingUnload(FString InLevelPackage)
{
	UE_LOG(LogGameEngineExt, Display, TEXT("[xsjme]*****UKMLevelPackagePrecache::OnLevelStreamingUnload  %s"), *InLevelPackage);
	//remove operation
	int32 Index = 0;
	for (Index = 0; Index < UnloadListeners.Num(); Index++)
	{
		if (UnloadListeners[Index]->LevelPackageName.Equals(InLevelPackage))
		{
			UnloadListeners[Index]->PreloadUnload.Unbind();
			break;
		}
	}
	UnloadListeners.RemoveAt(Index);

	//remove cached packages
	for (Index = 0; Index < LevelsNameforPreLoad.Num(); Index ++)
	{
		FString PackageName = LevelsNameforPreLoad[Index];
		
		if (PackageName.Equals(InLevelPackage))
		{
			EndPrecacheLevelPackage(PackageName);
			LevelsNameforPreLoad.RemoveAt(Index);

			break;
		}
	}

}

void UKMLevelPackagePrecache::PrecacheLevelPackage(const FString& PackageName)
{
	//this will be removed in future...
	UE_LOG(LogGameEngineExt, Display, TEXT("[xsjme]*******UGameEngineExt::PrecacheLevelPackage start  %s"), *PackageName);

	if (PackageName.Equals(FString(TEXT(""))))
	{
		return;
	}

	ULevel::StreamedLevelsOwningWorld.Add(FName(*PackageName), GetWorld());
	LoadPackageAsync(PackageName, FLoadPackageAsyncDelegate::CreateUObject(this, &UKMLevelPackagePrecache::AsyncPackageLoadComplete), UGameEngineExt::AsyncLoadMidPriority, PKG_ContainsMap, -1);
}

void UKMLevelPackagePrecache::AsyncPackageLoadComplete(const FName& PackageName, UPackage* LoadedPackage, EAsyncLoadingResult::Type Result)
{
	ULevel::StreamedLevelsOwningWorld.Remove(PackageName);

	if (Result == EAsyncLoadingResult::Succeeded)
	{
		UPackage* LevelPackage = LoadedPackage;

		// Try to find a UWorld object in the level package.
		UWorld* World = UWorld::FindWorldInPackage(LoadedPackage);

		CachedPackages.Add(World, LoadedPackage);
		UE_LOG(LogGameEngineExt, Display, TEXT("[xsjme]*********UKMLevelPackagePrecache PrecacheLevelPackage Success   %s"), *PackageName.ToString());
	}
	else {
		UE_LOG(LogGameEngineExt, Display, TEXT("[xsjme]*********PrecacheLevelPackage Failed   %s"), *PackageName.ToString());
	}
}

void UKMLevelPackagePrecache::EndPrecacheLevelPackage(const FString & PackageName)
{
	for (auto It = CachedPackages.CreateIterator(); It; ++It)
	{
		UPackage* levelPackage = It.Value();
		if (PackageName.Equals(levelPackage->GetFName().ToString()))
		{
			UE_LOG(LogGameEngineExt, Display, TEXT("[xsjme]*******UKMLevelPackagePrecache::EndPrecacheLevelPackage  %s"), *PackageName);

			CachedPackages.Remove(It.Key());
			break;
		}
	}
}

void UKMLevelPackagePrecache::CleanCachedLevelPackage()
{
	CachedPackages.Empty();
}