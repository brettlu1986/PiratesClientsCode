#include "AI/Components/PiratesPathFollowingComponent.h"
#include "Common.h"


UPiratesPathFollowingComponent::UPiratesPathFollowingComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer),
    MaxPorcessBlockTime(1),
    PorcessingBlockStartTime(0)
{

}


void UPiratesPathFollowingComponent::OnPathFinished(const FPathFollowingResult& Result)
{
    if (Result.Code == EPathFollowingResult::Blocked && OnResolveBlocked.IsBound())
    {
        float CurrentTime = GetWorld()->GetTimeSeconds();
        if (PorcessingBlockStartTime <= 0)
        {
            PorcessingBlockStartTime = CurrentTime;
            OnResolveBlocked.Execute();
        }
        else if (CurrentTime - PorcessingBlockStartTime >= MaxPorcessBlockTime)
        {
            PorcessingBlockStartTime = 0;
            Super::OnPathFinished(Result);
        }
    }
    else
    {
        Super::OnPathFinished(Result);
    }
}

void UPiratesPathFollowingComponent::SetBlockParams(float DistanceThreshold, float Interval, int32 NumSamples)
{
    SetBlockDetection(DistanceThreshold, Interval, NumSamples);
}
