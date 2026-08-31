#include "CameraShakeManager.h"
#include "EngineExt.h"
#include "CameraShaker.h"
// TODO 
//#include "KMGameInstance.h"

UCameraShakeManager::UCameraShakeManager(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void UCameraShakeManager::Init()
{

}

void UCameraShakeManager::ShakeCameraWithInterval(UObject* WorldContextObject, TSubclassOf<class UCameraShake> Shake, float Scale, float Interval, float TotalTime)
{
    ShakeCameraWithInterval_Internal(WorldContextObject, Shake, Scale, Interval, TotalTime);
    /*
	UKMGameInstance *GameInstance = UKMGameInstance::GetKMGameInstance(WorldContextObject);
	if (IsValid(GameInstance))
	{
		auto ShakeManager = GameInstance->GetCameraShakeManager();
		if (IsValid(ShakeManager))
		{
			ShakeManager->ShakeCameraWithInterval_Internal(WorldContextObject, Shake, Scale, Interval, TotalTime);
		}
	}
    */
}

void UCameraShakeManager::ShakeCameraWithInterval_Internal(UObject* WorldContextObject, const TSubclassOf<class UCameraShake> &Shake, float Scale, float Interval, float TotalTime)
{
    /* TODO 
	UWorld *World = GEngine->GetWorldFromContextObject(WorldContextObject);
	if (IsValid(World))
	{
		UCameraShaker *Shaker = NewObject<UCameraShaker>(this);
		Shaker->InitParams(Shake, Scale);
		CameraShakerList.Add(Shaker);
		UKMGameInstance *GameInstance = UKMGameInstance::GetKMGameInstance(WorldContextObject);
		if (IsValid(GameInstance))
		{
			auto TimerManager = GameInstance->GetKMTimerManager();
			if (IsValid(TimerManager))
			{
				TimerManager->SetAutoStopTimer(Shaker, &UCameraShaker::OnShake, Interval, TotalTime, [=] {
					CameraShakerList.Remove(Shaker);
				});
			}
		}
	}
    */
}