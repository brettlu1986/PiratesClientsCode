// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Animation/AnimInstance.h"
#include "KMAnimInstance.generated.h"

/**
 * 
 */
UCLASS(Blueprintable)
class ENGINEEXT_API UKMAnimInstance : public UAnimInstance
{
	GENERATED_UCLASS_BODY()

private:
	struct FImplement;
	TSharedPtr<FImplement> Impl;
	
public:
	UFUNCTION(BlueprintCallable, meta = (DisplayName = "PlayMontageSection", Keywords = "montage section"), Category = "KMAnimation")
	bool PlayMontageSection(UAnimMontage * MontageToPlay, FName SectionName, float InPlayRate = 1.f, bool needCallback = true);

	UFUNCTION(BlueprintNativeEvent, meta = (DisplayName = "OnMontagePlayEnd", Keywords = "montage playend"), Category = "KMAnimation")
	void OnMontagePlayEnd(FName SectionName);
};
