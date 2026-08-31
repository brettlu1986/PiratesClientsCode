// Fill out your copyright notice in the Description page of Project Settings.

#include "Camera/CameraModify/KMCameraOffsetMoveModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "Camera/KMGameCameraManager.h"
#include "Camera/KMGameCameraActor.h"
#include "Components/KMSpringArmComponent.h"

UKMCameraOffsetMoveModifier::UKMCameraOffsetMoveModifier(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
	, BaseSocketOffset(FVector::ZeroVector)
	, OffsetMoveInfo(nullptr)
	, BlendTimeToGo(0.f)
	, OffsetToGo(FVector::ZeroVector)
	, OffsetStart(FVector::ZeroVector)
{
}

void UKMCameraOffsetMoveModifier::ApplyCameraInfo(UInfoBase* Info)
{
	OffsetMoveInfo = Cast<UOffsetMoveInfo>(Info);

	if (OffsetMoveInfo)
	{
		AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();

		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();

		if (OffsetMoveInfo->bNeedBlend)
		{
			BlendTimeToGo = OffsetMoveInfo->BlendTime;
			if (OffsetMoveInfo->MoveOffset == FVector::ZeroVector)
			{
				OffsetToGo = BaseSocketOffset - SpringArm->SocketOffset;
			}
			else
			{
				FVector Target = BaseSocketOffset + OffsetMoveInfo->MoveOffset;
				OffsetToGo = Target - SpringArm->SocketOffset;
			}
			OffsetStart = SpringArm->SocketOffset;
		}
		else
		{
			if (OffsetMoveInfo->MoveOffset == FVector::ZeroVector)
			{
				SpringArm->SocketOffset = BaseSocketOffset;
			}
			else
			{
				SpringArm->SocketOffset = BaseSocketOffset + OffsetMoveInfo->MoveOffset;
			}
		}
	}
}

bool UKMCameraOffsetMoveModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
    Super::ModifyCamera(DeltaTime, InOutPOV);

    AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
    if (!IsValid(CameraManager) || IsDisabled())
    {
        return false;
    }

    if (OffsetMoveInfo && !OffsetMoveInfo->IsZero())
    {
		if (OffsetMoveInfo->bNeedBlend)
		{
			BlendTimeToGo -= DeltaTime;
			AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
			UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
			if (BlendTimeToGo > 0)
			{
				float DurationPct = (OffsetMoveInfo->BlendTime - BlendTimeToGo) / OffsetMoveInfo->BlendTime;
				float BlendPct = 0.f;
				switch (OffsetMoveInfo->InterpMode)
				{
					default:
					case 1: 
					{
						BlendPct = FMath::Lerp(0.f, 1.f, DurationPct); 
						break;
					}
					case 2: 
					{
						BlendPct = FMath::InterpSinIn(0.f, 1.f, DurationPct); 
						break;
					}
					case 3: 
					{
						BlendPct = FMath::InterpSinOut(0.f, 1.f, DurationPct); 
						break;
					}
					
				}
					
				FVector OffsetPct = OffsetToGo * BlendPct;
				SpringArm->SocketOffset = OffsetStart + OffsetPct;
			}
			else
			{
				BlendTimeToGo = 0;
				SpringArm->SocketOffset = OffsetStart + OffsetToGo;
				OffsetMoveInfo->bNeedBlend = false;
			}
		}
    }
    return false;
}
