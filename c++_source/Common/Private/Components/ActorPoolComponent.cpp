// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/ActorPoolComponent.h"
#include "Common.h"
#include "Components/ActorPoolItemInterface.h"

void UActorPoolComponent::GetActorInPool(TSubclassOf<AActor> ActorClass, AActor* NewOwner, APawn* NewInstigator, FTransform NewTransform, AActor*& OutActor)
{
//    ReturnIfNullptr(ActorClass.Get());

    if (!ActorPool.Contains(ActorClass->GetName()))
    {
        ActorPool.Add(ActorClass->GetName());
    }

    FTypedActorPool* TypedActorPool = ActorPool.Find(ActorClass->GetName());
    AActor* CurActor = nullptr;
    // Use actor in the pool.
    for (int i = TypedActorPool->FreeActors.Num() - 1; i >= 0; i--)
    {
        CurActor = TypedActorPool->FreeActors[i];
        if (IsValid(CurActor))
        {
            CurActor->SetOwner(NewOwner);
            CurActor->SetInstigator(NewInstigator);
            CurActor->SetActorTransform(NewTransform);

            TypedActorPool->FreeActors.RemoveAt(i);

            IActorPoolItemInterface::Execute_OnActorLeavePool(CurActor);

			OutActor = CurActor;
            return;
        }
        else
        {
            TypedActorPool->FreeActors.RemoveAt(i);
        }
    }

    // When we have to create a new actor.
    UWorld* world = this->GetWorld();
    if (!IsValid(world))
	{
		OutActor = nullptr;
        return;
    }

    FActorSpawnParameters params;
    params.Owner = NewOwner;
    params.Instigator = NewInstigator;
    params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
    FVector Loc = NewTransform.GetLocation();
    FRotator Rot = NewTransform.Rotator();
    CurActor = world->SpawnActor(ActorClass, &Loc, &Rot, params);
    CurActor->OnEndPlay.AddDynamic(this, &UActorPoolComponent::OnFreeActorEndPlay);

    IActorPoolItemInterface::Execute_OnActorLeavePool(CurActor);

	OutActor = CurActor;
    return;
}

void UActorPoolComponent::ReturnActorToPool(AActor *Actor)
{
//    ReturnIfNullptr(Actor);

    if (!ActorPool.Contains(Actor->GetClass()->GetName()))
    {
        return;
    }

    FTypedActorPool* TypedActorPool = ActorPool.Find(Actor->GetClass()->GetName());
    TypedActorPool->FreeActors.AddUnique(Actor);

    IActorPoolItemInterface::Execute_OnActorReturnedToPool(Actor);
}

FString UActorPoolComponent::GetDebugString()
{
    FString result;
    TArray<FString> keys;
    ActorPool.GenerateKeyArray(keys);
    for (FString ActorClassName : keys)
    {
        FTypedActorPool* TypedActorPool = ActorPool.Find(ActorClassName);

        TArray<FStringFormatArg> Args;
        Args.Add(ActorClassName);
        Args.Add(TypedActorPool->FreeActors.Num());

        result += FString::Format(TEXT("{0} Available={1}\n"), Args);
    }

    return result;
}

void UActorPoolComponent::OnFreeActorEndPlay(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	if (!ActorPool.Contains(Actor->GetClass()->GetName()))
	{
		return;
	}

	FTypedActorPool* TypedActorPool = ActorPool.Find(Actor->GetClass()->GetName());
	TypedActorPool->FreeActors.Remove(Actor);
}