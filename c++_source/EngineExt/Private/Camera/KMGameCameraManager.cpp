
#include "Camera/KMGameCameraManager.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraChangeTargetModifier.h"
#include "Camera/CameraModify/KMCameraHandleMoveModifier.h"
#include "Camera/CameraModify/KMCameraOffsetMoveModifier.h"
#include "Camera/CameraModify/KMCameraShakeModifier.h"
#include "Camera/CameraModify/KMCameraInfoInterface.h"
#include "Camera/CameraModify/KMCameraFovModifier.h"
#include "Camera/CameraModify/KMCameraArmLenModifier.h"
#include "Camera/CameraModify/KMCameraArmSyncRotModifier.h"
#include "Camera/CameraModify/KMCameraArmRotModifier.h"
#include "Camera/CameraModify/KMCameraTrackModifier.h"
#include "Camera/KMGameCameraActor.h"
#include "Net/UnrealNetwork.h"
#include "Components/KMSpringArmComponent.h"

DEFINE_LOG_CATEGORY_STATIC(LogAKMGameCameraManager, Log, All);

AKMGameCameraManager::AKMGameCameraManager(
    const FObjectInitializer& ObjectInitializer /*= FObjectInitializer::Get()*/)
    :Super(ObjectInitializer)
	,FollowTarget(nullptr)
	,RefFov(90.f)
	,WatchedPawn(nullptr)
	,CameraFollowType(ECameraFollowType::FollowNone)
	,LookAngleUpLimit(0.f)
	,LookAngleDownLimit(0.f)
	,bUseCacheRotation(false)
	,CacheArmLen(0.f)
	,TargetPawn(nullptr)
{
	PrimaryActorTick.bCanEverTick = true;
	SetActorTickEnabled(true);
	
}

void AKMGameCameraManager::SpawnCameraActor()
{
	if (CameraActor != NULL)
		return;

	UWorld* MyWorld = GetWorld();
	if (CameraActorClass != NULL)
	{
		CameraActor = GetWorld()->SpawnActor<AKMGameCameraActor>(CameraActorClass);
	}
	else
	{
		CameraActor = GetWorld()->SpawnActor<AKMGameCameraActor>(AKMGameCameraActor::StaticClass());
	}
}

