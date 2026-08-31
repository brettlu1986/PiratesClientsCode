#pragma once

#include "Gestures/Base/GestureBase.h"
#include "KMGestureRecognizer.generated.h"

class UGestureListen;
class UGestureResult;

UCLASS()
class COMMON_API UKMGestureRecognizer : public UObject, public FTickableGameObject
{
    GENERATED_BODY()

public:
	virtual ~UKMGestureRecognizer();

	void SetPlayerController(APlayerController* PlayerController);

	void CloseSelfTouchListen();

	void OpenSelfTouchListen();

    void ActiveListen(EGestureType Type);

    void DeactiveListen(EGestureType Type);

    // FTickableGameObject Interface Begin 
    virtual void Tick(float DeltaSeconds) override;

    virtual bool IsTickable() const override;

    virtual bool IsTickableWhenPaused() const override;
    
    virtual TStatId GetStatId() const override;
	// FTickableGameObject Interface End

	void TouchStart(ETouchIndex::Type FingerIndex, FVector Location);

	void TouchMove(ETouchIndex::Type FingerIndex, FVector Location);

	void TouchStop(ETouchIndex::Type FingerIndex, FVector Location);

	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

public:
    FGestureResultDelegate OnActiveDelegate;

    FGestureResultDelegate OnGestureDeactive;

private:

	void TouchStartByInput(ETouchIndex::Type FingerIndex, FVector Location);

	void TouchMoveByInput(ETouchIndex::Type FingerIndex, FVector Location);

	void TouchStopByInput(ETouchIndex::Type FingerIndex, FVector Location);

    void OnActiveEvent(UGestureResult* Result);

    void OnFailEvent(UGestureResult* Result);

    void RemoveActiveResultByType(EGestureType ResultType);

    void FilterActiveResult();

    void SortActiveResult();

    void SendActiveResult();

    void DeactiveAll();

private:

    TMap<EGestureType, UGestureListen*> ListenArray;

    TArray<UGestureResult*> ActiveMessages;

    TArray<UGestureResult*> FilteredMessages;

    TArray<UGestureResult*> FilteredTempMessages;

	bool bSelfTouchListenClosed;
};
