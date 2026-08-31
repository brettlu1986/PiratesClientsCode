// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/SceneCaptureComponent2D.h"
#include "KMSceneCaptureComponent2D.generated.h"

class UKMSceneCaptureRecord;
/**
 * 
 */
UCLASS(Blueprintable, ClassGroup = "UserInterface", hidecategories = (Object, Activation, "Components|Activation", Sockets, Base, Lighting, LOD, Mesh), editinlinenew, meta = (BlueprintSpawnableComponent))
class ENGINEEXT_API UKMSceneCaptureComponent2D : public USceneCaptureComponent2D
{
	GENERATED_BODY()
    virtual void BeginPlay() override;

private:
    UKMSceneCaptureRecord* CaptureRecord;
};
 