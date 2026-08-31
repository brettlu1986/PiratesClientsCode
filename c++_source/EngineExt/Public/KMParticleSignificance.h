// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Particles/Emitter.h"
#include "Particles/ParticleSystemComponent.h"
#include "SignificanceManager.h"
#include "KMParticleSignificance.generated.h"

UCLASS()
class ENGINEEXT_API UKMParticleSignificance : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "ParticleSignificance")
	static void RegisterParticle(UParticleSystemComponent* Particle);

	UFUNCTION(BlueprintCallable, Category = "ParticleSignificance")
	static void UnRegisterParticle(UParticleSystemComponent* Particle);
	
	UFUNCTION(BlueprintPure, Category = "ParticleSignificance")
	static bool IsParticleRegistered(UParticleSystemComponent* Particle);

protected:
	static float ParticleSignificance(USignificanceManager::FManagedObjectInfo* Info, const FTransform& Tranform);
	static void ParticlePostSignificance(USignificanceManager::FManagedObjectInfo* Info, float OldSignificance, float Significance, bool bIsPendingUnregister);
};
