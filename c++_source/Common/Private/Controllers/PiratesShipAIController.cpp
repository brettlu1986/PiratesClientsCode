// Fill out your copyright notice in the Description page of Project Settings.

#include "Controllers/PiratesShipAIController.h"
#include "Common.h"
#include "Pawns/PiratesShipPawn.h"
#include "BehaviorTree/BlackboardComponent.h"


APiratesShipAIController::APiratesShipAIController(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
}

void APiratesShipAIController::OnPossess(APawn * InPawn)
{
    Super::OnPossess(InPawn);
    
    APiratesShipPawn* ShipPawn = GetShipPawn();
    if (ShipPawn != nullptr)
    {
        ShipPawn->OnNavMoveFinished.AddDynamic(this, &APiratesShipAIController::OnNavMoveFinished);
        ShipPawn->OnAsyncPathFindingFinished.AddDynamic(this, &APiratesShipAIController::OnAsyncPathFindingFinished);
    }

    bIsMoving = false;
    CurrentAcceptanceRadius = 0.f;
    LastDestination = FVector::ZeroVector;
}

void APiratesShipAIController::OnUnPossess()
{
    APiratesShipPawn* ShipPawn = GetShipPawn();
    if (ShipPawn != nullptr)
    {
        ShipPawn->OnNavMoveFinished.RemoveAll(this);
        ShipPawn->OnAsyncPathFindingFinished.RemoveAll(this);
    }

    Super::OnUnPossess();
}

FPathFollowingRequestResult APiratesShipAIController::MoveTo(const FAIMoveRequest& MoveRequest, FNavPathSharedPtr* OutPath)
{
    //Temp code
    if (MoveRequest.IsUsingPathfinding())
    {
        return Super::MoveTo(MoveRequest, OutPath);
    }
    else
    {
        APiratesShipPawn* ShipPawn = GetShipPawn();
        if (ShipPawn->UsingAsyncPathFindingForAI())
        {
            ShipPawn->FindPathAsync(MoveRequest.GetDestination());
            CurrentAcceptanceRadius = MoveRequest.GetAcceptanceRadius();

            FPathFollowingRequestResult ResultData;
            ResultData.Code = EPathFollowingRequestResult::RequestSuccessful;

            return ResultData;
        }
        else
        {
            TArray<FVector> NavPath;
            FPathFollowingRequestResult ResultData;
            ResultData.Code = EPathFollowingRequestResult::Failed;

            if (ShipPawn->NavMove(MoveRequest.GetDestination(), MoveRequest.GetAcceptanceRadius(), true, NavPath))
            {
                ResultData.Code = EPathFollowingRequestResult::RequestSuccessful;
                bIsMoving = true;
                LastDestination = MoveRequest.GetDestination();
            }

            return ResultData;
        }
    }
}

void APiratesShipAIController::SimpleMoveToLocation(const FVector& Loc, float AcceptanceRadius)
{
	Super::MoveToLocation(Loc, AcceptanceRadius, true, true, false, false, nullptr, false);
}

bool APiratesShipAIController::GetDestination(FVector& OutDest)
{
    OutDest = LastDestination;
    return bIsMoving;
}

void APiratesShipAIController::SetBlackboardValueAsEnum(UBlackboardComponent* BBComponent, const FName& KeyName, int EnumValue)
{
    if (BBComponent)
    {
        BBComponent->SetValueAsEnum(KeyName, static_cast<uint8>(EnumValue));
    }
}

void APiratesShipAIController::HandleReceiveMoveCompleted(FAIRequestID RequestID, EPathFollowingResult::Type Result)
{
	
}

void APiratesShipAIController::OnNavMoveFinished(EMapNavGridPathFollowingResult Result)
{
    switch (Result)
    {
    case EMapNavGridPathFollowingResult::Completed:
        ReceiveMoveCompleted.Broadcast(FAIRequestID(), EPathFollowingResult::Type::Success);
        break;
    case EMapNavGridPathFollowingResult::Blocked:
        ReceiveMoveCompleted.Broadcast(FAIRequestID(), EPathFollowingResult::Type::Blocked);
        break;
    case EMapNavGridPathFollowingResult::Aborted:
        ReceiveMoveCompleted.Broadcast(FAIRequestID(), EPathFollowingResult::Type::Aborted);
        break;
    default:
        ReceiveMoveCompleted.Broadcast(FAIRequestID(), EPathFollowingResult::Type::Invalid);
        break;
    }

    bIsMoving = false;
}

void APiratesShipAIController::OnAsyncPathFindingFinished(bool bSuccess, const TArray<FVector>& NavPath)
{
    if (bSuccess)
    {
        APiratesShipPawn* ShipPawn = GetShipPawn();
        check(ShipPawn != nullptr);

        ShipPawn->DirectNavMove(NavPath, CurrentAcceptanceRadius, true);
        bIsMoving = true;
        LastDestination = NavPath[NavPath.Num() - 1];
    }
    else
    {
        UE_LOG(LogTemp, Warning, TEXT("Fail to async path finding"));
        ReceiveMoveCompleted.Broadcast(FAIRequestID(), EPathFollowingResult::Type::Invalid);
    }
}
