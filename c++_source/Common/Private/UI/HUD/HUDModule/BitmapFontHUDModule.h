// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "HUDModule/HUDModuleBase.h"
#include "BitmapFontHUDModule.generated.h"

USTRUCT(Blueprintable)
struct FBitmapCharData
{
	GENERATED_USTRUCT_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Values)
	float Width;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Values)
	float Height;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Values)
	float TextureU;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Values)
	float TextureV;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Values)
	float TextureUWidth;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Values)
	float TextureVHeight;
};

class UBitmapFontText;

UCLASS()
class COMMON_API UBitmapFontHUDModule : public UHUDModuleBase
{
	GENERATED_UCLASS_BODY()

private:
	struct Impl;
	TSharedPtr<Impl> impl;

public:
	virtual ~UBitmapFontHUDModule();
	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

public:
	UFUNCTION(BlueprintImplementableEvent, Category = BitmapFontHUDModule)
	FBitmapCharData GetCharData(uint8 FontType, const FString& Key);

	UFUNCTION(BlueprintImplementableEvent, Category = BitmapFontHUDModule)
	UTexture2D* GetFontTexture(uint8 FontType);

	UFUNCTION(BlueprintCallable, Category = BitmapFontHUDModule)
	UBitmapFontText* Acquire();

	UFUNCTION(BlueprintCallable, Category = BitmapFontHUDModule)
	void Release(UBitmapFontText* BitmapFontText);
};
