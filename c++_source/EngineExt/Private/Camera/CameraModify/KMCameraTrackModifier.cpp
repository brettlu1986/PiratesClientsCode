#include "Camera/CameraModify/KMCameraTrackModifier.h"
#include "EngineExt.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "Camera/KMGameCameraManager.h"
#include "KMCharacter.h"
#include "Kismet/KismetMathLibrary.h"

UKMCameraTrackModifier::UKMCameraTrackModifier(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, TrackInfo(nullptr)
	, DelayBeginTime(0.f)
	, TrackType(ETrackType::PlaceHolder)
	, TrackOnceTarget(FVector::ZeroVector)
	, bTrackOnceInit(false)
	, bTrackOnceStart(false)
	, TimeMin(0.f)
	, TimeRange(0.f)
	, TimeChange(0.f)
	, CacheTrackOnceTime(0.5f)
	, bBackFromMontage(false)
{
}

bool UKMCameraTrackModifier::IsCharacterMoving()
{
	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	AKMCharacter* Player = Cast<AKMCharacter>(CameraManager->GetCameraTargetPawn());
	if (Player)
	{
		UCharacterMovementComponent* MovementCom = Player->GetCharacterMovement();
		if (MovementCom->IsWalking() && MovementCom->Velocity != FVector::ZeroVector)
			return true;
	}
	return false;
}

bool UKMCameraTrackModifier::IsPlayingMontage()
{
	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	AKMCharacter* Player = Cast<AKMCharacter>(CameraManager->GetCameraTargetPawn());
	if (Player && Player->GetMesh())
	{
		USkeletalMeshComponent* SKMComponent = Player->GetMesh();
		auto AnimIns = SKMComponent->GetAnimInstance();
		return AnimIns->Montage_IsPlaying(nullptr);
	}
	return false;
}



bool UKMCameraTrackModifier::IsUseTrackCurve()
{
	return IsValid(StartToTargetCurve) && !bBackFromMontage;
}

void UKMCameraTrackModifier::ApplyCameraInfo(UInfoBase* Info)
{
	TrackInfo = Cast<UCameraTrackInfo>(Info);
	if (TrackInfo)
	{
		bool IsMoving = IsCharacterMoving();
		bTrackOnceInit = false;
		bTrackOnceStart = false;
		bBackFromMontage = false;
		bool IsCurveValid = IsValid(StartToTargetCurve);
		if (IsCurveValid)
		{
			StartToTargetCurve->GetTimeRange(TimeMin, TimeRange);
			TimeChange = TimeMin;
		}
		
		if (IsMoving)
		{
			SetTrackOnce();
		}
		else
		{
			//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier ApplyCameraInfo Tracking"));
			DelayBeginTime = TrackInfo->DelayBeginTime;
			TrackType = ETrackType::Tracking;
			TrackOnceTarget = FVector::ZeroVector;
		}
	}
}

void UKMCameraTrackModifier::ForceTrackOnce()
{
	bTrackOnceInit = false;
	bTrackOnceStart = false;
	CacheTrackOnceTime = 0.5f;
	SetTrackOnce();
}

void UKMCameraTrackModifier::SetTrackOnce()
{
	if (!bTrackOnceInit)
	{
		//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier SetTrackOnce "));
		DelayBeginTime = TrackInfo->DelayTrackOnceTime;
		TrackType = ETrackType::TrackOnce;
		CacheTrackOnceTime = 0.5f;
		bTrackOnceInit = true;
	}
}


void UKMCameraTrackModifier::Tracking(float DeltaTime, const FVector& TargetLoc)
{
	bool bMontagePlay = IsPlayingMontage();
	if (bMontagePlay)
	{
		//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier Montage is playing "));
		//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier will not use curve "));
		bBackFromMontage = true;
		return;
	}
	AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
	/*if (!CameraManager->IsCurrentShakeFinished())
	{
		return;
	}*/
	AKMGameCameraActor* CameraActor = CameraManager->GetPlayerCameraActor();
	FVector RelativeLoc = CameraActor->GetRootComponent()->GetRelativeLocation();
	FVector TargetLocation = FVector(TargetLoc.X + TrackInfo->OffsetForward, TargetLoc.Y, TargetLoc.Z);

	if (IsUseTrackCurve())
	{
		if (RelativeLoc.Equals(TargetLocation, 0.001))
		{
			TimeChange = TimeRange;
		}
		else
		{
			TimeChange = TimeChange + DeltaTime;
			if (TimeChange >= TimeRange)
				TimeChange = TimeMin;
		}

		float InterpAlpha = StartToTargetCurve->GetFloatValue(TimeChange);
		FVector FinalLoc = UKismetMathLibrary::VLerp(RelativeLoc, TargetLocation, InterpAlpha);
		CameraActor->SetActorRelativeLocation(FinalLoc);
		//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier use curve TargetLoc: ::%s, FinalLoc: ::%s"), *(TargetLocation.ToString()), *(FinalLoc.ToString()));
	}
	else
	{
		
		FVector FinalLoc = UKismetMathLibrary::VInterpTo(RelativeLoc, TargetLocation, DeltaTime, TrackInfo->TrackParam);
		CameraActor->SetActorRelativeLocation(FinalLoc);
		//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier not use curve TargetLoc: ::%s, FinalLoc: ::%s"), *(TargetLocation.ToString()), *(FinalLoc.ToString()));
		if (RelativeLoc.Equals(TargetLocation, 0.015f))
		{
			bBackFromMontage = false;
		}
	}
	
	/*UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier  TargetLoc: ::%s"), *(TargetLocation.ToString()));
	UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier  FinalLoc: ::%s"), *(FinalLoc.ToString()));*/
}

FTransform UKMCameraTrackModifier::GetRefTransform()
{
	FTransform RefMeshTrans = TrackInfo->RefMeshComponent->GetComponentTransform();
	RefMeshTrans = UKismetMathLibrary::ComposeTransforms(TrackInfo->SightRelativaTransform, RefMeshTrans );

	/*FVector LocOffset = UKismetMathLibrary::TransformLocation(RefMeshTrans, TrackInfo->SightRelativaTransform.GetLocation());
	RefMeshTrans.SetLocation(LocOffset);*/

	/*USkeletalMeshComponent* MeshCom = Cast<USkeletalMeshComponent>(TrackInfo->RefMeshComponent);
	int32 BoneIndex = MeshCom->GetBoneIndex(FName(TEXT("Weapons001")));
	FTransform RefMeshTrans = MeshCom->GetBoneTransform(BoneIndex);*/

	return UKismetMathLibrary::MakeRelativeTransform(
		RefMeshTrans,
		TrackInfo->TargetMeshComponent->GetSocketTransform(TrackInfo->TargetSocket)
	);
}


bool UKMCameraTrackModifier::ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV)
{
    Super::ModifyCamera(DeltaTime, InOutPOV);

    AKMGameCameraManager* CameraManager = Cast<AKMGameCameraManager>(CameraOwner);
    if (!IsValid(CameraManager) || IsDisabled())
    {
        return false;
    }

    if (TrackInfo && !TrackInfo->IsZero())
    {
		DelayBeginTime -= DeltaTime;
		if (DelayBeginTime > 0)
		{
			//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier ModifyCamera DelayBeginTime count "));
			return false;
		}

		if (TrackInfo->TargetMeshComponent && TrackInfo->RefMeshComponent)
		{
			if (TrackInfo->TargetMeshComponent->DoesSocketExist(TrackInfo->TargetSocket))
			{
				
				if (IsCharacterMoving())
				{
					SetTrackOnce();
				}
				else
				{
					bTrackOnceInit = false;
					bTrackOnceStart = false;
					CacheTrackOnceTime = 0.5f;
					TrackType = ETrackType::Tracking;
				}

				switch (TrackType)
				{
					case ETrackType::TrackOnce:
					{
						if (bTrackOnceStart)
						{
							CacheTrackOnceTime -= DeltaTime;
							if (CacheTrackOnceTime > 0.f)
							{
								FTransform RefTransform = GetRefTransform();
								TrackOnceTarget = RefTransform.GetLocation();
							}
							//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier TrackOnce Tracking: ::%s"), *(TrackOnceTarget.ToString()));
							Tracking(DeltaTime, TrackOnceTarget);
						}

						if (DelayBeginTime <= 0.f && !bTrackOnceStart)
						{
							//UE_LOG(LogTemp, Log, TEXT("UKMCameraTrackModifier TrackOnce Start: ::%s"), *(TrackOnceTarget.ToString()));
							bTrackOnceStart = true;
						}
							
						break;
					}
					case ETrackType::Tracking:
					{
						FTransform RefTransform = GetRefTransform();
						Tracking(DeltaTime, RefTransform.GetLocation());
						break;
					}
					default:
					{
						break;
					}
				}
			}
		}
    }
    return false;
}
