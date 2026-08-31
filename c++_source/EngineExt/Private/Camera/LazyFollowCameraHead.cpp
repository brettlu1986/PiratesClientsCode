// Fill out your copyright notice in the Description page of Project Settings.

#include "LazyFollowCameraHead.h"
#include "EngineExt.h"
#include "KMCameraActor.h"

namespace LazyFollowCameraHeadConst
{
	const static FRotator InitCameraArmRotation = FRotator(8, 0, 0);
	const static float InitCameraArmLength = 300;
	const static float DistanceToGround = 88 + InitCameraArmLength * FMath::Sin(FMath::DegreesToRadians(-InitCameraArmRotation.Pitch));
	const static float LOCATION_FLOAT_TOLERANCE = 1;
};

ULazyFollowCameraHead::ULazyFollowCameraHead()
{
	DistanceToGround = LazyFollowCameraHeadConst::DistanceToGround;
	TargetArmLength = LazyFollowCameraHeadConst::InitCameraArmLength;
	InitCameraArmRotation = LazyFollowCameraHeadConst::InitCameraArmRotation;
}

void ULazyFollowCameraHead::UpdateCamera(float DeltaSeconds)
{
	Super::UpdateCamera(DeltaSeconds);
	if (!AttachedActor.IsValid() || !AttachedActor->IsValidLowLevel())
	{
		return;
	}

	FVector PawnLocation = GetFixedAttachLocation();
	FRotator PawnRotation = AttachedActor->GetActorRotation();
	if (NeedResetCameraLocRot)
	{
		ResetCameraToDefaultLocation();
		TargetPitch = TargetCameraRotation.Pitch;
	}
	FVector CameraLocation = TargetCameraLocation; // 以目标位置为准，而不是当前摄像机实际位置，方便调节Lag延迟
	FVector CameraHeading = PawnLocation - CameraLocation; // 摄像机的位置朝向Pawn当前位置的向量，但是视口焦点未必对准Pawn的位置
	FVector PawnLocationOffset = PawnLocation - LastPawnLocation;
	if (CameraHeading.IsNearlyZero(LazyFollowCameraHeadConst::LOCATION_FLOAT_TOLERANCE))
	{
		NeedResetCameraLocRot = true;
	}
	else
	{
		if (!PawnLocationOffset.IsNearlyZero(LazyFollowCameraHeadConst::LOCATION_FLOAT_TOLERANCE) || NeedUpdateTargetCameraLocRot)
		{
			NeedUpdateTargetCameraLocRot = false;
			InterpCameraParamTotarget(DeltaSeconds);
			if (!CameraLocWasFrozen)
			{
				FVector CameraHeadingNormal = CameraHeading.GetUnsafeNormal();
				CameraHeading = CameraHeadingNormal * CameraArmLength; //固定摄影机到目标的距离

				FVector NewCameraLocation = PawnLocation - CameraHeading; //得出新位置
				TargetCameraLocation = NewCameraLocation;
				TargetCameraRotation = CameraHeading.Rotation();
				TargetPitch = AdapterPitchToGround();
			}
			else
			{
				TargetCameraRotation = CameraHeading.Rotation();
			}
			NeedUpdateCameraLocRot = true;
		}
		if (!CameraLocWasFrozen)
		{
			InterpToTargetPitch(DeltaSeconds, TargetPitch);
		}
		if (NeedUpdateCameraLocRot)
		{
			InterpCameraToTarget(TargetCameraLocation, TargetCameraRotation, DeltaSeconds);
		}
	}
	LastPawnLocation = PawnLocation;
}
