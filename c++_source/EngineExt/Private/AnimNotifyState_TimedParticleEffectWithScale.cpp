// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "AnimNotifyState_TimedParticleEffectWithScale.h"
#include "EngineExt.h"
#include "Components/SkeletalMeshComponent.h"
#include "Particles/ParticleSystemComponent.h"
#include "Kismet/GameplayStatics.h"

UAnimNotifyState_TimedParticleEffectWithScale::UAnimNotifyState_TimedParticleEffectWithScale(const FObjectInitializer& ObjectInitializer)
: Super(ObjectInitializer)
, Scale(1.f)
{
	PSTemplate = nullptr;
	LocationOffset.Set(0.0f, 0.0f, 0.0f);
	RotationOffset = FRotator(0.0f, 0.0f, 0.0f);
}

void UAnimNotifyState_TimedParticleEffectWithScale::NotifyBegin(USkeletalMeshComponent * MeshComp, class UAnimSequenceBase * Animation, float TotalDuration)
{
	// Only spawn if we've got valid params
	if(ValidateParameters(MeshComp))
	{
		UParticleSystemComponent* NewComponent = UGameplayStatics::SpawnEmitterAttached(PSTemplate, MeshComp, SocketName, LocationOffset, RotationOffset);
		if (NewComponent)
		{
			NewComponent->SetCustomScale(Scale);
		}
	}

	Received_NotifyBegin(MeshComp, Animation, TotalDuration);
}

void UAnimNotifyState_TimedParticleEffectWithScale::NotifyTick(USkeletalMeshComponent * MeshComp, class UAnimSequenceBase * Animation, float FrameDeltaTime)
{
	Received_NotifyTick(MeshComp, Animation, FrameDeltaTime);
}

void UAnimNotifyState_TimedParticleEffectWithScale::NotifyEnd(USkeletalMeshComponent * MeshComp, class UAnimSequenceBase * Animation)
{
	TArray<USceneComponent*> Children;
	MeshComp->GetChildrenComponents(false, Children);

	for(USceneComponent* Component : Children)
	{
		if(UParticleSystemComponent* ParticleComponent = Cast<UParticleSystemComponent>(Component))
		{
			bool bSocketMatch = ParticleComponent->GetAttachSocketName() == SocketName;
			bool bTemplateMatch = ParticleComponent->Template == PSTemplate;

#if WITH_EDITORONLY_DATA
			// In editor someone might have changed our parameters while we're ticking; so check
			// previous known parameters too.
			bSocketMatch |= PreviousSocketNames.Contains(ParticleComponent->GetAttachSocketName());
			bTemplateMatch |= PreviousPSTemplates.Contains(ParticleComponent->Template);
#endif

			if(bSocketMatch && bTemplateMatch && !ParticleComponent->bWasDeactivated)
			{
				// Either destroy the component or deactivate it to have it's active particles finish.
				// The component will auto destroy once all particle are gone.
				if(bDestroyAtEnd)
				{
					ParticleComponent->DestroyComponent();
				}
				else
				{
					ParticleComponent->bAutoDestroy = true;
					ParticleComponent->DeactivateSystem();
				}

#if WITH_EDITORONLY_DATA
				// No longer need to track previous values as we've found our component
				// and removed it.
				PreviousPSTemplates.Empty();
				PreviousSocketNames.Empty();
#endif
				// Removed a component, no need to continue
				break;
			}
		}
	}

	Received_NotifyEnd(MeshComp, Animation);
}

bool UAnimNotifyState_TimedParticleEffectWithScale::ValidateParameters(USkeletalMeshComponent* MeshComp)
{
	bool bValid = true;

	if(!PSTemplate)
	{
		bValid = false;
	}
	else if(!MeshComp->DoesSocketExist(SocketName) && MeshComp->GetBoneIndex(SocketName) == INDEX_NONE)
	{
		bValid = false;
	}

	return bValid;
}

FString UAnimNotifyState_TimedParticleEffectWithScale::GetNotifyName_Implementation() const
{
	if(PSTemplate)
	{
		return PSTemplate->GetName();
	}

	return UAnimNotifyState::GetNotifyName_Implementation();
}

#if WITH_EDITOR
void UAnimNotifyState_TimedParticleEffectWithScale::PreEditChange(FProperty* PropertyAboutToChange)
{
	if(PropertyAboutToChange)
	{
		if(PropertyAboutToChange->GetName() == GET_MEMBER_NAME_STRING_CHECKED(UAnimNotifyState_TimedParticleEffectWithScale, PSTemplate) && PSTemplate != NULL)
		{
			PreviousPSTemplates.Add(PSTemplate);
		}

		if(PropertyAboutToChange->GetName() == GET_MEMBER_NAME_STRING_CHECKED(UAnimNotifyState_TimedParticleEffectWithScale, SocketName) && SocketName != FName(TEXT("None")))
		{
			PreviousSocketNames.Add(SocketName);
		}
	}
}
#endif