void AKMGameCameraManager::PostInitializeComponents()
{
    Super::PostInitializeComponents();

    UKMCameraShakeModifier* ShakeModify = Cast<UKMCameraShakeModifier>(CachedCameraShakeMod);
    if (ShakeModify)
    {
		ShakeModify->DisableModifier(true);
        CurrentMorifierMap.Add(ECameraModeType::ModeShake, ShakeModify);
    }

	if (DefaultModifiers.Num() > 0)
	{
		for (auto ModifierClass : DefaultModifiers)
		{
			if (ModifierClass)
			{
				UCameraModifier* const NewModTrack = AddNewCameraModifier(ModifierClass);
				UKMCameraTrackModifier* const CameraTrackModifier = Cast<UKMCameraTrackModifier>(NewModTrack);
				if (CameraTrackModifier)
				{
					CameraTrackModifier->DisableModifier(true);
					CurrentMorifierMap.Add(ECameraModeType::ModeCameraTrack, CameraTrackModifier);
				}
			}
		}
	}

    //
    UCameraModifier* const NewModCT = AddNewCameraModifier(UKMCameraChangeTargetModifier::StaticClass());
    UKMCameraChangeTargetModifier* const ChangeTargetMod = Cast<UKMCameraChangeTargetModifier>(NewModCT);
    if (ChangeTargetMod)
    {
		ChangeTargetMod->DisableModifier(true);
        CurrentMorifierMap.Add(ECameraModeType::ModeChangeTarget, ChangeTargetMod);
    }

    UCameraModifier* const NewModHM = AddNewCameraModifier(UKMCameraHandleMoveModifier::StaticClass());
    UKMCameraHandleMoveModifier* const HandleMoveMod = Cast<UKMCameraHandleMoveModifier>(NewModHM);
    if (HandleMoveMod)
    {
		HandleMoveMod->DisableModifier(true);
        CurrentMorifierMap.Add(ECameraModeType::ModeHandleMove, HandleMoveMod);
    }

    UCameraModifier* const NewModOM = AddNewCameraModifier(UKMCameraOffsetMoveModifier::StaticClass());
    UKMCameraOffsetMoveModifier* const OffsetMoveMod = Cast<UKMCameraOffsetMoveModifier>(NewModOM);
    if (OffsetMoveMod)
    {
		OffsetMoveMod->DisableModifier(true);
        CurrentMorifierMap.Add(ECameraModeType::ModeOffsetMove, OffsetMoveMod);
    }

	UCameraModifier* const NewModFM = AddNewCameraModifier(UKMCameraFovModifier::StaticClass());
	UKMCameraFovModifier* const FovMod = Cast<UKMCameraFovModifier>(NewModFM);
	if (FovMod)
	{
		FovMod->DisableModifier(true);
		CurrentMorifierMap.Add(ECameraModeType::ModeFov, FovMod);
	}

	UCameraModifier* const NewModAM = AddNewCameraModifier(UKMCameraArmLenModifier::StaticClass());
	UKMCameraArmLenModifier* const ArmMod = Cast<UKMCameraArmLenModifier>(NewModAM);
	if (ArmMod)
	{
		ArmMod->DisableModifier(true);
		CurrentMorifierMap.Add(ECameraModeType::ModeArmLen, ArmMod);
	}

	UCameraModifier* const NewModAMR = AddNewCameraModifier(UKMCameraArmSyncRotModifier::StaticClass());
	UKMCameraArmSyncRotModifier* const ArmRotMod = Cast<UKMCameraArmSyncRotModifier>(NewModAMR);
	if (ArmRotMod)
	{
		ArmRotMod->DisableModifier(true);
		CurrentMorifierMap.Add(ECameraModeType::ModeSyncArmRot, ArmRotMod);
	}

	UCameraModifier* const NewModAMRot = AddNewCameraModifier(UKMCameraArmRotModifier::StaticClass());
	UKMCameraArmRotModifier* const ArmRotModifier = Cast<UKMCameraArmRotModifier>(NewModAMRot);
	if (ArmRotModifier)
	{
		ArmRotModifier->DisableModifier(true);
		CurrentMorifierMap.Add(ECameraModeType::ModeArmRot, ArmRotModifier);
	}

	/*UCameraModifier* const NewModTrack = AddNewCameraModifier(UKMCameraTrackModifier::StaticClass());
	UKMCameraTrackModifier* const CameraTrackModifier = Cast<UKMCameraTrackModifier>(NewModTrack);
	if (CameraTrackModifier)
	{
		CameraTrackModifier->DisableModifier(true);
		CurrentMorifierMap.Add(ECameraModeType::ModeCameraTrack, CameraTrackModifier);
	}*/
}

AKMGameCameraActor* AKMGameCameraManager::GetPlayerCameraActor()
{
	return CameraActor;
}

void AKMGameCameraManager::PlayCameraShakeInstance(TSubclassOf<UCameraShake> ShakeClass, float Scale, ECameraAnimPlaySpace::Type PlaySpace, FRotator UserPlaySpaceRot)
{
    if (ShakeClass && CachedCameraShakeMod && (Scale > 0.0f))
    {
		if (ShakeClass && CachedCameraShakeMod && (Scale > 0.0f))
		{
			CachedCameraShakeMod->AddCameraShake(ShakeClass, FAddCameraShakeParams(Scale, PlaySpace, UserPlaySpaceRot));
			CachedCameraShakeMod->EnableModifier();
		}
    }
}

void AKMGameCameraManager::StopCurrentShake()
{
	UKMCameraShakeModifier* ShakeMod = Cast<UKMCameraShakeModifier>(CurrentMorifierMap[ECameraModeType::ModeShake]);
	if (ShakeMod)
	{
		ShakeMod->StopCurrentShake();
	}
}

bool AKMGameCameraManager::IsCurrentShakeFinished()
{
	UKMCameraShakeModifier* ShakeMod = Cast<UKMCameraShakeModifier>(CurrentMorifierMap[ECameraModeType::ModeShake]);
	if (!ShakeMod->IsDisabled())
	{
		return ShakeMod->IsCurrentShakeFinished();
	}
	return true;
}

bool AKMGameCameraManager::IsArmBackRotBack() const
{
	UKMCameraHandleMoveModifier* const HandleMoveMod = Cast<UKMCameraHandleMoveModifier>(CurrentMorifierMap[ECameraModeType::ModeHandleMove]);
	if (HandleMoveMod)
	{
		return HandleMoveMod->IsArmBackAnim();
	}
	return false;
}

void AKMGameCameraManager::SetCacheArmRotator(bool bCache, FRotator Rot)
{
	bUseCacheRotation = bCache;
	CacheCameraRotator = Rot;
}

