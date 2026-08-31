// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Components/SpecialMovementComponent.h"
#include "Common.h"
#include "Delegates/KMDelegateManager.h"
#include "Game/GameEngineExt.h"
#include "AIController.h"

USpecialMovementComponent::USpecialMovementComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, ControlledByServer(false)
	, LastSavedYaw(0.0f)
{
	PrimaryComponentTick.bCanEverTick = true;

#ifndef USE_AICONTROLLER
	DestLocation = FVector::ZeroVector;
	SrcLocation = FVector::ZeroVector;
	DestLocationPercentage = 0.0f;
	DestRotation = FQuat::Identity;
	SrcRotation = FQuat::Identity;
	DestRotationPercentage = 0.0f;
#endif
}

void USpecialMovementComponent::Init(bool ByServer)
{
	ControlledByServer = ByServer;

#ifdef USE_AICONTROLLER
	if (ControlledByServer)
	{
		AAIController* AIController = GetOwner()->GetWorld()->SpawnActor<AAIController>();
		AIController->Possess(PawnOwner);
	}
#endif

	auto Owner = GetOwner();
	DestLocation = Owner->GetActorLocation();
	DestRotation = Owner->GetActorQuat();
	DestLocationPercentage = 1.0f;
	DestRotationPercentage = 1.0f;
}

void USpecialMovementComponent::Uninit()
{
#ifdef USE_AICONTROLLER
	auto AIController = CastChecked<AAIController>(PawnOwner->GetController());
	if (AIController)
	{
		PawnOwner->GetWorld()->DestroyActor(AIController);
	}
#endif
}

void USpecialMovementComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
	if (!IsValid())
	{
		return;
	}

	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (ControlledByServer)
	{
		TickControlledByServer(DeltaTime, TickType, ThisTickFunction);
	}
	else
	{
		TickControlledBySelf(DeltaTime, TickType, ThisTickFunction);
	}
}

void USpecialMovementComponent::BeginPlay()
{
	Super::BeginPlay();
}

void USpecialMovementComponent::SetSynData(const FVector& Location, float Yaw, int MoveState)
{
	if (ControlledByServer)
	{
#ifdef USE_AICONTROLLER
		auto AIController = CastChecked<AAIController>(PawnOwner->GetController());
		if (AIController)
		{
			AIController->MoveToLocation(Location, -1.0f, true, false);
		}
#else
		auto Owner = GetOwner();
		SrcLocation = Owner->GetActorLocation();
		SrcRotation = Owner->GetActorQuat();
		FRotator Rotator = Owner->GetActorRotation();
		Rotator.Yaw = Yaw;
		DestLocation = Location;
		DestRotation = Rotator.Quaternion();
		DestLocationPercentage = 0.0f;
		DestRotationPercentage = 0.0f;
#endif
	}
}

void USpecialMovementComponent::TickControlledByServer(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
	// 这里按照1秒到目标move过去，纯粹为了测试
	auto Owner = GetOwner();
	float MaxMoveToTargetLocationTime = 1.0f;
	float MaxMoveToTargetRotationTime = 0.2f;

	float LocationPercentage = DeltaTime / MaxMoveToTargetLocationTime;
	DestLocationPercentage += LocationPercentage;
	DestLocationPercentage = DestLocationPercentage > 1.0f ? 1.0f : DestLocationPercentage;
	FVector NewPostion = (DestLocation - SrcLocation)*DestLocationPercentage + SrcLocation;
	Owner->SetActorLocation(NewPostion);
	//Velocity = (DestLocation - SrcLocation).SafeNormal(0.001f) * 700.0f;

	float RotationPercentage = DeltaTime / MaxMoveToTargetRotationTime;
	DestRotationPercentage += RotationPercentage;
	DestRotationPercentage = DestRotationPercentage > 1.0f ? 1.0f : DestRotationPercentage;
	FQuat NewRotation = FQuat::Slerp(SrcRotation, DestRotation, DestRotationPercentage);
	Owner->SetActorRotation(NewRotation);
}

void USpecialMovementComponent::TickControlledBySelf(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
	auto Owner = GetOwner();
	FVector NewLocation = Owner->GetActorLocation();
	FRotator NewRotator = Owner->GetActorRotation();
	bool MovementChanged = FGenericPlatformMath::Abs(NewRotator.Yaw - LastSavedYaw) > 10.0f
		|| (FVector::Dist(LastSavedLocation, NewLocation) > 1000.0f);

	if (MovementChanged)
	{
		LastSavedLocation = NewLocation;
		LastSavedYaw = NewRotator.Yaw;
		OnSpecialMovementChanged.ExecuteIfBound(this, NewLocation, LastSavedYaw, GetMoveState());
	}
}
