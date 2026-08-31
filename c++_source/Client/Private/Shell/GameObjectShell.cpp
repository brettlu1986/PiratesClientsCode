// Fill out your copyright notice in the Description page of Project Settings.

#include "GameObjectShell.h"
#include "Client.h"

UObject * UGameObjectShell::CreateObject(UClass * Class)
{
    if (!Class)
    {
        return nullptr;
    }
    UObject* RetObject = NewObject<UObject>(this, Class);
    Objects.Add(RetObject);
    return RetObject;
}

void UGameObjectShell::ReleaseObject(UObject * Object)
{
    if (Object && (Objects.Remove(Object) > 0))
    {
        Object->MarkPendingKill();
    }
}

void UGameObjectShell::ClearAllObjects()
{
    for (auto& Object : Objects)
    {
        if (IsValid(Object))
        {
            Object->MarkPendingKill();
        }
    }
    Objects.Empty();
}

UWorld* UGameObjectShell::GetWorld() const
{
    auto Outer = GetOuter();
    return Outer ? Outer->GetWorld() : nullptr;
}
