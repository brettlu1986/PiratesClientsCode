
#include "KMCameraShake.h"
#include "EngineExt.h"

UKMCameraShake::UKMCameraShake(
	const FObjectInitializer& ObjectInitializer /*= FObjectInitializer::Get()*/)
	: Super(ObjectInitializer)
{
}

void UKMCameraShake::SetOscillationTimeValue(float Duration, float BlendInTime, float BlendOutTime)
{
	OscillationDuration = Duration;
	OscillationBlendInTime = BlendInTime;
	OscillationBlendOutTime = BlendOutTime;
}

bool UKMCameraShake::IsCameraShakeFinished()
{
	return IsFinished();
}

FFOscillator UKMCameraShake::MakeKMShakeOscillator(float Amplitude, float Frequency, TEnumAsByte<enum EInitialOscillatorOffset> InitialOffset)
{
	FFOscillator Oscillator;
	Oscillator.Amplitude = Amplitude;
	Oscillator.Frequency = Frequency;
	Oscillator.InitialOffset = InitialOffset;
	return Oscillator;
}

