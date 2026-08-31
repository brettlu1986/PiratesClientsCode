// Fill out your copyright notice in the Description page of Project Settings.

#include "KMParticleSignificance.h"
#include "Kismet/GameplayStatics.h"
#include "Engine.h"

DEFINE_LOG_CATEGORY_STATIC(LogParticleSignificance, Log, All);

static int32 GXSJEnableParticleSignificance = 0;
static FAutoConsoleVariableRef CVarXSJEnableParticleSignificance(
	TEXT("xsj.EnableParticleSignificance"),
	GXSJEnableParticleSignificance,
	TEXT("Enable Particle Significance.")
);

void UKMParticleSignificance::RegisterParticle(UParticleSystemComponent* Particle)
{
	if (GXSJEnableParticleSignificance == 0) return;
	if (USignificanceManager* SignificanceManager = USignificanceManager::Get(Particle->GetWorld()))
	{
		Particle->SetManagingSignificance(true);
		if (!SignificanceManager->GetManagedObject(Particle))
		{
			SignificanceManager->RegisterObject(Particle, TEXT("Particle"), ParticleSignificance, USignificanceManager::EPostSignificanceType::Sequential, ParticlePostSignificance);
		}
	}

}

void UKMParticleSignificance::UnRegisterParticle(UParticleSystemComponent* Particle)
{
	if (GXSJEnableParticleSignificance == 0) return;
	if (USignificanceManager* SignificanceManager = USignificanceManager::Get(Particle->GetWorld()))
	{
		Particle->SetManagingSignificance(false);
		SignificanceManager->UnregisterObject(Particle);
	}
}

bool UKMParticleSignificance::IsParticleRegistered(UParticleSystemComponent* Particle)
{
	if (GXSJEnableParticleSignificance == 0) return false;
	if (USignificanceManager* SignificanceManager = USignificanceManager::Get(Particle->GetWorld()))
	{
		return SignificanceManager->GetManagedObject(Particle) != nullptr;
	}
	return false;
}

float UKMParticleSignificance::ParticleSignificance(USignificanceManager::FManagedObjectInfo* Info, const FTransform& Tranform)
{	
	UObject* Object = Info->GetObject();
	if (IsValid(Object) && Object->IsValidLowLevel())
	{
		auto Particle = Cast<UParticleSystemComponent>(Object);
		check(Particle);
		if (APlayerController* Controller = UGameplayStatics::GetPlayerController(Particle, 0))
		{
			FVector ViewLocation;
			FRotator ViewRotation;
			Controller->GetPlayerViewPoint(ViewLocation, ViewRotation);
			FVector Forward = ViewRotation.Vector();
			FVector Direction = Particle->GetComponentLocation() - Tranform.GetLocation();
			float Projection = FVector::DotProduct(Forward, Direction);
			UE_LOG(LogParticleSignificance, Verbose, TEXT("Forward = (%s), Direction = (%s), Projection = %f"), *Forward.ToString(), *Direction.ToString(), Projection);
			return Projection;
		}
	}
	else
	{
		UE_LOG(LogParticleSignificance, Warning, TEXT("Particle is deleted without unregister from significance manager. (ParticleSignificance)"));
	}
	return 0.0f;
}

void UKMParticleSignificance::ParticlePostSignificance(USignificanceManager::FManagedObjectInfo* Info, float OldSignificance, float Significance, bool bIsPendingUnregister)
{
	UObject* Object = Info->GetObject();
	if (IsValid(Object) && Object->IsValidLowLevel())
	{
		auto Particle = Cast<UParticleSystemComponent>(Object);
		check(Particle);
		EParticleSignificanceLevel Level = EParticleSignificanceLevel::Low;
		if (Significance < 0.0f || Significance > 1500.0f)
		{
			Level = EParticleSignificanceLevel::Critical;
		}
		else if (Significance > 1000.0f)
		{
			Level = EParticleSignificanceLevel::High;
		}
		else if (Significance > 500.0f)
		{
			Level = EParticleSignificanceLevel::Medium;
		}
		//Level = EParticleSignificanceLevel::Critical;
		Particle->SetRequiredSignificance(Level);
	}
	else
	{
		UE_LOG(LogParticleSignificance, Warning, TEXT("Particle is deleted without unregister from significance manager. (ParticlePostSignificance)"));
	}
}

