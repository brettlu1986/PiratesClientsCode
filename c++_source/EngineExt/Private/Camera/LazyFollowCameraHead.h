// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CameraHeadBase.h"
#include "LazyFollowCameraHead.generated.h"

/**
 * 
 */
UCLASS()
class ENGINEEXT_API ULazyFollowCameraHead : public UCameraHeadBase
{
	GENERATED_BODY()
	
public:
	ULazyFollowCameraHead();
	void UpdateCamera(float DeltaSeconds);

private:
	float TargetPitch;
	FVector LastPawnLocation = FVector::ZeroVector;
};
