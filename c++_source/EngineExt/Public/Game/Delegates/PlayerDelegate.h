// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "PlayerDelegate.generated.h"

DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnPossess, uint32, PCUniqueId, uint32, PawnUniqueId);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnUnPossess, uint32, PCUniqueId);
DECLARE_DYNAMIC_DELEGATE_SixParams(FOnClientRestart, AController*, Controller, uint32, PCUniqueId, uint32, PCNetGuid, APawn*, Pawn, uint32, PawnUniqueId, uint32, PawnNetGuid);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnBeginSpectating, uint32, PCUniqueId);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnEndSpectating, uint32, PCUniqueId);
DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnServerExecGM, AKMPlayerController*, PlayerController, const FString&, Param);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnClientWasKicked, const FText&, Reason);

UCLASS()
class ENGINEEXT_API UPlayerDelegate : public UObject
{
    GENERATED_BODY()

public:
    UPROPERTY()
    FOnPossess OnPossess;

    UPROPERTY()
    FOnUnPossess OnUnPossess;

    UPROPERTY()
    FOnClientRestart OnClientRestart;

    UPROPERTY()
    FOnBeginSpectating OnBeginSpectating;

    UPROPERTY()
    FOnEndSpectating OnEndSpectating;

    UPROPERTY()
    FOnServerExecGM OnServerExecGM;

    UPROPERTY()
    FOnClientWasKicked OnClientWasKicked;
};
