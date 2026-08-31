// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/EmitterActivateComponent.h"
#include "Common.h"

void UEmitterActivateComponent::AddEmitterToWaitActivateMap(UParticleSystemComponent* ParticleSystemComponent, bool bAutoDestroy)
{
	WaitActivateMap.Add(ParticleSystemComponent, bAutoDestroy);
}

void UEmitterActivateComponent::RemoveEmitterFromWaitActivateMap(UParticleSystemComponent* ParticleSystemComponent)
{
	WaitActivateMap.Remove(ParticleSystemComponent);
}

bool UEmitterActivateComponent::IsEmitterInActivateMap(UParticleSystemComponent* ParticleSystemComponent)
{
	return WaitActivateMap.Find(ParticleSystemComponent) != nullptr;
}

void UEmitterActivateComponent::ActivateEmitter()
{
	for (auto Pair : WaitActivateMap)
	{
		UParticleSystemComponent* PS = Pair.Key;
		if (IsValid(PS))
		{
			PS->bAutoDestroy = Pair.Value;
			PS->Activate(true);
		}
	}
	WaitActivateMap.Empty();
}