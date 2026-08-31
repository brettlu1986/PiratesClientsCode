// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/MovementComponent.h"
#include "CustomMovementComponentEx.generated.h"

/**
 * 
 */
UCLASS(meta = (BlueprintSpawnableComponent), Blueprintable)
class COMMON_API UCustomMovementComponentEx : public UMovementComponent
{
	GENERATED_BODY()
	
public:
    // Override this to implement custom movement.
    UFUNCTION(BlueprintNativeEvent)
    void ComputeMovement(float DeltaTime, FVector& PositionDelta, FRotator& NewRotation);

    UFUNCTION(BlueprintCallable)
    bool AlongSurface(const FVector& Direction, float WalkableFloorAngle);
public:
    virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;


};
