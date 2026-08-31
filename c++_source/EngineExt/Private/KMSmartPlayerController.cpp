// Fill out your copyright notice in the Description page of Project Settings.

#include "KMSmartPlayerController.h"
#include "EngineExt.h"


AKMSmartPlayerController::AKMSmartPlayerController(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    AIController = nullptr;
    bIsNavMoving = false;
}

void AKMSmartPlayerController::BeginDestroy()
{
    if (AIController != nullptr)
    {
        AIController->Destroy();
        AIController = nullptr;
    }
    
    Super::BeginDestroy();
}

void AKMSmartPlayerController::SetPawn(APawn* InPawn)
{
    Super::SetPawn(InPawn);

    if (AIController != nullptr && AIController->GetPawn() != InPawn)
    {
        AIController->SetPawn(InPawn);

        UPathFollowingComponent* PathFollowingComp = AIController->GetPathFollowingComponent();
        if (PathFollowingComp != NULL)
        {
            PathFollowingComp->UpdateCachedComponents();
        }
    }
}

EPathFollowingRequestResult::Type AKMSmartPlayerController::StartNavMoveToLocation(
    const FVector& DestLocation,
    float AcceptanceRadius /* = -1.0f */,
    bool bStopOnOverlap /* = true */,
    bool bUsePathfinding /* = true */,
    bool bProjectDestinationToNavigation /* = false */,
    bool bCanStrafe /* = true */,
    TSubclassOf<UNavigationQueryFilter> FilterClass /* = NULL */,
    bool bAllowPartialPaths /* = true */)
{
    EnsureNavMovePreCondition();

    EPathFollowingRequestResult::Type Result = AIController->MoveToLocation(
        DestLocation,
        AcceptanceRadius,
        bStopOnOverlap,
        bUsePathfinding,
        bProjectDestinationToNavigation,
        bCanStrafe,
        FilterClass,
        bAllowPartialPaths
    );

    bIsNavMoving = (Result == EPathFollowingRequestResult::RequestSuccessful);
    return Result;
}

EPathFollowingRequestResult::Type AKMSmartPlayerController::StartNavMoveToActor(
    AActor* Target,
    float AcceptanceRadius /* = -1.0f */,
    bool bStopOnOverlap /* = true */,
    bool bUsePathfinding /* = true */,
    bool bCanStrafe /* = true */,
    TSubclassOf<UNavigationQueryFilter> FilterClass,
    bool bAllowPartialPaths /* = true */)
{
    EnsureNavMovePreCondition();

    EPathFollowingRequestResult::Type Result = AIController->MoveToActor(
        Target,
        AcceptanceRadius,
        bStopOnOverlap,
        bUsePathfinding,
        bCanStrafe,
        FilterClass,
        bAllowPartialPaths
    );

    bIsNavMoving = (Result == EPathFollowingRequestResult::RequestSuccessful);
    return Result;
}

void AKMSmartPlayerController::StopNavMove()
{
    if (bIsNavMoving)
    {
        AIController->StopMovement();
    }
}

FORCEINLINE bool AKMSmartPlayerController::IsNavMoving()
{
    return bIsNavMoving;
}

void AKMSmartPlayerController::EnsureNavMovePreCondition()
{
    bool IsOK = false;
    do
    {
        APawn* ThePawn = GetPawn();
        if (ThePawn == nullptr)
        {
            break;
        }

        // Client side needs AIController for NavMove
        if (IsLocalController())
        {
            if (ThePawn->AIControllerClass == nullptr)
            {
                break;
            }

            if (AIController == nullptr)
            {
                UWorld* World = GetWorld();
                if (World == nullptr)
                {
                    break;
                }

                AIController = World->SpawnActor<AAIController>(ThePawn->AIControllerClass);
                AIController->ReceiveMoveCompleted.AddDynamic(this, &AKMSmartPlayerController::HandleAIControllerReceiveMoveCompleted);
            }

            if (AIController->GetPawn() != ThePawn)
            {
                AIController->SetPawn(ThePawn);
            }
        }

        IsOK = true;

    } while (false);

    ensure(IsOK);
}

void AKMSmartPlayerController::HandleAIControllerReceiveMoveCompleted(FAIRequestID RequestID, EPathFollowingResult::Type Result)
{
    if (bIsNavMoving)
    {
        bIsNavMoving = false;
        OnNavMoveFinished.Broadcast(Result);
    }
}




