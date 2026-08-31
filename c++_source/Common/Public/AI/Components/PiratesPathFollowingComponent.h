#pragma once
#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Navigation/PathFollowingComponent.h"
#include "PiratesPathFollowingComponent.generated.h"



UCLASS()
class COMMON_API UPiratesPathFollowingComponent : public UPathFollowingComponent
{
    GENERATED_UCLASS_BODY()

   
public:
    DECLARE_DYNAMIC_DELEGATE(FOnResolveBlockedDelegate);

    virtual void OnPathFinished(const FPathFollowingResult& Result) override;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "PathFollowing")
    FOnResolveBlockedDelegate   OnResolveBlocked;
    

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "PathFollowing")
    float MaxPorcessBlockTime;

    UFUNCTION(BlueprintCallable, Category = "PathFollowing")
    void SetBlockParams(float DistanceThreshold, float Interval, int32 NumSamples);

private:
    float PorcessingBlockStartTime;
};
