// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "HUDModuleBase.h"
#include "ComboHUDModule.generated.h"

UCLASS()
class COMMON_API UComboHUDModule : public UHUDModuleBase
{
	GENERATED_UCLASS_BODY()

private:
	struct Impl;
	TSharedPtr<Impl> impl;

public:
	virtual ~UComboHUDModule();
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;
	virtual void DrawHUD(UCanvas *Canvas) override;

public:

	UFUNCTION(BlueprintCallable, Category = ComboHUDModule)
	void AddCombo();

	UFUNCTION(BlueprintCallable, meta = (BlueprintProtected), Category = ComboHUDModule)
	void SetComboTextType(uint8 TextType);

public:
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	UTexture2D* ComboTexture;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	int32 MinComboCount;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float MaxLastTime;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float MaxScale;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float ComboTextKerning;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float ComboMarginLeft;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float AlphaAnimTime;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default)
	float ScaleSpeed;
};
