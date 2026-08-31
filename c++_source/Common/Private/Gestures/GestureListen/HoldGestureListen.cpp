
#include "Gestures/GestureListen/HoldGestureListen.h"
#include "Common.h"
#include "Gestures/GestureResult/HoldGestureResult.h"

UHoldGestureListen::UHoldGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
{
//    OwnerType = EGestureType::Hold;
    SpeedTimeLimit = 0.5f;
    DistanceLimit = 10.f;
    Priority = 30;
}

UHoldGestureListen::~UHoldGestureListen()
{
}

void UHoldGestureListen::OnTouchMove(const ETouchIndex::Type FingerIndex)
{
    FFingerInfo* pFingerInfo = FingerInfoMap.Find(FingerIndex);
    ReturnIfNullptr(pFingerInfo);
    const float DeltaDistance = pFingerInfo->GetDeltaDistanceFromStart();
    bool IsOutTime = pFingerInfo->ElapsedTime > SpeedTimeLimit;
    ReturnIfFalse(IsOutTime);
//    bool IsInDistance = DeltaDistance < DistanceLimit;
//     if (InHoldingArray.Contains(FingerIndex) && !IsInDistance)
//     {    // 正在Holding并且超出距离时Hold失败
//         // 提前移除FingerInfoMap中数据，本次点击不再识别
//         FingerInfoMap.Remove(FingerIndex);
//         FGestureResult Result;
//         Result.DeltaDistance = DeltaDistance;
//         Result.DeltaPos = pFingerInfo->GetDeltaPos();
//         Result.ElapsedTime = pFingerInfo->ElapsedTime;
//         Result.FingerInfoMap.Add(FingerIndex, *pFingerInfo);
//         ReportFail(Result);
//         return;
//     }
    ReturnIfTrue(InHoldingArray.Contains(FingerIndex));
    // FGestureResult Result;
    // Result.DeltaDistance = DeltaDistance;
    // Result.DeltaPos = pFingerInfo->GetDeltaPos();
    // Result.ElapsedTime = pFingerInfo->ElapsedTime;
    // Result.FingerInfoMap.Add(FingerIndex, *pFingerInfo);
    // ReportActive(Result);
    InHoldingArray.AddUnique(FingerIndex);
}

void UHoldGestureListen::OnTouchStop(const ETouchIndex::Type FingerIndex)
{
    ReturnIfFalse(InHoldingArray.Contains(FingerIndex));
    // can't take finger when hold, else failed
    FFingerInfo* pFingerInfo = FingerInfoMap.Find(FingerIndex);
    ReturnIfNullptr(pFingerInfo);
    // FGestureResult Result;
    // Result.DeltaDistance = pFingerInfo->GetDeltaDistance();
    // Result.DeltaPos = pFingerInfo->GetDeltaPos();
    // Result.ElapsedTime = pFingerInfo->ElapsedTime;
    // Result.FingerInfoMap.Add(FingerIndex, *pFingerInfo);
    // ReportFail(Result);
    InHoldingArray.Remove(FingerIndex);
}
