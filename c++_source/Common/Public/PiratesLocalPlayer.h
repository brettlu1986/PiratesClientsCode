// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Engine/LocalPlayer.h"
#include "PiratesLocalPlayer.generated.h"

/**
 * 
 */
UCLASS()
class COMMON_API UPiratesLocalPlayer : public ULocalPlayer
{
	GENERATED_UCLASS_BODY()

public:
    bool InSmoothTravel() { return IsSmoothTravel; }
    void SetSmoothTravel(bool SeamlessTravel) { IsSmoothTravel = SeamlessTravel; }

    FVector& GetTravelSaveLocation() { return TravelSaveLocation; };
    FRotator& GetTravelSaveRotator() { return TravelSaveRotation; };
    FTransform& GetTravelSaveTransform() { return TravelTargetTransform; };

protected:
    bool IsSmoothTravel;

    FVector TravelSaveLocation;
    FRotator TravelSaveRotation;
    FTransform TravelTargetTransform;
};
