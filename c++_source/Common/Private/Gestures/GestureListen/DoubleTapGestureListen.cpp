
#include "Gestures/GestureListen/DoubleTapGestureListen.h"
#include "Common.h"
#include "Gestures/GestureResult/DoubleTapGestureResult.h"

UDoubleTapGestureListen::UDoubleTapGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
{
    OwnerType = EGestureType::DoubleTap;
    SpeedTimeLimit = 0.3f;
    DistanceLimit = 10.f;
    Priority = 70;
}

UDoubleTapGestureListen::~UDoubleTapGestureListen()
{
}

void UDoubleTapGestureListen::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	UDoubleTapGestureListen* This = CastChecked<UDoubleTapGestureListen>(InThis);
	for (auto& Pair : This->Results)
	{
		Collector.AddReferencedObject(Pair.Value, This);
	}
	Super::AddReferencedObjects(This, Collector);
}

void UDoubleTapGestureListen::OnTouchStart(const ETouchIndex::Type FingerIndex)
{
    FFingerInfo* pFingerInfo = FingerInfoMap.Find(FingerIndex);
    ReturnIfNullptr(pFingerInfo);

	if (!LastTapTimes.Contains(FingerIndex) || !LastPositions.Contains(FingerIndex))
	{
		RecordTap(FingerIndex);
		return;
	}

	float LastTapTime = LastTapTimes[FingerIndex];
    float TapElapsedTime = TotalElapseTime - LastTapTime;
	// If out of time, reset to one tap
    if ((LastTapTime == 0.f) || (TapElapsedTime > SpeedTimeLimit))
    {
        RecordTap(FingerIndex);
        return;
    }

	const FVector2D& CurrentPosition = pFingerInfo->Positions.Last();
	const FVector2D& LastPosition = LastPositions[FingerIndex];
    const FVector2D& DeltaPosition = CurrentPosition - LastPosition;
    const float DeltaDistance = DeltaPosition.Size();
    // If out of distance, reset to one tap
    if (DeltaDistance > DistanceLimit)
    {
        RecordTap(FingerIndex);
        return;
	}
	UDoubleTapGestureResult* Result = ConstructResult(FingerIndex);
	Result->DeltaPosition = DeltaPosition;
	Result->DeltaDistance = DeltaDistance;
	Result->Positions.Add(LastPosition);
	Result->Positions.Add(CurrentPosition);
    ReportActive(Result);
	RecordDoubleTap(FingerIndex);
}

void UDoubleTapGestureListen::OnTouchStop(const ETouchIndex::Type FingerIndex)
{
	if (ActiveStates.Contains(FingerIndex) && ActiveStates[FingerIndex])
	{
		UDoubleTapGestureResult* Result = ConstructResult(FingerIndex);
		ReportDeactive(Result);
		ResetDoubleTap(FingerIndex);
	}
}

void UDoubleTapGestureListen::RecordTap(const ETouchIndex::Type FingerIndex)
{
	FFingerInfo* pFingerInfo = FingerInfoMap.Find(FingerIndex);
	ReturnIfNullptr(pFingerInfo);
	LastTapTimes.Add(FingerIndex, TotalElapseTime);
	LastPositions.Add(FingerIndex, pFingerInfo->Positions.Last());
}

void UDoubleTapGestureListen::RecordDoubleTap(const ETouchIndex::Type FingerIndex)
{
	ActiveStates.Add(FingerIndex, true);
}

void UDoubleTapGestureListen::ResetDoubleTap(const ETouchIndex::Type FingerIndex)
{
	LastTapTimes[FingerIndex] = 0;
	LastPositions[FingerIndex] = FVector2D::ZeroVector;
	ActiveStates[FingerIndex] = false;
}

UDoubleTapGestureResult* UDoubleTapGestureListen::ConstructResult(const ETouchIndex::Type FingerIndex)
{
	if (!Results.Contains(FingerIndex))
	{
		Results.Add(FingerIndex, NewObject<UDoubleTapGestureResult>(this));
	}
	return Results[FingerIndex];
}
