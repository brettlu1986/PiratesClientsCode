#pragma once

#include "Gestures/Base/GestureListen.h"
#include "TapGestureListen.generated.h"

class UTapGestureResult;

UCLASS()
class UTapGestureListen : public UGestureListen
{
    GENERATED_UCLASS_BODY()
public:
    
	virtual ~UTapGestureListen();
	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

protected:

	virtual void OnTouchStop(const ETouchIndex::Type FingerIndex) override;

	UTapGestureResult* ConstructResult(const ETouchIndex::Type FingerIndex);
    
private:
	TMap<ETouchIndex::Type, UTapGestureResult*> Results;
};
