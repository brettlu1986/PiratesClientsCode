// Fill out your copyright notice in the Description page of Project Settings.

#include "KMCameraActor.h"
#include "EngineExt.h"
#include "CameraDefine.h"

void AKMCameraActor::PostActorCreated()
{
	Super::PostActorCreated();
	PrimaryActorTick.bCanEverTick = true;
}

void AKMCameraActor::BeginDestroy()
{
	Super::BeginDestroy();
}

void AKMCameraActor::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	if (CameraHeadDelegate)
	{
		CameraHeadDelegate->UpdateCamera(DeltaSeconds);
	}
}

void AKMCameraActor::BecomeViewTarget(class APlayerController* PC)
{
	Super::BecomeViewTarget(PC);
	SetActorTickEnabled(true);
	GetCameraComponent()->Activate();
}
void AKMCameraActor::EndViewTarget(class APlayerController* PC)
{
	Super::EndViewTarget(PC);
	SetActorTickEnabled(false);
	GetCameraComponent()->Deactivate();
};

void AKMCameraActor::SetCameraHeadDelegate(ICameraHeadDelegate *Delegate)
{
	CameraHeadDelegate = Delegate;
}