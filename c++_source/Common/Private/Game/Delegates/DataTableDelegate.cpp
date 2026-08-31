// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Delegates/DataTableDelegate.h"
#include "Common.h"
#include "Delegates/DataTableDelegate.h"

DEFINE_LOG_CATEGORY_STATIC(DataTableDelegateLog, Log, All)

int UDataTableDelegate::GetInt(const FString& TableName, int Id, const FString& ColumnName)
{
    int Ret = 0;
    if (OnGetIntInDataTable.IsBound())
    {
        Ret = OnGetIntInDataTable.Execute(TableName, Id, ColumnName);
    }
    else
    {
        // Delegate 'OnGetIntInDataTable' isn't bound in lua or maybe it's in mistake ManagerGroup
        UE_LOG(DataTableDelegateLog, Error, TEXT("Delegate 'OnGetIntInDataTable' isn't bound in lua."))
    }
    return Ret;
}

float UDataTableDelegate::GetFloat(const FString& TableName, int Id, const FString& ColumnName)
{
    float Ret = 0;
    if (OnGetFloatInDataTable.IsBound())
    {
        Ret = OnGetFloatInDataTable.Execute(TableName, Id, ColumnName);
    }
    else
    {
        // Delegate 'OnGetFloatInDataTable' isn't bound in lua or maybe it's in mistake ManagerGroup
        UE_LOG(DataTableDelegateLog, Error, TEXT("Delegate 'OnGetFloatInDataTable' isn't bound in lua."))
    }
    return Ret;
}

FString UDataTableDelegate::GetString(const FString& TableName, int Id, const FString& ColumnName)
{
    FString Ret;
    if (OnGetStringInDataTable.IsBound())
    {
        Ret = OnGetStringInDataTable.Execute(TableName, Id, ColumnName);
    }
    else
    {
        // Delegate 'OnGetStringInDataTable' isn't bound in lua or maybe it's in mistake ManagerGroup
        UE_LOG(DataTableDelegateLog, Error, TEXT("Delegate 'OnGetStringInDataTable' isn't bound in lua."))
    }
    return Ret;
}