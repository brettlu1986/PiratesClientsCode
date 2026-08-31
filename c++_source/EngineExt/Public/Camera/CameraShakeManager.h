#pragma once

#include "KMObject.h"
#include "CameraShakeManager.generated.h"

class UCameraShaker;
/**
*
*/
UCLASS()
class ENGINEEXT_API UCameraShakeManager : public UKMObject
{
	GENERATED_UCLASS_BODY()

public:
	void Init();

	UFUNCTION(BlueprintCallable, Category = "UCameraShakeHelper", meta = (WorldContext = "WorldContextObject", DeprecatedFunction))
	void ShakeCameraWithInterval(UObject* WorldContextObject, TSubclassOf<class UCameraShake> Shake, float Scale, float Interval, float TotalTime);

private:
	UPROPERTY()
	TArray<UCameraShaker *> CameraShakerList;

	void ShakeCameraWithInterval_Internal(UObject* WorldContextObject, const TSubclassOf<class UCameraShake> &Shake, float Scale, float Interval, float TotalTime);
};