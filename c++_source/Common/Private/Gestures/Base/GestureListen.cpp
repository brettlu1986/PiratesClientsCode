
#include "Gestures/Base/GestureListen.h"
#include "Common.h"

UGestureListen::UGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
    , Priority          (0)
    , DistanceLimit     (0.f)
    , SpeedTimeLimit    (0.f)
    , TotalElapseTime   (0.f)
    , IsExecuting       (false)
    , OwnerType         (EGestureType::None)
{
}

UGestureListen::~UGestureListen()
{
}

void UGestureListen::Init()
{
}

void UGestureListen::Execute()
{
    IsExecuting = true;
}

void UGestureListen::Cancel()
{
    IsExecuting = false;
}

void UGestureListen::Tick(float DeltaSeconds)
{
    ReturnIfFalse(IsExecuting);
    TotalElapseTime += DeltaSeconds;
}

void UGestureListen::TouchStart(ETouchIndex::Type FingerIndex, FVector Location)
{
    FFingerInfo FingerInfo;
    FingerInfo.Positions.Add(FVector2D(Location));
    FingerInfo.StartTime = TotalElapseTime;
    FingerInfoMap.Add(FingerIndex, FingerInfo);

    OnTouchStart(FingerIndex);
}

void UGestureListen::TouchMove(ETouchIndex::Type FingerIndex, FVector Location)
{
    ReturnIfFalse(FingerInfoMap.Contains(FingerIndex));
    FFingerInfo& FingerInfo = FingerInfoMap[FingerIndex];
    FingerInfo.Positions.Add(FVector2D(Location));
    FingerInfo.ElapsedTime = TotalElapseTime - FingerInfo.StartTime;

    OnTouchMove(FingerIndex);
}

void UGestureListen::TouchStop(ETouchIndex::Type FingerIndex, FVector Location)
{
    ReturnIfFalse(FingerInfoMap.Contains(FingerIndex));
    FFingerInfo& FingerInfo = FingerInfoMap[FingerIndex];
    FingerInfo.Positions.Add(FVector2D(Location));
    FingerInfo.ElapsedTime = TotalElapseTime - FingerInfo.StartTime;

    OnTouchStop(FingerIndex);
    FingerInfoMap.Remove(FingerIndex);
}

void UGestureListen::ReportActive(UGestureResult* Result)
{
    Result->GestureType = OwnerType;
    Result->Priority = Priority;
    OnActiveDelegate.ExecuteIfBound(Result);
}

void UGestureListen::ReportDeactive(UGestureResult* Result)
{
    Result->GestureType = OwnerType;
    Result->Priority = Priority;
    OnDeactiveDelegate.ExecuteIfBound(Result);
}
