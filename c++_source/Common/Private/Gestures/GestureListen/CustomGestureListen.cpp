
#include "Gestures/GestureListen/CustomGestureListen.h"
#include "Common.h"
#include "Gestures/GestureResult/CustomGestureResult.h"

UCustomGestureListen::UCustomGestureListen(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
{
//    OwnerType = EGestureType::Custom;
    SpeedTimeLimit = 1.f;
    DistanceLimit = 100.f;
    Priority = 50;
}

UCustomGestureListen::~UCustomGestureListen()
{
}
