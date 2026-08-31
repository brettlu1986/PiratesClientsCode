// Fill out your copyright notice in the Description page of Project Settings.

#include "Camera/CameraModify/KMCameraFovModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "KMGameCameraManager.h"

UKMCameraFovModifier::UKMCameraFovModifier(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, FovInfo(nullptr)
	, BlendTimeToGo(0.f)
	, FovStart(0.f)
	, FovToGo(0.f)
{
	Key = 5.f;
	KeyReduce = 0.6f;
}

void UKMCameraFovModifier::ApplyCameraInfo(UInfoBase* Info)
{
	FovInfo = Cast<UFovInfo>(Info);

	if (FovInfo)
	{
		AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UCameraComponent* Camera = CameraActor->GetCamera();
		Key = 5.f;
		KeyReduce = 0.6f;

		float AimFov = 0.f;
		if (FovInfo->TargetFovRate == 0.f)
		{
			AimFov = CameraManager->RefFov;
		}
		else
		{
			float Angle = CameraManager->RefFov / 2;
			float RefTan = FMath::Tan(Angle * PI / 180.f);
			AimFov = (180.f) / PI * FMath::Atan(RefTan / FovInfo->TargetFovRate);
			AimFov *= 2.f;
		}

		BlendTimeToGo = FovInfo->BlendTime;
		if (BlendTimeToGo == 0.f)
		{
			FovStart = 0.f;
			FovToGo = AimFov;
			Camera->SetFieldOfView(AimFov);
		}
		else
		{
			FovStart = Camera->FieldOfView;
			FovToGo = AimFov - FovStart;
			Camera->SetFieldOfView(FovStart);
		}
	}
}

bool UKMCameraFovModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
	Super::ModifyCamera(DeltaTime, InOutPOV);

	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	if (!IsValid(CameraManager) || IsDisabled())
	{
		return false;
	}

	if (FovInfo && !FovInfo->IsZero())
	{
		Key -= KeyReduce;
		if (Key < 1.8f)
			Key = 1.8f;
		BlendTimeToGo -= Key * DeltaTime;
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UCameraComponent* Camera = CameraActor->GetCamera();
		if (BlendTimeToGo > 0)
		{
			float DurationPct = (FovInfo->BlendTime - BlendTimeToGo) / FovInfo->BlendTime;
			//float BlendPct = FMath::Lerp(0.f, 1.f, DurationPct);
			float BlendPct = FMath::Clamp(DurationPct, 0.f, 1.f);
			float OffsetPct = FovToGo * BlendPct;
			Camera->SetFieldOfView(FovStart + OffsetPct);
		}
		else
		{
			BlendTimeToGo = 0;
			float TargetFov = FovStart + FovToGo;
			if (Camera->FieldOfView != TargetFov)
			{
				Camera->SetFieldOfView(TargetFov);
			}
			DisableModifier(true);
		}
	}
	return false;
}
