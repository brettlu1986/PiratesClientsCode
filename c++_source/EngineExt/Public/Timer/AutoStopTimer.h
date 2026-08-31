#pragma once

#include "KMObject.h"
#include "AutoStopTimer.generated.h"

UCLASS()
class ENGINEEXT_API UAutoStopTimer : public UKMObject
{
	GENERATED_UCLASS_BODY()

	void InitParams(const FTimerHandle &_DelegateTimeHandle, float _StopTime, TFunction<void()> _OnComplete);

	void Activate();

	UFUNCTION()
	void OnTimeOut();

	inline bool IsTimeOut()
	{
		return bIsTimeOut;
	}

private:
	float StopTime;
	bool bIsTimeOut;
	FTimerHandle DelegateTimeHandle;
	FTimerHandle SelfTimeHandle;
	TFunction<void()> OnComplete;
};