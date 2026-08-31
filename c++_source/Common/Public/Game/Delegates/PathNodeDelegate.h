// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "PathNodeDelegate.generated.h"

DECLARE_DYNAMIC_DELEGATE_RetVal_TwoParams(FVector, FOnGetPathNodeLocation, int, PathId, int, CurrentPathNodeIndex);
DECLARE_DYNAMIC_DELEGATE_FiveParams(FOnGetNextPathNodeInfo, int, PathId, int, CurrentPathNodeIndex, int&, OutNextPathNodeIndex, FVector&, OutNextPathNodeLocation, bool&, OutIsEndPoint);

UCLASS()
class COMMON_API UPathNodeDelegate : public UObject
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintPure, Category = "PathNode", meta = (WorldContext = "WorldContextObject"))
    static FVector GetPathNodeLocation(UObject* WorldContextObject, int PathId, int CurrentPathNodeIndex);

    UFUNCTION(BlueprintPure, Category = "PathNode", meta = (WorldContext = "WorldContextObject"))
    static void GetNextPathNodeInfo(UObject* WorldContextObject, int PathId, int CurrentPathNodeIndex, int& OutNextPathNodeIndex, 
        FVector& OutNextPathNodeLocation, bool& OutIsEndPoint);

public:
    UPROPERTY()
    FOnGetPathNodeLocation OnGetPathNodeLocation;

    UPROPERTY()
    FOnGetNextPathNodeInfo OnGetNextPathNodeInfo;
};
