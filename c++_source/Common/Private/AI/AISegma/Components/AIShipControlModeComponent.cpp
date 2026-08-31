#include "AISegma/Components/AIShipControlModeComponent.h"
#include "Common.h"


UAIShipControlModeComponent::UAIShipControlModeComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer),
    ShipPawn(nullptr)
{
    PrimaryComponentTick.bCanEverTick = false;
}

void UAIShipControlModeComponent::AbortMoving()
{
    if (ShipPawn)
    {
        ShipPawn->GetShipMovementComponent()->StopMovementImmediately();
    }
}

void UAIShipControlModeComponent::UpdateControlRotation(const FRotator& NewControlRotation)
{
    AController* Controller = Cast<AController>(GetOwner());
    if (Controller)
    {
        Controller->SetControlRotation(NewControlRotation);
    }
}

bool UAIShipControlModeComponent::MoveTo(const FAIMoveRequest& MoveRequest, FPathFollowingRequestResult& Result)
{
    if (ShipPawn)
    {
        if ( ShipPawn->GetShipMovementComponent()->IsShipPathMove() && LastDestLocation.X == MoveRequest.GetDestination().X && LastDestLocation.Y == MoveRequest.GetDestination().Y)
            return true;

        float CurrentAcceptanceRadius = MoveRequest.GetAcceptanceRadius();
        if (ShipPawn->UsingAsyncPathFindingForAI())
        {
            ShipPawn->FindPathAsync(MoveRequest.GetDestination());
            Result.MoveId = FAIRequestID::AnyRequest;
            Result.Code = EPathFollowingRequestResult::RequestSuccessful;
        }
        else
        {
            TArray<FVector> NavPath;
            if (ShipPawn->IsLocationReachable(MoveRequest.GetDestination()) && ShipPawn->NavMove(MoveRequest.GetDestination(), MoveRequest.GetAcceptanceRadius(), true, NavPath))
            {
                Result.MoveId = FAIRequestID::AnyRequest;
                Result.Code = EPathFollowingRequestResult::RequestSuccessful;
                LastDestLocation = MoveRequest.GetDestination();
            }
        }
    }
    return true;
}

void UAIShipControlModeComponent::Possess(APawn* InPawn)
{
    ShipPawn = Cast<APiratesShipPawn>(InPawn);
}

void UAIShipControlModeComponent::UnPossess()
{
    ShipPawn = nullptr;
}