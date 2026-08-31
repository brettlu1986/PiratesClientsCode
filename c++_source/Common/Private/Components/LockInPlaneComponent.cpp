// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/LockInPlaneComponent.h"
#include "Common.h"

// Called when the game starts
void ULockInPlaneComponent::BeginPlay()
{
	Super::BeginPlay();

    PrimaryComponentTick.bCanEverTick = true;
    this->SetTickGroup(TG_PostPhysics);
}


// Called every frame
void ULockInPlaneComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    for (auto Pair : LockedComponents)
    {
        USceneComponent* Component = Pair.Key;
        if (IsValid(Component))
        {
            FVector Location = Pair.Key->GetComponentLocation();
            Location.Z = Pair.Value;

            FRotator Rotation = Component->GetComponentRotation();
            Rotation.Roll = 0;
            Rotation.Pitch = 0;

            Component->SetWorldLocationAndRotation(Location, Rotation);
        }
    }
}

void ULockInPlaneComponent::AddComponent(USceneComponent* Component, float LockLocationZ)
{
    if (Component)
    {
        LockedComponents.Add(Component, LockLocationZ);
    }
}

void ULockInPlaneComponent::RemoveComponent(USceneComponent* Component)
{
    if (Component)
    {
        LockedComponents.Remove(Component);
    }
}
