#pragma once

#include "CoreMinimal.h"
#include "ActorPoolItemInterface.generated.h"

/** Interface for actor pool items */
UINTERFACE()
class UActorPoolItemInterface : public UInterface
{
	//GENERATED_UINTERFACE_BODY()
    GENERATED_BODY()
};

class COMMON_API IActorPoolItemInterface
{
	GENERATED_IINTERFACE_BODY()


    UFUNCTION(BlueprintImplementableEvent, Category = Pooling)
    void OnActorLeavePool();


    UFUNCTION(BlueprintImplementableEvent, Category = Pooling)
    void OnActorReturnedToPool();
};
