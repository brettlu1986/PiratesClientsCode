// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "GameplayExtensions.generated.h"

/**
 * 
 */


UCLASS()
class COMMON_API UGameplayExtensions : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
	
	DECLARE_LOG_CATEGORY_CLASS(GameplayExtensionsLog, Log, All);

public:

    /**
    * xuweihua: CPP implementation of BP_LauncherGroup update.
    */
    UFUNCTION(BlueprintCallable, Category = "Gameplay", meta = (WorldContext = "WorldContextObject"))
    static void LauncherGroupUpdate(UObject* WorldContextObject,
        float DeltaSeconds,
        FTransform VirtualTransform,
        FVector TargetLocation,
        float MinYaw,
        float MaxYaw,
        float FollowingAngleSpeed,
        float LocalYaw,
        float MaxTargetingAngleDiff,
        float& OutLocalYaw,
        float& LeftYawDiff,
        bool& TargetingSucceeded);


    /**
    * xuweihua: CPP implementation to find actors in a sector.
    */
    UFUNCTION(BlueprintCallable, Category = "Gameplay", meta = (WorldContext = "WorldContextObject"))
    static void FindActorsInSector(const TArray<AActor*> &actors, const FVector &sectorCenter, const FVector &sectorForward,
        const float &sectorAngle, const float &radius, TArray<AActor*> &outActors);
};
