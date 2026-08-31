// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "PropertyDelegate.generated.h"

DECLARE_DYNAMIC_DELEGATE_RetVal_TwoParams(float, FOnGetFloatPropertyFromLua, int32, UniqueId, const FString&, Key);
DECLARE_DYNAMIC_DELEGATE_RetVal_TwoParams(bool, FOnGetBoolPropertyFromLua, int32, UniqueId, const FString&, Key);
DECLARE_DYNAMIC_DELEGATE_RetVal_TwoParams(int32, FOnGetIntPropertyFromLua, int32, UniqueId, const FString&, Key);

UCLASS()
class COMMON_API UPropertyDelegate : public UObject
{
    GENERATED_BODY()

public:
	UFUNCTION(BlueprintPure, Category="PropertyDelegate")
	float GetFloatPropertyFromLua(AActor* Actor, const FString& Key);

	UFUNCTION(BlueprintPure, Category = "PropertyDelegate")
	bool GetBoolPropertyFromLua(AActor* Actor, const FString& Key);

	UFUNCTION(BlueprintPure, Category = "PropertyDelegate")
	int32 GetIntPropertyFromLua(AActor* Actor, const FString& Key);

	UPROPERTY()
	FOnGetFloatPropertyFromLua OnGetFloatPropertyFromLua;

	UPROPERTY()
	FOnGetBoolPropertyFromLua OnGetBoolPropertyFromLua;

	UPROPERTY()
	FOnGetIntPropertyFromLua OnGetIntPropertyFromLua;
};
