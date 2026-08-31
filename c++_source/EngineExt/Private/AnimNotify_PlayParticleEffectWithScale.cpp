// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.
#include "AnimNotify_PlayParticleEffectWithScale.h"
#include "EngineExt.h"
#include "Particles/ParticleSystem.h"
#include "Components/SkeletalMeshComponent.h"
#include "ParticleHelper.h"
#include "Kismet/GameplayStatics.h"
#include "Animation/AnimSequenceBase.h"

/////////////////////////////////////////////////////
// UAnimNotify_PlayParticleEffectWithScale

UAnimNotify_PlayParticleEffectWithScale::UAnimNotify_PlayParticleEffectWithScale()
	: Super()
	, Scale(1.f)
{
	Attached = true;

#if WITH_EDITORONLY_DATA
	NotifyColor = FColor(192, 255, 99, 255);
#endif // WITH_EDITORONLY_DATA
}

void UAnimNotify_PlayParticleEffectWithScale::PostLoad()
{
	Super::PostLoad();

	RotationOffsetQuat = FQuat(RotationOffset);
}

#if WITH_EDITOR
void UAnimNotify_PlayParticleEffectWithScale::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);

	if (PropertyChangedEvent.MemberProperty && PropertyChangedEvent.MemberProperty->GetFName() == GET_MEMBER_NAME_CHECKED(UAnimNotify_PlayParticleEffectWithScale, RotationOffset))
	{
		RotationOffsetQuat = FQuat(RotationOffset);
	}
}
#endif

void UAnimNotify_PlayParticleEffectWithScale::Notify(class USkeletalMeshComponent* MeshComp, class UAnimSequenceBase* Animation)
{
	// Don't call super to avoid unnecessary call in to blueprints
	if (PSTemplate)
	{
		if (PSTemplate->IsImmortal())
		{
			UE_LOG(LogTemp, Warning, TEXT("Particle Notify: Anim %s tried to spawn infinitely looping particle system %s. Spawning suppressed."), *GetNameSafe(Animation), *GetNameSafe(PSTemplate));
			return;
		}

		if (Attached)
		{
			UParticleSystemComponent* ParticleSystemComponent = UGameplayStatics::SpawnEmitterAttached(PSTemplate, MeshComp, SocketName, LocationOffset, RotationOffset);
			if (ParticleSystemComponent)
			{
				ParticleSystemComponent->SetCustomScale(Scale);
			}
		}
		else
		{
			const FTransform MeshTransform = MeshComp->GetSocketTransform(SocketName);
			FTransform SpawnTransform;
			SpawnTransform.SetLocation(MeshTransform.TransformPosition(LocationOffset));
			SpawnTransform.SetRotation(MeshTransform.GetRotation() * RotationOffsetQuat);
			UParticleSystemComponent* ParticleSystemComponent = UGameplayStatics::SpawnEmitterAtLocation(MeshComp->GetWorld(), PSTemplate, SpawnTransform);
			if (ParticleSystemComponent)
			{
				ParticleSystemComponent->SetCustomScale(Scale);
			}
		}
	}
	else
	{
		UE_LOG(LogTemp, Warning, TEXT("Particle Notify: Null PSTemplate for particle notify in anim: %s"), *GetNameSafe(Animation));
	}
}

FString UAnimNotify_PlayParticleEffectWithScale::GetNotifyName_Implementation() const
{
	if (PSTemplate)
	{
		return PSTemplate->GetName();
	}
	else
	{
		return Super::GetNotifyName_Implementation();
	}
}
