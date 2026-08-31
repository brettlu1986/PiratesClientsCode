// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/SaveGame.h"
#include "KMSaveGame.generated.h"

USTRUCT()
struct FSaveGameData
{
    GENERATED_BODY()

    UPROPERTY()
    FString Key;

    UPROPERTY()
    TArray<uint8> DataArray;
};

UCLASS(BlueprintType)
class CLIENT_API UKMSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    void OnPostLoadData();

    void AddData(const FString& Key, const TArray<uint8>& DataArray);
    const TArray<uint8>& GetData(const FString& Key);

private:
    UPROPERTY()
    TArray<FSaveGameData> GameDataArray;
    TMap<FString, int32> GameDataIdxMap;
};
