// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Particles/EmitterCameraLensEffectBase.h"
#include "KMEmitterCameraLensEffectBase.generated.h"

/**
 * 
 */
UCLASS()
class ENGINEEXT_API AKMEmitterCameraLensEffectBase : public AEmitterCameraLensEffectBase
{
	GENERATED_UCLASS_BODY()

public:
	virtual void BeginPlay();

protected:
	void ReCalculateReleativeTransform();
public:
	UPROPERTY(EditDefaultsOnly, Category = EmitterCameraLensEffectBase)
    float StandardAspectRatio;

	UPROPERTY(EditDefaultsOnly, Category = EmitterCameraLensEffectBase)
    float StandardDistance;

	UPROPERTY(EditDefaultsOnly, Category = EmitterCameraLensEffectBase)
    float StandardUnitDistance;
	
};
