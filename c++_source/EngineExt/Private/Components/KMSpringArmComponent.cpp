#include "Components/KMSpringArmComponent.h"
#include "GameFramework/Pawn.h"
#include "CollisionQueryParams.h"
#include "WorldCollision.h"
#include "Kismet/KismetMathLibrary.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "PhysicsEngine/PhysicsSettings.h"

static const float KISMET_TRACE_DEBUG_IMPACTPOINT_SIZE = 16.f;

UKMSpringArmComponent::UKMSpringArmComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	XVel = 15.f;
	ZVel = 10.f;
	ZRecoverVel = 10.f;
	//UpTraceLength = 100;
	UpMinDistance = 80.f;
	UpTraceValidDistance = 10.f;
	FixOffset = -14.f;
	FixBackStartOffset = 35.f;

	UpTargetLocation = FVector::ZeroVector;
	BackTargetLocation = FVector::ZeroVector;
	bBackHitted = false;

	bEnableLocationLag = false;
	LocationLagTime = 0.5f;
	LocationLagSpeed = 10.f;
	LocationLagRecoverAccSpeed = 1000.f;
	LocationLagRecoverMaxSpeed = 600.f;
	LocationLagRecoverCurSpeed = 0.f;
	PreArmLocationZ = 0.f;
	bUpHitted = false;

	QueryParams = FCollisionQueryParams(SCENE_QUERY_STAT(SpringArm), false, GetOwner());

}
//
//void DrawDebugLineTraceSingle(const UWorld* World, const FVector& Start, const FVector& End, EDrawDebugTrace::Type DrawDebugType, bool bHit, const FHitResult& OutHit, FLinearColor TraceColor, FLinearColor TraceHitColor, float DrawTime)
//{
//	if (DrawDebugType != EDrawDebugTrace::None)
//	{
//		bool bPersistent = DrawDebugType == EDrawDebugTrace::Persistent;
//		float LifeTime = (DrawDebugType == EDrawDebugTrace::ForDuration) ? DrawTime : 0.f;
//
//		// @fixme, draw line with thickness = 2.f?
//		if (bHit && OutHit.bBlockingHit)
//		{
//			// Red up to the blocking hit, green thereafter
//			::DrawDebugLine(World, Start, OutHit.ImpactPoint, TraceColor.ToFColor(true), bPersistent, LifeTime);
//			::DrawDebugLine(World, OutHit.ImpactPoint, End, TraceHitColor.ToFColor(true), bPersistent, LifeTime);
//			::DrawDebugPoint(World, OutHit.ImpactPoint, KISMET_TRACE_DEBUG_IMPACTPOINT_SIZE, TraceColor.ToFColor(true), bPersistent, LifeTime);
//		}
//		else
//		{
//			// no hit means all red
//			::DrawDebugLine(World, Start, End, TraceColor.ToFColor(true), bPersistent, LifeTime);
//		}
//	}
//}

FCollisionObjectQueryParams ConfigCollisionObjectParams(const TArray<TEnumAsByte<EObjectTypeQuery> > & ObjectTypes)
{
	TArray<TEnumAsByte<ECollisionChannel>> CollisionObjectTraces;
	CollisionObjectTraces.AddUninitialized(ObjectTypes.Num());

	for (auto Iter = ObjectTypes.CreateConstIterator(); Iter; ++Iter)
	{
		CollisionObjectTraces[Iter.GetIndex()] = UEngineTypes::ConvertToCollisionChannel(*Iter);
	}

	FCollisionObjectQueryParams ObjectParams;
	for (auto Iter = CollisionObjectTraces.CreateConstIterator(); Iter; ++Iter)
	{
		const ECollisionChannel & Channel = (*Iter);
		if (FCollisionObjectQueryParams::IsValidObjectQuery(Channel))
		{
			ObjectParams.AddObjectTypesToQuery(Channel);
		}
		else
		{
			UE_LOG(LogBlueprintUserMessages, Warning, TEXT("%d isn't valid object type"), (int32)Channel);
		}
	}

	return ObjectParams;
}


