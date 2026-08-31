#pragma once
#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "AI/OceanGrid/AIOceanGridManagerRoot.h"
#include "OceanGridDetectComponent.generated.h"




UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UOceanGridDetectComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
   
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

    UFUNCTION(BlueprintPure, Category = "TorpedoDetect")
    int32 GetNumTopedos() const
    {
        return Torpedos.Num();
    }

    UPROPERTY(Category = "VehicleDetect", EditAnywhere, BlueprintReadWrite)
    float SightDistance;

    UPROPERTY(Category = "VehicleDetect", EditAnywhere, BlueprintReadWrite)
    float SightFOV;

    UPROPERTY(Category = "VehicleDetect", EditAnywhere, BlueprintReadWrite)
    float RefreshInterval;

    UFUNCTION(BlueprintCallable, Category = "OceanGridDetect")
    void SetEnable(bool bEnable);

    UFUNCTION(BlueprintPure, Category = "TorpedoDetect")
    AActor* GetTopedoInfo(int32 Index) const
    {
        check(Index < Torpedos.Num());
        if (Torpedos[Index].IsValid())
        {
            return Torpedos[Index].Get();
        }
        return nullptr;
    }

private:
    void UpdateItems();

    float TimeToNextRefresh;
    TArray<TWeakObjectPtr<AActor>>  Torpedos;
};
