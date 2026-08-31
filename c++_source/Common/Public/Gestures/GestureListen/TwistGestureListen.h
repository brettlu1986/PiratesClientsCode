#pragma once

#include "Gestures/Base/GestureListen.h"
#include "TwistGestureListen.generated.h"

UCLASS()
class UTwistGestureListen : public UGestureListen
{
    GENERATED_UCLASS_BODY()
public:

    virtual ~UTwistGestureListen();

protected:

    virtual void OnTouchMove(const ETouchIndex::Type FingerIndex) override;

    float GetAtan2(FVector2D From, FVector2D To);

    float GetAngleResult(FVector2D Finger0, FVector2D Finger1, FVector2D RefPos0, FVector2D RefPos1);

    void ConstrcutFailResultAndReport(float DeltaRotation = 0.f);

protected:
    bool bIsInTwist;

    float StartTwistTime;
    
private:
    class UTwistGestureResult* Result;
};
