// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/PlayerController.h"
#include "KMPlayerController.generated.h"

class AKMCharacter;

DECLARE_DELEGATE_OneParam(FOnPossessCharacter, AKMCharacter*);

/**
 * 
 */
UCLASS()
class ENGINEEXT_API AKMPlayerController : public APlayerController
{
    GENERATED_UCLASS_BODY()

private:
    struct FImplement;
    TSharedPtr<FImplement> Impl;

public:
    virtual void PostInitProperties() override;

	virtual bool CanRestartPlayer() override;

    virtual void CleanupPlayerState() override;

    virtual void BeginSpectatingState() override;

    virtual void EndSpectatingState() override;

    virtual void ClientWasKicked_Implementation(FText const& KickReason) override;

	UPROPERTY(BlueprintReadWrite, Category = "KMPlayerController")
	bool LevelLoadedOnClient = true;

	UFUNCTION()
	AActor* GetPlayerPawn();

	// 临时
	UFUNCTION()
	FString GetPlayerName() { return PlayerName;}

	UFUNCTION(BlueprintCallable, Category = "KMPlayerController")
	void ResetStartSpot();

    //UFUNCTION(BlueprintCallable, Server, Reliable, WithValidation, Category = "KMPlayerController")
    //void SendToServer(const FString& Data);

    //UFUNCTION(BlueprintCallable, Client, Reliable, Category = "KMPlayerController")
    //void SendToOwningClient(const FString& Data);

	//UFUNCTION(BlueprintPure, Category = "KMPlayerController")
	//int32 GetServerId();

	//UFUNCTION()
	//int32 GetNetworkGuid();

	//FString GetServerNetworkAddress(bool AppendPort);

	/**
	* Called when the local player is about to travel to a new map or IP address.  Provides subclass with an opportunity
	* to perform cleanup or other tasks prior to the travel.
	*/
	UFUNCTION(BlueprintImplementableEvent, Category = "ROG2PlayerController", meta = (DisplayName = "Pre Client Travel Event"))
	void PreClientTravelEvent(const FString& PendingURL, ETravelType TravelType, bool bIsSeamlessTravel);
	virtual void PreClientTravel(const FString& PendingURL, ETravelType TravelType, bool bIsSeamlessTravel) override;

	virtual void InitPlayerState() override;
	virtual void OnPossess(APawn* InPawn) override;
    virtual void OnUnPossess() override;

    virtual void GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const override;
    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

    //void SetPawnScriptType(const FString& ScriptType);
    //const FString& GetPawnScriptType();

    FOnPossessCharacter OnPossessCharacter;

	//UPROPERTY(BlueprintReadWrite, Category = "KMPlayerController")
	//int32 PlayerControllerID;

	//UPROPERTY(BlueprintReadWrite, Category = "KMPlayerController")
	//int32 RoleID;

	//bool InitialFromDataset(class FKMNodeDataset* DS);

    //FString PriorStartSpot;

	FString PlayerName;

public:
    UFUNCTION(server, reliable, WithValidation)
    void ServerExecGMCommand(const FString& Param);


    //////////////////////////////////////////////////////////////////////////
    TArray<uint8>& GetInitProtoData() { return InitProtoData; }

    UFUNCTION(BlueprintPure, Category = "KMPlayerController")
    const int GetLogicInstanceId() const { return LogicInstanceId; }

    void SetLogicInstanceId(int Id) { LogicInstanceId = Id; }

private:
    UPROPERTY(Replicated)
    TArray<uint8> InitProtoData;

    UPROPERTY(Replicated)
    int LogicInstanceId;
};
