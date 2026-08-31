
#include "Gestures/GestureListen/TwistGestureListen.h"
#include "Common.h"
#include "Gestures/GestureResult/TwistGestureResult.h"

UTwistGestureListen::UTwistGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
    , bIsInTwist        (false)
    , StartTwistTime(0.f)
{
//    OwnerType = EGestureType::Twist;
    SpeedTimeLimit = -1.f;
    DistanceLimit = 100.f;
    Priority = 60;
}

UTwistGestureListen::~UTwistGestureListen()
{
}

void UTwistGestureListen::OnTouchMove(const ETouchIndex::Type FingerIndex)
{
    // Must two finger
    if (FingerInfoMap.Num() != 2)
    {
        ConstrcutFailResultAndReport();
        return;
    }
    FFingerInfo* pFingerInfo0 = nullptr;
    FFingerInfo* pFingerInfo1 = nullptr;
    for (auto& FingerInfo : FingerInfoMap)
    {
        if (pFingerInfo0 == nullptr)
        {
            pFingerInfo0 = &FingerInfo.Value;
        }
        else
        {
            pFingerInfo1 = &FingerInfo.Value;
        }
    }
    ReturnIfTrue((pFingerInfo0 == nullptr) || (pFingerInfo1 == nullptr));
    auto& PosArray0 = pFingerInfo0->Positions;
    auto& PosArray1 = pFingerInfo1->Positions;

    // Position number can't too little
    ReturnIfTrue((PosArray0.Num() < 3) || (PosArray1.Num() < 3));
    float DeltaRotation = GetAngleResult(PosArray0.Last(), PosArray1.Last(), PosArray0[PosArray0.Num() - 2], PosArray1[PosArray1.Num() - 2]);
    float DeltaDistance = FVector2D::Distance(PosArray0.Last(), PosArray1.Last());
    bool IsInDistance = DeltaDistance < DistanceLimit;
    if (!IsInDistance)
    {
        ConstrcutFailResultAndReport(DeltaRotation);
        return;
    }
    if (!bIsInTwist)
    {
        bIsInTwist = true;
        StartTwistTime = TotalElapseTime;
    }
    // FGestureResult Result;
    // Result.DeltaRotation = DeltaRotation;
    // Result.ElapsedTime = TotalElapseTime - StartTwistTime;
    // Result.FingerInfoMap.Append(FingerInfoMap);

    // ReportActive(Result);
}

float UTwistGestureListen::GetAtan2(FVector2D From, FVector2D To)
{
    float PerpDot = (From.X * To.Y) - (From.Y * To.X);
    return FMath::Atan2(PerpDot, FVector2D::DotProduct(From, To));
}

float UTwistGestureListen::GetAngleResult(FVector2D Finger0, FVector2D Finger1, FVector2D RefPos0, FVector2D RefPos1)
{
    FVector2D CurDir = (Finger0 - Finger1).GetSafeNormal();
    FVector2D RefDir = (RefPos0 - RefPos1).GetSafeNormal();
    return FMath::RadiansToDegrees(GetAtan2(RefDir, CurDir));
}

void UTwistGestureListen::ConstrcutFailResultAndReport(float DeltaRotation)
{
    ReturnIfFalse(bIsInTwist);
    // FGestureResult Result;
    // Result.DeltaRotation = DeltaRotation;
    // Result.ElapsedTime = TotalElapseTime - StartTwistTime;
    // Result.FingerInfoMap.Append(FingerInfoMap);
    // ReportFail(Result);

    bIsInTwist = false;
}
