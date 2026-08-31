
#include "Gestures/GestureListen/TapGestureListen.h"
#include "Common.h"
#include "Gestures/GestureResult/TapGestureResult.h"

UTapGestureListen::UTapGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
{
    OwnerType = EGestureType::Tap;
    SpeedTimeLimit = 0.3f;
    DistanceLimit = 20.f;
    Priority = 10;
}

UTapGestureListen::~UTapGestureListen()
{
}

void UTapGestureListen::OnTouchStop(const ETouchIndex::Type FingerIndex)
{
	FFingerInfo& FingerInfo = FingerInfoMap[FingerIndex];

	const float DeltaDistance = FingerInfo.GetDeltaDistanceFromStart();
	const bool IsInTime = FingerInfo.ElapsedTime < SpeedTimeLimit;
	const bool IsInDistance = DeltaDistance < DistanceLimit;
	const bool IsInCount = FingerInfo.Positions.Num() < 5;
	ReturnIfTrue(!IsInTime || !IsInDistance || !IsInCount);

	UTapGestureResult* Result = ConstructResult(FingerIndex);
	ReportActive(Result);
}

UTapGestureResult* UTapGestureListen::ConstructResult(const ETouchIndex::Type FingerIndex)
{
	if (!Results.Contains(FingerIndex))
	{
		Results.Add(FingerIndex, NewObject<UTapGestureResult>(this));
	}

	FFingerInfo& FingerInfo = FingerInfoMap[FingerIndex];
	UTapGestureResult* Result = Results[FingerIndex];
	Result->ElapsedTime = FingerInfo.ElapsedTime;
	Result->Position = FingerInfo.Positions.Last();
	Result->Positions = FingerInfo.Positions;
	Result->DataNum = FingerInfo.Positions.Num();
	Result->DeltaPositionFromStart = FingerInfo.GetDeltaPositionFromStart();
	Result->DeltaDistanceFromStart = FingerInfo.GetDeltaDistanceFromStart();
	return Result;
}

void UTapGestureListen::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	UTapGestureListen* This = CastChecked<UTapGestureListen>(InThis);
	for (auto& Pair : This->Results)
	{
		Collector.AddReferencedObject(Pair.Value, This);
	}
	Super::AddReferencedObjects(This, Collector);
}
