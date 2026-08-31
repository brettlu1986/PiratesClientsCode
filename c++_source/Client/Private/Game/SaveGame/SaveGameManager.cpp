// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/SaveGame/SaveGameManager.h"
#include "Client.h"
#include "Game/SaveGame/KMSaveGame.h"
#include "Kismet/GameplayStatics.h"

static const TCHAR SLOT_NAME_FORMAT[] = TEXT("GAME_SLOT_%d");
static const int32 DEFAULT_USER_ID = 0;
static const int32 DEFAULT_USER_INDEX = 0;

DEFINE_LOG_CATEGORY_STATIC(SaveGameManagerLog, Log, All)

inline
static void s_AddSaveGameData(UKMSaveGame* SaveGame, const FString& Key, const TArray<uint8>& DataArray)
{
    if (SaveGame)
    {
        SaveGame->AddData(Key, DataArray);
    }
    else
    {
        UE_LOG(SaveGameManagerLog, Error, TEXT("FAILED to add SaveGame data, SaveGame is null."));
    }
}

inline
static const TArray<uint8>& s_GetSaveGameData(UKMSaveGame* SaveGame, const FString& Key)
{
    if (SaveGame)
    {
        return SaveGame->GetData(Key);
    }
    else
    {
        UE_LOG(SaveGameManagerLog, Error, TEXT("FAILED to get SaveGame data, SaveGame is null."));
        static TArray<uint8> EMPTY_DATA_ARRAY;
        return EMPTY_DATA_ARRAY;
    }
}

USaveGameManager::USaveGameManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , IsUseDefaultUserId(false)
    , CurrentUserId(DEFAULT_USER_ID)
{
}

void USaveGameManager::Init()
{
	ResetToDefaultSlot();
}

void USaveGameManager::SetSlotUserId(int32 UserId)
{
    CurrentUserId = UserId;
    Load();
}

void USaveGameManager::ResetToDefaultSlot()
{
    SetSlotUserId(DEFAULT_USER_ID);
}

void USaveGameManager::SetUseDefaultUserId(bool bUse)
{
    IsUseDefaultUserId = bUse;
    Load();
}

void USaveGameManager::Save()
{
	UGameplayStatics::SaveGameToSlot(DefaultSaveGame, GetSlotName(), DEFAULT_USER_INDEX);
}

FString USaveGameManager::GetSlotName()
{
	int32 CurId = IsUseDefaultUserId ? DEFAULT_USER_ID : CurrentUserId;
	return FString::Printf(SLOT_NAME_FORMAT, CurId);
}

void USaveGameManager::Load()
{
	const FString& SlotName = GetSlotName();
	if (UGameplayStatics::DoesSaveGameExist(SlotName, DEFAULT_USER_INDEX))
	{
		DefaultSaveGame = Cast<UKMSaveGame>(UGameplayStatics::LoadGameFromSlot(SlotName, DEFAULT_USER_INDEX));
	}
	if (!DefaultSaveGame)
    {
        DefaultSaveGame = NewObject<UKMSaveGame>(this);
	}
	DefaultSaveGame->OnPostLoadData();
}

void USaveGameManager::AddIntData(const FString& Key, int Data)
{
    TArray<uint8> DataArray;
    DataArray.Append((uint8 *)&Data, sizeof(int));
    s_AddSaveGameData(DefaultSaveGame, Key, DataArray);
}

int USaveGameManager::GetIntData(const FString& Key)
{
    return GetIntDataWithDefault(Key, 0);
}

int USaveGameManager::GetIntDataWithDefault(const FString& Key, int DefaultData)
{
    int Ret = DefaultData;
    auto& DataArray = s_GetSaveGameData(DefaultSaveGame, Key);
    auto Size = sizeof(Ret);
    if (DataArray.Num() == Size)
    {
        FMemory::Memcpy(&Ret, DataArray.GetData(), Size);
    }
    return Ret;
}

void USaveGameManager::AddFloatData(const FString& Key, float Data)
{
    TArray<uint8> DataArray;
    DataArray.Append((uint8 *)&Data, sizeof(float));
    s_AddSaveGameData(DefaultSaveGame, Key, DataArray);
}

float USaveGameManager::GetFloatData(const FString& Key)
{
    return GetFloatDataWithDefault(Key, 0.f);
}

float USaveGameManager::GetFloatDataWithDefault(const FString& Key, float DefaultData)
{
    float Ret = DefaultData;
    auto& DataArray = s_GetSaveGameData(DefaultSaveGame, Key);
    auto Size = sizeof(Ret);
    if (DataArray.Num() == Size)
    {
        FMemory::Memcpy(&Ret, DataArray.GetData(), Size);
    }
    return Ret;
}

void USaveGameManager::AddBoolData(const FString& Key, bool Data)
{
    TArray<uint8> DataArray;
    DataArray.Append((uint8 *)&Data, sizeof(bool));
    s_AddSaveGameData(DefaultSaveGame, Key, DataArray);
}

bool USaveGameManager::GetBoolData(const FString& Key)
{
    return GetBoolDataWithDefault(Key, false);
}

bool USaveGameManager::GetBoolDataWithDefault(const FString& Key, bool DefaultData)
{
    bool Ret = DefaultData;
    auto& DataArray = s_GetSaveGameData(DefaultSaveGame, Key);
    auto Size = sizeof(Ret);
    if (DataArray.Num() == Size)
    {
        FMemory::Memcpy(&Ret, DataArray.GetData(), Size);
    }
    return Ret;
}

void USaveGameManager::AddStringData(const FString& Key, const FString& Data)
{
    auto DataAddr = Data.GetCharArray().GetData();
    uint32 BufferSize = Data.Len() * sizeof(TCHAR);
    TArray<uint8> DataArray;
    if (DataAddr != nullptr)
    {
        DataArray.Append((uint8*)DataAddr, BufferSize);
    }
    s_AddSaveGameData(DefaultSaveGame, Key, DataArray);
}

FString USaveGameManager::GetStringData(const FString& Key)
{
    return GetStringDataWithDefault(Key, FString());
}

FString USaveGameManager::GetStringDataWithDefault(const FString& Key, const FString& DefaultData)
{
    FString Ret = DefaultData;
    auto& DataArray = s_GetSaveGameData(DefaultSaveGame, Key);
    int32 StringLen = DataArray.Num() / sizeof(TCHAR);
    if (StringLen > 0)
    {
        Ret.AppendChars((TCHAR*)DataArray.GetData(), StringLen);
    }
    return MoveTemp(Ret);
}
