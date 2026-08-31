// Fill out your copyright notice in the Description page of Project Settings.

#include "SplinePointSource.h"
#include "PiratesEditor.h"

static const FName SplineComponentName = FName(TEXT("Spline"));

// Sets default values
ASplinePointSource::ASplinePointSource()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = false;

    RootComponent = CreateDefaultSubobject<USceneComponent>(USceneComponent::GetDefaultSceneRootVariableName());
    SetRootComponent(RootComponent);

    Spline = CreateDefaultSubobject<USplineComponent>(SplineComponentName);
    Spline->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);
    Spline->SetClosedLoop(true);
    SetActorRelativeLocation(FVector::ZeroVector);
    bIsEditorOnlyActor = true;
    Spline->bIsEditorOnly = true;
}

void ASplinePointSource::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
    Super::PostEditChangeProperty(PropertyChangedEvent);
}
