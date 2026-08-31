// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "KMObject.h"
#include "PathNodeFinder.generated.h"


UCLASS()
class COMMON_API UPathNodeFinder : public UKMObject
{
	GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "PathNodeSystem")
    bool AddPath(int PathId, bool bCycle);

    UFUNCTION(BlueprintCallable, Category = "PathNodeSystem")
    bool RemovePath(int PathId);

    UFUNCTION(BlueprintCallable, Category = "PathNodeSystem")
    void Clear();

    UFUNCTION(BlueprintCallable, Category = "PathNodeSystem")
    int AddNode(int PathId, float X, float Y, float Z);

    UFUNCTION(BlueprintCallable, Category = "PathNodeSystem")
    bool RemoveNode(int PathId, int Index);

    UFUNCTION(BlueprintCallable, Category = "PathNodeSystem")
    const bool FindPathNodeLocation(int PathId, int CurrentIndex, FVector& OutLocation) const;

    UFUNCTION(BlueprintCallable, Category = "PathNodeSystem")
    const bool FindNextPathInfo(int PathId, int CurrentIndex, int& OutNextIndex, FVector& OutLocation, bool& OutIsEndPoint) const;

private:
    struct FPath
    {
        TArray<FVector> Nodes;
        int PathId;
        bool Cycle;

        FPath() : PathId(-1), Cycle(false)
        {}
    };

    TMap<int, FPath> Paths;
};
