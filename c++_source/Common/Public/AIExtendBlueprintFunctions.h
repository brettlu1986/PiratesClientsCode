// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "AIExtendBlueprintFunctions.generated.h"

class AAIController;

UCLASS()
class COMMON_API UAIExtendBlueprintFunctions : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "AI Function")
	static float FindDirectionAngleOutOfCrowd(const FVector &CenterLocation, const TArray<FVector> &OtherActorsLocationArray);

	UFUNCTION(BlueprintCallable, Category = "AI Function")
	static float GetDirectionAngleOfTwoLocation(const FVector &CenterLocation, const FVector &TargetLocation);

	UFUNCTION(BlueprintCallable, Category = "AI Function", BlueprintAuthorityOnly, meta = (DefaultToSelf = "AIController"))
	static void LockAIResources(AAIController *AIController, bool bLockMovement, bool LockAILogic);

	UFUNCTION(BlueprintCallable, Category = "AI Function", BlueprintAuthorityOnly, meta = (DefaultToSelf = "AIController"))
	static void UnlockAIResources(AAIController *AIController, bool bUnlockMovement, bool UnlockAILogic);

    UFUNCTION(BlueprintPure, Category = "AI Function")
    static bool IsInSightWithRatio(AAIController *AIController, const FVector& TargetLocation, float Ratio);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "AI Function")
    static int32 QueryDoor(UObject* WorldContextObject, const FVector& Location, float Size);

    UFUNCTION(BlueprintCallable, Category = "AI Function")
    static void ConfigSightParams(UAIPerceptionComponent *PerceptionComponen, float SightDistance,
        float LoseSightDistance, float FOV);

    ///////////////////////////////////////////////////////////////////////////////////////////
    UFUNCTION(BlueprintPure, Category = "No Table Ret Functions")
    static void GetActorLocation_NT(AActor* Actor, float& X, float& Y, float& Z);

    UFUNCTION(BlueprintPure, Category = "No Table Ret Functions")
    static void GetActorRotation_NT(AActor* Actor, float& Pitch, float& Yaw, float& Roll);

    UFUNCTION(BlueprintPure, Category = "No Table Ret Functions")
    static void GetActorVelocity_NT(AActor* Actor, float& X, float& Y, float& Z);

    UFUNCTION(BlueprintPure, Category = "No Table Ret Functions")
    static void GetComponentLocation_NT(USceneComponent* Component, float& X, float& Y, float& Z);
};