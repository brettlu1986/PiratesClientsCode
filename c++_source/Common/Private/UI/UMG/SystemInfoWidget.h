// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "PiratesUserWidget.h"
#include "SystemInfoWidget.generated.h"

UENUM(BlueprintType)
enum class EBatteryUIState : uint8
{
	COMMON,
	LOW,
	CHARGING
};

UCLASS()
class COMMON_API USystemInfoWidget : public UPiratesUserWidget
{
	GENERATED_UCLASS_BODY()

public:
	UPROPERTY(meta = (BindWidgetOptional))
	class UImage* imgNet;

	UPROPERTY(meta = (BindWidgetOptional))
	class UImage* imgBatteryBg;

	UPROPERTY(meta = (BindWidgetOptional))
	class UProgressBar* pgbBattery;

	UPROPERTY(meta = (BindWidgetOptional))
	class UTextBlock* txtTime;

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString TimeFormat;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	int BatteryLowLevel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (DisplayThumbnail = "true", AllowedClasses = "Texture,MaterialInterface,SlateTextureAtlasInterface"))
	UObject* WifiNetRes;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (DisplayThumbnail = "true", AllowedClasses = "Texture,MaterialInterface,SlateTextureAtlasInterface"))
	UObject* MobileNetRes;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TMap<EBatteryUIState, FLinearColor> BatteryColorMap;
	
protected:
	virtual void NativeConstruct() override;
	virtual void NativeTickInternal(const FGeometry& MyGeometry, float InDeltaTime) override;

private:
	EBatteryUIState GetBatteryUIState();
	int GetBatteryLevel();

	void Update();
	void UpdateNet();
	void UpdateBatteryLevel();
	void UpdateBatteryState();
	void UpdateTime();

protected:
	FDateTime LastDataTime;
	bool bLastIsWifi;
	int LastBatteryLevel;
	EBatteryUIState LastBatteryUIState;
};
