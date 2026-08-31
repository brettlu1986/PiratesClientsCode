// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Delegates/FightDelegate.h"
#include "Common.h"

float UFightDelegate::CalculateCannonHitDamage(AActor* CauserShip, AActor* TakerShip, TArray<int32> IntParam, TArray<float> FloatParam, int32& HitResult, bool& HitTeammate)
{
	float Ret = 0;
	HitResultTemp = 0;
	bHitTeammateTemp = false;
	if (OnCalculateCannonHitDamage.IsBound() && IsValid(CauserShip) && IsValid(TakerShip))
	{
		Ret = OnCalculateCannonHitDamage.Execute(CauserShip->GetUniqueID(), TakerShip->GetUniqueID(), IntParam, FloatParam);
	}
	HitResult = HitResultTemp;
	HitTeammate = bHitTeammateTemp;
	return Ret;
}

float UFightDelegate::CalculateTorpedoHitDamage(AActor* CauserShip, AActor* TakerShip, TArray<int32> IntParam, TArray<float> FloatParam, int32& HitResult, bool& HitTeammate)
{
	float Ret = 0;
	HitResultTemp = 0;
	bHitTeammateTemp = false;
	if (OnCalculateTorpedoHitDamage.IsBound() && IsValid(CauserShip) && IsValid(TakerShip))
	{
		Ret = OnCalculateTorpedoHitDamage.Execute(CauserShip->GetUniqueID(), TakerShip->GetUniqueID(), IntParam, FloatParam);
	}
	HitResult = HitResultTemp;
	HitTeammate = bHitTeammateTemp;
	return Ret;
}

void UFightDelegate::SpawnGameObject(int32 SpawnerId)
{
	if (OnSpawnGameObject.IsBound())
	{
		OnSpawnGameObject.Execute(SpawnerId);
	}
}

void UFightDelegate::AddStatusBuffById(AActor* Actor, int32 StatusBuffId, int32 Level)
{
	if (OnAddStatusBuffById.IsBound() && IsValid(Actor))
	{
		OnAddStatusBuffById.Execute(Actor->GetUniqueID(), StatusBuffId, Level);
	}
}

void UFightDelegate::StatusBuffAdd(AActor * Actor, int32 StatusBuffId, float LifeTime, int32 Count)
{
	if (OnStatusBuffAdd.IsBound() && IsValid(Actor))
	{
		OnStatusBuffAdd.Execute(Actor->GetUniqueID(), StatusBuffId, LifeTime, Count);
	}
}

void UFightDelegate::StatusBuffRemove(AActor* Actor, int32 StatusBuffId)
{
	if (OnStatusBuffRemove.IsBound() && IsValid(Actor))
	{
		OnStatusBuffRemove.Execute(Actor->GetUniqueID(), StatusBuffId);
	}
}

UClass* UFightDelegate::GetShotClassByResId(int32 ResId)
{
	if (OnGetShotClassPathByResId.IsBound())
	{
		FString Path = OnGetShotClassPathByResId.Execute(ResId);
		return StaticLoadClass(UObject::StaticClass(), NULL, *Path);
	}
	return nullptr;
}

void UFightDelegate::ShowHeadDialog(AActor* Actor, int32 DialogId)
{
	if (OnShowHeadDialog.IsBound() && IsValid(Actor))
	{
		OnShowHeadDialog.Execute(Actor->GetUniqueID(), DialogId);
	}
}

int32 UFightDelegate::GetBPTablePropertyAsInt(const FString& TableName, int32 Id, const FString& Key)
{
	if (OnGetBPTablePropertyAsInt.IsBound())
	{
		return OnGetBPTablePropertyAsInt.Execute(TableName, Id, Key);
	}
	return 0;
}

float UFightDelegate::GetBPTablePropertyAsFloat(const FString& TableName, int32 Id, const FString& Key)
{
	if (OnGetBPTablePropertyAsFloat.IsBound())
	{
		return OnGetBPTablePropertyAsFloat.Execute(TableName, Id, Key);
	}
	return 0.0f;
}

void UFightDelegate::AddFirePunishment(AActor* Actor)
{
    if (OnAddFirePunishment.IsBound() && IsValid(Actor))
    {
        return OnAddFirePunishment.Execute(Actor->GetUniqueID());
    }
}