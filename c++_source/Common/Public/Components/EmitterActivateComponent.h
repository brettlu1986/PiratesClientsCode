// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "EmitterActivateComponent.generated.h"

UCLASS()
class COMMON_API UEmitterActivateComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	void AddEmitterToWaitActivateMap(UParticleSystemComponent* ParticleSystemComponent, bool bAutoDestroy);

	void RemoveEmitterFromWaitActivateMap(UParticleSystemComponent* ParticleSystemComponent);

	void ActivateEmitter();

	bool IsEmitterInActivateMap(UParticleSystemComponent* ParticleSystemComponent);

private:
	UPROPERTY()
	TMap<UParticleSystemComponent*, bool> WaitActivateMap;
};
