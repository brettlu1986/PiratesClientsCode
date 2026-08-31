// Fill out your copyright notice in the Description page of Project Settings.

#include "KMTickableObject.h"
#include "EngineExt.h"

UKMTickableObject::UKMTickableObject()
{
    InitializeDefaults();
}

UKMTickableObject::UKMTickableObject(const FObjectInitializer& ObjectInitializer)
{
    InitializeDefaults();
}

void UKMTickableObject::InitializeDefaults()
{
    CustomTimeDilation = 1.0f;
    MinTickInterval = 0.0f;
    LastTickDeltaSeconds = 0.0f;
    bTickableWhenPaused = false;
    bTickableInEditor = false;
    bTickableInDedicatedServer = false;
    bTickable = true;
}

void UKMTickableObject::Tick(float DeltaSeconds)
{
    
    if (MinTickInterval > 0)
    {
        LastTickDeltaSeconds += DeltaSeconds;
        if (LastTickDeltaSeconds >= MinTickInterval)
        {
            ReceiveTick(LastTickDeltaSeconds * CustomTimeDilation);
            LastTickDeltaSeconds = 0.0f;
        }
    }
    else
    {
        ReceiveTick(DeltaSeconds * CustomTimeDilation);
    }
}

bool UKMTickableObject::IsTickableWhenPaused() const
{
    return bTickableWhenPaused;
}

bool UKMTickableObject::IsTickableInEditor() const
{
    return bTickableInEditor;
}

UWorld* UKMTickableObject::GetTickableGameObjectWorld() const
{
    return GetWorld();
}

TStatId UKMTickableObject::GetStatId() const
{
    return TStatId();
}

bool UKMTickableObject::IsTickable() const
{
    return bTickable && !IsTemplate() && (bTickableInDedicatedServer || !IsRunningDedicatedServer());
}
