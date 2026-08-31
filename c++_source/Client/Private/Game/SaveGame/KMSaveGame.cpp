// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/SaveGame/KMSaveGame.h"
#include "Client.h"

DEFINE_LOG_CATEGORY_STATIC(KMSaveGameLog, Log, All)

void UKMSaveGame::OnPostLoadData()
{
    int32 GameDataCount = GameDataArray.Num();
    GameDataIdxMap.Empty(GameDataCount);
    for (int i = 0; i < GameDataCount; ++i)
    {
        auto& GameData = GameDataArray[i];
        auto IdxPtr = GameDataIdxMap.Find(GameData.Key);
        if (IdxPtr != nullptr)
        {
            UE_LOG(KMSaveGameLog, Error, TEXT("[OnPostLoadData] Duplicated GameData for key:%s"), *GameData.Key);
        }
        GameDataIdxMap.Add(GameData.Key, i);
    }
}

void UKMSaveGame::AddData(const FString& Key, const TArray<uint8>& DataArray)
{
    FSaveGameData NewData;
    NewData.Key = Key;
    NewData.DataArray = DataArray;
    auto IdxPtr = GameDataIdxMap.Find(Key);
    if (IdxPtr == nullptr)
    {
        GameDataIdxMap.Add(Key, GameDataArray.Num());
        GameDataArray.Add(NewData);
    }
    else
    {
        GameDataArray[*IdxPtr] = NewData;
    }
}

const TArray<uint8>& UKMSaveGame::GetData(const FString& Key)
{
    auto IdxPtr = GameDataIdxMap.Find(Key);
    if (IdxPtr == nullptr)
    {
        static TArray<uint8> EMPTY_DATA;
        return EMPTY_DATA;
    }
    else
    {
        return GameDataArray[*IdxPtr].DataArray;
    }
}