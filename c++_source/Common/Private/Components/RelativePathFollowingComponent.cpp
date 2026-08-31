// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/RelativePathFollowingComponent.h"
#include "Common.h"

URelativePathFollowingComponent::URelativePathFollowingComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryComponentTick.bCanEverTick = 1;
	PrimaryComponentTick.bStartWithTickEnabled = 0;
	PrimaryComponentTick.SetTickFunctionEnable(false);

	PrevNavPoint = FVector::ZeroVector;
	CurrentPathIndex = 0;
}

void URelativePathFollowingComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction * ThisTickFunction)
{
	check(MovementComponent != nullptr);

	/*if (Status != EMapNavGridPathFollowingStatus::Moving)
	{
	return;
	}*/

	FVector& TargetLocation = NavPath[CurrentPathIndex];
	FVector MoveToVector = TargetLocation - GetCurrentLocation();

	bool bIsLast = IsLastPathPoint();

	bool bHasReached = false;
	if (MoveToVector.SizeSquared2D() < FMath::Square(AcceptanceRadius + NavAgentRadius))
	{
		bHasReached = true;
	}
	else if (!bIsLast)
	{
		bHasReached = ((TargetLocation - PrevNavPoint) | MoveToVector) < 0.f;
	}

	if (bHasReached)
	{
		if (bIsLast)
		{
			FinishNavPath(EPathFollowingResult::Type::Success);
			return;
		}

		PrevNavPoint = TargetLocation;
		++CurrentPathIndex;
	}

	RequestMovement(NavPath[CurrentPathIndex], IsLastPathPoint());
}

void URelativePathFollowingComponent::StartMove(float Radius)
{
	UpdateMovementData(true);

	AcceptanceRadius = Radius;
	PrevNavPoint = GetCurrentLocation();

	check(CurrentPathIndex < NavPath.Num());
	PrimaryComponentTick.SetTickFunctionEnable(true);
	Status = EPathFollowingStatus::Type::Moving;
}

void URelativePathFollowingComponent::AbortMove(EPathFollowingResult::Type Result)
{
	if (PrimaryComponentTick.IsTickFunctionEnabled())
	{
		FinishNavPath(Result);
	}
}

void URelativePathFollowingComponent::UpdateMovementData(bool bForced)
{
	if (MovementComponent == nullptr || bForced)
	{
		AActor* Owner = GetOwner();
		check(Owner != nullptr);

		MovementComponent = Owner->FindComponentByClass<UNavMovementComponent>();
		check(MovementComponent != nullptr);

		NavAgentRadius = MovementComponent->NavAgentProps.AgentRadius;
	}
}

void URelativePathFollowingComponent::RequestMovement(const FVector& TargetLocation, bool bIsLast)
{
	FVector CurrentLocation = GetCurrentLocation();
	FVector Velocity = (TargetLocation - CurrentLocation) / (GetWorld()->GetDeltaSeconds());

	MovementComponent->RequestDirectMove(Velocity, bIsLast);
}

void URelativePathFollowingComponent::FinishNavPath(EPathFollowingResult::Type Result)
{
    NavPath.Empty();
    CurrentPathIndex = 0;

	FAIRequestID MoveId = FAIRequestID::CurrentRequest;
    PrimaryComponentTick.SetTickFunctionEnable(false);
    Status = EPathFollowingStatus::Type::Idle;
    OnPathFinished.Broadcast(Result);

    MovementComponent->StopActiveMovement();
}