// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"

#include "ActorPoolComponent.generated.h"


struct FTypedActorPool
{
    TArray<AActor*> FreeActors;
};


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class COMMON_API UActorPoolComponent : public UActorComponent
{
	GENERATED_BODY()

public:

    UFUNCTION(BlueprintCallable, Category = "Pooling", meta = (DeterminesOutputType = "ActorClass", DynamicOutputParam = "OutActor"))
    void GetActorInPool(TSubclassOf<AActor> ActorClass, AActor* NewOwner, APawn* NewInstigator, FTransform NewTransform, AActor*& OutActor);

    UFUNCTION(BlueprintCallable, Category = "Pooling")
    void ReturnActorToPool(AActor *Actor);

    UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Pooling")
    FString GetDebugString();

protected:
	UFUNCTION()
	void OnFreeActorEndPlay(AActor* Actor, EEndPlayReason::Type EndPlayReason);

private:
    TMap<FString, FTypedActorPool> ActorPool;
};
