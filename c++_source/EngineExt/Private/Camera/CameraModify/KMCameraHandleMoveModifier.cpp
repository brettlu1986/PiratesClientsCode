#include "Camera/CameraModify/KMCameraHandleMoveModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "Kismet/GameplayStatics.h"
#include "KMGameCameraManager.h"
#include "Kismet/KismetMathLibrary.h"
#include "Components/KMSpringArmComponent.h"

UKMCameraHandleMoveModifier::UKMCameraHandleMoveModifier(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
	, HandleMoveInfo(nullptr)
	, CacheArmRot(FRotator::ZeroRotator)
	, bCameraArmBack(false)
	, InterpSpeed(0.f)
	, AnimTime(0.f)
	, MoveToGo(FVector::ZeroVector)
	, MoveHasGo(FVector::ZeroVector)
	, MoveWillGo(FVector::ZeroVector)
    , bCollisionCheck(false)
	, bIsResetOrigin(false)
	, CollisionCheckBox(90, 32, 2)
{
}

void UKMCameraHandleMoveModifier::MoveCamera(float MoveX, float MoveY)
{

	APlayerController* PlayerController = UGameplayStatics::GetPlayerController(this, 0);
	APawn* Pawn = PlayerController->GetPawn();

	bool bSupportPlayerInput = false;
	if (Pawn && !Pawn->IsPendingKill())
	{
		bSupportPlayerInput = true;
	}

	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();

	UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
	MoveY *= -1.f;
	float NewPitch = SpringArm->GetRelativeRotation().Pitch + MoveY;
	NewPitch = FMath::ClampAngle(NewPitch, CameraManager->ViewPitchMin, CameraManager->ViewPitchMax);
	switch (HandleMoveInfo->MoveType)
	{
		case EHandleInputType::UseController:
		{
			if (bSupportPlayerInput)
			{
				Pawn->AddControllerYawInput(MoveX);
				Pawn->AddControllerPitchInput(MoveY * -1.f);
			}
			break;
		}
		case EHandleInputType::UseControllerArmPitch:
		{
			if (bSupportPlayerInput)
			{
                FRotator Dir = Pawn->GetActorRotation();
                Dir += PlayerController->RotationInput;
                //FRotator(0, Character->GetActorRotation().Yaw + HandleMoveInfo->MoveX, 0).Vector();
                //Dir.Normalize();
                Dir.Yaw += MoveX * PlayerController->InputYawScale;
                if(CheckCanChangeYaw(Dir))
                    Pawn->AddControllerYawInput(MoveX);
                Pawn->AddControllerPitchInput(MoveY * -1.f);
				SpringArm->SetRelativeRotation(FRotator(NewPitch, SpringArm->GetRelativeRotation().Yaw, SpringArm->GetRelativeRotation().Roll));
			}
			break;
		}
		case EHandleInputType::UseArm:
		{
			float NewYaw = SpringArm->GetRelativeRotation().Yaw + MoveX;
			SpringArm->SetRelativeRotation(FRotator(NewPitch, NewYaw, SpringArm->GetRelativeRotation().Roll));
			break;
		}
		case EHandleInputType::UseControllerPitchNegativeArm:
		{
			if (bSupportPlayerInput)
			{
				Pawn->AddControllerYawInput(MoveX);
				Pawn->AddControllerPitchInput(MoveY * -1.f);
				float NewYaw = SpringArm->GetRelativeRotation().Yaw + MoveX;
				SpringArm->SetRelativeRotation(FRotator(NewPitch, NewYaw, SpringArm->GetRelativeRotation().Roll));
			}
			break;
		}
		case EHandleInputType::UseControllerArm:
		{
			if (bSupportPlayerInput)
			{
				FRotator Dir = Pawn->GetActorRotation();
				Dir += PlayerController->RotationInput;
				Dir.Yaw += MoveX * PlayerController->InputYawScale;
				float NewYaw = SpringArm->GetRelativeRotation().Yaw;
				if (CheckCanChangeYaw(Dir))
				{
					Pawn->AddControllerYawInput(MoveX);
					NewYaw = SpringArm->GetRelativeRotation().Yaw + MoveX;
				}

				Pawn->AddControllerPitchInput(MoveY * -1.f);
				SpringArm->SetRelativeRotation(FRotator(NewPitch, NewYaw, SpringArm->GetRelativeRotation().Roll));
			}
			break;
		}
		case EHandleInputType::UseNone:
		default:
		{
			break;
		}
	}
}

void UKMCameraHandleMoveModifier::ApplyCameraInfo(UInfoBase* Info)
{
	HandleMoveInfo = Cast<UHandleMoveInfo>(Info);

	if (HandleMoveInfo)
	{
		if (HandleMoveInfo->bWithAnim)
		{
			MoveToGo.X = HandleMoveInfo->MoveX;
			MoveToGo.Y = HandleMoveInfo->MoveY;
			MoveHasGo = FVector::ZeroVector;
			MoveWillGo = FVector::ZeroVector;
			AnimTime = HandleMoveInfo->AnimTime;
		}
		else
		{
			MoveCamera(HandleMoveInfo->MoveX, HandleMoveInfo->MoveY);
		}
	}
}

FRotator UKMCameraHandleMoveModifier::GetCacheArmRot() const
{
	return CacheArmRot;
}

void UKMCameraHandleMoveModifier::InitDataCache()
{
	if (!bCameraArmBack)
	{
		AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
		if (bIsResetOrigin)
		{
			CacheArmRot = SpringArm->GetRelativeRotation();
		}
		else
		{
			CacheArmRot = FRotator(SpringArm->GetRelativeRotation().Pitch, 0.f, SpringArm->GetRelativeRotation().Roll);
		}	
		bCameraArmBack = false;
	}
}

void UKMCameraHandleMoveModifier::ResetDataCache(bool bWithAnim, float InInterpSpeed)
{
	if (!bIsResetOrigin)
	{
		CacheArmRot.Yaw = 0.f;
	}

	if (bWithAnim)
	{
		bCameraArmBack = true;
		InterpSpeed = InInterpSpeed;
	}
	else
	{
		bCameraArmBack = false;
		AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
		SpringArm->SetRelativeRotation(CacheArmRot);
	}
}

void UKMCameraHandleMoveModifier::ForceToResetFreeViewRotation()
{
	if (bCameraArmBack)
	{
		AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
		if (!bIsResetOrigin)
		{
			CacheArmRot.Yaw = 0.f;
		}
		SpringArm->SetRelativeRotation(CacheArmRot);
		bCameraArmBack = false;
	}
}

bool UKMCameraHandleMoveModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
    Super::ModifyCamera(DeltaTime, InOutPOV);

    AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
    if (!IsValid(CameraManager) || IsDisabled())
    {
        return false;
    }

	if (HandleMoveInfo && !HandleMoveInfo->IsZero())
	{
		//TODO:change param to camera
	}

	if (bCameraArmBack)
	{
		AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
		UKMSpringArmComponent* SpringArm = CameraActor->GetSpringArm();
		FRotator ArmRot = SpringArm->GetRelativeRotation();
		if (ArmRot.Equals(CacheArmRot, 0.1f))
		{
			bCameraArmBack = false;
		}
		else
		{
			FRotator NewRot = FMath::RInterpTo(ArmRot, CacheArmRot, DeltaTime, InterpSpeed);
			SpringArm->SetRelativeRotation(NewRot);
		}
	}

	if (HandleMoveInfo->bWithAnim)
	{
		AnimTime -= DeltaTime;
		if (AnimTime > 0)
		{
			float DurationPct = (HandleMoveInfo->AnimTime - AnimTime) / HandleMoveInfo->AnimTime;
			float BlendPct = FMath::Lerp(0.f, 1.f, DurationPct);
			MoveWillGo = MoveToGo * BlendPct;

			FVector Offset = MoveWillGo - MoveHasGo;
			MoveCamera(Offset.X, Offset.Y);
			MoveHasGo = MoveWillGo;
			//UE_LOG(LogTemp, Log, TEXT("Pct ::%f, MoveToGo ::%s, MoveHasGo::%s"), BlendPct, *(MoveToGo.ToString()), *(MoveHasGo.ToString()) );
		}
		else
		{
			FVector OffsetFinal = MoveToGo - MoveHasGo;
			MoveCamera(OffsetFinal.X, OffsetFinal.Y);
			//UE_LOG(LogTemp, Log, TEXT("Pct ::OffsetFinal ::%s"),  *(OffsetFinal.ToString()) );
			AnimTime = 0;
			HandleMoveInfo->bWithAnim = false;
		}
	}

    return false;
}

bool UKMCameraHandleMoveModifier::CheckCanChangeYaw(const FRotator& Dir)
{
    if (!bCollisionCheck)
        return true;

    ACharacter* Character = UGameplayStatics::GetPlayerCharacter(this, 0);
	if (Character && !Character->IsPendingKill())
	{
		FVector StartTrace = Character->GetActorLocation();
		//FVector EndTrace = StartTrace + Dir * 50;
		TArray<AActor*> ActorsToIgnore;
		ActorsToIgnore.Add(Character);
		FHitResult HitResult;
		TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
		ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
		bool Result = UKismetSystemLibrary::BoxTraceSingleForObjects(Character, StartTrace, StartTrace, CollisionCheckBox, Dir, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);
		return !Result;
	}
	return true;
    
}
