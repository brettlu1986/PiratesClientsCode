#include "Camera/CameraModify/KMCameraShakeModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "Camera/KMGameCameraManager.h"
#include "Camera/KMCameraShake.h"
#include "Kismet/KismetMathLibrary.h"
#include "Components/KMSpringArmComponent.h"
#include "Camera/CameraModifier_CameraShake.h"
#include "Camera/CameraShakeSourceComponent.h"

UKMCameraShakeModifier::UKMCameraShakeModifier(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
	, ShakeInfo(nullptr)
	, FireShakeInstance(nullptr)
	, ShakeCount(0)
{
}

void UKMCameraShakeModifier::StopCurrentShake()
{
	if (FireShakeInstance && !FireShakeInstance->IsPendingKill())
	{
		if (!FireShakeInstance->IsCameraShakeFinished())
		{
			//UE_LOG(LogTemp, Log, TEXT("[Shake] remove shake  "))
			RemoveCameraShake(FireShakeInstance, true);
		}
	}
}

bool UKMCameraShakeModifier::IsCurrentShakeFinished()
{
	if (FireShakeInstance && !FireShakeInstance->IsPendingKill())
	{
		return FireShakeInstance->IsCameraShakeFinished() && ShakeCount == 0;
	}
	return true;
}

bool UKMCameraShakeModifier::ShakeOnce()
{
	if (FireShakeInstance && !FireShakeInstance->IsPendingKill())
	{
		if (FireShakeInstance->IsCameraShakeFinished())
		{
			CreateCurrentShake();
			return true;
		}
	}
	else
	{
		CreateCurrentShake();
		return true;
	}
	return false;
}

void UKMCameraShakeModifier::ProcessShakeInfo()
{
	if (ShakeCount > 0)
	{
		bool bNewShake = ShakeOnce();
		if (bNewShake)
		{
			ShakeCount -= 1;
		}
	}
	//-1 will shake infinite until call disable modifier
	if (ShakeCount == -1)
	{
		ShakeOnce();
	}
}

void UKMCameraShakeModifier::CreateCurrentShake()
{
	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
	UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();

	FireShakeInstance = NewObject<UKMCameraShake>(this, UKMCameraShake::StaticClass());
	float Scale = 1.f;
	if (ShakeInfo->ShakeCount == -1 || ShakeInfo->ShakeCount == 0 )
	{
		Scale = 1.f;
	}
	else
	{
		float Value = (ShakeInfo->ShakeCount - ShakeCount) * ShakeInfo->DecayParam;
		Scale = 1.f - Value;
		if (Scale <= 0)
			Scale = 1.f;
	}
	float TargetTime = ShakeInfo->Duration;
	//duration will not scale
	//TargetTime *= Scale;
	//UE_LOG(LogTemp, Log, TEXT("[Shake] CreateCurrentShake add shake instance %f, %f, %f"), TargetTime, TargetTime / 2, Scale)
	FireShakeInstance->SetOscillationTimeValue(TargetTime, TargetTime / 2, TargetTime / 2);

	const FVector& TargetAngle = ShakeInfo->TargetAngle;

	FFOscillator PitchOscillator;
	float freq = 1 / TargetTime;
	if ( (ShakeInfo->bRecoil && ShakeInfo->bUseRecoverV) || !ShakeInfo->bRecoil )
	{
		PitchOscillator = FireShakeInstance->MakeKMShakeOscillator(TargetAngle.Y * Scale, freq, EInitialOscillatorOffset::EOO_OffsetZero);
	}
	FFOscillator YawOscillator = FireShakeInstance->MakeKMShakeOscillator(TargetAngle.X * Scale, freq, EInitialOscillatorOffset::EOO_OffsetRandom);
	float key = UKismetMathLibrary::RandomBool() ? 1 : -1;
	FFOscillator RollOscillator = FireShakeInstance->MakeKMShakeOscillator(TargetAngle.Z * Scale, freq, EInitialOscillatorOffset::EOO_OffsetRandom);

	FROscillator RotOscillator;
	RotOscillator.Pitch = PitchOscillator;
	RotOscillator.Yaw = YawOscillator;
	RotOscillator.Roll = RollOscillator;
	FireShakeInstance->RotOscillation = RotOscillator;

	FVOscillator PosOscillator;
	PosOscillator.X = FireShakeInstance->MakeKMShakeOscillator(ShakeInfo->PosOffset.X * Scale, freq, EInitialOscillatorOffset::EOO_OffsetRandom);
	PosOscillator.Y = FireShakeInstance->MakeKMShakeOscillator(ShakeInfo->PosOffset.Y * Scale, freq, EInitialOscillatorOffset::EOO_OffsetRandom);
	PosOscillator.Z = FireShakeInstance->MakeKMShakeOscillator(ShakeInfo->PosOffset.Z * Scale, freq, EInitialOscillatorOffset::EOO_OffsetRandom);
	FireShakeInstance->LocOscillation = PosOscillator;

	FireShakeInstance->FOVOscillation = FireShakeInstance->MakeKMShakeOscillator(ShakeInfo->FovChange * Scale, freq, EInitialOscillatorOffset::EOO_OffsetZero);

	
	AddCameraShakeInstance(FireShakeInstance, FAddCameraShakeParams(1.f, ECameraAnimPlaySpace::CameraLocal, FRotator::ZeroRotator));

	if (ShakeInfo->bRecoil)
	{
		const FVector& TargetRecoverAngle = ShakeInfo->RecoverAngle;
		APlayerController* PlayerController = UGameplayStatics::GetPlayerController(this, 0);

		float VarPitch = TargetAngle.Y ;
		if (ShakeInfo->bUseRecoverV)
			VarPitch = TargetAngle.Y + TargetRecoverAngle.Y;
		float VarYaw = TargetAngle.X + TargetRecoverAngle.X;

		VarYaw /= PlayerController->InputYawScale;
		VarPitch /= PlayerController->InputPitchScale;
		PlayerController->AddYawInput(VarYaw);

		//float CurPitch = SpringArm->RelativeRotation.Pitch;
		float CurPitch = CameraManager->GetCameraRotation().Pitch;
		if (CurPitch < CameraManager->ViewPitchMax)
		{
			if (ShakeInfo->bFollowPitch)
			{
				SpringArm->AddRelativeRotation(FRotator(-VarPitch, 0.f, 0.f));
				PlayerController->AddPitchInput(VarPitch);
			}
			else
			{
				PlayerController->AddPitchInput(VarPitch);
			}
		}
	}
}

void UKMCameraShakeModifier::ApplyCameraInfo(UInfoBase* Info)
{
	ShakeInfo = Cast<UCameraShakeInfo>(Info);
	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);

	if (ShakeInfo)
	{
		StopCurrentShake();
		//UE_LOG(LogTemp, Log, TEXT("[Shake]apply shake info"))
		ShakeCount = ShakeInfo->ShakeCount;
	}
}

