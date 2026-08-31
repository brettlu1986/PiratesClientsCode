// Fill out your copyright notice in the Description page of Project Settings.

#include "KMThickVolume.h"
#include "EngineExt.h"
#include "Components/BrushComponent.h"

void AKMThickVolume::BeginPlay()
{
	Super::BeginPlay();
	if (GetBrushComponent())
	{
		FBox BoundingBox = GetBounds().GetBox();
		FTransform Transform = GetBrushComponent()->GetComponentTransform();
		OriginalScale2D.Set(Transform.GetScale3D().X, Transform.GetScale3D().Y);
		OriginalSize2D.Set(BoundingBox.GetSize().X, BoundingBox.GetSize().Y);
	}
}

void AKMThickVolume::NotifyActorBeginOverlap(AActor* OtherActor)
{
	Super::NotifyActorBeginOverlap(OtherActor);
	if (GetBrushComponent())
	{
		FTransform Transform = GetBrushComponent()->GetComponentTransform();
		FVector NewScale(OriginalScale2D * CalcNewScale(Thickness), Transform.GetScale3D().Z);
		GetBrushComponent()->SetWorldScale3D(NewScale);
	}
}

void AKMThickVolume::NotifyActorEndOverlap(AActor* OtherActor)
{
	Super::NotifyActorEndOverlap(OtherActor);
	if (GetBrushComponent())
	{
		FTransform Transform = GetBrushComponent()->GetComponentTransform();
		FVector NewScale(OriginalScale2D * CalcNewScale(-Thickness), Transform.GetScale3D().Z);
		GetBrushComponent()->SetWorldScale3D(NewScale);
	}
}

FVector2D AKMThickVolume::CalcNewScale(float InThickness) const
{
	FVector2D NewScale = (OriginalSize2D + InThickness) / OriginalSize2D;
	return FVector2D(FMath::Max(NewScale.X, 0.0f), FMath::Max(NewScale.Y, 0.0f));
}
