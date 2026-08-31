// Fill out your copyright notice in the Description page of Project Settings.


#include "KMEmitterCameraLensEffectBase.h"

AKMEmitterCameraLensEffectBase::AKMEmitterCameraLensEffectBase(const FObjectInitializer& ObjectInitializer)
    : Super                 (ObjectInitializer)
    , StandardAspectRatio   (1.778)
    , StandardDistance      (1250)
    , StandardUnitDistance  (450)
{
    bDestroyOnSystemFinish = true;
}

void AKMEmitterCameraLensEffectBase::BeginPlay()
{
    Super::BeginPlay();
    ReCalculateReleativeTransform();
}

void AKMEmitterCameraLensEffectBase::ReCalculateReleativeTransform()
{
    int32 SizeX;
    int32 SizeY;
    GetWorld()->GetFirstPlayerController()->GetViewportSize(SizeX, SizeY);
    float AspectRatio = SizeX * 1.f / SizeY;
    float LocationX = StandardDistance + (AspectRatio - StandardAspectRatio) * StandardUnitDistance;
    RelativeTransform.SetLocation(FVector(LocationX, 0, 0));
}