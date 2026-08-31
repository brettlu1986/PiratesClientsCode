#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "HandlerComponentFactory.h"

#include "ReconnectHandlerComponentFactory.generated.h"

class HandlerComponent;

/**
* Factory class for loading HandlerComponent's contained within Engine
*/
UCLASS()
class UReconnectHandlerComponentFactory : public UHandlerComponentFactory
{
    GENERATED_UCLASS_BODY()

public:
    virtual TSharedPtr<HandlerComponent> CreateComponentInstance(FString& Options) override;
};
