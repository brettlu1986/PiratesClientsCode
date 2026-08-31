// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "LockInPlaneComponent.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class COMMON_API ULockInPlaneComponent : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

    UFUNCTION(BlueprintCallable, Category="Game")
    void AddComponent(USceneComponent* Component, float LockLocationZ);

    UFUNCTION(BlueprintCallable, Category = "Game")
    void RemoveComponent(USceneComponent* Component);

protected:
    // Called when the game starts
    virtual void BeginPlay() override;

private:
        TMap<USceneComponent*, float> LockedComponents;
};
