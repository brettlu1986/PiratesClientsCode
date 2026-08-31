#pragma once

#include "Gestures/Base/GestureListen.h"
#include "DoubleTapGestureListen.generated.h"

UCLASS()
class UDoubleTapGestureListen : public UGestureListen
{
    GENERATED_UCLASS_BODY()
public:
    
	virtual ~UDoubleTapGestureListen();
	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

protected:

	virtual void OnTouchStart(const ETouchIndex::Type FingerIndex) override;
    virtual void OnTouchStop(const ETouchIndex::Type FingerIndex) override;
	void RecordTap(const ETouchIndex::Type FingerIndex);
	void RecordDoubleTap(const ETouchIndex::Type FingerIndex);
	void ResetDoubleTap(const ETouchIndex::Type FingerIndex);
	class UDoubleTapGestureResult* ConstructResult(const ETouchIndex::Type FingerIndex);
	    
private:
	TMap<ETouchIndex::Type, float> LastTapTimes;
	TMap<ETouchIndex::Type, FVector2D> LastPositions;
	TMap<ETouchIndex::Type, bool> ActiveStates;
	TMap<ETouchIndex::Type, class UDoubleTapGestureResult*> Results;
};
