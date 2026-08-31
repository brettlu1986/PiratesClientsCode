#pragma once
#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "VehicleDetectComponent.generated.h"

UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UVehicleDetectComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
   
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

    UFUNCTION(BlueprintPure, Category = "VehicleDetect")
    const TArray<int32>& GetVehicles() const;

    UPROPERTY(Category = "VehicleDetect", EditAnywhere, BlueprintReadWrite)
    float SightDistance;

    UPROPERTY(Category = "VehicleDetect", EditAnywhere, BlueprintReadWrite)
    float SightFOV;

    UPROPERTY(Category = "VehicleDetect", EditAnywhere, BlueprintReadWrite)
    float RefreshInterval;

    UFUNCTION(BlueprintCallable, Category = "VehicleDetect")
    void SetEnable(bool bEnable);

private:
    void UpdateItems();

    float TimeToNextRefresh;
    TArray<int32>  FoundVehicles;
};
