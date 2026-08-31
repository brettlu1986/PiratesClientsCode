// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "UObject/Object.h"
#include "LogReport.generated.h"

UCLASS()
class COMMON_API ULogReport : public UObject
{
    GENERATED_BODY()

public:
    bool Init();

    bool Uninit();

    UFUNCTION()
    bool IsEnabled();

    UFUNCTION()
    void SetEnabled(bool bEnabled);

    DECLARE_DYNAMIC_DELEGATE_FiveParams(FOnLogReport, uint8, Level, const FString&, Message, const FString&, Category, int64, CurrentTime, int32, FrameCount);
    UPROPERTY()
    FOnLogReport OnLogReport;

private:
    class FLogReport* LogReport;
};
