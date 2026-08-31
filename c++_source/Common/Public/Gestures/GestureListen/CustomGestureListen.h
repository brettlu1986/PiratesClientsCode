#pragma once

#include "Gestures/Base/GestureListen.h"
#include "CustomGestureListen.generated.h"

UCLASS()
class UCustomGestureListen : public UGestureListen
{
    GENERATED_UCLASS_BODY()
public:

    virtual ~UCustomGestureListen();

private:
    class UCustomGestureResult* Result;
};
