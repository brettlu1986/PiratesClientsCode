// Fill out your copyright notice in the Description page of Project Settings.

#include "Camera/CameraModify/KMCameraArmLenModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "KMGameCameraManager.h"
#include "Components/KMSpringArmComponent.h"


UKMCameraArmLenModifier::UKMCameraArmLenModifier(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, ArmLenInfo(nullptr)
	, AnimTime(0.f)
	, MoveToGo(0.f)
	, MoveHasGo(0.f)
	, MoveWillGo(0.f)
	, EndLen(0.f)
	, bNeedBlend(false)
{
}

void UKMCameraArmLenModifier::ApplyCameraInfo(UInfoBase* Info)
{
	ArmLenInfo = Cast<UMoveArmLenInfo>(Info);

	if(ArmLenInfo)
	{
		AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();

		MoveToGo = ArmLenInfo->ArmLenToGo;
		MoveHasGo = 0.f;
		MoveWillGo = 0.f;
		AnimTime = ArmLenInfo->BlendTime;
		EndLen = SpringArm->TargetArmLength + MoveToGo;
		bNeedBlend = true;
	}
}

bool UKMCameraArmLenModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
	Super::ModifyCamera(DeltaTime, InOutPOV);

	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	if (!IsValid(CameraManager) || IsDisabled())
	{
		return false;
	}

	if (ArmLenInfo && !ArmLenInfo->IsZero())
	{
		if (bNeedBlend)
		{
			AnimTime -= DeltaTime;
			AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
			UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
			if (AnimTime > 0)
			{
				float DurationPct = (ArmLenInfo->BlendTime - AnimTime) / ArmLenInfo->BlendTime;
				float BlendPct = FMath::Lerp(0.f, 1.f, DurationPct);
				MoveWillGo = MoveToGo * BlendPct;

				float Offset = MoveWillGo - MoveHasGo;
				SpringArm->TargetArmLength = SpringArm->TargetArmLength + Offset;
				MoveHasGo = MoveWillGo;
			}
			else
			{
				if (SpringArm->TargetArmLength != EndLen)
				{
					SpringArm->TargetArmLength = EndLen;
				}
				AnimTime = 0;
				bNeedBlend = false;
			}
		}
	}
	return false;
}
