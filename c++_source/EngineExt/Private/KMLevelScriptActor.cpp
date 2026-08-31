// Fill out your copyright notice in the Description page of Project Settings.

#include "KMLevelScriptActor.h"
#include "EngineExt.h"
#include "KMGameInstance.h"

DEFINE_LOG_CATEGORY_STATIC(KMLevelScriptActorLog, Log, All)


AKMLevelScriptActor::AKMLevelScriptActor(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

FString AKMLevelScriptActor::GetLevelName()
{
	auto Level = Cast<ULevel>(GetOuter());
	auto World = Cast<UWorld>(Level->GetOuter());
	auto Name = World->GetName();
	return Name;
}
