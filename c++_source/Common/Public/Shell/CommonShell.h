// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Shell/EngineExtShell.h"
#include "PiratesGameStatusDefine.h"
#include "CommonShell.generated.h"

class UDungeonCommonActorShell;
struct lua_State;

/**
* Expose interfaces of UGameCommon to Lua/Blueprint
*/
UCLASS(BlueprintType)
class COMMON_API UCommonShell : public UEngineExtShell
{
	GENERATED_UCLASS_BODY()
	
public:
    UFUNCTION(BlueprintPure, Category = "Common", meta = (WorldContext = "WorldContextObject", DisplayName = "GetCommonShell"))
    static UCommonShell* GetCommon(UObject* WorldContextObject);

    virtual void Init() override;
    virtual void Shutdown() override;

    UFUNCTION(BlueprintPure, Category = "Common")
    class UInputManager* GetInputManager();

    UFUNCTION(BlueprintPure, Category = "Common")
    class UGameDelegateManager* GetGameDelegateManager();

    UFUNCTION()
    class UHttpHelper* GetHttpHelper();

    UFUNCTION()
    class UOceanNavGridManager* GetOceanNavGridManager();

    UFUNCTION()
    class UShipMovementComponent* GetShipMovementComponent(AActor* Actor);

    UFUNCTION()
    class URPCNetworkManager* GetRPCNetworkManager();

    UFUNCTION()
    class UCommonActorShell* GetCommonActorShell() { return CommonActorShell; }

    UFUNCTION(BlueprintCallable, Category = "Common")
    class UPiratesAreaTriggerManager* GetAreaTriggerManager();

    UFUNCTION(BlueprintPure, Category = "Common")
    class UAICoverPointsManager* GetAICoverPointsManager();

    UFUNCTION(BlueprintPure, Category = "Common")
    class UAIDestructibleObjectManagerRoot* GetAIDestructibleObjectManager();

    UFUNCTION()
    class UPiratesActorTriggerGroupManager* GetActorTriggerGroupManager();
    UFUNCTION(BlueprintCallable, Category = "Common")
    class UPathNodeFinder* GetPathNodeFinder();

    UFUNCTION(BlueprintCallable, Category = "Common")
    void SetGameStatus(EPiratesGameStatus Status);

    UFUNCTION(BlueprintPure, Category = "Common")
    const EPiratesGameStatus GetGameStatus() const;

    UFUNCTION()
    float GetConnectionTimeout();

    UFUNCTION()
    class UPiratesPlayerGrid* GetPiratesPlayerGrid();
    UFUNCTION()
    void RequestExit(bool Force);

    //UFUNCTION()
    //class UPiratesGridTriggerManager* GetGridTriggerManager();

    UFUNCTION(BlueprintPure, Category = "Common")
	class UPiratesGridTypeManager* GetGridTypeManager();

    UFUNCTION(BlueprintPure, Category = "Common")
    class UTemplateActorDataManager* GetTemplateActorDataManager();

    UFUNCTION(BlueprintPure, Category = "Common")
    class UAIVehicleManager* GetAIVehicleManager();

    UFUNCTION(BlueprintPure, Category = "Common")
    class UAIOceanGridManagerRoot* GetAIOceanGridManager();

    UFUNCTION(BlueprintPure, Category = "Common")
    class UAISmokeManager* GetAISmokeManager();

    UFUNCTION()
    void SetTemplateActorDataManager(class UTemplateActorDataManager* Manager);

    UFUNCTION()
    static UObject* CreateNewTestObject(int PropertyNum, int FunctionNum, int FunctionInputParamNum, int FunctionOutputParamNum);

    UFUNCTION()
    bool IsGMEnabled();

    UFUNCTION()
    bool IsPreloadMap() const;

    UFUNCTION(BlueprintPure, Category = "Common")
    class UU4LuaLib* GetLuaLib();

    UFUNCTION()
    class ULogReport* GetLogReport();

    UFUNCTION()
    class UPiratesActorWeaponInhibitManager* GetWeaponInhibitManager();

    UFUNCTION()
    static void SetRemoteLuaRepository(const FString& URL);

    UFUNCTION()
    static void SetNetLogEnabled(bool Enabled);

    UFUNCTION(BlueprintCallable)
    void RecordSpawnActorFrameCounter();

protected:
    UPROPERTY()
    UCommonActorShell* CommonActorShell;

    EPiratesGameStatus GameStatus;
};
