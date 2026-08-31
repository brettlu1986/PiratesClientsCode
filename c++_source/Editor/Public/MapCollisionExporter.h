// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/Actor.h"
#include "Components/SplineComponent.h"
#include "MapCollisionExporter.generated.h"

UCLASS(BlueprintType, Blueprintable)
class EDITOR_API UMapCollisionExporter : public UObject
{
    GENERATED_UCLASS_BODY()

public:

    UFUNCTION(BlueprintCallable, Category = "Export Map Collision", meta = (CallInEditor = "true"))
    static bool ExportMapCollision(const FString& LevelName, const FString& ConfigFilePath, const FString& SaveDir);


};
