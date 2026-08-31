// Fill out your copyright notice in the Description page of Project Settings.

#include "CameraHeadBase.h"
#include "EngineExt.h"
#include "KMCameraActor.h"

namespace CameraHeadBaseConst
{
	const static float CAMERA_LOCATION_RESUME_SPEED = 6.0f;
	const static float CAMERA_LOCATION_Z_RESUME_SPEED = 8.0f;
	const static float CAMERA_ROTATION_RESUME_SPEED = 4.0f;
	const static float LOCATION_FLOAT_TOLERANCE = 1;
	const static float ROTATION_FLOAT_TOLERANCE = 0.1;
	const static float HighCameraArmPitch = -70;
	const static float LowCameraArmPitch = 30;
	const static float CameraPitchResumeSpeed = 60;
	const static float ArmLengthResumeSpeed = 2.0f;
};

UCameraHeadBase::UCameraHeadBase() :
Super(),
CameraLocationResumeSpeed(CameraHeadBaseConst::CAMERA_LOCATION_RESUME_SPEED),
CameraRotationResumeSpeed(CameraHeadBaseConst::CAMERA_ROTATION_RESUME_SPEED) {}

inline static float valid_pitch(float Pitch)
{
	if (Pitch < CameraHeadBaseConst::HighCameraArmPitch)
	{
		return CameraHeadBaseConst::HighCameraArmPitch;
	}
	if (Pitch > CameraHeadBaseConst::LowCameraArmPitch)
	{
		return CameraHeadBaseConst::LowCameraArmPitch;
	}
	return Pitch;
}

inline static float cal_pitch_of_camera(float PawnZ, float CameraZ, float Radius)
{
	float Pitch = FMath::Asin((PawnZ - CameraZ) / Radius);
	Pitch = FMath::RadiansToDegrees(Pitch);
	Pitch = valid_pitch(Pitch);
	return Pitch;
}

void UCameraHeadBase::SetCameraActor(AKMCameraActor *Actor)
{
	if (Actor != nullptr && Actor->IsValidLowLevel())
	{
		CameraActor = Actor;
		NeedUpdateCameraLocRot = true;
	}
	else
	{
		CameraActor = nullptr;
	}
}

void UCameraHeadBase::UpdateCamera(float DeltaSeconds)
{

}

bool UCameraHeadBase::IsAvailable()
{
	return true;
}

void UCameraHeadBase::ResetCameraLocRot()
{
	NeedResetCameraLocRot = true;
}

FVector UCameraHeadBase::GetCameraLocation()
{
	FVector RetLocation = FVector::ZeroVector;
	if (CameraActor.IsValid() && CameraActor->IsValidLowLevel())
	{
		RetLocation = CameraActor->GetActorLocation();
	}
	return RetLocation;
}

bool UCameraHeadBase::GetCameraLocationAndRotation(FVector &Location, FRotator &Rotation)
{
    if (CameraActor.IsValid() && CameraActor->IsValidLowLevel())
    {
        Location = CameraActor->GetActorLocation();
        Rotation = CameraActor->GetActorRotation();
        
        return true;
    }
    
    return false;
}

void UCameraHeadBase::SetCameraLocation(const FVector &Location)
{
	if (CameraActor.IsValid() && CameraActor->IsValidLowLevel())
	{
		CameraActor->SetActorLocation(Location);
	}
}

void UCameraHeadBase::SetCameraRotation(const FRotator &Rotation)
{
	if (CameraActor.IsValid() && CameraActor->IsValidLowLevel())
	{
		CameraActor->SetActorRotation(Rotation);
	}
}

void UCameraHeadBase::SetCameraLocationAndRotation(const FVector &Location, const FRotator &Rotation)
{
	if (CameraActor.IsValid() && CameraActor->IsValidLowLevel())
	{
		CameraActor->SetActorLocationAndRotation(Location, Rotation);
	}
}

void UCameraHeadBase::ResetCameraToDefaultLocation()
{
	NeedResetCameraLocRot = false;
	CameraArmLength = TargetArmLength;
	AttachedLocationOffset = TargetLocationOffset;
	RecaculateDistanceToGround();
	FVector NewCameraLocation = FVector::ZeroVector;
	FVector AttachActorLocation = GetFixedAttachLocation();
	NewCameraLocation.X = CameraArmLength;
	FRotator ArmRotationWithPawn = AttachedActor->GetActorRotation() + InitCameraArmRotation;
	NewCameraLocation = -ArmRotationWithPawn.RotateVector(NewCameraLocation);
	NewCameraLocation += AttachActorLocation;
	TargetCameraLocation = NewCameraLocation;
	TargetCameraRotation = ArmRotationWithPawn;
	SetCameraLocationAndRotation(TargetCameraLocation, TargetCameraRotation);
}

