// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Game/Delegates/KMDelegateManager.h"
#include "GameDelegateManager.generated.h"

UCLASS()
class COMMON_API UGameDelegateManager : public UKMDelegateManager
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UFightDelegate* Fight;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UPropertyDelegate* Property;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UDataTableDelegate* DataTable;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UPiratesGameStateDelegate* GameState;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UBattleShipPropertyBlackboard* BattleShipPropertyBlackboard;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UPathNodeDelegate* PathNode;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UPiratesGameMiscDelegate* GameMisc;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UPiratesPlayerStateDelegate* PlayerState;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UPiratesGameNetDelegate* GameNet;
    UPROPERTY(BlueprintReadOnly, Category = GameDelegate)
    class UPiratesMovementDelegate* Movement;

public:
	virtual void Init() override;
};
