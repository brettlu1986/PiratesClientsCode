#include "AISegma/Components/AIControlModeComponentBase.h"
#include "Common.h"


UAIControlModeComponentBase::UAIControlModeComponentBase(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{

}

void UAIControlModeComponentBase::AbortMoving()
{

}

bool UAIControlModeComponentBase::MoveTo(const FAIMoveRequest& MoveRequest, FPathFollowingRequestResult& Result)
{
    return false;
}

void UAIControlModeComponentBase::UpdateControlRotation(const FRotator& NewControlRotation)
{
    
}

void UAIControlModeComponentBase::Possess(APawn* InPawn)
{

}

void UAIControlModeComponentBase::UnPossess()
{

}
