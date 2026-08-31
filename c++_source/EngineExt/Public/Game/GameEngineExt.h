// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Game/Actor/KMScriptActorSpawnContext.h"
#include "FGameAssetLoader.h"
#include "Loading/WorldCompositionData.h"
#include "Loading/KMLevelPackagePrecache.h"
#include "Components/AudioComponent.h"
#include "Sound/SoundBase.h"
#include "GameEngineExt.generated.h"

class UKMDelegateManager;
class UKMEngineConfig;

DECLARE_LOG_CATEGORY_EXTERN(LogGameEngineExt, Log, All);

UCLASS()
class ENGINEEXT_API UGameEngineExt : public UObject
{
	GENERATED_UCLASS_BODY()

public:
    static UGameEngineExt* Get(const UObject* WorldContextObject);
    virtual ~UGameEngineExt();

    virtual UWorld* GetWorld() const override;
    
    virtual void Init();
    virtual void PostInit();
    virtual void Start();
    virtual void Shutdown();
    virtual void Uninit();
    virtual bool Exec(const TCHAR* Cmd, FOutputDevice& Ar);   
    
    UKMDelegateManager* GetKMDelegateManager() const { return KMDelegateManager; }
    virtual UClass* GetKMDelegateManagerClass() { return nullptr; }
    FKMScriptActorSpawnContext& GetActorSpawnContext() { return ScriptActorSpawnContext; }
    UKMEngineConfig*    GetEngineConfig() { return EngineConfig;  }

    bool LoadAssetAsync(const FString& AssetName);
    bool LoadMultiAssetsAsync(const TArray<FString>& AssetNames, FOnMultiAssetsLoaded Callback);

    virtual void OnWorldChanged(UWorld* NewWorld) {}
	virtual void OnWorldCleanup(UWorld* World);

    virtual UAudioComponent* PlaySoundInClient(USoundBase* Sound, uint8 SoundType, const FVector& Location, AActor* SoundSource) { return nullptr; }

	//yangjingzhao 
	//called by game play
	void UpdatePendingLoadLevelPriority(UWorld* InWorld, const FVector& InLoc);
	void UpdatePendingLoadLevelPriority(UWorld* InWorld, FString& Packagename, TAsyncLoadPriority InPriority);
	//used by game to loc levelstreaming
	void PreLoadLevelStreamingPackageForPoint(UWorld* InWorld, const FVector& InLoc);
	
	//add for world composition config system
	static void CollectWorldComposition_Editor(const FString& PersistentName, TArray<FString>& WorldRoots, bool IsServer = true);
	void OnWorldCompositionCollecting(const FString& PersistentName, TArray<FString>& WorldRoots);
	//used for assetmanager 
	static TArray<FString> CheckWorldCompositionAndGetSubleves(const FPrimaryAssetId& PrimaryAssetID);

	// Default priority for all async loads; just for level streaming
	//don't use it on other assets(they can use streamablemanager::DefaultAsyncLoadPriority....),
	static const TAsyncLoadPriority DefaultAsyncLoadPriority = 0;
	static const TAsyncLoadPriority AsyncLoadMidPriority = 100;
	// Priority to try and load immediately
	static const TAsyncLoadPriority AsyncLoadHighPriority = 1000;
	//yangjingzhao end

	//yangjingzhao
	//Load WorldComposition Levels immediately
	void LoadLevelsImmediatelyByLocation(FVector InLoc);

protected:
    static UObject* GetGame(const UObject* WorldContextObject);

    virtual void TickImplement(float DeltaTime);
    virtual void StartTick();
    virtual void StopTick();

    template<class TObjectClass, typename... TArgsType>
    FORCEINLINE TObjectClass* NewUObjectAndInit(TArgsType&&... Args)
    {
        TObjectClass* Ret = NewObject<TObjectClass>(this);
        Ret->Init(Forward<TArgsType>(Args)...);
        return Ret;
    }

#define SAVE_UPDATE(x, t) if(x) { x->Update(t); }
#define SAVE_TICK(x, t) if(x) { x->Tick(t); }
#define SAVE_UNINIT(x) if(x) { x->Uninit(); x = nullptr; }
#define SAVE_CLEAR(x) if(x) { x->Clear(); x = nullptr; }

	UPROPERTY()
	UKMDelegateManager* KMDelegateManager;

	FGameAssetLoader GameAssetLoader;
	FKMScriptActorSpawnContext ScriptActorSpawnContext;
	
	UPROPERTY()
	UKMEngineConfig*  EngineConfig;
	
	//yangjingzhao 
	//used for precache world composition data, loaded when engine start up
	UPROPERTY()
	UWorldCompositionData* WCData;

	UPROPERTY()
	UKMLevelPackagePrecache* LevelPrecache;
	//yangjingzhao end

private:
    bool Tick(float DeltaTime);

	//yangjingzhao used for precache world composition data in game client
	void PrecacheWorldCompositionData();

    FDelegateHandle TickHandle;
    FDelegateHandle OnHandleSystemErrorHandle;
    void ProcessOnCrash();
};