void AKMGameCameraManager::ForceToResetFreeViewRotation()
{
	UKMCameraHandleMoveModifier* const HandleMoveMod = Cast<UKMCameraHandleMoveModifier>(CurrentMorifierMap[ECameraModeType::ModeHandleMove]);
	if (HandleMoveMod)
	{
		HandleMoveMod->ForceToResetFreeViewRotation();
	}
}

void AKMGameCameraManager::InitCacheArmParam()
{
	SetCacheArmRotator(true, GetCameraRotation());
	UKMCameraHandleMoveModifier* const HandleMoveMod = Cast<UKMCameraHandleMoveModifier>(CurrentMorifierMap[ECameraModeType::ModeHandleMove]);
	if (HandleMoveMod)
	{
		HandleMoveMod->InitDataCache();
	}
}

void AKMGameCameraManager::UnInitCacheArmParam(bool bWithAnim, float InterpSpeed)
{
	SetCacheArmRotator(false, FRotator::ZeroRotator);
	UKMCameraHandleMoveModifier* const HandleMoveMod = Cast<UKMCameraHandleMoveModifier>(CurrentMorifierMap[ECameraModeType::ModeHandleMove]);
	if (HandleMoveMod)
	{
		HandleMoveMod->ResetDataCache(bWithAnim, InterpSpeed);
	}
}

FRotator AKMGameCameraManager::GetMoveCameraRotation() const
{
	if (bUseCacheRotation)
	{
		return CacheCameraRotator;
	}
	return GetCameraRotation();
}

void AKMGameCameraManager::ResetBaseSocketOffset(FVector SocketOffset)
{
	UKMCameraOffsetMoveModifier* const OffsetMoveMod = Cast<UKMCameraOffsetMoveModifier>(CurrentMorifierMap[ECameraModeType::ModeOffsetMove]);
	if (OffsetMoveMod)
	{
		OffsetMoveMod->BaseSocketOffset = SocketOffset;
	}
}

void AKMGameCameraManager::InitCameraActorParam(const FInitCameraInfo& CameraInfo)
{
	SpawnCameraActor();

	UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();

	float NewPitch = FMath::ClampAngle(CameraInfo.SpringArmRotation.Pitch, CameraInfo.PitchViewMin, CameraInfo.PitchViewMax);
	SpringArm->SetRelativeLocationAndRotation(CameraInfo.SpringArmLocation, FRotator(NewPitch, CameraInfo.SpringArmRotation.Yaw, CameraInfo.SpringArmRotation.Roll));

	SpringArm->TargetArmLength = CameraInfo.SpringArmLength;
	SpringArm->SocketOffset = CameraInfo.SocketOffset;
	UCameraComponent* CameraComponent = CameraActor->GetCamera();
	CameraComponent->SetRelativeRotation(CameraInfo.CameraRotation);
	CameraComponent->SetRelativeLocation(FVector::ZeroVector);
	CameraComponent->SetFieldOfView(CameraInfo.InitFov);
	RefFov = CameraInfo.InitFov;
	ViewPitchMax = CameraInfo.PitchViewMax;
	ViewPitchMin = CameraInfo.PitchViewMin;
	LookAngleUpLimit = CameraInfo.LookUpLimit;
	LookAngleDownLimit = CameraInfo.LookDownLimit;
}

void AKMGameCameraManager::UnInitCameraActorParam()
{
	if (CameraActor)
	{
		UE_LOG(LogAKMGameCameraManager, Log, TEXT("[ClientWatch]UnInitCameraActorParam detach now"));
		CameraActor->DetachFromActor(FDetachmentTransformRules::KeepWorldTransform);
	}

	if (CameraFollowType == ECameraFollowType::NotAttachFollowLocation ||
		CameraFollowType == ECameraFollowType::NotAttachFollowLocationXY ||
		CameraFollowType == ECameraFollowType::NotAttachFollowLocXYRotYaw ||
		CameraFollowType == ECameraFollowType::NotAttackFollowLocRotYaw ||
		CameraFollowType == ECameraFollowType::NotAttachFollowMeshLocation)
	{
		FollowLocOffset = FVector::ZeroVector;
		FollowTarget = nullptr;
		CameraFollowType = ECameraFollowType::FollowNone;
	}

}

