#pragma once

#include "LatentActions.h"

// FDelayAction
// A simple delay action; counts down and triggers it's output link when the time remaining falls to zero
class FDelayCallAction : public FPendingLatentAction
{
public:
	bool Cancel;
	bool Complete;

	FName ExecutionFunction;
	int32 OutputLink;
	FWeakObjectPtr CallbackTarget;

	FDelayCallAction(const FLatentActionInfo& LatentInfo)
		: Cancel(false)
		, Complete(false)
		, ExecutionFunction(LatentInfo.ExecutionFunction)
		, OutputLink(LatentInfo.Linkage)
		, CallbackTarget(LatentInfo.CallbackTarget)
	{
	}

	virtual void UpdateOperation(FLatentResponse& Response)
	{
		Response.DoneIf(Cancel);
		Response.FinishAndTriggerIf(Complete, ExecutionFunction, OutputLink, CallbackTarget);
	}
};