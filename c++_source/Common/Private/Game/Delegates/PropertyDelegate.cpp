// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Delegates/PropertyDelegate.h"
#include "Common.h"

float UPropertyDelegate::GetFloatPropertyFromLua(AActor * Actor, const FString & Key)
{
	float Ret = 0;
	if (OnGetFloatPropertyFromLua.IsBound() && IsValid(Actor))
	{
		Ret = OnGetFloatPropertyFromLua.Execute(Actor->GetUniqueID(), Key);
	}
	return Ret;
}

bool UPropertyDelegate::GetBoolPropertyFromLua(AActor * Actor, const FString & Key)
{
	bool Ret = false;
	if (OnGetBoolPropertyFromLua.IsBound() && IsValid(Actor))
	{
		Ret = OnGetBoolPropertyFromLua.Execute(Actor->GetUniqueID(), Key);
	}
	return Ret;
}

int32 UPropertyDelegate::GetIntPropertyFromLua(AActor * Actor, const FString & Key)
{
	int32 Ret = 0;
	if (OnGetIntPropertyFromLua.IsBound() && IsValid(Actor))
	{
		Ret = OnGetIntPropertyFromLua.Execute(Actor->GetUniqueID(), Key);
	}
	return Ret;
}