void AKMGameCameraManager::ResetPitchView(float PitchMax, float PitchMin)
{
	ViewPitchMax = PitchMax;
	ViewPitchMin = PitchMin;

	if (CameraActor && !CameraActor->IsPendingKill())
	{
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
		FRotator ArmRot = SpringArm->GetRelativeRotation();
		float ArmPitch = ArmRot.Pitch;
		APlayerController* PlayerController = UGameplayStatics::GetPlayerController(this, 0);
		FRotator ControlRot = PlayerController->GetControlRotation();
		if (ArmPitch >= PitchMax)
		{
			SpringArm->SetRelativeRotation(FRotator(PitchMax, ArmRot.Yaw, ArmRot.Roll));
			PlayerController->SetControlRotation(FRotator(PitchMax, ControlRot.Yaw, ControlRot.Roll));
		}

		if (ArmPitch <= PitchMin)
		{
			SpringArm->SetRelativeRotation(FRotator(PitchMin, ArmRot.Yaw, ArmRot.Roll));
			PlayerController->SetControlRotation(FRotator(PitchMin, ControlRot.Yaw, ControlRot.Roll));
		}
	}
}

void AKMGameCameraManager::UnInitCameraForDead()
{
	if (CameraActor)
	{
		UE_LOG(LogAKMGameCameraManager, Log, TEXT("[ClientWatch]UnInitCameraForDead detach now"));
		CameraActor->DetachFromActor(FDetachmentTransformRules::KeepWorldTransform);
	}

	if (CameraFollowType == ECameraFollowType::NotAttachFollowLocation ||
		CameraFollowType == ECameraFollowType::NotAttachFollowLocationXY ||
		CameraFollowType == ECameraFollowType::NotAttachFollowLocXYRotYaw ||
		CameraFollowType == ECameraFollowType::NotAttackFollowLocRotYaw)
	{
		FollowLocOffset = FVector::ZeroVector;
		FollowTarget = nullptr;
		CameraFollowType = ECameraFollowType::FollowNone;
	}
}

void AKMGameCameraManager::InitAimParam(float AimArmLen, float AimRate)
{
	UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
	UCameraComponent* CameraComponent = CameraActor->GetCamera();
	CacheArmLen = SpringArm->TargetArmLength;
	SpringArm->TargetArmLength = AimArmLen;
}

void AKMGameCameraManager::UnInitAimParam()
{
	USpringArmComponent* SpringArm = CameraActor->GetSpringArm();
	UCameraComponent* CameraComponent = CameraActor->GetCamera();
	SpringArm->TargetArmLength = CacheArmLen;
}

void AKMGameCameraManager::InitAttachAimParam(float AimArmLen, FVector CameraOffset, float AimRate, FName SocketName, USceneComponent* Parent)
{
	UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
	UCameraComponent* CameraComponent = CameraActor->GetCamera();

	SpringArm->SocketOffset = FVector::ZeroVector;
	SpringArm->SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
	CameraComponent->SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
	CameraActor->SetActorLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
	if (Parent)
	{
		CameraActor->AttachToComponent(Parent, FAttachmentTransformRules::KeepRelativeTransform, SocketName);
		CameraActor->SetActorRelativeLocation(CameraOffset);
	}

	CacheArmLen = SpringArm->TargetArmLength;
	SpringArm->TargetArmLength = AimArmLen;
}

void AKMGameCameraManager::UnInitAttachAimParam()
{
	if (CameraActor)
	{
		UE_LOG(LogAKMGameCameraManager, Log, TEXT("[ClientWatch]UnInitAttachAimParam detach now"));
		CameraActor->DetachFromActor(FDetachmentTransformRules::KeepRelativeTransform);
	}
}

void AKMGameCameraManager::SetFollowLocationOffset(FVector FollowOffset)
{
	FollowLocOffset = FollowOffset;
	if (FollowTarget && !FollowTarget->IsPendingKill())
	{
		const FVector& TargetLocation = FollowTarget->GetActorLocation();
		FVector Loc = FollowLocOffset + TargetLocation;
		CameraActor->SetActorLocation(Loc);
	}
}

