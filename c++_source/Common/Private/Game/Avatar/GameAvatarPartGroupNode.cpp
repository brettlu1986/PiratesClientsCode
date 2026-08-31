// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Avatar/GameAvatarPartGroupNode.h"
#include "Common.h"

UGameAvatarPartGroupNode::UGameAvatarPartGroupNode(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , ActivedNode(nullptr)
    , NeedRefreshAll(false)
{

}

void UGameAvatarPartGroupNode::Refresh_Implementation(bool bIncludeChildren, bool bRecursion, bool bForceRefreshSelf)
{
    bForceRefreshSelf |= NeedRefreshAll;
    NeedRefreshAll = false;
    if (ActivedNode)
    {
        ActivedNode->Refresh(bIncludeChildren, bRecursion, bForceRefreshSelf);
    }
    else
    {
        UGameAvatarPartProcessNodeBase::Refresh(bIncludeChildren, bRecursion, bForceRefreshSelf);
    }
}

bool UGameAvatarPartGroupNode::SetRawData_Implementation(const FString& In)
{
    ActivedNode = nullptr;
    NeedRefreshAll = true;
    if (In.Len() > 0)
    {
        FName TempKeyName(*In);
        int iCount = Children.Num();
        for (int ii=0; ii<iCount; ii++)
        {
            if (Children[ii]->GetDataKeyName() == TempKeyName)
            {
                ActivedNode = Children[ii];
                break;
            }
        }
    }
    return true;
}