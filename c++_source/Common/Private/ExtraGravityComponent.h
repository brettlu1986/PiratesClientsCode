// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "ExtraGravityComponent.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class UExtraGravityComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UExtraGravityComponent();

public:	
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	UFUNCTION(BlueprintCallable, Category="ExtraGravityComponent")
	void SetExtraGravity(const FVector& ExtraGravity);
	
private:
	UPrimitiveComponent* RootComponent;
	FVector Force;
};
