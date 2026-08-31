#pragma once
#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "AITypes.h"
#include "Navigation/PathFollowingComponent.h"
#include "AIControlModeComponentBase.generated.h"


UCLASS(Abstract)
class COMMON_API UAIControlModeComponentBase : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
    virtual void AbortMoving();
    virtual bool MoveTo(const FAIMoveRequest& MoveRequest, FPathFollowingRequestResult& Result);
    virtual void UpdateControlRotation(const FRotator& NewControlRotation);

    virtual void Possess(APawn* InPawn);
    virtual void UnPossess();
private:

};
