// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "WaterHitBlueprintBase.generated.h"



UCLASS(ClassGroup = (Utility, Common), BlueprintType, Blueprintable, meta = (BlueprintSpawnableComponent, IgnoreCategoryKeywordsInSubclasses))
class COMMON_API UWaterHitBlueprintBase : public UActorComponent
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintImplementableEvent, BlueprintCallable, Category = "WaterHit")
    void OnWaterHit();


public:	
	// Sets default values for this component's properties
	UWaterHitBlueprintBase();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float SeaLevelBias;
};