void UKMSpringArmComponent::EnableCameraLocationLagWithTimeAndSpeed(bool enable, float time, float speed)
{
	bEnableLocationLag = enable;
	LocationLagTime = time;
	LocationLagSpeed = speed;
	LocationLagRecoverCurSpeed = 0.f;
}

void UKMSpringArmComponent::AddArmCollisionIgnoreActor(AActor* IgnoreActor)
{
	if (IgnoreActor && !IgnoreActor->IsPendingKill())
	{
		QueryParams.AddIgnoredActor(IgnoreActor);
	}
}

void UKMSpringArmComponent::UpdateDesiredArmLocation(bool bDoTrace, bool bDoLocationLag, bool bDoRotationLag, float DeltaTime)
{
	FRotator DesiredRot = GetTargetRotation();

	const float InverseCameraLagMaxTimeStep = (1.f / CameraLagMaxTimeStep);

	// Apply 'lag' to rotation if desired
	if (bDoRotationLag)
	{
		if (bUseCameraLagSubstepping && DeltaTime > CameraLagMaxTimeStep && CameraRotationLagSpeed > 0.f)
		{
			const FRotator ArmRotStep = (DesiredRot - PreviousDesiredRot).GetNormalized() * (CameraLagMaxTimeStep / DeltaTime);
			FRotator LerpTarget = PreviousDesiredRot;
			float RemainingTime = DeltaTime;
			while (RemainingTime > KINDA_SMALL_NUMBER)
			{
				const float LerpAmount = FMath::Min(CameraLagMaxTimeStep, RemainingTime);
				LerpTarget += ArmRotStep * (LerpAmount * InverseCameraLagMaxTimeStep);
				RemainingTime -= LerpAmount;

				DesiredRot = FRotator(FMath::QInterpTo(FQuat(PreviousDesiredRot), FQuat(LerpTarget), LerpAmount, CameraRotationLagSpeed));
				PreviousDesiredRot = DesiredRot;
			}
		}
		else
		{
			DesiredRot = FRotator(FMath::QInterpTo(FQuat(PreviousDesiredRot), FQuat(DesiredRot), DeltaTime, CameraRotationLagSpeed));
		}
	}
	PreviousDesiredRot = DesiredRot;

	// Get the spring arm 'origin', the target we want to look at
	FVector ArmOrigin = GetComponentLocation() + TargetOffset;
	// We lag the target, not the actual camera position, so rotating the camera around does not have lag
	FVector DesiredLoc = ArmOrigin;

	// Now offset camera position back along our rotation
	DesiredLoc -= DesiredRot.Vector() * TargetArmLength;
	// Add socket offset in local space
	DesiredLoc += FRotationMatrix(DesiredRot).TransformVector(SocketOffset);

	// Do a sweep to ensure we are not penetrating the world
	FVector ResultLoc;
	if (bDoTrace && (TargetArmLength != 0.0f))
	{
		bIsCameraFixed = true;
		//FCollisionQueryParams QueryParams(SCENE_QUERY_STAT(SpringArm), false, GetOwner());
		ACharacter* Character = UGameplayStatics::GetPlayerCharacter(this, 0);
		if (Character && !Character->IsPendingKill())
		{
			QueryParams.AddIgnoredActor(Character);
		}

		//no use for now, but referenced in engine, so keep it
		UnfixedCameraPosition = DesiredLoc;

		//trace up
		FHitResult TopResult;
		FVector UpStartLoc = GetComponentLocation() + FVector(0, 0, FixOffset + SocketOffset.Z);
		FVector UpEndLoc = UpStartLoc + FVector(0, 0, 1) * UpMinDistance;//UpTraceLength;

		FCollisionObjectQueryParams ObjectParams = ConfigCollisionObjectParams(TraceObjectTypes);
		bool const bHitTop = GetWorld()->SweepSingleByObjectType(TopResult, UpStartLoc, UpEndLoc, FQuat::Identity, ObjectParams, FCollisionShape::MakeSphere(ProbeSize), QueryParams);
		//bool const bHitTop = GetWorld()->SweepSingleByChannel(TopResult, UpStartLoc, UpEndLoc, FQuat::Identity, ProbeChannel, FCollisionShape::MakeSphere(ProbeSize), QueryParams);
		//DrawDebugLineTraceSingle(GetWorld(), UpStartLoc, UpEndLoc, EDrawDebugTrace::ForDuration, bHitTop, TopResult, FLinearColor::Red, FLinearColor::Green, 1.f);

		//this is to change the  arm component relative location
		BlendLocationsForUpTrace(UpStartLoc, TopResult.Location, bHitTop, DeltaTime);

		//calculate upresult loc
		FVector UpResultLoc = GetComponentLocation() - DesiredRot.Vector() * TargetArmLength;
		UpResultLoc += FRotationMatrix(DesiredRot).TransformVector(SocketOffset);

		//trace back
		FHitResult BackResult;
		//not equal to UpStartLoc, becaust the component location may change
		FVector BackStartLoc = GetComponentLocation() + FVector(0, 0, FixOffset + SocketOffset.Z);
		BackStartLoc -= DesiredRot.Vector() * FixBackStartOffset;

		bool const bHitBack = GetWorld()->SweepSingleByChannel(BackResult, BackStartLoc, UpResultLoc, FQuat::Identity, ProbeChannel, FCollisionShape::MakeSphere(ProbeSize), QueryParams);
		//DrawDebugLineTraceSingle(GetWorld(), BackStartLoc, UpResultLoc, EDrawDebugTrace::ForDuration, bHitBack, BackResult, FLinearColor::Red, FLinearColor::Green, 1.f);
		ResultLoc = BlendLocationsForBackTrace(UpResultLoc, BackResult.Location, DesiredRot, bHitBack, DeltaTime);

		if (ResultLoc == DesiredLoc)
		{
			bIsCameraFixed = false;
		}

	}
	else
	{
		ResultLoc = DesiredLoc;
		bIsCameraFixed = false;
		UnfixedCameraPosition = ResultLoc;
	}

	if (bEnableLocationLag)
	{
		LocationLagTime -= DeltaTime;
		ResultLoc = FMath::VInterpTo(PreviousDesiredLoc, ResultLoc, DeltaTime, LocationLagSpeed);
		if (LocationLagTime <= 0)
		{
			LocationLagRecoverCurSpeed = LocationLagSpeed + LocationLagRecoverAccSpeed * DeltaTime;
			if (LocationLagRecoverCurSpeed >= LocationLagRecoverMaxSpeed)
				LocationLagRecoverCurSpeed = LocationLagRecoverMaxSpeed;
			LocationLagSpeed = LocationLagRecoverCurSpeed;
			if (PreviousDesiredLoc.Equals(ResultLoc, 0.001f))
			{
				bEnableLocationLag = false;
				LocationLagTime = 0;
				//UE_LOG(LogTemp, Log, TEXT("desire arm location equals"));
			}
		}
	}

	PreviousDesiredLoc = ResultLoc;

	// Form a transform for new world transform for camera
	FTransform WorldCamTM(DesiredRot, ResultLoc);
	// Convert to relative to component
	FTransform RelCamTM = WorldCamTM.GetRelativeTransform(GetComponentTransform());

	// Update socket location/rotation
	RelativeSocketLocation = RelCamTM.GetLocation();
	RelativeSocketRotation = RelCamTM.GetRotation();

	UpdateChildTransforms();
}

