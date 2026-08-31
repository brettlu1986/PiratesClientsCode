// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/PathNode/PathNodeFinder.h"
#include "Common.h"
#include "Game/GameCommon.h"

bool UPathNodeFinder::AddPath(int PathId, bool bCycle)
{
    if (Paths.Find(PathId))
    {
        return false;
    }

    FPath& Path = Paths.Add(PathId);
    Path.PathId = PathId;
    Path.Cycle = bCycle;
    return true;
}

bool UPathNodeFinder::RemovePath(int PathId)
{
    return Paths.Remove(PathId) > 0;
}

void UPathNodeFinder::Clear()
{
    Paths.Empty();
}

int UPathNodeFinder::AddNode(int PathId, float X, float Y, float Z)
{
    FPath* Path = Paths.Find(PathId);
    if (!Path)
    {
        return -1;
    }

    Path->Nodes.AddUninitialized();
    FVector& Location = Path->Nodes.Last();
    Location.X = X;
    Location.Y = Y;
    Location.Z = Z;
    return Path->Nodes.Num() - 1;
}

bool UPathNodeFinder::RemoveNode(int PathId, int Index)
{
    FPath* Path = Paths.Find(PathId);
    if (!Path)
    {
        return false;
    }

    if (Index < 0 || Index >= Path->Nodes.Num())
    {
        return false;
    }

    Path->Nodes.RemoveAt(Index);
    return true;
}

const bool UPathNodeFinder::FindPathNodeLocation(int PathId, int CurrentIndex, FVector& OutLocation) const
{
    const FPath* Path = Paths.Find(PathId);
    if (!Path)
    {
        return false;
    }

    if (CurrentIndex < 0 || CurrentIndex >= Path->Nodes.Num())
    {
        return false;
    }

    OutLocation = Path->Nodes[CurrentIndex];
    return true;
}

const bool UPathNodeFinder::FindNextPathInfo(int PathId, int CurrentIndex,
    int& OutNextIndex, FVector& OutLocation, bool& OutIsEndPoint) const
{
    OutNextIndex = -1;
    OutLocation = FVector::ZeroVector;
    OutIsEndPoint = true;

    const FPath* Path = Paths.Find(PathId);
    if (!Path)
    {
        return false;
    }

    const TArray<FVector>& Nodes = Path->Nodes;
    int NodeCount = Nodes.Num();
    if (CurrentIndex < 0 || CurrentIndex >= NodeCount)
    {
        return false;
    }

    if (Path->Cycle)
    {
        OutIsEndPoint = false;
        OutNextIndex = CurrentIndex + 1;
        if (OutNextIndex >= NodeCount)
        {
            OutNextIndex = 0;
        }
    }
    else
    {
        if (CurrentIndex >= NodeCount - 1)
        {
            OutNextIndex = CurrentIndex;
            OutIsEndPoint = true;
        }
        else
        {
            OutNextIndex = CurrentIndex + 1;
            OutIsEndPoint = false;
        }
    }

    OutLocation = Nodes[OutNextIndex];
    return true;
}