void UCameraHeadBase::InterpCameraToTarget(const FVector &TargetLocation, const FRotator &TargetRotation, float DeltaSeconds)
{
	if (!CameraActor.IsValid() || !CameraActor->IsValidLowLevel())
	{
		return;
	}

	FVector CameraLocation = CameraActor->GetActorLocation();
	FRotator CameraRotation = CameraActor->GetActorRotation();
	bool NeedSetCameraLocation = false;
	bool NeedSetCameraRotation = false;
	FVector NewCameraLocation = CameraLocation;
	FRotator NewCameraRotation = CameraRotation;

	if (!CameraLocation.Equals(TargetLocation, CameraHeadBaseConst::LOCATION_FLOAT_TOLERANCE))
	{
		NewCameraLocation = FMath::VInterpTo(CameraLocation, TargetLocation, DeltaSeconds, CameraLocationResumeSpeed);
		NewCameraLocation.Z = FMath::FInterpTo(CameraLocation.Z, TargetLocation.Z, DeltaSeconds, CameraHeadBaseConst::CAMERA_LOCATION_Z_RESUME_SPEED);
		NeedSetCameraLocation = true;
	}

	if (!CameraRotation.Equals(TargetRotation, CameraHeadBaseConst::ROTATION_FLOAT_TOLERANCE))
	{
		NewCameraRotation = FMath::RInterpTo(CameraRotation, TargetRotation, DeltaSeconds, CameraRotationResumeSpeed);
		NeedSetCameraRotation = true;
	}

	if (NeedSetCameraLocation && NeedSetCameraRotation && !RotateManually)
	{
		CameraActor->SetActorLocationAndRotation(NewCameraLocation, NewCameraRotation);
	}
	else if (NeedSetCameraLocation)
	{
		CameraActor->SetActorLocation(NewCameraLocation);
	}
	else if (NeedSetCameraRotation && !RotateManually)
	{
		CameraActor->SetActorRotation(NewCameraRotation);
	}
	else
	{
		NeedUpdateCameraLocRot = false;
	}
}

void UCameraHeadBase::InterpCameraParamTotarget(float DeltaSeconds)
{
	bool NeedRecaculate = false;
	if (!FMath::IsNearlyEqual(CameraArmLength, TargetArmLength, 0.5f))
	{
		CameraArmLength = FMath::FInterpTo(CameraArmLength, TargetArmLength, DeltaSeconds, CameraHeadBaseConst::ArmLengthResumeSpeed);
		NeedRecaculate = true;
	}
	if (!TargetLocationOffset.Equals(AttachedLocationOffset, 0.5f))
	{
		AttachedLocationOffset = FMath::VInterpTo(AttachedLocationOffset, TargetLocationOffset, DeltaSeconds, 1.0f);
		NeedRecaculate = true;
	}
	if (NeedRecaculate)
	{
		RecaculateDistanceToGround();
	}
}

void UCameraHeadBase::SetRotationManually(bool Manual)
{
	RotateManually = Manual;
}

void UCameraHeadBase::RotateCameraManually(const FRotator &RotationOffset)
{
	if (CameraActor.IsValid() && CameraActor->IsValidLowLevel())
	{
		CameraActor->GetCameraComponent()->AddRelativeRotation(RotationOffset);
	}
}

void UCameraHeadBase::AttachToActor(AActor *Actor)
{
	if (Actor != nullptr && Actor->IsValidLowLevel())
	{
		AttachedActor = Actor;
		NeedUpdateCameraLocRot = true;
	}
	else
	{
		AttachedActor = nullptr;
	}
}

