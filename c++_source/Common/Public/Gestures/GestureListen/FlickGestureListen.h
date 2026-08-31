#pragma once

#include "Gestures/Base/GestureListen.h"
#include "FlickGestureListen.generated.h"

UCLASS()
class UFlickGestureListen : public UGestureListen
{
    GENERATED_UCLASS_BODY()
public:
    
    virtual ~UFlickGestureListen();

protected:
    
    virtual void OnTouchStop(const ETouchIndex::Type FingerIndex) override;
    
private:
    class UFlickGestureResult* Result;
};
