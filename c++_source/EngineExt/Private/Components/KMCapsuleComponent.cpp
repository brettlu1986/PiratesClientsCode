// Fill out your copyright notice in the Description page of Project Settings.

#include "KMCapsuleComponent.h"
#include "EngineExt.h"
#include "KMCharacter.h"
#include "KMCharacterMovementComponent.h"

UKMCapsuleComponent::UKMCapsuleComponent(const FObjectInitializer& ObjectInitializer /*= FObjectInitializer::Get()*/)
	: Super(ObjectInitializer)
{
}

//bool UKMCapsuleComponent::MoveComponentImpl(const FVector& Delta, const FQuat& NewRotation, bool bSweep, FHitResult* Hit, EMoveComponentFlags MoveFlags, ETeleportType Teleport)
//{
//	FQuat OldQuat = FQuat::Identity;
//	AActor *ActorOwner = GetOwner();
//	if (ActorOwner)
//	{
//		OldQuat = ActorOwner->GetActorQuat();
//	}
//	
//	// 在使用 Custom Movement 模式下，由于播放Root Motion的时候不进行客户端与服务器的数据交换，
//	// 所以当有朝向变化的时候（如使用SetActorRotation等操作），需要通知所属Actor
//	// TODO NewRotation精度需要调整到与Character中Rotation Quantizatoin Level一致以节省带宽
//	bool MoveResult = Super::MoveComponentImpl(Delta, NewRotation, bSweep, Hit, MoveFlags, Teleport);
//	if (MoveResult)
//	{
//		AKMCharacter *Owner = Cast<AKMCharacter>(ActorOwner);
//		if (Owner && !Owner->IsLocallyControlled() && Owner->GetRemoteRole() == ROLE_AutonomousProxy)
//		{
//			UKMCharacterMovementComponent *MovementComponent = Cast<UKMCharacterMovementComponent>(Owner->GetMovementComponent());
//			if (MovementComponent && MovementComponent->bUseCustomCharacterMovement && MovementComponent->bStopSyncWhenPlayingRootMotion && Owner->IsPlayingRootMotion() && NewRotation != OldQuat)
//			{
//				UE_LOG(LogNetPlayerMovement, Verbose, TEXT("Notify client change rotation"));
//				Owner->ClientChangeRotation(NewRotation);
//			}
//		}
//	}
//	
//	return MoveResult;
//}