void UKMSpringArmComponent::UpdatePreArmLocationZ(float LocZ)
{
	PreArmLocationZ = LocZ;
}

void UKMSpringArmComponent::BlendLocationsForUpTrace(const FVector& ArmStartLocation, const FVector& TraceHitLocation, bool bHitSomething, float DeltaTime)
{
    FVector TempRelativeLocation = GetRelativeLocation();
	if (bHitSomething)
	{
		bUpHitted = true;
		float Distance = TraceHitLocation.Z - ArmStartLocation.Z;

		//UE_LOG(LogTemp, Log, TEXT("disLong %f"), Distance);
		if (Distance <= UpMinDistance / 2 && Distance > UpTraceValidDistance)
		{
			FVector CompLoc = TempRelativeLocation;
			SetRelativeLocation(FVector(CompLoc.X, CompLoc.Y, CompLoc.Z - ZVel * DeltaTime));
		}
	}
	else
	{
		if (!bUpHitted)
		{
			PreArmLocationZ = TempRelativeLocation.Z;
		}

		if (TempRelativeLocation.Z != PreArmLocationZ && bUpHitted)
		{
			float InterpLocZ = FMath::FInterpTo(TempRelativeLocation.Z, PreArmLocationZ, DeltaTime, ZRecoverVel);
			//UE_LOG(LogTemp, Log, TEXT("disLong and targetLen %f, %f, %f"), InterpLocZ, TempRelativeLocation.Z, PreArmLocationZ);
			if (FMath::Abs(InterpLocZ - PreArmLocationZ) <= 0.2f)
				InterpLocZ = PreArmLocationZ;
			SetRelativeLocation(FVector(TempRelativeLocation.X, TempRelativeLocation.Y, InterpLocZ));
		}
		else
		{
			if (bUpHitted)
				bUpHitted = false;
		}
	}

}

