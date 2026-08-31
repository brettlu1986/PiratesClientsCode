#pragma once
#include "AIControlModeComponentBase.h"
#include "Pawns/PiratesShipPawn.h"
#include "AIShipControlModeComponent.generated.h"


UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UAIShipControlModeComponent : public UAIControlModeComponentBase
{
    GENERATED_UCLASS_BODY()

public:
    virtual void AbortMoving() override;
    virtual bool MoveTo(const FAIMoveRequest& MoveRequest, FPathFollowingRequestResult& Result) override;
    virtual void UpdateControlRotation(const FRotator& NewControlRotation) override;

    virtual void Possess(APawn* InPawn) override;
    virtual void UnPossess() override;
private:
    APiratesShipPawn* ShipPawn;

private:
    FVector LastDestLocation;
};