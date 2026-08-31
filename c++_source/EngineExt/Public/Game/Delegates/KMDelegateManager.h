// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMObject.h"
#include "KMDelegateManager.generated.h"

//DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnReceivedProtoData, uint32, NetworkGuid, const FString&, Data);

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnCurrentWorldChanged, uint32, UniqueId);
DECLARE_DYNAMIC_DELEGATE_RetVal_OneParam(bool, FOnExecCommand, const FString&, Cmd);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnConsoleShow);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnActorHitAirWall, AActor*, AirWallActor, AActor*, HitActor, bool, IsBeginOverlap);
DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnLoadAssetAsync, const FString&, AssetName, UObject*, Object);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnActorTouched, const AActor*, TouchedActor);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnMultiAssetsLoaded, const TArray<UObject*>&, LoadedAssets);

UCLASS()
class ENGINEEXT_API UKMDelegateManager : public UKMObject
{
    GENERATED_UCLASS_BODY()

public:

	virtual void Init();
	
    UPROPERTY()
    class UActorDelegate* Actor;
    
    UPROPERTY()
    class ULevelDelegate* Level;

    UPROPERTY()
    class UGameModeDelegate* GameMode;

    UPROPERTY()
    class UPlayerDelegate* Player;

    //UPROPERTY()
    //FOnReceivedProtoData OnReceivedProtoData;

    UPROPERTY()
	FOnCurrentWorldChanged OnCurrentWorldChanged;

	UPROPERTY()
	FOnExecCommand OnExecCommand;

	UPROPERTY()
	FOnConsoleShow OnConsoleShow;

	UPROPERTY(BlueprintCallable, BlueprintAssignable)
	FOnActorHitAirWall OnActorHitAirWall;

    UPROPERTY()
    FOnLoadAssetAsync OnLoadAssetAsync;

    UPROPERTY()
    FOnActorTouched OnActorTouched;
};
