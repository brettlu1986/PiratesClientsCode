// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "DataTableDelegate.generated.h"

DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(int, FOnGetIntInDataTable, const FString&, TableName, int, Id, const FString&, ColumnName);
DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(float, FOnGetFloatInDataTable, const FString&, TableName, int, Id, const FString&, ColumnName);
DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(FString, FOnGetStringInDataTable, const FString&, TableName, int, Id, const FString&, ColumnName);

UCLASS()
class COMMON_API UDataTableDelegate : public UObject
{
    GENERATED_BODY()

public:

    UFUNCTION(BlueprintPure, Category = DataTableDelegate)
    int GetInt(const FString& TableName, int Id, const FString& ColumnName);
    UPROPERTY()
    FOnGetIntInDataTable OnGetIntInDataTable;

    // Get Int Property
    UFUNCTION(BlueprintPure, Category = DataTableDelegate)
    float GetFloat(const FString& TableName, int Id, const FString& ColumnName);
    UPROPERTY()
    FOnGetFloatInDataTable OnGetFloatInDataTable;

    // Get Bool Property
    UFUNCTION(BlueprintPure, Category = PropertyDelegate)
    FString GetString(const FString& TableName, int Id, const FString& ColumnName);
    UPROPERTY()
    FOnGetStringInDataTable OnGetStringInDataTable;
};
