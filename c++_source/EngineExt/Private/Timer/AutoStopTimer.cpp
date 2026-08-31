#include "AutoStopTimer.h"
#include "EngineExt.h"
#include "KMTimerManager.h"

UAutoStopTimer::UAutoStopTimer(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
}

void UAutoStopTimer::InitParams(const FTimerHandle &_DelegateTimeHandle, float _StopTime, TFunction<void()> _OnComplete)
{
	DelegateTimeHandle = _DelegateTimeHandle;
	StopTime = _StopTime;
	OnComplete = _OnComplete;
}

void UAutoStopTimer::Activate()
{
	auto World = GetWorld();
	bIsTimeOut = true;
	if (IsValid(World))
	{
		World->GetTimerManager().SetTimer(SelfTimeHandle, this, &UAutoStopTimer::OnTimeOut, StopTime, false);
		if (SelfTimeHandle.IsValid())
		{
			bIsTimeOut = false;
		}
	}
}

void UAutoStopTimer::OnTimeOut()
{
	auto World = GetWorld();
	if (IsValid(World))
	{
		World->GetTimerManager().ClearTimer(DelegateTimeHandle);
	}
	if (nullptr != OnComplete)
	{
		OnComplete();
	}
	bIsTimeOut = true;
}
