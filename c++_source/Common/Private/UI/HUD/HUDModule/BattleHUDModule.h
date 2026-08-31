// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "HUDModuleBase.h"
#include "BattleHUDModule.generated.h"

UCLASS()
class COMMON_API UBattleHUDModule : public UHUDModuleBase
{
	GENERATED_UCLASS_BODY()

private:
	struct Impl;
	TSharedPtr<Impl> impl;

public:
	virtual ~UBattleHUDModule();
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;
	virtual void DrawHUD(UCanvas *Canvas) override;

public:
	UFUNCTION(BlueprintCallable, Meta = (BlueprintProtected, FontSize = "48.f", FontKerning = "-0.5f"), Category = BattleHUDModule)
	void AddBattleData(uint8 FontType, FVector2D Position, FString BattleText, float FontSize, float FontKerning);

public:

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float DataScaleAnimTime;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float DataHideAnimTime;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float DataHideDelayTime;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float DataMoveOffsetXRatio;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float DataMoveOffsetYRatio;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float DataScaleMaxRatio;
};
