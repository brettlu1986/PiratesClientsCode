#pragma once

#include "Camera/CameraShake.h"
#include "KMCameraShake.generated.h"

UCLASS(Blueprintable, editinlinenew)
class UKMCameraShake : public UCameraShake
{
	GENERATED_BODY()

public:
	UKMCameraShake(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	UFUNCTION(BlueprintCallable, Category = Oscillation)
	void SetOscillationTimeValue(float Duration, float BlendInTime, float BlendOutTime);

	UFUNCTION(BlueprintCallable, Category = Oscillation)
	bool IsCameraShakeFinished();

	UFUNCTION(BlueprintCallable, Category = Oscillation)
	FFOscillator MakeKMShakeOscillator(float Amplitude, float Frequency, TEnumAsByte<enum EInitialOscillatorOffset> InitialOffset);
};