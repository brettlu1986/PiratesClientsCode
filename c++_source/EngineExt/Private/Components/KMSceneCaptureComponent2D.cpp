// Fill out your copyright notice in the Description page of Project Settings.

#include "KMSceneCaptureComponent2D.h"
#include "EngineExt.h"
#include "KMSceneCaptureRecord.h"

void UKMSceneCaptureComponent2D::BeginPlay()
{
    Super::BeginPlay();
    SetComponentTickEnabled(false);
    this->DetachFromComponent(FDetachmentTransformRules::KeepRelativeTransform);
}