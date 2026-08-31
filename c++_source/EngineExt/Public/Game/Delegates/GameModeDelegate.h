// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameModeDelegate.generated.h"

DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnInitGameMode, AKMGameMode*, GameMode, const FString&, Options);
DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnStartGameModeManually, AKMGameMode*, GameMode, const FString&, Options);
DECLARE_DYNAMIC_DELEGATE_FourParams(FOnInitNewPlayer, APlayerController*, PlayerController, uint32, PCUniqueId, uint32, PCNetGuid, const FString&, Options);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnPostLogin, uint32, UniqueId);
DECLARE_DYNAMIC_DELEGATE_RetVal_OneParam(FString, FApproveLogin, const FString&, Options);
DECLARE_DYNAMIC_DELEGATE_RetVal_OneParam(AActor*, FOnSpawnDefaultPawnForController, uint32, PCUniqueId);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnLogout, uint32, UniqueId);
DECLARE_DYNAMIC_DELEGATE(FOnEndPlay);
DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnStartPlay, AKMGameMode*, GameMode, const FString&, Options);
//DECLARE_DYNAMIC_DELEGATE_OneParam(FOnInitGameState, AActor*, GameState);


UCLASS()
class ENGINEEXT_API UGameModeDelegate : public UObject
{
    GENERATED_BODY()

public:

    UPROPERTY()
    FOnInitGameMode OnInitGameMode;

    UPROPERTY()
    FApproveLogin OnApproveLogin;

    UPROPERTY()
    FOnStartPlay OnStartPlay;

    UPROPERTY()
    FOnInitNewPlayer OnInitNewPlayer;

    UPROPERTY()
    FOnSpawnDefaultPawnForController OnSpawnDefaultPawnForController;

    UPROPERTY()
    FOnPostLogin OnPostLogin;

    UPROPERTY()
    FOnLogout OnLogout;

    UPROPERTY()
    FOnEndPlay OnEndPlay;

    UPROPERTY()
    FOnStartGameModeManually OnStartGameModeManually;

    //UPROPERTY()
    //FOnInitGameState OnInitGameState;

    //UPROPERTY()
    //FOnGetDefaultPawnClassForController OnGetDefaultPawnClassForController;
};
