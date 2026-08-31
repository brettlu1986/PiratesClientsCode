// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "LogCatcher.generated.h"

/**
 * 
 */
UCLASS()
class COMMON_API ULogCatcher : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()

    UFUNCTION(BlueprintCallable, Category = "LogCatcher")
    static bool IsEnabled();

    UFUNCTION(BlueprintCallable, Category = "LogCatcher")
    static void SetEnable(bool bEnable);

    //UFUNCTION(BlueprintCallable, Category = "LogCatcher")
    //static float GetMainThreadDumpLogTime();

    //UFUNCTION(BlueprintCallable, Category = "LogCatcher")
    //static float GetWorkThreadDumpLogTime();
};
