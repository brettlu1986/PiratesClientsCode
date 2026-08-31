
#include "Components/ShipNavGridPathFollowingComponent.h"
#include "Common.h"
#include "Components/ShipMovementComponent.h"


UShipNavGridPathFollowingComponent::UShipNavGridPathFollowingComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

void UShipNavGridPathFollowingComponent::UpdateMovementData(bool bForced)
{
    Super::UpdateMovementData(bForced);

    ShipMovementComponent = Cast<UShipMovementComponent>(MovementComponent);
    check(ShipMovementComponent != nullptr);
}

FVector UShipNavGridPathFollowingComponent::GetCurrentLocation()
{
    return ShipMovementComponent->GetShipLocation();
}

FVector UShipNavGridPathFollowingComponent::GetCurrentDirection()
{
    return ShipMovementComponent->GetShipDirection();
}
