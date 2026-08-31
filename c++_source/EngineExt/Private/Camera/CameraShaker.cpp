#include "CameraShaker.h"
#include "EngineExt.h"

UCameraShaker::UCameraShaker(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
}

UCameraShaker::~UCameraShaker()
{
}

void UCameraShaker::InitParams(const TSubclassOf<class UCameraShake> &_CameraShake, float _Scale)
{
	CameraShake = _CameraShake;
	Scale = _Scale;
}

void UCameraShaker::OnShake()
{
	UWorld *World = GetWorld();
	if (nullptr != World)
	{ 
		APlayerController *PC = World->GetFirstPlayerController();
		if (nullptr != PC)
		{
			PC->ClientPlayCameraShake(CameraShake, Scale);
		}
	}
}