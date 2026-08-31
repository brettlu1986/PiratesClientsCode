#pragma once

#include "AIController.h"
#include "EngineExt/Public/KMCharacter.h"
#include "Components/HumanMountMovementComponent.h"
#include "Components/RelativePathFollowingComponent.h"
#include "PiratesMountCharacter.generated.h"


UCLASS()
class COMMON_API APiratesMountCharacter : public AKMCharacter
{
    GENERATED_UCLASS_BODY()

    virtual void PostNetReceiveRole() override;
};