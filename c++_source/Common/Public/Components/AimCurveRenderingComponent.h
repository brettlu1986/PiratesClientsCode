// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/StaticMeshComponent.h"
#include "AimCurveRenderingComponent.generated.h"

UCLASS(editinlinenew, meta = (BlueprintSpawnableComponent))
class COMMON_API UAimCurveRenderingComponent : public UStaticMeshComponent
{
	GENERATED_UCLASS_BODY()

public:
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float DefaultLength;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float RealLength;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float WidthRatio;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float HeightRatio;

	UFUNCTION(BlueprintCallable, Category = AimCurveRenderingComponent)
	void SetCurveRealLength(float InRealLength);

	UFUNCTION(BlueprintPure, Category = AimCurveRenderingComponent)
	float GetCurveRealLength();

	UFUNCTION(BlueprintPure, Category = AimCurveRenderingComponent)
	float GetCurveLengthRatio();
};