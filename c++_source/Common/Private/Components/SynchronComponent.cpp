// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/SynchronComponent.h"
#include "Common.h"


// Sets default values for this component's properties
USynchronComponent::USynchronComponent(): ShipMovementComponent(NULL), FlotageComponent(NULL)
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
	// ...
}

// Called when the game starts
void USynchronComponent::BeginPlay()
{
	Super::BeginPlay();

	// ...
	if (NULL != GetOwner())
	{
		ShipMovementComponent = Cast<UShipMovementComponent>(GetOwner()->GetComponentByClass(UShipMovementComponent::StaticClass()));
		FlotageComponent = Cast<UFlotageComponent>(GetOwner()->GetComponentByClass(UFlotageComponent::StaticClass()));
	}	
}


// Called every frame
void USynchronComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
	if ((NULL != ShipMovementComponent) && (NULL != FlotageComponent))
	{
		ShipMovementComponent->UpdateShipTransformRestrictly(FlotageComponent->LocationZ, FlotageComponent->Pitch, FlotageComponent->Roll);

		FlotageComponent->SetShipLinearSpeed(ShipMovementComponent->GetCurrentLinearSpeed());
		FlotageComponent->SetShipAngularSpeed(ShipMovementComponent->GetCurrentAngularSpeed());
	}
}

