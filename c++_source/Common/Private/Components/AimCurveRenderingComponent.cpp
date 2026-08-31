// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/AimCurveRenderingComponent.h"
#include "Common.h"

UAimCurveRenderingComponent::UAimCurveRenderingComponent(const class FObjectInitializer& ObjectInitializer)
	: Super			(ObjectInitializer)
	, DefaultLength (0.f)
	, RealLength	(0.f)
	, WidthRatio	(1.f)
	, HeightRatio	(1.f)
{

}

void UAimCurveRenderingComponent::SetCurveRealLength(float InRealLength)
{
	RealLength = InRealLength;
	float Ratio = RealLength / DefaultLength;
	SetRelativeScale3D(FVector(Ratio, WidthRatio, Ratio * HeightRatio));
}

float UAimCurveRenderingComponent::GetCurveRealLength()
{
	return DefaultLength * GetCurveLengthRatio();
}

float UAimCurveRenderingComponent::GetCurveLengthRatio()
{
	return GetRelativeTransform().GetScale3D().X;
}