#pragma once

#include "KMObject.h"
#include "CameraShaker.generated.h"

UCLASS()
class UCameraShaker : public UKMObject
{
	GENERATED_UCLASS_BODY()

	TSubclassOf<class UCameraShake> CameraShake;
	float Scale;

	~UCameraShaker();

	void InitParams(const TSubclassOf<class UCameraShake> &_CameraShake, float _Scale);

	UFUNCTION()
	void OnShake();
};