// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AITypes.h"
#include "Navigation/PathFollowingComponent.h"
#include "RelativePathFollowingComponent.generated.h"


UCLASS(meta = (BlueprintSpawnableComponent), Blueprintable)
class COMMON_API URelativePathFollowingComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:

	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

public:

	DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FPathFinishedDelegate, EPathFollowingResult::Type, Result);
	FPathFinishedDelegate OnPathFinished;

public:

	virtual void StartMove(float Radius);

	virtual void AbortMove(EPathFollowingResult::Type Result = EPathFollowingResult::Type::Aborted);

	FORCEINLINE TArray<FVector>& GetPath() { return NavPath; }

	FORCEINLINE void ResetPath(const TArray<FVector>& InNavPath)
	{
		NavPath.Empty(InNavPath.Num());
		AppendPath(InNavPath);
		CurrentPathIndex = 0;
	}

	FORCEINLINE void AppendPath(const TArray<FVector>& InNavPath) { NavPath.Append(InNavPath); }

	FORCEINLINE int32 GetCurrentPathIndex() const { return CurrentPathIndex; }

	FORCEINLINE EPathFollowingStatus::Type GetStatus() const { return Status; }


protected:

	UNavMovementComponent * MovementComponent;

	float AcceptanceRadius;
	float NavAgentRadius;

	FVector PrevNavPoint;
	int32 CurrentPathIndex;
	TArray<FVector> NavPath;
	EPathFollowingStatus::Type Status;

protected:

	virtual void UpdateMovementData(bool bForced);

	virtual void RequestMovement(const FVector& TargetLocation, bool bIsLast);

	FORCEINLINE virtual FVector GetCurrentLocation() { return MovementComponent->UpdatedComponent->GetRelativeLocation(); }

	FORCEINLINE virtual FVector GetCurrentDirection() { return MovementComponent->UpdatedComponent->GetForwardVector(); }


private:

	FORCEINLINE bool IsLastPathPoint() { return CurrentPathIndex == NavPath.Num() - 1; }

	void FinishNavPath(EPathFollowingResult::Type Result);
};
