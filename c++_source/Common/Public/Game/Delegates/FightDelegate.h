// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "FightDelegate.generated.h"

DECLARE_DYNAMIC_DELEGATE_RetVal_FourParams(float, FOnCalculateDamage, uint32, nCauserShipUniqueId, uint32, nTakerShipUniqueId, TArray<int32>, IntParam, TArray<float>, FloatParam);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnSpawnGameObject, int32, SpawnerId);
DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnAddStatusBuffById, uint32, UniqueId, int32, StatusBuffId, int32, Level);
DECLARE_DYNAMIC_DELEGATE_FourParams(FOnStatusBuffAdd, uint32, UniqueId, int32, StatusBuffId, float, LifeTime, int32, Count);
DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnStatusBuffRemove, uint32, UniqueId, int32, StatusBuffId);
DECLARE_DYNAMIC_DELEGATE_RetVal_OneParam(FString, FOnGetShotClassPathByResId, int32, ResId);
DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnShowHeadDialog, uint32, UniqueId, int32, DialogId);
DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(int32, FOnGetBPTablePropertyAsInt, const FString&, TableName, int32, Id, const FString&, Key);
DECLARE_DYNAMIC_DELEGATE_RetVal_ThreeParams(float, FOnGetBPTablePropertyAsFloat, const FString&, TableName, int32, Id, const FString&, Key);
DECLARE_DYNAMIC_DELEGATE_OneParam(FOnAddFirePunishment, uint32, UniqueId);

UCLASS()
class COMMON_API UFightDelegate : public UObject
{
    GENERATED_BODY()

public:

    UFUNCTION(BlueprintCallable, Category = FightDelegate)
	float CalculateCannonHitDamage(AActor* CauserShip, AActor* TakerShip, TArray<int32> IntParam, TArray<float> FloatParam, int32& HitResult, bool& HitTeammate);

	UFUNCTION(BlueprintCallable, Category = FightDelegate)
	float CalculateTorpedoHitDamage(AActor* CauserShip, AActor* TakerShip, TArray<int32> IntParam, TArray<float> FloatParam, int32& HitResult, bool& HitTeammate);

	UFUNCTION(BlueprintCallable)
	void SpawnGameObject(int32 SpawnerId);

	UFUNCTION(BlueprintCallable, Category = FightDelegate)
	void AddStatusBuffById(AActor* Actor, int32 StatusBuffId, int32 Level);

	UFUNCTION(BlueprintCallable)
	void StatusBuffAdd(AActor* Actor, int32 StatusBuffId, float LifeTime, int32 Count);

	UFUNCTION(BlueprintCallable)
	void StatusBuffRemove(AActor* Actor, int32 StatusBuffId);

	UFUNCTION(BlueprintPure)
	UClass* GetShotClassByResId(int32 ResId);

	UFUNCTION(BlueprintCallable)
	void ShowHeadDialog(AActor* Actor, int32 DialogId);

	UFUNCTION(BlueprintPure)
	int32 GetBPTablePropertyAsInt(const FString& TableName, int32 Id, const FString& Key);

	UFUNCTION(BlueprintPure)
	float GetBPTablePropertyAsFloat(const FString& TableName, int32 Id, const FString& Key);

    UFUNCTION(BlueprintCallable)
    void AddFirePunishment(AActor* Actor);

	UPROPERTY()
	FOnCalculateDamage OnCalculateCannonHitDamage;

	UPROPERTY()
	FOnCalculateDamage OnCalculateTorpedoHitDamage;

	UPROPERTY()
	FOnAddStatusBuffById OnAddStatusBuffById;

	UPROPERTY()
	FOnSpawnGameObject OnSpawnGameObject;

	UPROPERTY()
	FOnStatusBuffAdd OnStatusBuffAdd;

	UPROPERTY()
	FOnStatusBuffRemove OnStatusBuffRemove;

	UPROPERTY()
	FOnGetShotClassPathByResId OnGetShotClassPathByResId;

	UPROPERTY()
	FOnShowHeadDialog OnShowHeadDialog;

	UPROPERTY()
    FOnGetBPTablePropertyAsFloat OnGetBPTablePropertyAsFloat;

    UPROPERTY()
    FOnGetBPTablePropertyAsInt OnGetBPTablePropertyAsInt;

    UPROPERTY()
    FOnAddFirePunishment OnAddFirePunishment;
private:
	UPROPERTY()
	int32 HitResultTemp;
	
	UPROPERTY()
	bool bHitTeammateTemp;
};
