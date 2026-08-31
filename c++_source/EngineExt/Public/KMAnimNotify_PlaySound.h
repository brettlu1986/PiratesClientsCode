// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Animation/AnimNotifies/AnimNotifyState.h"
#include "KMAnimNotify_PlaySound.generated.h"

UCLASS(const, hidecategories = Object, collapsecategories, meta = (DisplayName = "KMPlay Sound"))
class ENGINEEXT_API UKMAnimNotify_PlaySound : public UAnimNotifyState
{
    GENERATED_UCLASS_BODY()

public:

    // The animation is starting
    virtual void NotifyBegin(USkeletalMeshComponent* MeshComp,
        UAnimSequenceBase* Animation,
        float TotalDuration) override;

    // The animation stoped
    virtual void NotifyEnd(USkeletalMeshComponent* MeshComp, 
        UAnimSequenceBase* Animation) override;

public:

    // Sound to Play
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "POLICEAnimation")
    USoundBase* SoundToPlay;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "POLICEAnimation")
	bool bFollow;

    // The audio player
    UPROPERTY(BlueprintReadWrite, Category = "POLICEAnimation")
    UAudioComponent* AudioComponent;
    
};
