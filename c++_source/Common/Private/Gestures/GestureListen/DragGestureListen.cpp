
#include "Gestures/GestureListen/DragGestureListen.h"
#include "Common.h"
#include "Gestures/GestureResult/DragGestureResult.h"

UDragGestureListen::UDragGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
{
	OwnerType = EGestureType::Drag;
	SpeedTimeLimit = -1.f;
	DistanceLimit = -1.f;
	Priority = 20;
}

UDragGestureListen::~UDragGestureListen()
{
}

UDragGestureResult* UDragGestureListen::ConstructResult(const ETouchIndex::Type FingerIndex)
{
	if (!Results.Contains(FingerIndex))
	{
		Results.Add(FingerIndex, NewObject<UDragGestureResult>(this));
	}

	FFingerInfo& FingerInfo = FingerInfoMap[FingerIndex];

	UDragGestureResult* Result = Results[FingerIndex];
	Result->FingerIndex = FingerIndex;
	Result->ElapsedTime = FingerInfo.ElapsedTime;
	Result->CurrentPosition = FingerInfo.Positions.Last();
	Result->Positions = FingerInfo.Positions;
	Result->DataNum = Result->Positions.Num();
	Result->DeltaPosition = Result->Positions.Last() - Result->Positions[Result->DataNum - 2];
	Result->DeltaDistance = Result->DeltaPosition.Size();
	Result->DeltaPositionFromStart = FingerInfo.GetDeltaPositionFromStart();
	Result->DeltaDistanceFromStart = FingerInfo.GetDeltaDistanceFromStart();
	return Result;
}

void UDragGestureListen::OnTouchMove(const ETouchIndex::Type FingerIndex)
{
	FFingerInfo& FingerInfo = FingerInfoMap[FingerIndex];

	const float DeltaDistance = FingerInfo.GetDeltaDistanceFromStart();
	const bool IsOutDistance = DeltaDistance > DistanceLimit;
	const bool IsOutTime = FingerInfo.ElapsedTime > SpeedTimeLimit;

	ReturnIfTrue(!IsOutDistance || !IsOutTime);
	ReturnIfTrue(FingerInfo.Positions.Num() < 2);

	UDragGestureResult* Result = ConstructResult(FingerIndex);
	ReportActive(Result);
	InDragIndexs.AddUnique(FingerIndex);
}

void UDragGestureListen::OnTouchStop(const ETouchIndex::Type FingerIndex)
{
	// 如果正在被拖拽，停下时需触发Deactive
	ReturnIfFalse(InDragIndexs.Contains(FingerIndex));
	InDragIndexs.Remove(FingerIndex);

	UDragGestureResult* Result = ConstructResult(FingerIndex);
	ReportDeactive(Result);
}

void UDragGestureListen::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	UDragGestureListen* This = CastChecked<UDragGestureListen>(InThis);
	for (auto& Pair : This->Results)
	{
		Collector.AddReferencedObject(Pair.Value, This);
	}
	Super::AddReferencedObjects(This, Collector);
}