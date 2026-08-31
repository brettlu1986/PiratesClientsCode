// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/SystemInfo/SystemInfoManager.h"
#include "Client.h"

USystemInfoManager::USystemInfoManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , CurrentNetState(EGameNetState::DisconnectionState)
{
}

void USystemInfoManager::Init()
{
    StartTicker(1.0f);
}

void USystemInfoManager::SetTickInterval(float Interval)
{
    StopTicker();
    StartTicker(Interval);
}

void USystemInfoManager::Uninit()
{
    StopTicker();
}

bool USystemInfoManager::Tick(float DeltaTime)
{
    EGameNetState LastNetState = CurrentNetState;
    CurrentNetState = FGamePlatformMisc::CheckNetState();
    if (LastNetState != CurrentNetState)
    {
        OnNetStateChanged.Broadcast(CurrentNetState);
    }
    return true;
}

void USystemInfoManager::StartTicker(float TickInterval)
{
    TickHandle = FTicker::GetCoreTicker().AddTicker(FTickerDelegate::CreateUObject(this, &USystemInfoManager::Tick), TickInterval);

    // 强刷下
    Tick(0.0f);
}

void USystemInfoManager::StopTicker()
{
    if (TickHandle.IsValid())
    {
        FTicker::GetCoreTicker().RemoveTicker(TickHandle);
        TickHandle.Reset();
    }
}