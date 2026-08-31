// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/CapsuleComponent.h"
#include "KMCapsuleComponent.generated.h"

/**
 * 
 */
UCLASS()
class ENGINEEXT_API UKMCapsuleComponent : public UCapsuleComponent
{
	GENERATED_BODY()
	
public:
	UKMCapsuleComponent(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());
	
protected:
	//virtual bool MoveComponentImpl(const FVector& Delta, const FQuat& NewRotation, bool bSweep, FHitResult* Hit = NULL, EMoveComponentFlags MoveFlags = MOVECOMP_NoFlags, ETeleportType Teleport = ETeleportType::None) override;
};
