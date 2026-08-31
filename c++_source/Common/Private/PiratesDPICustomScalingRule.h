// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DPICustomScalingRule.h"
#include "PiratesDPICustomScalingRule.generated.h"

/**
 * 
 */
UCLASS()
class UPiratesDPICustomScalingRule : public UDPICustomScalingRule
{
	GENERATED_BODY()
	

public:

	/**
	* Return the scale to use given the size of the viewport.
	* @param Size The size of the viewport.
	* @return The Scale to apply to the entire UI.
	*/
	virtual float GetDPIScaleBasedOnSize(FIntPoint Size) const override;
	
	
};
