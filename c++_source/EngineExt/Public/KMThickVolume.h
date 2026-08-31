// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Volume.h"
#include "KMThickVolume.generated.h"

UCLASS(Abstract)
class ENGINEEXT_API AKMThickVolume : public AVolume
{
	GENERATED_BODY()
	
public:
	virtual void BeginPlay() override;
	virtual void NotifyActorBeginOverlap(AActor* OtherActor) override;
	virtual void NotifyActorEndOverlap(AActor* OtherActor) override;

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float Thickness = 100.0f;

private:
	FVector2D CalcNewScale(float InThickness) const;

private:
	FVector2D OriginalScale2D;
	FVector2D OriginalSize2D;	
	
};
