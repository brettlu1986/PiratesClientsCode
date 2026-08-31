// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/GameMode.h"
#include "KMGameMode.generated.h"

/**
 * 
 */
//class UKMScriptActorHelper;
class UGameModeDelegate;


UCLASS()
class ENGINEEXT_API AKMGameMode : public AGameMode
{
	GENERATED_UCLASS_BODY()
	
public:
    // 抛delegate
    virtual FString InitNewPlayer(class APlayerController* NewPlayerController, const FUniqueNetIdRepl& UniqueId, const FString& Options, const FString& Portal) override;
    virtual void InitGameState() override;
    virtual void StartPlay() override;
    virtual void InitGame(const FString& MapName, const FString& Options, FString& ErrorMessage) override;
	virtual void PostLogin(APlayerController* NewPlayer) override;
    virtual void Logout(AController* Exiting) override;
    virtual bool ReadyToStartMatch_Implementation() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    virtual void FinishRestartPlayer(AController* NewPlayer, const FRotator& StartRotation) override;

	//yangjingzhao 2019.3.18
	//We override it now, for avoiding huge data replication when initializing player
	//World will update local level streaming state when character is spawned
	virtual void ReplicateStreamingStatus(APlayerController* PC) override;

    UFUNCTION()
    FString ParseInitOptions(const FString &InKey);

    UFUNCTION()
    void GetAllPlayerStart(TArray<APlayerStart*>& Out);

protected:
    virtual APawn* SpawnDefaultPawnFor_Implementation(AController* NewPlayer, AActor* StartSpot) override;
};
