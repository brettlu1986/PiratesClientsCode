// Fill out your copyright notice in the Description page of Project Settings.

#include "Camera/CameraModify/KMCameraArmRotModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "KMGameCameraManager.h"
#include "Components/KMSpringArmComponent.h"

UKMCameraArmRotModifier::UKMCameraArmRotModifier(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, ArmRotInfo(nullptr)
	, RotStart(FRotator::ZeroRotator)
	, RotToGo(FRotator::ZeroRotator)
{
}

void UKMCameraArmRotModifier::ApplyCameraInfo(UInfoBase* Info)
{
	ArmRotInfo = Cast<UArmRotInfo>(Info);
	if (ArmRotInfo)
	{
		AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();

		RotStart = SpringArm->GetRelativeRotation();
		RotToGo = ArmRotInfo->TargetRot - RotStart;
		BlendTimeToGo = ArmRotInfo->BlendTime;
		SpringArm->SetRelativeRotation(RotStart);
	}
}

bool UKMCameraArmRotModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
	Super::ModifyCamera(DeltaTime, InOutPOV);

	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	if (!IsValid(CameraManager) || IsDisabled())
	{
		return false;
	}

	if (ArmRotInfo && !ArmRotInfo->IsZero())
	{
		BlendTimeToGo -= DeltaTime;
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
		if (BlendTimeToGo > 0)
		{
			float DurationPct = (ArmRotInfo->BlendTime - BlendTimeToGo) / ArmRotInfo->BlendTime;
			float BlendPct = FMath::Lerp(0.f, 1.f, DurationPct);
			FRotator OffsetPct = RotToGo * BlendPct;
			SpringArm->SetRelativeRotation(RotStart + OffsetPct);
		}
		else
		{
			BlendTimeToGo = 0;
		}
	}
	return false;
}
