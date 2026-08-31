// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Camera/CameraActor.h"
#include "KMCameraActor.generated.h"

/**
 * 
 */
class ICameraHeadDelegate;
UCLASS()
class ENGINEEXT_API AKMCameraActor : public ACameraActor
{
	GENERATED_BODY()
public:
	virtual void PostActorCreated() override;
	virtual void BeginDestroy() override;
	virtual void Tick(float DeltaSeconds) override;
	virtual void BecomeViewTarget(class APlayerController* PC) override;
	virtual void EndViewTarget(class APlayerController* PC) override;

	void SetCameraHeadDelegate(ICameraHeadDelegate *Delegate);

private:
	ICameraHeadDelegate *CameraHeadDelegate;
};
