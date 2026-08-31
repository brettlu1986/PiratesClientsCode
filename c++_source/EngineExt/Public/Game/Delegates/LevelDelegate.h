// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "LevelDelegate.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_FiveParams(FOnWorldCreation, UWorld *, World, uint32, WorldUniqueId, ALevelScriptActor*, Actor, uint32, LevelUniqueId, const FString&, ScriptType);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_FiveParams(FOnWorldRestart, UWorld *, World, uint32, WorldUniqueId, ALevelScriptActor*, Actor, uint32, LevelUniqueId, const FString&, ScriptType);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnWorldCleanup, uint32, WorldUniqueId);
//DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnPreLoadMap);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnPostLoadMap);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnLevelAddedToWorld, ULevel*, pLevel, const FString&, LevelName, bool, bPersistent);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnLevelRemovedFromWorld, uint32, LevelUniqueId, uint32, WorldUniqueId);

UCLASS()
class ENGINEEXT_API ULevelDelegate : public UObject
{
    GENERATED_BODY()

public:
    UPROPERTY()
    FOnWorldCreation OnWorldCreation;

    UPROPERTY()
    FOnWorldRestart OnWorldRestart;

    UPROPERTY()
    FOnWorldCleanup OnWorldCleanup;

    //UPROPERTY()
    //FOnPreLoadMap OnPreLoadMap;

    UPROPERTY()
    FOnPostLoadMap OnPostLoadMap;

    UPROPERTY()
    FOnLevelAddedToWorld OnLevelAddedToWorld;

    UPROPERTY()
    FOnLevelRemovedFromWorld OnLevelRemovedFromWorld;
};
