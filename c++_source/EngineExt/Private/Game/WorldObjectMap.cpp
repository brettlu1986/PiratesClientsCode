// Fill out your copyright notice in the Description page of Project Settings.

#include "WorldObjectMap.h"
#include "EngineExt.h"

const UGameInstance* FWorldObjectMap::GetGameInstanceFromContextObject(const UObject* WorldContextObject)
{
    check(WorldContextObject);
    const UGameInstance* RetGameInstance = Cast<UGameInstance>(WorldContextObject); // 切换场景时，World为nullptr，此时WorldContextObject应为GameInstance本身
    if (nullptr == RetGameInstance)
    {
        auto World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
        if (nullptr != World)
        {
            RetGameInstance = World->GetGameInstance();
        }
    }
    return RetGameInstance;
}

UObject* FWorldObjectMap::GetObject(const UObject* WorldContextObject)
{
    check(WorldContextObject);
    auto GameInstance = GetGameInstanceFromContextObject(WorldContextObject);
    if (nullptr != GameInstance)
    {
        auto Game = GameMap.Find(GameInstance);
        return Game ? *Game : nullptr;
    }
    return nullptr;
}

void FWorldObjectMap::AddObject(const UObject* WorldContextObject, UObject* GameObject)
{
    check(WorldContextObject);
    auto GameInstance = GetGameInstanceFromContextObject(WorldContextObject);
    if (nullptr != GameInstance)
    {
        GameMap.Add(GameInstance, GameObject);
    }
}

bool FWorldObjectMap::RemoveObject(const UObject* WorldContextObject)
{
    check(WorldContextObject);
    auto GameInstance = GetGameInstanceFromContextObject(WorldContextObject);
    if (nullptr != GameInstance)
    {
        return GameMap.Remove(GameInstance) > 0;
    }
    return false;
}

void FWorldObjectMap::AddReferencedObjects(FReferenceCollector& Collector)
{
    Collector.AddReferencedObjects(GameMap);
}