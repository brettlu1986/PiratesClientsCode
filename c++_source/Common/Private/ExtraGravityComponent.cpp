// Fill out your copyright notice in the Description page of Project Settings.

#include "ExtraGravityComponent.h"
#include "Common.h"

UExtraGravityComponent::UExtraGravityComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
}


void UExtraGravityComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	if (RootComponent && RootComponent->IsCollisionEnabled())
	{
		RootComponent->AddForce(Force);
	}
}

void UExtraGravityComponent::SetExtraGravity(const FVector & ExtraGravity)
{
	RootComponent = Cast<UPrimitiveComponent>(GetOwner()->GetRootComponent());
	if (RootComponent)
	{
		Force = ExtraGravity * RootComponent->GetMass();
	}
}

