// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Engine/LevelScriptActor.h"
//#include "ScriptActorDef.h"
#include "KMLevelScriptActor.generated.h"

/**
 * 
 */
UCLASS()
class ENGINEEXT_API AKMLevelScriptActor : public ALevelScriptActor
{
	GENERATED_UCLASS_BODY()

public:
    //TFunction<void()> OnBeginPlayDelegate;
    //TFunction<void(const EEndPlayReason::Type)> OnEndPlayDelegate;

	//UFUNCTION(BlueprintImplementableEvent)
	//void OnMatchStarted();

	UFUNCTION(BlueprintPure, Category="KMLevelScriptActor")
	FString GetLevelName();

    const FString& GetScriptType() const { return ScriptName; }

public:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = LevelActor)
    FString ScriptName;
};
