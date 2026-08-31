// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/SceneComponent.h"
#include "Camera/CameraTypes.h"
#include "KMSceneCaptureRecord.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, ClassGroup = "UserInterface", hidecategories = (Object, Activation, "Components|Activation", Sockets, Base, Lighting, LOD, Mesh), editinlinenew, meta = (BlueprintSpawnableComponent))
class ENGINEEXT_API UKMSceneCaptureRecord : public USceneComponent
{
	GENERATED_BODY()
    virtual void BeginPlay() override;
public:

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Projection, meta = (DisplayName = "Projection Type"))
    TEnumAsByte<ECameraProjectionMode::Type> ProjectionType;

    /** Camera field of view (in degrees). */
    UPROPERTY(interp, Category = Projection, meta = (DisplayName = "Field of View", UIMin = "5.0", UIMax = "170", ClampMin = "0.001", ClampMax = "360.0"))
    float FOVAngle;

    /** The desired width (in world units) of the orthographic view (ignored in Perspective mode) */
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Projection)
    float OrthoWidth;
};
 