// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Delegates/GameDelegateManager.h"
#include "Common.h"
#include "Game/Delegates/FightDelegate.h"
#include "Game/Delegates/PropertyDelegate.h"
#include "Game/Delegates/DataTableDelegate.h"
#include "Game/Delegates/PiratesGameStateDelegate.h"
#include "Game/Delegates/PathNodeDelegate.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Game/Delegates/PiratesPlayerStateDelegate.h"
#include "Game/Delegates/PiratesGameNetDelegate.h"
#include "Game/Delegates/PiratesMovementDelegate.h"
#include "Game/Battle/BattleShipPropertyBlackboard.h"

void UGameDelegateManager::Init()
{
    Super::Init();
    Fight = NewObject<UFightDelegate>(this);
    Property = NewObject<UPropertyDelegate>(this);
    DataTable = NewObject<UDataTableDelegate>(this);
    GameState = NewObject<UPiratesGameStateDelegate>(this);
    BattleShipPropertyBlackboard = NewObject<UBattleShipPropertyBlackboard>(this);
    PathNode = NewObject<UPathNodeDelegate>(this);
    GameMisc = NewObject<UPiratesGameMiscDelegate>(this);
    PlayerState = NewObject<UPiratesPlayerStateDelegate>(this);
    GameNet = NewObject<UPiratesGameNetDelegate>(this);
    Movement = NewObject<UPiratesMovementDelegate>(this);

    GameMisc->Init();
}