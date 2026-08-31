// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/StaticMeshComponent.h"
#include "ShipCollisionComponent.generated.h"

/**
 * 
 */
UCLASS(ClassGroup = Ship, meta = (BlueprintSpawnableComponent), Blueprintable)
class COMMON_API UShipCollisionComponent : public UStaticMeshComponent
{
	GENERATED_BODY()
	
public:
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float DamageScale;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    UMaterialInterface* VisualMaterial;

#if WITH_EDITOR
    virtual void PostInitProperties() override;


    virtual void PostEditChangeProperty(struct FPropertyChangedEvent& PropertyChangedEvent) override;


private:
    void Visualize();

#endif
};
