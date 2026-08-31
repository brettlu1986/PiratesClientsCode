#pragma once

#include "Components/ActorComponent.h"
#include "ShipNavigationComponent.generated.h"


class APiratesShipPawn;
class UShipMovementComponent;
class FMapNavGridLayout;
struct FMapNavGridCost;
class FMapNavGridPathFinding;
class FMapNavGridAsyncPathFindingManager;
class FMapNavGridAsyncPathFindingFuture;

UCLASS(meta = (BlueprintSpawnableComponent), Blueprintable)
class COMMON_API UShipNavigationComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:

    virtual void BeginPlay() override;

    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

    virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

//public:
//
//    UPROPERTY(BlueprintReadWrite, EditAnywhere)
//    bool bEnableNavigation = true;

public:

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    bool FindPathSync(const FVector& DestLocation, TArray<FVector>& OutPath);

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    void FindPathAsync(const FVector& DestLocation);

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    void CancelAsyncPathFinding();

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    bool IsLocationReachable(const FVector& Location);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    bool IsLocationSafe(const FVector& Location);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    bool GetNearestReachableLocation(const FVector& InLocation, float Radius, FVector& OutLocation);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    bool GetNearestSafeLocation(const FVector& InLocation, float Radius, FVector& OutLocation);

private:

    APiratesShipPawn* ShipPawn;
    UShipMovementComponent* MovementComponent;

    bool bNavDataAcquired;
    FMapNavGridPathFinding* PathFinding;
    FMapNavGridLayout* GridLayout;
    FMapNavGridCost* GridCost;
    FMapNavGridAsyncPathFindingManager* AsyncPathFindingManager;
    FMapNavGridAsyncPathFindingFuture* AsyncPathFindingFuture;

    bool bNeedRetryAsyncPathFinding;
    FVector AsyncPathFindingRetryLocation;

private:

    bool AcquireNavData();
};