// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/BoxComponent.h"
#include "Components/ShipMovementComponent.h"
#include "ShipPartForDamage.generated.h"

UENUM(Blueprintable)
enum class ESPFDEnabledState : uint8
{
	Any,
	FullSail,
	HalfSail
};

/**
 * 
 */
UCLASS(ClassGroup = Ship, meta = (BlueprintSpawnableComponent), Blueprintable)
class COMMON_API UShipPartForDamage : public UBoxComponent
{
	GENERATED_BODY()
	
public:

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString SPFDName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	ESPFDEnabledState EnabledState;
};
