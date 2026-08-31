// Fill out your copyright notice in the Description page of Project Settings.

#include "KMChildActorComponent.h"
#include "EngineExt.h"

UKMChildActorComponent::UKMChildActorComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , LastActor(nullptr)
{
}

void UKMChildActorComponent::PostNetReceive()
{
    Super::PostNetReceive();
    VerifyChildActorReplication();
}

void UKMChildActorComponent::VerifyChildActorReplication()
{
    if (GetChildActor() != LastActor)
    {
        LastActor = GetChildActor();
        OnRepChildActor(LastActor);
    }
}

void UKMChildActorComponent::OnRepChildActor_Implementation(AActor* Actor)
{
}