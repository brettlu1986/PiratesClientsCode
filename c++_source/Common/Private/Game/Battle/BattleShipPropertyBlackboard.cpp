
#include "Game/Battle/BattleShipPropertyBlackboard.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/DataTableDelegate.h"

static inline
UBattleShipPropertyBlackboard* GetCurrentBlackboard(UObject* WorldContextObject)
{
    return UGameCommon::Get(WorldContextObject)->GetGameDelegateManager()->BattleShipPropertyBlackboard;
}

int UBattleShipPropertyBlackboard::GetIntProperty(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, const FName& PropertyName)
{
    int Ret = 0;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetIntProperty.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetIntProperty.Execute(PropertyType, Actor->GetUniqueID(), PropertyName);
    }
    return Ret;
}

float UBattleShipPropertyBlackboard::GetFloatProperty(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, const FName& PropertyName)
{
    float Ret = 0;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetFloatProperty.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetFloatProperty.Execute(PropertyType, Actor->GetUniqueID(), PropertyName);
    }
    return Ret;
}

bool UBattleShipPropertyBlackboard::GetBoolProperty(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, const FName& PropertyName)
{
    bool Ret = false;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetBoolProperty.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetBoolProperty.Execute(PropertyType, Actor->GetUniqueID(), PropertyName);
    }
    return Ret;
}

FString UBattleShipPropertyBlackboard::GetStringProperty(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, const FName& PropertyName)
{
    FString Ret;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetStringProperty.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetStringProperty.Execute(PropertyType, Actor->GetUniqueID(), PropertyName);
    }
    return MoveTemp(Ret);
}

int UBattleShipPropertyBlackboard::GetIntPropertyWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const FName& PropertyName)
{
    int Ret = 0;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetIntPropertyWithTwoKeys.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetIntPropertyWithTwoKeys.Execute(PropertyType, Actor->GetUniqueID(), Key, PropertyName);
    }
    return Ret;
}

float UBattleShipPropertyBlackboard::GetFloatPropertyWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const FName& PropertyName)
{
	float Ret = 0;
	auto Blackboard = GetCurrentBlackboard(WorldContextObject);
	if (Blackboard->OnGetFloatPropertyWithTwoKeys.IsBound() && IsValid(Actor))
	{
		Ret = Blackboard->OnGetFloatPropertyWithTwoKeys.Execute(PropertyType, Actor->GetUniqueID(), Key, PropertyName);
	}
	return Ret;
}

void UBattleShipPropertyBlackboard::GetFloatPropertysWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const TArray<FString>& PropertyNames, TArray<float>& OutValues)
{
	OutValues.Empty();
	auto Blackboard = GetCurrentBlackboard(WorldContextObject);
	if (Blackboard->OnGetFloatPropertysWithTwoKeys.IsBound() && IsValid(Actor))
	{
		Blackboard->OnGetFloatPropertysWithTwoKeys.Execute(PropertyType, Actor->GetUniqueID(), Key, PropertyNames, OutValues);
	}
}

bool UBattleShipPropertyBlackboard::GetBoolPropertyWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const FName& PropertyName)
{
    bool Ret = false;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetBoolPropertyWithTwoKeys.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetBoolPropertyWithTwoKeys.Execute(PropertyType, Actor->GetUniqueID(), Key, PropertyName);
    }
    return Ret;
}

FString UBattleShipPropertyBlackboard::GetStringPropertyWithTwoKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key, const FName& PropertyName)
{
    FString Ret;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetStringPropertyWithTwoKeys.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetStringPropertyWithTwoKeys.Execute(PropertyType, Actor->GetUniqueID(), Key, PropertyName);
    }
    return MoveTemp(Ret);
}

int UBattleShipPropertyBlackboard::GetIntPropertyWithThreeKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key1, int Key2, const FName& PropertyName)
{
    int Ret = 0;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetIntPropertyWithThreeKeys.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetIntPropertyWithThreeKeys.Execute(PropertyType, Actor->GetUniqueID(), Key1, Key2, PropertyName);
    }
    return Ret;
}

float UBattleShipPropertyBlackboard::GetFloatPropertyWithThreeKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key1, int Key2, const FName& PropertyName)
{
    float Ret = 0;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetFloatPropertyWithThreeKeys.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetFloatPropertyWithThreeKeys.Execute(PropertyType, Actor->GetUniqueID(), Key1, Key2, PropertyName);
    }
    return Ret;
}

bool UBattleShipPropertyBlackboard::GetBoolPropertyWithThreeKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key1, int Key2, const FName& PropertyName)
{
    bool Ret = false;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetBoolPropertyWithThreeKeys.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetBoolPropertyWithThreeKeys.Execute(PropertyType, Actor->GetUniqueID(), Key1, Key2, PropertyName);
    }
    return Ret;
}

FString UBattleShipPropertyBlackboard::GetStringPropertyWithThreeKeys(UObject* WorldContextObject, const FName& PropertyType, AActor* Actor, int Key1, int Key2, const FName& PropertyName)
{
    FString Ret;
    auto Blackboard = GetCurrentBlackboard(WorldContextObject);
    if (Blackboard->OnGetStringPropertyWithThreeKeys.IsBound() && IsValid(Actor))
    {
        Ret = Blackboard->OnGetStringPropertyWithThreeKeys.Execute(PropertyType, Actor->GetUniqueID(), Key1, Key2, PropertyName);
    }
    return MoveTemp(Ret);
}