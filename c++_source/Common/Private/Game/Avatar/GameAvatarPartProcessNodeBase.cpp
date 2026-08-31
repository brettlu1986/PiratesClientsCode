// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Avatar/GameAvatarPartProcessNodeBase.h"
#include "Common.h"

UGameAvatarPartProcessNodeBase::UGameAvatarPartProcessNodeBase(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , NeedSave(false)
    , Actor(nullptr)
    , Parent(nullptr)
    , PassDirtyToParent(false)
    , PassDrityToChildren(false)
    , Dirty(false)
    , Processing(false)
    , Priority(0)
    , IsMerge(true)
{

}

void UGameAvatarPartProcessNodeBase::AddChild(UGameAvatarPartProcessNodeBase* Child)
{
    Children.AddUnique(Child);
}

void UGameAvatarPartProcessNodeBase::RemoveChild(UGameAvatarPartProcessNodeBase* Child)
{
    Children.Remove(Child);
}

UWorld* UGameAvatarPartProcessNodeBase::GetCurrentWorld()
{
    return Actor ? Actor->GetWorld() : nullptr;
}

UGameAvatarPartProcessNodeBase* UGameAvatarPartProcessNodeBase::FindChild(const FName& TempDataKeyName)
{
    UGameAvatarPartProcessNodeBase* Ret = nullptr;
    int iCount = Children.Num();
    for (int ii=0; ii<iCount; ii++)
    {
        if (Children[ii]->GetDataKeyName() == TempDataKeyName)
        {
            Ret = Children[ii];
            break;
        }
        else
        {
            Ret = Children[ii]->FindChild(TempDataKeyName);
            if (Ret)
            {
                break;
            }
        }
    }
    return Ret;
}

void UGameAvatarPartProcessNodeBase::Init(
    AActor* TempActor, const FName& TempDataKeyName,
    UGameAvatarPartProcessNodeBase* TempParent,
    bool TempPassDirtyToParent, bool TempPassDirtyToChildren,
    bool NeedSaveToTabFile)
{
    Actor = TempActor;
    DataKeyName = TempDataKeyName;
    Parent = TempParent;
    PassDirtyToParent = TempPassDirtyToParent;
    PassDrityToChildren = TempPassDirtyToChildren;
    NeedSave = NeedSaveToTabFile;
	PartID = 0;
    if (Parent)
    {
        Parent->AddChild(this);
    }

    OnInit();
}

void UGameAvatarPartProcessNodeBase::Uninit()
{
    OnUninit();
}

bool UGameAvatarPartProcessNodeBase::ApplyRawData_Implementation(const FString& In)
{
    bool bRet = SetRawData(In);
    MarkDirty();
    return bRet;
}

bool UGameAvatarPartProcessNodeBase::SetRawData_Implementation(const FString& In)
{   
    return false;
}

bool UGameAvatarPartProcessNodeBase::GetRawData_Implementation(FString& Out)
{
    return false;
}

void UGameAvatarPartProcessNodeBase::Refresh_Implementation(bool bIncludeChildren, bool bRecursion, bool bForceRefreshSelf)
{
    if (Processing)
    {
        return;
    }
    double T1 = FPlatformTime::Seconds();
    Processing = true;
    if (bIncludeChildren)
    {
        int iCount = Children.Num();
        if (iCount > 0)
        {
            for (int ii = 0; ii<iCount; ii++)
            {
                Children[ii]->Refresh(bRecursion, bRecursion, bForceRefreshSelf);

            }
        }
    }

    if (IsDirty() || bForceRefreshSelf)
    {
        RefreshSelf();
        ClearDirty();
    }
    Processing = false;
    double T2 = FPlatformTime::Seconds();
    float TempDelta = (float)(T2 - T1);
    DebugCostTime(TempDelta * 1000.f);
}

void UGameAvatarPartProcessNodeBase::CollectResources_Implementation(TArray<FString>& OutResources)
{

}

void UGameAvatarPartProcessNodeBase::DebugCostTime_Implementation(float TotalTime)
{

}

void UGameAvatarPartProcessNodeBase::MarkDirty()
{
    if (Processing)
    {
        return;
    }

    Processing = true;
    Dirty = true;
    if (PassDirtyToParent && Parent)
    {
        Parent->MarkDirty();
    }

    if (PassDrityToChildren && Children.Num())
    {
        int iCount = Children.Num();
        for (int ii=0; ii<iCount; ii++)
        {
            Children[ii]->MarkDirty();
        }
    }
    Processing = false;
}

void UGameAvatarPartProcessNodeBase::GetChildren(TArray<UGameAvatarPartProcessNodeBase*>& Out, bool bRecursion)
{
    int iCount = Children.Num();
    if (bRecursion)
    {
        for (int ii=0; ii<iCount; ii++)
        {
            Children[ii]->GetChildren(Out, true);
            Out.Add(Children[ii]);
        }
    }
    else
    {
        for (int ii = 0; ii < iCount; ii++)
        {
            Out.Add(Children[ii]);
        }
    }
}

UWorld* UGameAvatarPartProcessNodeBase::GetWorld() const
{
    return Actor ? Actor->GetWorld() : GWorld;
}

void UGameAvatarPartProcessNodeBase::RefreshSelf_Implementation()
{

}

void UGameAvatarPartProcessNodeBase::OnInit_Implementation()
{

}

void UGameAvatarPartProcessNodeBase::OnUninit_Implementation()
{

}

void UGameAvatarPartProcessNodeBase::SetPartID(int nInID)
{
	PartID = nInID;
}

int UGameAvatarPartProcessNodeBase::GetPartID()
{
	return PartID;
}


void UGameAvatarPartProcessNodeBase::SetPartPriority(int nPriority)
{
    Priority = nPriority;
}

int UGameAvatarPartProcessNodeBase::GetPartPriority()
{
    return Priority;
}

void UGameAvatarPartProcessNodeBase::SetPartMergeFlag(bool bMerge)
{
    IsMerge = bMerge;
}

bool UGameAvatarPartProcessNodeBase::GetPartMergeFlag()
{
    return IsMerge;
}



void UGameAvatarPartProcessNodeBase::SetForceStreaming()
{

}

void UGameAvatarPartProcessNodeBase::GetAsset_Implementation(UGameAvatarPartProcessNodeBase* From)
{

}
