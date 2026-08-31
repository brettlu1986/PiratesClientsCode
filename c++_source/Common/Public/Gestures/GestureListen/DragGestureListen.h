#pragma once

#include "Gestures/Base/GestureListen.h"
#include "DragGestureListen.generated.h"

class UDragGestureResult;

UCLASS()
class UDragGestureListen : public UGestureListen
{
	GENERATED_UCLASS_BODY()
public:
	
	virtual ~UDragGestureListen();
	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

protected:
	
	virtual void OnTouchMove(const ETouchIndex::Type FingerIndex) override;
	
	virtual void OnTouchStop(const ETouchIndex::Type FingerIndex) override;

	UDragGestureResult* ConstructResult(const ETouchIndex::Type FingerIndex);

	TArray<ETouchIndex::Type> InDragIndexs;

	TMap<ETouchIndex::Type, UDragGestureResult*> Results;
};
