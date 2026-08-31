
#include "Gestures/GestureListen/FlickGestureListen.h"
#include "Common.h"
#include "Gestures/GestureResult/FlickGestureResult.h"

#define EPS (1e-6)
#define MIN_POS_COUNT 3
#define FLOAT_EQUAL_ZERO(X) (FMath::Abs(X) < EPS)

UFlickGestureListen::UFlickGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
{
//    OwnerType = EGestureType::Flick;
    SpeedTimeLimit = 0.25f;
    DistanceLimit = 80.f;
    Priority = 40;
}

UFlickGestureListen::~UFlickGestureListen()
{
}

void UFlickGestureListen::OnTouchStop(const ETouchIndex::Type FingerIndex)
{
    FFingerInfo* pFingerInfo = FingerInfoMap.Find(FingerIndex);
    ReturnIfNullptr(pFingerInfo);
    TArray<FVector2D>& PosArray = pFingerInfo->Positions;
    ReturnIfTrue(PosArray.Num() < MIN_POS_COUNT);
    // 手gesture need keep straight line
    float DeltaA = PosArray.Last().Y - PosArray[0].Y;
    float DeltaB = PosArray[0].X - PosArray.Last().X;
    float DeltaC = PosArray.Last().X * PosArray[0].Y - PosArray[0].X *PosArray.Last().Y;

    float SqrtPart = FMath::Sqrt(FMath::Pow(DeltaA, 2) + FMath::Pow(DeltaB, 2));
    ReturnIfTrue(FLOAT_EQUAL_ZERO(SqrtPart));
    const FVector2D ViewportSize = FVector2D(GEngine->GameViewport->Viewport->GetSizeXY());
    float MaxDistance = ViewportSize.X / 10;
    for (int i = 1; i < PosArray.Num() - 1; ++i)
    {
        float Distance = FMath::Abs(DeltaA * PosArray[i].X + DeltaB * PosArray[i].Y + DeltaC) / SqrtPart;
        ReturnIfTrue(Distance > MaxDistance);
    }
    // Cannot out of distance or time
    bool IsOutDistance = pFingerInfo->GetDeltaDistanceFromStart() > DistanceLimit;
    bool IsInTime = pFingerInfo->ElapsedTime < SpeedTimeLimit;
    ReturnIfTrue(!IsOutDistance || !IsInTime);

    // FGestureResult Result;
    // Result.DeltaDistance = pFingerInfo->GetDeltaDistance();
    // Result.DeltaRotation = FMath::Atan2(-(PosArray.Last().Y - PosArray[0].Y), PosArray.Last().X - PosArray[0].X) * 180.f / PI;
    // Result.DeltaPos = pFingerInfo->GetDeltaPos();
    // Result.ElapsedTime = pFingerInfo->ElapsedTime;
    // Result.FingerInfoMap.Add(FingerIndex, *pFingerInfo);
    // ReportActive(Result);
}
