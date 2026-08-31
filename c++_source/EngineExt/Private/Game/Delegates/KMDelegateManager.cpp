// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Delegates/KMDelegateManager.h"
#include "EngineExt.h"
#include "Game/Delegates/PlayerDelegate.h"
#include "Game/Delegates/ActorDelegate.h"
#include "Game/Delegates/LevelDelegate.h"
#include "Game/Delegates/GameModeDelegate.h"

UKMDelegateManager::UKMDelegateManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , Actor(nullptr)
    , Level(nullptr)
    , GameMode(nullptr)
    , Player(nullptr)
{
}

void UKMDelegateManager::Init()
{
    Actor = NewObject<UActorDelegate>(this);
    Level = NewObject<ULevelDelegate>(this);
    GameMode = NewObject<UGameModeDelegate>(this);
    Player = NewObject<UPlayerDelegate>(this);
}