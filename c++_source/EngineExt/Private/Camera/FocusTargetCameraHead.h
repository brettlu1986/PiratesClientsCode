// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CameraHeadBase.h"
#include "FocusTargetCameraHead.generated.h"

/**
 * 
 */
UCLASS()
class ENGINEEXT_API UFocusTargetCameraHead : public UCameraHeadBase
{
	GENERATED_BODY()
	
public:
	UFocusTargetCameraHead();

	virtual void UpdateCamera(float DeltaSeconds) override;
	virtual bool IsAvailable() override;

	void SetFocusActor(AActor *Actor);

private:
	float TargetPitch;
	TWeakObjectPtr<AActor> FocusActor = nullptr;
};
