// Fill out your copyright notice in the Description page of Project Settings.

#include "Camera/CameraModify/KMCameraArmSyncRotModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "KMGameCameraManager.h"
#include "Components/KMSpringArmComponent.h"
#include "Kismet/KismetMathLibrary.h"


UKMCameraArmSyncRotModifier::UKMCameraArmSyncRotModifier(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, ArmSyncInfo(nullptr)
	, TargetRot(FRotator::ZeroRotator)
{
}

void UKMCameraArmSyncRotModifier::ApplyCameraInfo(UInfoBase* Info)
{
	ArmSyncInfo = Cast<USyncArmRotInfo>(Info);
	if (ArmSyncInfo)
	{
		InterpSpeed = ArmSyncInfo->InterpSpeed;
	}
}

bool UKMCameraArmSyncRotModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
	Super::ModifyCamera(DeltaTime, InOutPOV);

	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	if (!IsValid(CameraManager) || IsDisabled())
	{
		return false;
	}

	if (ArmSyncInfo && !ArmSyncInfo->IsZero())
	{
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
		APawn* pSyncPawn = ArmSyncInfo->SyncPawn;
		if (pSyncPawn && !pSyncPawn->IsPendingKill())
		{
			const FRotator& Rot = pSyncPawn->GetBaseAimRotation();
			float OffsetYaw = ArmSyncInfo->OffsetYaw;

			FRotator VarRot = Rot;
			VarRot.Roll = 0.f;
			if (!ArmSyncInfo->bSyncYaw)
			{
				VarRot.Yaw = SpringArm->GetRelativeRotation().Yaw + OffsetYaw;
				VarRot.Pitch = UKismetMathLibrary::NormalizedDeltaRotator(Rot, pSyncPawn->GetActorRotation()).Pitch;
				//SpringArm->SetRelativeRotation(FRotator(Rot.Pitch, SpringArm->GetRelativeRotation().Yaw + OffsetYaw, 0.f));
			}
			else
			{
				VarRot.Yaw = Rot.Yaw + OffsetYaw;
				//SpringArm->SetRelativeRotation(FRotator(Rot.Pitch, Rot.Yaw + OffsetYaw, 0.f));
			}

			if (TargetRot != VarRot)
			{
				TargetRot = VarRot;
			}

			FRotator CurrentRot = SpringArm->GetRelativeRotation();
			FRotator RotTo = FMath::RInterpTo(CurrentRot, TargetRot, DeltaTime, InterpSpeed);
			RotTo.Roll = 0.f;
			SpringArm->SetRelativeRotation(RotTo);
		}
	}
	return false;
}
