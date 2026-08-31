// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/CapsuleComponent.h"
#include "KMCylinderComponent.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UKMCylinderComponent : public UCapsuleComponent
{
    GENERATED_UCLASS_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    float Deviation;
    UPROPERTY(EditAnywhere, BlueprintReadOnly)
    bool IsUseDefaultCollision;

    UFUNCTION(BlueprintCallable, Category = "Components|Cylinder")
    void SetSize(float Radius, bool bUpdateOverlaps = true);
    UFUNCTION(BlueprintCallable, Category = "Components|Cylinder")
    void SetEnabled(bool bEnabled);
    UFUNCTION(BlueprintCallable)
    void SetDeviation(float Value);

    UFUNCTION(BlueprintCallable)
    void OnActorBeginOverlap(AActor* Actor);
    UFUNCTION(BlueprintCallable)
    void OnActorEndOverlap(AActor* Actor);
    UFUNCTION(BlueprintCallable)
    void SetUseDefaultCollision(bool bValue);

    virtual void OnComponentDestroyed(bool bDestroyingHierarchy) override;
    virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;

//     virtual void BeginComponentOverlap(const FOverlapInfo& OtherOverlap, bool bDoNotifies) override;
//     virtual void EndComponentOverlap(const FOverlapInfo& OtherOverlap, bool bDoNotifies = true, bool bSkipNotifySelf = false) override;
//     virtual bool UpdateOverlapsImpl(TArray<FOverlapInfo> const* NewPendingOverlaps = nullptr, bool bDoNotifies = true, const TArray<FOverlapInfo>* OverlapsAtEndLocation = nullptr) override;

private:
    bool IsInCylinderBounds(AActor* Actor);
    bool AddEnterTriggerActor(AActor* Actor, bool bIsInBounds);
    bool RemoveEnterTriggerActor(AActor* Actor);
    bool VerifyInCylinderBounds(AActor* Actor);

    void ClearEnteredTriggerActor();

    TMap<TWeakObjectPtr<AActor>, bool> EnteredTriggerActors;
};
