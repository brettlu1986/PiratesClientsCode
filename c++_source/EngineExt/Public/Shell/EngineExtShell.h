// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Delegates/KMDelegateManager.h"
#include "EngineExtShell.generated.h"

/**
* Expose interfaces of UGameEngineExt to Lua/Blueprint
*/
UCLASS(BlueprintType)
class ENGINEEXT_API UEngineExtShell : public UObject
{
	GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintPure, Category = "EngineExt", meta = (WorldContext = "WorldContextObject", DisplayName = "GetEngineExtShell", CallInEditor = "true"))
    static UEngineExtShell* Get(UObject* WorldContextObject);

    virtual UWorld* GetWorld() const override;

    virtual void Init();
    virtual void Start();
    virtual void Shutdown();
    virtual void Uninit();
    static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

    UFUNCTION(BlueprintPure, Category = "EngineExt", meta = (CallInEditor = "true"))
    static const bool IsEditor();

	/** Is edit mode or not, for excluding pie and game mode */
	UFUNCTION(BlueprintPure, Category = "EngineExt", meta = (CallInEditor = "true"))
	static const bool IsEditMode(UObject* Object);

    UFUNCTION(BlueprintCallable, Category = "EngineExt", meta = (CallInEditor = "true"))
    static FString GenerateObjectGuidString();

    UFUNCTION(BlueprintPure, Category = "EngineExt")
    UKMDelegateManager* GetKMDelegateManager();

    UFUNCTION()
    FString GetCurrentMapName();

    UFUNCTION()
    float GetWorldRealTimeSeconds();

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    bool LoadAssetAsync(const FString& AssetName);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    bool LoadMultiAssetsAsync(const TArray<FString>& AssetNames, FOnMultiAssetsLoaded Callback);

    UFUNCTION()
    void LoadMultiAssetsAsyncCallbackFire(const TArray<UObject*>& LoadedObjects) {}

    UFUNCTION()
    void ReloadEngineConfig();

    UFUNCTION()
    static bool LoadFileLines(const FString& Path, TArray<FString>& Lines);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static UObject* StaticLoadObjectWithoutFlush(const FString& Path);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static UObject* StaticFindObject(const FString& Path);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
	static UClass* StaticFindClass(const FString& Path);

	UFUNCTION(BlueprintCallable, Category = "EngineExt", meta = (CallInEditor = "true"))
	static void PrintLog(const FString& Log);

    UFUNCTION(BlueprintCallable, Category = "EngineExt", meta = (CallInEditor = "true"))
    static void PrintWarningLog(const FString& Log);

    UFUNCTION(BlueprintCallable, Category = "EngineExt", meta = (CallInEditor = "true"))
    static void PrintErrorLog(const FString& Log);

	//call from logic set drawdistance for skeletalmeshcomponent created from lua or blueprint
	UFUNCTION(BlueprintCallable, Category = "EngineExt")
	static void SetSkeletalMeshComDrawDis(USkeletalMeshComponent* Comp);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void SetComponentDrawDistance(UPrimitiveComponent* Comp);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void FlushLog();

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static float GetScreenPercentageDefault();

	UFUNCTION(BlueprintCallable, Category = "EngineExt")
	static bool GetNearestHitResult(ECollisionChannel DamagedChannel, const TArray<FHitResult>& Hits, const FVector& Location, FHitResult& OutHit);

protected:
    static UObject* GetShell(UObject* WorldContextObject);

    //////////////////////////////////////////////////////////////////////////
    // test crash
    //UFUNCTION()
    //static void CrashTest(UObject* WorldContextObject);

    UFUNCTION()
    static void TriggerCrash(bool bOtherThread);
};
