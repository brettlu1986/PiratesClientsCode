// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMObject.h"
#include "BitmapFontText.generated.h"

class UBitmapFontHUDModule;

UCLASS()
class COMMON_API UBitmapFontText : public UKMObject
{
	GENERATED_UCLASS_BODY()

private:
	struct Impl;
	TSharedPtr<Impl> impl;

public:
	~UBitmapFontText();
	void Init(UBitmapFontHUDModule* BitmapFontHUDModule);
	void Draw(AHUD* HUD);

public:

	UFUNCTION(BlueprintCallable, Category = BitmapFontText)
	void SetFontType(uint8 FontType);

	UFUNCTION(BlueprintCallable, Category = BitmapFontText)
	uint8 GetFontType();

	UFUNCTION(BlueprintCallable, Category = BitmapFontText)
	float GetFontWidth();

	UFUNCTION(BlueprintCallable, Category = BitmapFontText)
	float GetFontHeight();

	UFUNCTION(BlueprintCallable, Category = BitmapFontText)
	void Reset();

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default, Meta = (DefaultValue = "0.f,0.f"))
	FVector2D Position;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default, Meta = (DefaultValue = "128.f"))
	float FontSize;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default, Meta = (DefaultValue = "0.f"))
	float FontKerning;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default, Meta = (DefaultValue = "1.f"))
	float Alpha;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default, Meta = (DefaultValue = ""))
	FString Text;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Default, Meta = (DefaultValue = "true"))
	bool Visible;
};