float UCameraHeadBase::AdapterPitchToGround()
{
	float RetPitch = TargetCameraRotation.Pitch;
	FVector AttachActorLocation = GetFixedAttachLocation();
	// 碰撞检测
	static FName TraceTagName(TEXT("SpringArm"));
	FCollisionQueryParams QueryParams(TraceTagName, false);
	QueryParams.AddIgnoredActor(CameraActor.Get());
	QueryParams.AddIgnoredActor(AttachedActor.Get());

	FHitResult Result;
	FVector HighLoc = TargetCameraLocation + FVector(0, 0, 10000);
	FVector LowLoc = TargetCameraLocation - FVector(0, 0, 10000);

	// 先探测摄像机新位置下方的地面
	CameraActor->GetWorld()->SweepSingleByChannel(Result, TargetCameraLocation, LowLoc, FQuat::Identity, ECollisionChannel::ECC_Camera, FCollisionShape::MakeSphere(40), QueryParams);
	if (Result.bBlockingHit)
	{
		float NewZ = Result.Location.Z + DistanceToGround; // 摄像机到地面的距离为定值
		RetPitch = cal_pitch_of_camera(AttachActorLocation.Z, NewZ, CameraArmLength); // 矫正Pitch
	}
	else // 此时地面可能在摄像机上方
	{
		Result.Reset(false);
		CameraActor->GetWorld()->SweepSingleByChannel(Result, TargetCameraLocation, HighLoc, FQuat::Identity, ECollisionChannel::ECC_Camera, FCollisionShape::MakeSphere(40), QueryParams);
		if (Result.bBlockingHit)
		{
			float NewZ = Result.Location.Z + DistanceToGround;
			RetPitch = cal_pitch_of_camera(AttachActorLocation.Z, NewZ, CameraArmLength);
		}
	}
	return RetPitch;
}

bool UCameraHeadBase::InterpToTargetPitch(float DeltaSeconds, float TargetPitch)
{
	if (!FMath::IsNearlyEqual(TargetCameraRotation.Pitch, TargetPitch, CameraHeadBaseConst::ROTATION_FLOAT_TOLERANCE))
	{
		// 摄像机Pitch有改变，需要重新计算位置
		// 匀速差值，防止摄像机抖动
		TargetCameraRotation.Pitch = FMath::FInterpConstantTo(TargetCameraRotation.Pitch, TargetPitch, DeltaSeconds, CameraHeadBaseConst::CameraPitchResumeSpeed);
		FVector CameraHeading = TargetCameraRotation.Vector().GetUnsafeNormal() * CameraArmLength;
		FVector AttachActorLocation = GetFixedAttachLocation();
		TargetCameraLocation = AttachActorLocation - CameraHeading;
		NeedUpdateCameraLocRot = true;
		return true;
	}
	return false;
}

void UCameraHeadBase::SetCameraArmLength(float ArmLength)
{
	TargetArmLength = ArmLength;
	NeedUpdateTargetCameraLocRot = true;
}

void UCameraHeadBase::SetCameraPitch(float Pitch)
{
	InitCameraArmRotation.Pitch = Pitch;
	RecaculateDistanceToGround();
}

void UCameraHeadBase::SetAttachLocationOffset(FVector Offset)
{
	TargetLocationOffset = Offset;
	NeedUpdateTargetCameraLocRot = true;
}

void UCameraHeadBase::SyncCameraParamsWithHead(const UCameraHeadBase *OriginHead)
{
	SetCameraPitch(OriginHead->InitCameraArmRotation.Pitch);
	SetCameraArmLength(OriginHead->TargetArmLength);
	SetAttachLocationOffset(OriginHead->TargetLocationOffset);
	FreezeCameraLoc(OriginHead->CameraLocWasFrozen);
}

void UCameraHeadBase::RecaculateDistanceToGround()
{
	DistanceToGround = 88 + CameraArmLength * FMath::Sin(FMath::DegreesToRadians(-InitCameraArmRotation.Pitch)) + AttachedLocationOffset.Size();
	NeedUpdateTargetCameraLocRot = true;
}

void UCameraHeadBase::GetTargetTransform(FVector &Location, FRotator &Rotation)
{
    Location = TargetCameraLocation;
    Rotation = TargetCameraRotation;
}

void UCameraHeadBase::SetTargetTransform(const FVector &Location, const FRotator &Rotation)
{
    TargetCameraLocation = Location;
    TargetCameraRotation = Rotation;
}

void UCameraHeadBase::SetTargetCameraTransform(const FTransform &Transform)
{
	TargetCameraLocation = Transform.GetLocation();
	TargetCameraRotation = Transform.GetRotation().Rotator();
	SetCameraLocationAndRotation(TargetCameraLocation, TargetCameraRotation);
}

void UCameraHeadBase::FreezeCameraLoc(bool Freeze)
{
	CameraLocWasFrozen = Freeze;
}

FVector UCameraHeadBase::GetFixedAttachLocation()
{
	return AttachedActor->GetActorLocation() + AttachedLocationOffset;
}