// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/Actor.h"
#include "Components/SplineComponent.h"
#include "SplinePointSource.generated.h"

UCLASS()
class EDITOR_API ASplinePointSource : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ASplinePointSource();

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Category = ASplinePointSource)
    USplineComponent* Spline;

    //~ Begin UObject Interface
    virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
    //~ End UObject Interface
};
