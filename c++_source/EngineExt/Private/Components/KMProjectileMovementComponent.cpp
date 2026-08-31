// Fill out your copyright notice in the Description page of Project Settings.

#include "KMProjectileMovementComponent.h"
#include "EngineExt.h"
#include "KMCharacter.h"


UKMProjectileMovementComponent::UKMProjectileMovementComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
    MaxRange = 0;
    CheckSeaLevel = true;
}

void UKMProjectileMovementComponent::SetUpdatedComponent(USceneComponent* NewUpdatedComponent)
{
    Super::SetUpdatedComponent(NewUpdatedComponent);
    if(NewUpdatedComponent)
        OriginalLocation = NewUpdatedComponent->GetComponentLocation();
}

void UKMProjectileMovementComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    if (CheckSeaLevel && UpdatedComponent && UpdatedComponent->GetComponentLocation().Z < 0)
    {
        OnIntoWater.Broadcast();
    }

    if (MaxRange > 0 && UpdatedComponent)
    {
        FVector CurrentLocation = UpdatedComponent->GetComponentLocation();
        float Length = (CurrentLocation - OriginalLocation).Size();
        if (Length > MaxRange)
        {
            OnOutOfRange.Broadcast();
        }
    }
}