FVector UKMSpringArmComponent::BlendLocationsForBackTrace(const FVector& UpResultLocation, const FVector& TraceHitLocation, const FRotator& DesireRot, bool bHitSomething, float DeltaTime)
{
	return bHitSomething ? TraceHitLocation : UpResultLocation;

	//return bHitSomething ? TraceHitLocation : DesiredArmLocation;
	/*if (bHitSomething)
	{
		FVector BackStartLoc = GetComponentLocation() + SocketOffset;
		return FVector(TraceHitLocation.X, TraceHitLocation.Y, BackStartLoc.Z);
	}
	return DesiredArmLocation;*/


	//if (bHitSomething)
	//{
	//	FVector BackStartLoc = GetComponentLocation() + SocketOffset;
	//	// select the right Z, so the final z will not so large that can not see the pawn's head
	//	BackTargetLocation = FVector(TraceHitLocation.X, TraceHitLocation.Y, BackStartLoc.Z);
	////	BackTargetLocation = FVector(TraceHitLocation.X, TraceHitLocation.Y, DesiredArmLocation.Z);
	//	bBackHitted = true;
	//	return BackTargetLocation;
	//}
	//else
	//{
	//	if (!bBackHitted)
	//	{
	//		BackTargetLocation = DesiredArmLocation;
	//	}
	//}
	//
	//if (!BackTargetLocation.Equals(DesiredArmLocation, 0.1)  && bBackHitted)
	//{
	//    //先临时这么改一下， interp的过程种 频繁晃镜头 还是会有问题
	//	//BackTargetLocation = FMath::VInterpTo(BackTargetLocation, DesiredArmLocation, DeltaTime, XVel);
	//	BackTargetLocation = DesiredArmLocation;
	//	return  BackTargetLocation;
	//}
	//else
	//{
	//	if(bBackHitted)
	//	{
	//		bBackHitted = false;
	//	}
	//	return DesiredArmLocation;
	//}

	//return bHitSomething ? TraceHitLocation : DesiredArmLocation;
	//UE_LOG(LogTemp, Log, TEXT("desire arm location %s, %s"), *(BackTargetLocation.ToString()), *(DesiredArmLocation.ToString() ));

}