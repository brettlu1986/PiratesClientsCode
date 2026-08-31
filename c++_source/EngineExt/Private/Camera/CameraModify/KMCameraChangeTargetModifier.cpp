#include "Camera/CameraModify/KMCameraChangeTargetModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "KMGameCameraActor.h"
#include "Kismet/GameplayStatics.h"
#include "KMGameCameraManager.h"

UKMCameraChangeTargetModifier::UKMCameraChangeTargetModifier(const FObjectInitializer& ObjectInitializer )
    : Super(ObjectInitializer)
	, TargetInfo(nullptr)
{
}

void UKMCameraChangeTargetModifier::ApplyCameraInfo(UInfoBase* Info)
{
	TargetInfo = Cast<UChangeTargetInfo>(Info);
	if (TargetInfo)
	{
		AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();

		FViewTargetTransitionParams TransitionParams;
		TransitionParams.BlendFunction = TargetInfo->BlendFunc;
		TransitionParams.BlendExp = TargetInfo->BlendExp;

		if (TargetInfo->bChangeImmediatly)
		{
			TransitionParams.bLockOutgoing = false;
			TransitionParams.BlendTime = 0.f;
			CameraManager->SetViewTarget(CameraActor, TransitionParams);
		}
		else
		{
			TransitionParams.BlendTime = 1.f;
			TransitionParams.bLockOutgoing = true;
			CameraManager->SetViewTarget(nullptr, TransitionParams);
			TransitionParams.BlendTime = TargetInfo->BlendTime;
			CameraManager->SetViewTarget(CameraActor, TransitionParams);
		}
	}
}

bool UKMCameraChangeTargetModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
    Super::ModifyCamera(DeltaTime, InOutPOV);

    AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
    if (!IsValid(CameraManager) || IsDisabled())
    {
        return false;
    }
    return false;
}