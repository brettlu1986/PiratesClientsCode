#pragma once
#include "Config/KMEngineConfig.h"
#include "Engine/LevelStreaming.h"
#include "KMLevelPackagePrecache.generated.h"

/************************************************************************/
/* used to listen sublevel unload event, and dispatch to  UKMLevelPackagePrecache;
	we can not listen sublevel unload event in UKMLevelPackagePrecache directly
	'cause TileStreaming's OnLevelUnloaded has no parameter; we don't know
	which sublevel is unloading*/
/************************************************************************/
UCLASS()
class ULevelUnloadOperation : public UObject
{
	GENERATED_BODY()

public:

	UPROPERTY()
	FString LevelPackageName;

	UPROPERTY()
	TWeakObjectPtr<ULevelStreaming> SavedLevel;

	DECLARE_DELEGATE_OneParam(FLevelPreloadUnload, FString);
	FLevelPreloadUnload PreloadUnload;

	UFUNCTION()
	void OnLevelUnload();

private:


};


UCLASS()
class ENGINEEXT_API UKMLevelPackagePrecache : public UObject
{
	GENERATED_UCLASS_BODY()

public:

	//used for changing levelstreaming's priority which is pending load
	void AddListenForPendingLoadSubLevel(UObject* WorldContextObject);
	void RemoveListenForPendingLoadSubLevel(UObject* WorldContextObject);
	void UpdatePendingLoadLevelPriority(UWorld* InWorld, FString& Packagename, TAsyncLoadPriority InPriority);
	void UpdatePendingLoadLevelPriority(UWorld* InWorld, const FVector& InLoc, TAsyncLoadPriority InPriority);


	//used by game to loc levelstreaming
	void PreLoadLevelStreamingPackageForPoint(UWorld* InWorld, const FVector& InLoc);
	//called before world transilation
	void CleanCachedLevelPackage();

private:

	//used for changing levelstreaming's priority which is pending load
	void OnSubLevelLoaded(FString InPackageName);
	TArray<FString> LoadedLevelNames;


	//used for preload levels(holding world in level package, should be cleaned when level transition)
	void PrecacheLevelPackage(const FString & PackageName);
	//used for world composition to end preload(avoid cleaning in engine ,so we should clean used package manually by game play)
	void EndPrecacheLevelPackage(const FString & PackageName);
	//for removing cached package;
	void OnLevelStreamingUnload(FString InLevelPackage);
	void AsyncPackageLoadComplete(const FName& PackageName, UPackage* LoadedPackage, EAsyncLoadingResult::Type Result);

	UPROPERTY()
	TMap<UWorld*, UPackage*> CachedPackages;

	TArray<FString> LevelsNameforPreLoad;

	//goto description of ULevelUnloadOperation
	UPROPERTY()
	TArray<ULevelUnloadOperation*> UnloadListeners;

};
