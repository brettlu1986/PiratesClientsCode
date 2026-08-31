// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "HUDModuleBase.h"
#include "GestureHUDModule.generated.h"

UCLASS(Config = Pirates)
class COMMON_API UGestureHUDModule : public UHUDModuleBase
{
	GENERATED_UCLASS_BODY()

private:	
	struct Impl;
	TSharedPtr<Impl> impl;

public:
	virtual ~UGestureHUDModule();
    virtual void BeginPlay() override;
	virtual void DrawHUD(UCanvas* Canvas) override;
	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

public:

    UFUNCTION(BlueprintCallable, Category = "GestureHUDModule")
	void RecordVirtualJoystick(const FVector2D& DistanceDelta, const FVector2D& CurrentPosition, const FVector2D& StartPosition);

    UFUNCTION(BlueprintCallable, Category = "GestureHUDModule")
	void HideVirtualJoystick();

	UFUNCTION(BlueprintCallable, Category = "GestureHUDModule")
	void SetVirtualJoystickEnable(bool Enable);

public:

	UPROPERTY(config)
	FString JoystickTexturePath;

	UPROPERTY(config)
	FString JoystickPadActiveTexturePath;

	UPROPERTY(config)
	FString JoystickPadDeactiveTexturePath;
};