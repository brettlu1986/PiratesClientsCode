
#include "Gestures/GestureListen/PinchGestureListen.h"
#include "Common.h"
#include "Gestures/GestureResult/PinchGestureResult.h"

UPinchGestureListen::UPinchGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
    , bInPinch			(false)
	, StartDistance		(0.f)
	, LastDistance		(0.f)
	, StartTime			(0.f)
{
//    OwnerType = EGestureType::Pinch;
    SpeedTimeLimit = -1.f;
    DistanceLimit = 50.f;
    Priority = 80;
}

UPinchGestureListen::~UPinchGestureListen()
{
}

void UPinchGestureListen::Init()
{
	Result = NewObject<UPinchGestureResult>(this);
}

void UPinchGestureListen::OnTouchMove(const ETouchIndex::Type FingerIndex)
{
    if (FingerInfoMap.Num() != 2)
	{
		ResetData(FingerIndex);
        return;
	}

	if (StartTime == 0.f)
	{
		StartTime = TotalElapseTime;
	}

	FFingerInfo& FingerInfo_1 = FingerInfoMap[ETouchIndex::Touch1];
	FFingerInfo& FingerInfo_2 = FingerInfoMap[ETouchIndex::Touch1];

    const TArray<FVector2D>& Positions_1 = FingerInfo_1.Positions;
	const TArray<FVector2D>& Positions_2 = FingerInfo_2.Positions;

    ReturnIfTrue((Positions_1.Num() < 3) || (Positions_2.Num() < 3));

    float Distance = FVector2D::Distance(Positions_1.Last(), Positions_2.Last());
    if (!bInPinch)
    {
        StartDistance = Distance;
		LastDistance = Distance;

		ReturnIfTrue(FMath::Abs(Distance - StartDistance) < DistanceLimit);
	}

	UpdateResultData(Distance);
	ReportActive(Result);
	LastDistance = Distance;
	bInPinch = true;
}

void UPinchGestureListen::OnTouchStop(const ETouchIndex::Type FingerIndex)
{
	ReturnIfFalse((FingerInfoMap.Num() == 2));
	ReturnIfFalse(bInPinch);

	bInPinch = false;

	FFingerInfo& FingerInfo_1 = FingerInfoMap[ETouchIndex::Touch1];
	FFingerInfo& FingerInfo_2 = FingerInfoMap[ETouchIndex::Touch1];

	const TArray<FVector2D>& Positions_1 = FingerInfo_1.Positions;
	const TArray<FVector2D>& Positions_2 = FingerInfo_2.Positions;

	float Distance = FVector2D::Distance(Positions_1.Last(), Positions_2.Last());
	UpdateResultData(Distance);
	ReportDeactive(Result);
}

void UPinchGestureListen::ResetData(const ETouchIndex::Type FingerIndex)
{
	FFingerInfo& FingerInfo = FingerInfoMap[FingerIndex];
	FingerInfo.Positions.Empty();
	StartTime = 0.f;
	StartDistance = 0.f;
	LastDistance = 0.f;
}

void UPinchGestureListen::UpdateResultData(float Distance)
{
	Result->ElapsedTime = TotalElapseTime - StartTime;
	Result->StartDistance = StartDistance;
	Result->DeltaDistance = Distance - LastDistance;
	Result->DeltaDistanceFromStart = Distance - StartDistance;
	Result->PinchRatio = Distance / StartDistance;
}
