// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "SaveGameManager.generated.h"

UCLASS(Blueprintable)
class CLIENT_API USaveGameManager : public UObject
{
    GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintCallable)
    void Init();

    UFUNCTION(BlueprintCallable)
    void SetSlotUserId(int32 UserId);

    UFUNCTION(BlueprintCallable)
    void ResetToDefaultSlot();

    UFUNCTION(BlueprintCallable)
    void SetUseDefaultUserId(bool bUse);

    UFUNCTION(BlueprintCallable)
    void Save();

    UFUNCTION(BlueprintCallable)
    void AddIntData(const FString& Key, int Data);

    UFUNCTION(BlueprintPure)
    int GetIntData(const FString& Key);

    UFUNCTION(BlueprintPure)
    int GetIntDataWithDefault(const FString& Key, int DefaultData);

    UFUNCTION(BlueprintCallable)
    void AddFloatData(const FString& Key, float Data);

    UFUNCTION(BlueprintPure)
    float GetFloatData(const FString& Key);

    UFUNCTION(BlueprintPure)
    float GetFloatDataWithDefault(const FString& Key, float DefaultData);

    UFUNCTION(BlueprintCallable)
    void AddBoolData(const FString& Key, bool Data);

    UFUNCTION(BlueprintPure)
    bool GetBoolData(const FString& Key);

    UFUNCTION(BlueprintPure)
    bool GetBoolDataWithDefault(const FString& Key, bool DefaultData);

    UFUNCTION(BlueprintCallable)
    void AddStringData(const FString& Key, const FString& Data);

    UFUNCTION(BlueprintPure)
    FString GetStringData(const FString& Key);

    UFUNCTION(BlueprintPure)
    FString GetStringDataWithDefault(const FString& Key, const FString& DefaultData);

    UPROPERTY()
    bool IsUseDefaultUserId;
private:
    void Load();
	FString GetSlotName();

    UPROPERTY()
    class UKMSaveGame* DefaultSaveGame;
    int32 CurrentUserId;
};
