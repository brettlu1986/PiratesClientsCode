// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "PersistentTimer.generated.h"

/*
    此类只应用于不受GamePause限制的 Ping包 和 断线重连的timer 别的地方慎用
*/
UCLASS()
class COMMON_API UPersistentTimer : public UObject
{
	GENERATED_BODY()

public:
    void Init();
    void Uninit();
    void Tick(float DeltaTime);

    UFUNCTION()
    FTimerHandle SetTimer(UObject* Object, FString FunctionName, float Time, bool bLooping);
    UFUNCTION()
    FTimerHandle SetTimerDelegate(FTimerDynamicDelegate Delegate, float Time, bool bLooping);

    UFUNCTION()
    void ClearTimerHandle(FTimerHandle Handle);
private:
    FTimerManager* TimerManager;
};