void AKMGameCameraManager::InitFollowTarget(AActor* InFollowTarget, ECameraFollowType InFollowType, bool bSetControlRot, USceneComponent* Parent, FVector InOffset, FName SocketName)
{
	FollowTarget = InFollowTarget;
	CameraFollowType = InFollowType;
	FollowLocOffset = InOffset;
	FollowComponent = Parent;

	if (FollowTarget && !FollowTarget->IsPendingKill())
	{
		const FRotator& TargetRotation = FollowTarget->GetActorRotation();
		if (bSetControlRot)
		{
			APlayerController* PlayerController = UGameplayStatics::GetPlayerController(this, 0);
			FRotator Rot = FRotator(TargetRotation.Pitch, TargetRotation.Yaw, 0);
			PlayerController->SetControlRotation(Rot);
			//UE_LOG(LogAKMGameCameraManager, Log, TEXT("lz== FollowTarget Yaw %f, Pitch %f"), TargetRotation.Yaw, TargetRotation.Pitch);
		}
		switch (CameraFollowType)
		{
			case ECameraFollowType::AttachToSocket:
			{
				CameraActor->SetActorLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
				FAttachmentTransformRules AttachmentTransformRules = FAttachmentTransformRules::KeepRelativeTransform;
				CameraActor->AttachToComponent(Parent, AttachmentTransformRules, SocketName);
				UE_LOG(LogAKMGameCameraManager, Log, TEXT("[ClientWatch]FollowTarget attach to socket"));
				break;
			}
			case ECameraFollowType::Attach:
			{
				UE_LOG(LogAKMGameCameraManager, Log, TEXT("[ClientWatch]FollowTarget Attach"));
				CameraActor->SetActorLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
				FAttachmentTransformRules AttachmentTransformRules = FAttachmentTransformRules::KeepRelativeTransform;
				CameraActor->AttachToActor(FollowTarget, AttachmentTransformRules);
				break;
			}
			case ECameraFollowType::NotAttachFollowLocation:
			case ECameraFollowType::NotAttackFollowLocRotYaw:
			{
				UE_LOG(LogAKMGameCameraManager, Log, TEXT("[ClientWatch]FollowTarget NotAttachFollowLocation"));
				const FVector& TargetLocation = FollowTarget->GetActorLocation();
				CameraActor->SetActorRotation(FRotator(0, TargetRotation.Yaw, 0));
				FVector Loc = FollowLocOffset + TargetLocation;
				CameraActor->SetActorLocation(Loc);
				break;
			}
			case ECameraFollowType::NotAttachFollowMeshLocation:
			{
				const FVector& TargetLocation = Parent->GetComponentLocation();
				CameraActor->SetActorRotation(FRotator(0, TargetRotation.Yaw, 0));
				FVector Loc = FollowLocOffset + TargetLocation;
				CameraActor->SetActorLocation(Loc);
				UE_LOG(LogAKMGameCameraManager, Log, TEXT("[ClientWatch]FollowTarget NotAttachFollowMeshLocation"));
				break;
			}
			case ECameraFollowType::NotAttachFollowLocXYRotYaw:
			case ECameraFollowType::NotAttachFollowLocationXY:
			{
				const FVector& TargetLocation = FollowTarget->GetActorLocation();
				CameraActor->SetActorRotation(FRotator(0, TargetRotation.Yaw, 0));
				FVector Loc = FollowLocOffset + TargetLocation;
				Loc.Z = 0;
				CameraActor->SetActorLocation(Loc);
				UE_LOG(LogAKMGameCameraManager, Log, TEXT("[ClientWatch]FollowTarget NotAttachFollowLocationXY"));
				//UE_LOG(LogAKMGameCameraManager, Log, TEXT("lz== The ship rot is Yaw %f, Pitch %f"), TargetRotation.Yaw, TargetRotation.Pitch);
				break;
			}
			case ECameraFollowType::FollowNone:
			default:
			{
				break;
			}
		}
	}
}

void AKMGameCameraManager::UpdateFollowTarget(float DeltaSeconds)
{

	if (FollowTarget && !FollowTarget->IsPendingKill())
	{
		const FVector& Location = FollowTarget->GetActorLocation();
		FVector Loc = FollowLocOffset + Location;
		switch (CameraFollowType)
		{
			case ECameraFollowType::NotAttachFollowLocation:
			{
				CameraActor->SetActorLocation(Loc);
				break;
			}
			case ECameraFollowType::NotAttachFollowMeshLocation:
			{
				Loc = FollowComponent->GetComponentLocation() + FollowLocOffset;
				CameraActor->SetActorLocation(Loc);
				break;
			}
			case ECameraFollowType::NotAttachFollowLocationXY:
			{
				Loc.Z = 0;
				CameraActor->SetActorLocation(Loc);
				break;
			}
			case ECameraFollowType::NotAttachFollowLocXYRotYaw:
			{
				const FRotator& Rotator = FollowTarget->GetActorRotation();
				Loc.Z = 0;
				CameraActor->SetActorLocation(Loc);
				CameraActor->SetActorRotation(FRotator(0, Rotator.Yaw, 0));
				break;
			}
			case ECameraFollowType::NotAttackFollowLocRotYaw:
			{
				const FRotator& Rotator = FollowTarget->GetActorRotation();
				CameraActor->SetActorLocation(Loc);
				CameraActor->SetActorRotation(FRotator(0, Rotator.Yaw, 0));
				break;
			}
			case ECameraFollowType::Attach:
			case ECameraFollowType::FollowNone:
			default:
			{
				break;
			}
		}
	}
}


