#pragma once

#include "CoreMinimal.h"
#include "AIModule/Public/SimpleCellGrid.h"
#include "AIVehicle.h"
#include "AIVehicleManager.generated.h"

class AIVehiclePerIsland : public TSimpleCellGrid<FAIVehicleCell>
{
public:

    bool SetVehicleLocation(FAIVehicle* Vehicle, const FVector& Location);
};


UCLASS(config = Game, defaultconfig)
class COMMON_API UAIVehicleManager : public UObject
{
public:
    GENERATED_UCLASS_BODY()

    static const FString FileExtension;

    bool Init();
    bool Uninit();

    UFUNCTION()
    bool SetVehicleLocation(int32 InstanceId, const FVector& Location);

    UFUNCTION()
    bool RemoveVehicle(int32 InstanceId);

    FAIVehicle* GetVehicle(int32 InstanceId);

    UFUNCTION()
    void FindVisibleVehicle(APawn* Pawn, int32 IslandId, float SightDist, float SightFOV, UWorld* World, TArray<int32>& OutInstanceIds);

    UFUNCTION()
    void Dump();

protected:

    void OnPostLoadMap(UWorld* CurrentWorld)
    {
        if (CurrentWorld->IsServer())
        {
            FString WorldName = CurrentWorld->GetName();
            Load(WorldName);
        }
    }

    void OnWorldCleanUp(UWorld* CurrentWorld, bool bSessionEnded, bool bCleanupResources)
    {
        Unload();
    }

    void InitVehicleClass();

    UPROPERTY(config)
    FString  VehicleClassName;

    UPROPERTY()
    UClass* VehicleClass;

    bool Load(const FString& FilePath);
    void Unload();

    FDelegateHandle OnPostLoadMapHandle;
    FDelegateHandle OnWorldCleanUpHandle;

    typedef TMap<int32, TSharedPtr<AIVehiclePerIsland>> IslandMap;
    IslandMap Islands;

    typedef TMap<int32, TSharedPtr<FAIVehicle>> VehicleMap;
    VehicleMap Vehicles;

    bool bLoaded;
};