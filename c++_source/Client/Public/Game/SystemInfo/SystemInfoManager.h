// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GamePlatformMisc.h"
#include "SystemInfoManager.generated.h"


UCLASS()
class CLIENT_API USystemInfoManager : public UObject
{
    GENERATED_UCLASS_BODY()

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnNetStateChanged, EGameNetState, NetState);

public:
    UPROPERTY()
    FOnNetStateChanged OnNetStateChanged;

public:
    void Init();
    void Uninit();

    UFUNCTION()
    EGameNetState GetNetState() { return CurrentNetState; } // 不是即时更新，tick时才更新，如果需要即时值直接用UGamePlatformMiscLibrary里的

    UFUNCTION()
    void SetTickInterval(float Interval);

private:
    bool Tick(float DeltaTime);
    void StartTicker(float TickInterval);
    void StopTicker();
    
private:
    FDelegateHandle TickHandle;    
    EGameNetState CurrentNetState;
};
