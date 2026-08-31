#pragma once

#include "Gestures/Base/GestureListen.h"
#include "HoldGestureListen.generated.h"

UCLASS()
class UHoldGestureListen : public UGestureListen
{
    GENERATED_UCLASS_BODY()
public:
    
    virtual ~UHoldGestureListen();

protected:
    
    virtual void OnTouchMove(const ETouchIndex::Type FingerIndex) override;
    
    virtual void OnTouchStop(const ETouchIndex::Type FingerIndex) override;

protected:
    TArray<ETouchIndex::Type> InHoldingArray;
    
private:
    class UHoldGestureResult* Result;
};
