// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ChildActorComponent.h"
#include "KMChildActorComponent.generated.h"

/**
 * 
 */
UCLASS(Blueprintable)
class ENGINEEXT_API UKMChildActorComponent : public UChildActorComponent
{
	GENERATED_UCLASS_BODY()
	
public:
    virtual void PostNetReceive() override;
	
protected:
    UFUNCTION(BlueprintNativeEvent)
    void OnRepChildActor(AActor* Actor);

private:
    void VerifyChildActorReplication();

private:
    AActor* LastActor;
};
