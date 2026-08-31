#pragma once

#include "MapNavGridPathFollowingComponent.h"
#include "ShipNavGridPathFollowingComponent.generated.h"


class UShipMovementComponent;


UCLASS(ClassGroup = Ship, meta = (BlueprintSpawnableComponent), Blueprintable)
class COMMON_API UShipNavGridPathFollowingComponent : public UMapNavGridPathFollowingComponent
{
    GENERATED_UCLASS_BODY()

protected:
    
    virtual void UpdateMovementData(bool bForced) override;

    virtual FVector GetCurrentLocation() override;

    virtual FVector GetCurrentDirection() override;

protected:

    UShipMovementComponent* ShipMovementComponent;

};