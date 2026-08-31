// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMObject.h"
#include "PiratesHUD.h"
#include "HUDModuleBase.generated.h"


UCLASS()
class COMMON_API UHUDModuleBase : public UKMObject
{
	GENERATED_UCLASS_BODY()
	
public:
	virtual ~UHUDModuleBase();

	virtual void BeginPlay();
	virtual void Tick(float DeltaSeconds);
	virtual void DrawHUD(UCanvas *Canvas);

	UFUNCTION(BlueprintImplementableEvent, meta = (DisplayName = "BeginPlay"))
	void ReceiveBeginPlay();

protected:
    class APiratesHUD* PiratesHUD;
};