void AKMGameCameraManager::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	UpdateFollowTarget(DeltaSeconds);
	UpdateSendClientCamera(DeltaSeconds);
}

APawn* AKMGameCameraManager::GetCameraTargetPawn()
{
	if (WatchedPawn && !WatchedPawn->IsPendingKill())
	{
		return WatchedPawn;
	}
	return UGameplayStatics::GetPlayerPawn(this, 0);
}

void AKMGameCameraManager::SetWatchTarget(APawn* InSyncPawn)
{
	WatchedPawn = InSyncPawn;
}


void AKMGameCameraManager::ActiveCameraMode(ECameraModeType InfoType, UInfoBase* Info)
{
	IKMCameraInfoInterface* InfoModifier = Cast<IKMCameraInfoInterface>(CurrentMorifierMap[InfoType]);
	InfoModifier->ApplyCameraInfo(Info);
    CurrentMorifierMap[InfoType]->EnableModifier();

	if (InfoType == ECameraModeType::ModeSyncArmRot)
	{
		USyncArmRotInfo* ArmSyncInfo = Cast<USyncArmRotInfo>(Info);
		if (ArmSyncInfo)
		{
			SetWatchTarget(ArmSyncInfo->SyncPawn);
		}
	}
}

void AKMGameCameraManager::DeactiveCameraMode(ECameraModeType InfoType)
{
    CurrentMorifierMap[InfoType]->DisableModifier(true);
}

ECameraAngleType AKMGameCameraManager::GetCameraVerticleAngleType()
{
	UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
	float Pitch = SpringArm->GetRelativeRotation().Pitch;
	if (Pitch > LookAngleUpLimit)
	{
		return ECameraAngleType::LookUp;
	}
	else if (Pitch < LookAngleDownLimit)
	{
		return ECameraAngleType::LookDown;
	}
	else
	{
		return ECameraAngleType::LookForward;
	}
}

void AKMGameCameraManager::EnableCameraMoveCollisionCheck(bool bEnable, bool bCrawl)
{
	UKMCameraHandleMoveModifier* MoveMod = Cast<UKMCameraHandleMoveModifier>(CurrentMorifierMap[ECameraModeType::ModeHandleMove]);
	if (MoveMod)
	{
        MoveMod->SetEnableCollisionCheck(bEnable);
		MoveMod->SetIsResetOrigin(bCrawl);
	}
}

void AKMGameCameraManager::EnableCameraMoveBackOrigin(bool bReset)
{
	UKMCameraHandleMoveModifier* MoveMod = Cast<UKMCameraHandleMoveModifier>(CurrentMorifierMap[ECameraModeType::ModeHandleMove]);
	if (MoveMod)
	{
		MoveMod->SetIsResetOrigin(bReset);
	}
}

void AKMGameCameraManager::SetForceUpdateClientCamera(bool bForce, APawn* Target)
{
	bForceUpdateClientCamera = bForce;
	if (Target)
	{
		TargetPawn = Target;
	}
}

void AKMGameCameraManager::UpdateSendClientCamera(float DeltaSeconds)
{
	if (bForceUpdateClientCamera)
	{
		if ( TargetPawn && !TargetPawn->IsPendingKill() && this->bUseClientSideCameraUpdates)
		{
			UPawnMovementComponent* PawnMovement = TargetPawn->GetMovementComponent();
			if (PawnMovement != nullptr &&
				!PawnMovement->IsMoveInputIgnored() &&
				(PawnMovement->GetLastInputVector() != FVector::ZeroVector || PawnMovement->Velocity != FVector::ZeroVector))
			{
				this->bShouldSendClientSideCameraUpdate = true;
			}
		}
	}
}

void AKMGameCameraManager::ForceSendClientCamera()
{
	if (!this->bShouldSendClientSideCameraUpdate)
	{
		this->bShouldSendClientSideCameraUpdate = true;
	}
}