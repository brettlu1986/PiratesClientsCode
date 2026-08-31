// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "BattleShipPropertyBlackboard.generated.h"

DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(float, FOnGetFloatProperty, const FName&, PropertyType, int, Key, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(int, FOnGetIntProperty, const FName&, PropertyType, int, Key, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(bool, FOnGetBoolProperty, const FName&, PropertyType, int, Key, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(FString, FOnGetStringProperty, const FName&, PropertyType, int, Key, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_FourParams(float, FOnGetFloatPropertyWithTwoKeys, const FName&, PropertyType, int, Key1, int, Key2, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_FourParams(int, FOnGetIntPropertyWithTwoKeys, const FName&, PropertyType, int, Key1, int, Key2, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_FourParams(bool, FOnGetBoolPropertyWithTwoKeys, const FName&, PropertyType, int, Key1, int, Key2, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_FourParams(FString, FOnGetStringPropertyWithTwoKeys, const FName&, PropertyType, int, Key1, int, Key2, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_FiveParams(float, FOnGetFloatPropertyWithThreeKeys, const FName&, PropertyType, int, Key1, int, Key2, int, Key3, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_FiveParams(int, FOnGetIntPropertyWithThreeKeys, const FName&, PropertyType, int, Key1, int, Key2, int, Key3, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_FiveParams(bool, FOnGetBoolPropertyWithThreeKeys, const FName&, PropertyType, int, Key1, int, Key2, int, Key3, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_RetVal_FiveParams(FString, FOnGetStringPropertyWithThreeKeys, const FName&, PropertyType, int, Key1, int, Key2, int, Key3, const FName&, PropertyName);
DECLARE_DYNAMIC_DELEGATE_FiveParams(FOnGetFloatPropertysWithTwoKeys, const FName&, PropertyType, int, Key1, int, Key2, const TArray<FString>&, PropertyNames, TArray<float>&, OutValues);

UCLASS()
class COMMON_API UBattleShipPropertyBlackboard : public UObject
{
	GENERATED_BODY()

public:
    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static int GetIntProperty(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static float GetFloatProperty(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static bool GetBoolProperty(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static FString GetStringProperty(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static int GetIntPropertyWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
	static float GetFloatPropertyWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const FName& PropertyName);

	UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
	static void GetFloatPropertysWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const TArray<FString>& PropertyNames, TArray<float>& OutValues);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static bool GetBoolPropertyWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static FString GetStringPropertyWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const FName& PropertyName);
    
    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static int GetIntPropertyWithThreeKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key1, int Key2, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static float GetFloatPropertyWithThreeKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key1, int Key2, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static bool GetBoolPropertyWithThreeKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key1, int Key2, const FName& PropertyName);

    UFUNCTION(BlueprintPure, Category = "BattleBlackboard", meta = (WorldContext = "WorldContextObject"))
    static FString GetStringPropertyWithThreeKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key1, int Key2, const FName& PropertyName);

    UPROPERTY()
    FOnGetFloatProperty OnGetFloatProperty;
    UPROPERTY()
    FOnGetIntProperty OnGetIntProperty;
    UPROPERTY()
    FOnGetBoolProperty OnGetBoolProperty;
    UPROPERTY()
	FOnGetStringProperty OnGetStringProperty;
	UPROPERTY()
	FOnGetFloatPropertyWithTwoKeys OnGetFloatPropertyWithTwoKeys;
	UPROPERTY()
	FOnGetFloatPropertysWithTwoKeys OnGetFloatPropertysWithTwoKeys;
    UPROPERTY()
    FOnGetIntPropertyWithTwoKeys OnGetIntPropertyWithTwoKeys;
    UPROPERTY()
    FOnGetBoolPropertyWithTwoKeys OnGetBoolPropertyWithTwoKeys;
    UPROPERTY()
    FOnGetStringPropertyWithTwoKeys OnGetStringPropertyWithTwoKeys;
    UPROPERTY()
    FOnGetFloatPropertyWithThreeKeys OnGetFloatPropertyWithThreeKeys;
    UPROPERTY()
    FOnGetIntPropertyWithThreeKeys OnGetIntPropertyWithThreeKeys;
    UPROPERTY()
    FOnGetBoolPropertyWithThreeKeys OnGetBoolPropertyWithThreeKeys;
    UPROPERTY()
    FOnGetStringPropertyWithThreeKeys OnGetStringPropertyWithThreeKeys;
};
