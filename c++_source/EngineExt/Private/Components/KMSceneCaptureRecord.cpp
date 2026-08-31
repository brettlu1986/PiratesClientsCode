// Fill out your copyright notice in the Description page of Project Settings.

#include "KMSceneCaptureRecord.h"
#include "EngineExt.h"

void UKMSceneCaptureRecord::BeginPlay()
{
    Super::BeginPlay();
    SetComponentTickEnabled(false);
    this->DetachFromComponent(FDetachmentTransformRules::KeepRelativeTransform);
}