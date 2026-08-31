// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "ShipDamageType.generated.h"

UCLASS(const, Blueprintable, BlueprintType)
class COMMON_API UShipDamageType : public UDamageType
{
	GENERATED_BODY()

public:

    virtual UWorld* GetWorld() const override;
};
