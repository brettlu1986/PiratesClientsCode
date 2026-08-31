// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/PersistentTimer/PersistentTimer.h"
#include "Common.h"

void UPersistentTimer::Init()
{
    TimerManager = new FTimerManager();
}

void UPersistentTimer::Uninit()
{
    delete TimerManager;
    TimerManager = nullptr;
}

void UPersistentTimer::Tick(float DeltaTime)
{
    if (TimerManager == nullptr)
    {
        UE_LOG(LogBlueprintUserMessages, Error,
            TEXT("PersistentTimer Tick, but TimerManager is null"));
        return;
    }
    TimerManager->Tick(DeltaTime);
}

FTimerHandle UPersistentTimer::SetTimer(UObject* Object, FString FunctionName, float Time, bool bLooping)
{
    FName const FunctionFName(*FunctionName);

    if (Object)
    {
        UFunction* const Func = Object->FindFunction(FunctionFName);
        if (Func && (Func->ParmsSize > 0))
        {
            UE_LOG(LogBlueprintUserMessages, Warning, TEXT("PersistentTimer SetTimer passed a function (%s) that expects parameters."), *FunctionName);
            return FTimerHandle();
        }
    }

    FTimerDynamicDelegate Delegate;
    Delegate.BindUFunction(Object, FunctionFName);
    return SetTimerDelegate(Delegate, Time, bLooping);

}

FTimerHandle UPersistentTimer::SetTimerDelegate(FTimerDynamicDelegate Delegate, float Time, bool bLooping)
{
    FTimerHandle Handle;
    if (TimerManager == nullptr)
    {
        UE_LOG(LogBlueprintUserMessages, Error,
            TEXT("PersistentTimer SetTimer, but TimerManager is null"));
        return Handle;
    }

    if (Delegate.IsBound())
    {
        Handle = TimerManager->K2_FindDynamicTimerHandle(Delegate);
        TimerManager->SetTimer(Handle, Delegate, Time, bLooping);
    }
    else
    {
        UE_LOG(LogBlueprintUserMessages, Warning,
            TEXT("PersistentTimer SetTimer passed a bad function (%s) or object (%s)"),
            *Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
    }

    return Handle;
}

void UPersistentTimer::ClearTimerHandle(FTimerHandle Handle)
{
    if (TimerManager == nullptr)
    {
        UE_LOG(LogBlueprintUserMessages, Error,
            TEXT("PersistentTimer ClearTimerHandle, but TimerManager is null"));
        return;
    }
    TimerManager->ClearTimer(Handle);
}