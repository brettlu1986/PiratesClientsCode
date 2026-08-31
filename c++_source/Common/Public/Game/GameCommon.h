// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameEngineExt.h"
#include "PiratesGameStatusDefine.h"
#include "GameCommon.generated.h"

class UCharacterManager;
class UGameDelegateManager;
class UPiratesAreaTriggerManager;
class UPiratesActorTriggerGroupManager;
class UOceanNavGridManager;
class ULandNavMeshDataManager;
class UPathNodeFinder;
class UPiratesPlayerGrid;
class UGameLuaManager;
class UGameLimitedTimeTaskManager;
class UPiratesGridTriggerManager;
class UPiratesGridTypeManager;
class UTemplateActorDataManager;
class UAICoverPointsManager;
class UGameLuaRoot;
class UPiratesActorWeaponInhibitManager;
class UAIDestructibleObjectManagerRoot;
class UAIVehicleManager;
class UAIOceanGridManagerRoot;
class UAISmokeManager;

UCLASS()
class COMMON_API UGameCommon : public UGameEngineExt
{
	GENERATED_UCLASS_BODY()

public:
    virtual void Init() override;
    virtual void PostInit() override;
    virtual void Start() override;
    virtual void Shutdown() override;

    static UGameCommon* Get(const UObject* WorldContextObject);

    class UInputManager* GetInputManager() const { return InputManager; }
    UCharacterManager* GetCharacterManager() const { return CharacterManager; }
    class URPCNetworkManager* GetRPCNetworkManager() const { return RPCNetworkManager; }
    UGameDelegateManager* GetGameDelegateManager() const;
    virtual UClass* GetKMDelegateManagerClass() override;
    UPathNodeFinder* GetPathNodeFinder() { return PathNodeFinder; }
    void SetGameStatus(EPiratesGameStatus Status) { GameStatus = Status; }
    const EPiratesGameStatus GetGameStatus() const { return GameStatus; }
    class ULogReport* GetLogReport();

    class UHttpHelper* GetHttpHelper();
    UPiratesAreaTriggerManager* GetAreaTriggerManager() { return AreaTriggerManager; }
    UPiratesActorTriggerGroupManager* GetActorTriggerGroupManager();
    UPiratesActorWeaponInhibitManager* GetActorWeaponInhibitManager();
    virtual FString ApproveLogin(const FString& Options);
	virtual void PlayerControllerUpdate(class APiratesPlayerController* PC);
    
    //调用该函数时，必须要有NetDriver
    float GetConnectionTimeout();

    UOceanNavGridManager* GetOceanNavGridManager() const { return OceanNavGridManager; }
    ULandNavMeshDataManager* GetLandNavMeshDataManager() const { return LandNavMeshDataManager; }
	UPiratesPlayerGrid* GetPiratesPlayerGrid();
    //UGameLuaManager* GetGameLuaManager() const { return GameLuaManager; }
    UGameLuaRoot* GetLuaRoot() const { return LuaRoot; }
    UGameLimitedTimeTaskManager* GetTaskManager() const { return TaskManager; }
    //UPiratesGridTriggerManager* GetGridTriggerManager() const { return GridTriggerManager; }
	UPiratesGridTypeManager* GetGridTypeManager();
    UTemplateActorDataManager* GetTemplateActorDataManager() { return TemplateActorManager; }
    UAIDestructibleObjectManagerRoot* GetAIDestructibleObjectManager() const { return AIDestructibleObjectManager; }
    UAIVehicleManager* GetAIVehicleManager() const { return AIVehicleManager; }
    UAIOceanGridManagerRoot* GetAIOceanGridManager() const { return AIOceanGridManager; }
    UAISmokeManager* GetAISmokeManager() const { return AISmokeManager; }

    void SetTemplateActorDataManager(UTemplateActorDataManager* Manager) { TemplateActorManager = Manager; }

    virtual UAudioComponent* PlaySoundInClient(USoundBase* Sound, uint8 SoundType, const FVector& Location, AActor* SoundSource) override;

    UAICoverPointsManager* GetAICoverPointsManager() const;
    static void SetUseU4LuaEnabled(bool Enabled);
    static bool IsU4LuaEnabled();
    static void SetRemoteLuaRepository(const FString& URL);

    bool IsGMEnabled() const;
    bool IsPreloadMap() const;
    void OnLowMemoryWarning();

    void RecordSpawnActorFrameCounter();

    uint64 GetLastSpawnActorFrameCounter();

#if WITH_EDITOR
    static bool DoLuaStringInEditor(const TArray<FString>& Paths, const FString& Script, FString& OutReturn, FString& OutError);
#endif

protected:
    virtual void TickImplement(float DeltaTime) override;
    virtual void InitLua();
    virtual void PostInitLua();
    virtual void UninitLua();
    virtual void OnWorldChanged(UWorld* NewWorld) override;
    virtual void OnWorldCleanup(UWorld* World) override;

protected:
    UPROPERTY()
    class UInputManager* InputManager;

    UPROPERTY()
    UCharacterManager* CharacterManager;

    UPROPERTY()
    UHttpHelper* HttpHelper;

    UPROPERTY()
    UPiratesAreaTriggerManager* AreaTriggerManager;
    UPROPERTY()
    UPiratesActorTriggerGroupManager* ActorTriggerGroupManager;
    UPROPERTY()
    class URPCNetworkManager* RPCNetworkManager;

    UPROPERTY()
    UOceanNavGridManager* OceanNavGridManager;

    UPROPERTY()
    ULandNavMeshDataManager* LandNavMeshDataManager;

    UPROPERTY()
    UPathNodeFinder* PathNodeFinder;

    UPROPERTY()
    UPiratesPlayerGrid* PiratesPlayerGrid;

    UPROPERTY()
    UGameLimitedTimeTaskManager* TaskManager;

    EPiratesGameStatus GameStatus;

    //UPROPERTY()
    //UPiratesGridTriggerManager* GridTriggerManager;

	UPROPERTY()
	UPiratesGridTypeManager* GridTypeManager;

    UPROPERTY()
    UAICoverPointsManager* AICoverPointsManager;

    UPROPERTY()
    UTemplateActorDataManager* TemplateActorManager;

	UPROPERTY()
    ULogReport* LogReport;
   
    UPROPERTY()
    UPiratesActorWeaponInhibitManager* PiratesActorWeaponInhibitManager;
    
    UPROPERTY()
    UAIDestructibleObjectManagerRoot* AIDestructibleObjectManager;

    UPROPERTY()
    UAIVehicleManager* AIVehicleManager;

    UPROPERTY()
    UAIOceanGridManagerRoot* AIOceanGridManager;

    UPROPERTY()
    UAISmokeManager* AISmokeManager;

    // lua 
protected:
    // 这里用宏编不过，只能注掉
//#if ENABLE_U4LUA
    UPROPERTY()
    UGameLuaRoot* LuaRoot;
//#else
    //UPROPERTY()
    //UGameLuaManager* GameLuaManager;
//#endif    

    FString LuaInitScriptName;
    FString LuaStartScriptName;
    FString LuaPathCacheFile;
    FString LuaGlobalTableDefineScriptName;    

    bool EnableGM;
    bool PreloadMap;
    uint64 LastSpawnActorFrame;
};
