// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.
#include "KMAnimNotify_PlaySound.h"
#include "EngineExt.h"
#include "Components/SkeletalMeshComponent.h"
#include "Sound/SoundBase.h"
#include "GameEngineExt.h"

/////////////////////////////////////////////////////
// UAnimNotify_PlaySound
UKMAnimNotify_PlaySound::UKMAnimNotify_PlaySound(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , SoundToPlay(NULL)
	, bFollow(false)
	, AudioComponent(NULL)
{

}

///////////////////////////////////////////////////////////////////////////////
void UKMAnimNotify_PlaySound::NotifyBegin(USkeletalMeshComponent* MeshComp,
    UAnimSequenceBase* Animation,
    float TotalDuration)
{
	AudioComponent = NULL;
    // Spawn the sound
    if (SoundToPlay)
    {
		if (bFollow)
		{
			AudioComponent = UGameplayStatics::SpawnSoundAttached(
				SoundToPlay, MeshComp, NAME_None,
				FVector(ForceInit), EAttachLocation::KeepRelativeOffset,
				true
			);
		}
		else if (MeshComp->GetOwner())
		{
			AudioComponent = UGameplayStatics::SpawnSoundAtLocation(GWorld, SoundToPlay, MeshComp->GetOwner()->GetActorLocation(),
				FRotator::ZeroRotator, 1.f, 1.f, 0.f, nullptr, nullptr, false);
		}

    }
}

///////////////////////////////////////////////////////////////////////////////
void UKMAnimNotify_PlaySound::NotifyEnd(USkeletalMeshComponent* MeshComp,
    UAnimSequenceBase* Animation)
{
    // Stop the sound if needed
    if (AudioComponent)
    {
        AudioComponent->Stop();
        AudioComponent = NULL;
    }
}