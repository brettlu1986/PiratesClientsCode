// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ShipMovementComponent.h"
#include "AIController.h"
#include "Pawns/PiratesShipPawn.h"
#include "PiratesShipAIController.generated.h"


UCLASS()
class COMMON_API APiratesShipAIController : public AAIController
{
	GENERATED_BODY()
	
protected:

	APiratesShipAIController(const FObjectInitializer& ObjectInitializer);

	virtual void OnPossess(APawn* InPawn) override;

	virtual void OnUnPossess() override;

    FPathFollowingRequestResult MoveTo(const FAIMoveRequest& MoveRequest, FNavPathSharedPtr* OutPath /* = nullptr */) override;

public:

	UFUNCTION(BlueprintCallable, Category = "ShipAIController", DisplayName="MoveToLocation")
	virtual void SimpleMoveToLocation(const FVector& Loc, float AcceptanceRadius = -1);

    UFUNCTION(BlueprintCallable, Category = "ShipAIController")
    bool GetDestination(FVector& OutDest);

    UFUNCTION(BlueprintCallable, Category = "ShipAIController")
    void SetBlackboardValueAsEnum(class UBlackboardComponent* BBComponent, const FName& KeyName, int EnumValue);

protected:

	UFUNCTION()
	virtual void HandleReceiveMoveCompleted(FAIRequestID RequestID, EPathFollowingResult::Type Result);

    UFUNCTION()
    void OnNavMoveFinished(EMapNavGridPathFollowingResult Result);

    UFUNCTION()
    void OnAsyncPathFindingFinished(bool bSuccess, const TArray<FVector>& NavPath);

private:

	APiratesShipPawn* GetShipPawn() const { return Cast<APiratesShipPawn>(GetPawn()); }

	UShipMovementComponent* GetShipMovement() const
	{
		APiratesShipPawn* ShipPawn = GetShipPawn();
		if (ShipPawn != nullptr)
		{
			return ShipPawn->GetShipMovementComponent();
		}

		return nullptr;
	}
	
    bool bIsMoving;
    FVector LastDestination;
    float CurrentAcceptanceRadius;
};
