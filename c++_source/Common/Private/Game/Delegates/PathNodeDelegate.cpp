// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Delegates/PathNodeDelegate.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Game/PathNode/PathNodeFinder.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/PathNode/PathNodeFinder.h"

DEFINE_LOG_CATEGORY_STATIC(GamePathNodeLog, Log, All);

static UPathNodeDelegate* GetDelegate(UObject* WorldContextObject)
{
    return UGameCommon::Get(WorldContextObject)->GetGameDelegateManager()->PathNode;
}

FVector UPathNodeDelegate::GetPathNodeLocation(UObject* WorldContextObject, int PathId, int CurrentPathNodeIndex)
{
    FVector Ret;
    //auto& Delegate = GetDelegate(WorldContextObject)->OnGetPathNodeLocation;
    //if (Delegate.IsBound())
    //{
    //    Ret = Delegate.Execute(PathId, CurrentPathNodeIndex);
    //}

    UGameCommon* Common = UGameCommon::Get(WorldContextObject);
    if (Common)
    {
        if (!Common->GetPathNodeFinder()->FindPathNodeLocation(PathId, CurrentPathNodeIndex, Ret) && PathId > 0)
        {
            UE_LOG(GamePathNodeLog, Warning, TEXT("GetPathNodeLocation failed, PathId: %d, NodeIndex: %d"),
                PathId, CurrentPathNodeIndex);
        }
    }
    return Ret;
}

void UPathNodeDelegate::GetNextPathNodeInfo(UObject* WorldContextObject, int PathId, int CurrentPathNodeIndex, int& OutNextPathNodeIndex, 
    FVector& OutNextPathNodeLocation, bool& OutIsEndPoint)
{
    //OutNextPathNodeIndex = -1;
    //OutNextPathNodeLocation = FVector::ZeroVector;
    //auto& Delegate = GetDelegate(WorldContextObject)->OnGetNextPathNodeInfo;
    //if (Delegate.IsBound())
    //{
    //    Delegate.Execute(PathId, CurrentPathNodeIndex, OutNextPathNodeIndex, OutNextPathNodeLocation, OutIsEndPoint);
    //}

    UGameCommon* Common = UGameCommon::Get(WorldContextObject);
    if (Common)
    {
        if (!Common->GetPathNodeFinder()->FindNextPathInfo(PathId, CurrentPathNodeIndex,
            OutNextPathNodeIndex, OutNextPathNodeLocation, OutIsEndPoint))
        {
            UE_LOG(GamePathNodeLog, Log, TEXT("GetNextPathNodeInfo failed, PathId: %d, NodeIndex: %d"),
                PathId, CurrentPathNodeIndex);
        }
    }
}