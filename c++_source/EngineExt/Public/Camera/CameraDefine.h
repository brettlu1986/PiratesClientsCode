#pragma once
#include "CameraDefine.generated.h"

UENUM(BlueprintType)
namespace ECameraName
{
	enum Type
	{
		None,
		LazyFollowPlayerCamera,
		KeepFollowPlayerCamera,
		FocusPlayerCamera
	};
}

class ICameraHeadDelegate
{
public:
	virtual void UpdateCamera(float DeltaSeconds) = 0;
};