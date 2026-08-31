#pragma once

#include "Gestures/Base/GestureListen.h"
#include "PinchGestureListen.generated.h"

class UPinchGestureResult;

UCLASS()
class UPinchGestureListen : public UGestureListen
{
    GENERATED_UCLASS_BODY()
public:
    
    virtual ~UPinchGestureListen();

	virtual void Init() override;

protected:
    
    virtual void OnTouchMove(const ETouchIndex::Type FingerIndex) override;

	virtual void OnTouchStop(const ETouchIndex::Type FingerIndex) override;

	void ResetData(const ETouchIndex::Type FingerIndex);

	void UpdateResultData(float Distance);

protected:
    bool bInPinch;

	float StartDistance;
	
	float LastDistance;

	float StartTime;
    
	UPROPERTY()
    UPinchGestureResult* Result;
};
