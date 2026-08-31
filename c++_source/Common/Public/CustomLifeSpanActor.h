// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "CustomLifeSpanActor.generated.h"

UCLASS(meta=(ChildCanTick))
class COMMON_API ACustomLifeSpanActor : public AActor
{
	GENERATED_BODY()

public:
	virtual void LifeSpanExpired() override;
	
protected:
	UFUNCTION(BlueprintImplementableEvent, meta = (DisplayName = "LifeSpanExpired"))
	void ReceiveLifeSpanExpired();
};
