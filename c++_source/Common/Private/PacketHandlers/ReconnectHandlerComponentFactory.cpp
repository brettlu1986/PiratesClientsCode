#include "PacketHandlers/ReconnectHandlerComponentFactory.h"
#include "Common.h"
#include "PacketHandlers/ReconnectHandlerComponent.h"

/**
* UEngineHandlerComponentFactor
*/
UReconnectHandlerComponentFactory::UReconnectHandlerComponentFactory(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

TSharedPtr<HandlerComponent> UReconnectHandlerComponentFactory::CreateComponentInstance(FString& Options)
{
    if (Options == TEXT("ReconnectHandlerComponent"))
    {
        return MakeShareable(new ReconnectHandlerComponent);
    }

    return nullptr;
}
