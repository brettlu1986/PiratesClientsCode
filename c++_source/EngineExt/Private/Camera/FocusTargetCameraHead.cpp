 // Fill out your copyright notice in the Description page of Project Settings.

#include "FocusTargetCameraHead.h"
#include "EngineExt.h"

namespace FocusTargetCameraHeadConst
{ 
	const static FRotator InitCameraArmRotation = FRotator(-15, 0, 0);
	const static float InitCameraArmLength = 600;
	const static float DistanceToGround = 88 + InitCameraArmLength * FMath::Sin(FMath::DegreesToRadians(-InitCameraArmRotation.Pitch));
	const static float CAMERA_FOCUS_OFFSET = 100.0f;
};

UFocusTargetCameraHead::UFocusTargetCameraHead() : Super()
{
	DistanceToGround = FocusTargetCameraHeadConst::DistanceToGround;
	TargetArmLength = FocusTargetCameraHeadConst::InitCameraArmLength;
	InitCameraArmRotation = FocusTargetCameraHeadConst::InitCameraArmRotation;
}

void UFocusTargetCameraHead::UpdateCamera(float DeltaSeconds)
{
	Super::UpdateCamera(DeltaSeconds);
	if (!AttachedActor.IsValid() || !AttachedActor->IsValidLowLevel())
	{
		return;
	}
	if (!FocusActor.IsValid() || !FocusActor->IsValidLowLevel())
	{
		return;
	}

	FVector PawnLocation = GetFixedAttachLocation();
	FRotator PawnRotation = AttachedActor->GetActorRotation();
	if(NeedResetCameraLocRot)
	{
		ResetCameraToDefaultLocation();
		TargetPitch = TargetCameraRotation.Pitch;
	}
	else
	{
		if (!CameraLocWasFrozen)
		{
			FRotator DirectRotation;
			FVector DirectVec;

			FVector FocusLocation = FocusActor->GetActorLocation();
			DirectVec = FocusLocation - PawnLocation;
			DirectVec.Z = 0;
			DirectRotation = (DirectVec).Rotation();

			TargetCameraRotation.Yaw = DirectRotation.Yaw;
			FVector CameraHeading = TargetCameraRotation.Vector().GetUnsafeNormal() * CameraArmLength;
			TargetCameraLocation = PawnLocation - CameraHeading;

			TargetPitch = AdapterPitchToGround();
			InterpCameraParamTotarget(DeltaSeconds);
			InterpToTargetPitch(DeltaSeconds, TargetPitch);
		}
		else
		{
			TargetCameraRotation = (PawnLocation - TargetCameraLocation).Rotation();
		}
		InterpCameraToTarget(TargetCameraLocation, TargetCameraRotation, DeltaSeconds);
	}
}

bool UFocusTargetCameraHead::IsAvailable()
{
	return FocusActor.IsValid() && FocusActor->IsValidLowLevel();
}

void UFocusTargetCameraHead::SetFocusActor(AActor *Actor)
{
	if (Actor != nullptr && Actor->IsValidLowLevel())
	{
		FocusActor = Actor;
	}
	else
	{
		FocusActor = nullptr;
	}
}