bool UKMCameraShakeModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
    Super::ModifyCamera(DeltaTime, InOutPOV);

    AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
    if (!IsValid(CameraManager) || IsDisabled())
    {
        return false;
    }

	if (ShakeInfo && !ShakeInfo->IsZero())
	{
		ProcessShakeInfo();
	}

    return false;
}

void UKMCameraShakeModifier::AddCameraShakeInstance(UCameraShake* NewShake, const FAddCameraShakeParams& Params)
{
    if (NewShake)
    {
		float Scale = Params.Scale;
		const UCameraShakeSourceComponent* SourceComponent = Params.SourceComponent;

        // adjust for splitscreen
        if (CameraOwner != nullptr && GEngine->IsSplitScreen(CameraOwner->GetWorld()))
        {
            Scale *= SplitScreenShakeScale;
        }

        NewShake->PlayShake(CameraOwner, Scale, Params.PlaySpace, Params.UserPlaySpaceRot);

        // look for nulls in the array to replace first -- keeps the array compact
        bool bReplacedNull = false;
        for (int32 Idx = 0; Idx < ActiveShakes.Num(); ++Idx)
        {
			FActiveCameraShakeInfo& TempShakeInfo = ActiveShakes[Idx];
            if (TempShakeInfo.ShakeInstance == nullptr)
            {
                TempShakeInfo.ShakeInstance = NewShake;
                TempShakeInfo.ShakeSource = SourceComponent;
                bReplacedNull = true;
            }
        }

        // no holes, extend the array
        if (bReplacedNull == false)
        {
			FActiveCameraShakeInfo lShakeInfo;
			lShakeInfo.ShakeInstance = NewShake;
			lShakeInfo.ShakeSource = SourceComponent;
            ActiveShakes.Emplace(lShakeInfo);
        }

    }
}
