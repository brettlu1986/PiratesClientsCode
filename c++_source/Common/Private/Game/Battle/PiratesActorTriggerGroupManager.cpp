#include "Game/Battle/PiratesActorTriggerGroupManager.h"
#include "Common.h"
#include "PiratesPlayerController.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Kismet/KismetMathLibrary.h"


UPiratesActorTriggerGroupManager::UPiratesActorTriggerGroupManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , Delegate(nullptr)
    , MaxGroupId(0)
    , bCheckRemove(false)
{
    PrimaryComponentTick.bCanEverTick = false;
}

int UPiratesActorTriggerGroupManager::GenerateGroup()
{
    return ++MaxGroupId;
}

void UPiratesActorTriggerGroupManager::Clear()
{
    ActorTriggerGroupInfos.Empty();
}

int UPiratesActorTriggerGroupManager::CreateTriggerGroup(AActor* pActor, float Radius, float UpdateInterval, bool IsCheckBounds)
{
    if (!IsValid(pActor))
        return -1;

    int GroupId = GenerateGroup();
    TSharedPtr<FActorTriggerGroupInfo> ActorTriggerInfo = MakeShareable(new FActorTriggerGroupInfo());
    ActorTriggerInfo->GroupId = GroupId;
    ActorTriggerInfo->OwnerActor = pActor;
    ActorTriggerInfo->RadiusSquared = Radius * Radius;
    ActorTriggerInfo->UpdateInterval = UpdateInterval;
    ActorTriggerInfo->bCheckBounds = IsCheckBounds;

    ActorTriggerGroupInfos.Emplace(ActorTriggerInfo);

    return GroupId;
}

int UPiratesActorTriggerGroupManager::CreateTriggerGroupWithOffsetHeight(AActor* pActor, float Radius, float UpdateInterval, float OffsetHeight, bool IsCheckBounds)
{
    if (!IsValid(pActor))
        return -1;

    int GroupId = GenerateGroup();
    TSharedPtr<FActorTriggerGroupInfo> ActorTriggerInfo = MakeShareable(new FActorTriggerGroupInfo());
    ActorTriggerInfo->GroupId = GroupId;
    ActorTriggerInfo->OwnerActor = pActor;
    ActorTriggerInfo->RadiusSquared = Radius * Radius;
    ActorTriggerInfo->OffsetHeight = OffsetHeight;
    ActorTriggerInfo->bCheckBounds = IsCheckBounds;
    ActorTriggerInfo->UpdateInterval = UpdateInterval;

    ActorTriggerGroupInfos.Emplace(ActorTriggerInfo);

    return GroupId;
}

bool UPiratesActorTriggerGroupManager::DestroyTriggerGroup(int GroupId)
{
    for (int i = 0; i < ActorTriggerGroupInfos.Num(); i++)
    {
        TSharedPtr<FActorTriggerGroupInfo>& TriggerGroupInfo = ActorTriggerGroupInfos[i];
        if (TriggerGroupInfo.IsValid() && TriggerGroupInfo->GroupId == GroupId)
        {
            bCheckRemove = true;
            TriggerGroupInfo->bRemove = true;          
            return true;
        }
    }

    return false;
}

void UPiratesActorTriggerGroupManager::DoRemove()
{
    for (int i = ActorTriggerGroupInfos.Num() - 1; i >= 0; i--)
    {
        TSharedPtr<FActorTriggerGroupInfo>& TriggerGroupInfo = ActorTriggerGroupInfos[i];
        if (!TriggerGroupInfo.IsValid() || !TriggerGroupInfo->OwnerActor.IsValid() || TriggerGroupInfo->bRemove)
        {
            ActorTriggerGroupInfos.RemoveAt(i);
            continue;
        }

        for (int j = TriggerGroupInfo->AreaInfos.Num() - 1; j >= 0; j--)
        {
            FActorTriggerInfo& ActorAreaInfo = TriggerGroupInfo->AreaInfos[j];
            if (!ActorAreaInfo.Actor.IsValid() || ActorAreaInfo.bRemove)
            {
                TriggerGroupInfo->AreaInfos.RemoveAt(j);
            }
        }
    }
}

int UPiratesActorTriggerGroupManager::FindGroupIndex(int GroupId)
{
    for (int i = 0; i < ActorTriggerGroupInfos.Num(); i++)
    {
        TSharedPtr<FActorTriggerGroupInfo>& TriggerGroupInfo = ActorTriggerGroupInfos[i];
        if (TriggerGroupInfo.IsValid() && TriggerGroupInfo->GroupId == GroupId)
        {
            return i;
        }
    }

    return -1;
}

bool UPiratesActorTriggerGroupManager::AddTriggerInGroup(int GroupId, AActor* pActor)
{
    if (!IsValid(pActor))
    {
        return false;
    }

    int Index = FindGroupIndex(GroupId);
    if (Index < 0)
    {
        return false;
    }

    TSharedPtr<FActorTriggerGroupInfo>& TriggerGroupInfo = ActorTriggerGroupInfos[Index];
    if (!TriggerGroupInfo->OwnerActor.IsValid())
    {
        return false;
    }

    TArray<FActorTriggerInfo>& ActorAreaInfos = TriggerGroupInfo->AreaInfos;
    for (int i = 0; i < ActorAreaInfos.Num(); i++)
    {
        if (ActorAreaInfos[i].Actor.Get() == pActor)
        {
            if (ActorAreaInfos[i].bRemove)
            {
                ActorAreaInfos[i].bRemove = false;
            }
            return true;
        }
    }

    ActorAreaInfos.Emplace(pActor);
    return true;
}

bool UPiratesActorTriggerGroupManager::RemoveTriggerInGroup(int GroupId, AActor* pActor)
{
    if (!IsValid(pActor))
    {
        return false;
    }

    int Index = FindGroupIndex(GroupId);
    if (Index < 0)
    {
        return false;
    }

    TSharedPtr<FActorTriggerGroupInfo>& TriggerGroupInfo = ActorTriggerGroupInfos[Index];
    if (!TriggerGroupInfo->OwnerActor.IsValid())
    {
        return false;
    }

    uint32 ActorUniqueId = TriggerGroupInfo->OwnerActor->GetUniqueID();
    uint32 TargetUniqueId = pActor->GetUniqueID();
    TArray<FActorTriggerInfo>& AreaInfos = TriggerGroupInfo->AreaInfos;
    for (int i = 0; i < AreaInfos.Num(); i++)
    {
        FActorTriggerInfo& AreaInfo = AreaInfos[i];
        if (AreaInfo.Actor.Get() == pActor)
        {
            bCheckRemove = true;
            AreaInfo.bRemove = true;
            if (AreaInfo.bIn)
            {
                AreaInfo.bIn = false;
                Delegate->OnActorLeaveTriggerGroup.ExecuteIfBound(GroupId, ActorUniqueId, TargetUniqueId);
            }
            return true;
        }
    }

    return false;
}

void UPiratesActorTriggerGroupManager::Update(float DeltaTime)
{
    for (int i = ActorTriggerGroupInfos.Num() - 1; i >= 0; i--)
    {
        TSharedPtr<FActorTriggerGroupInfo>& TriggerGroupInfo = ActorTriggerGroupInfos[i];
        if (!TriggerGroupInfo.IsValid() || !TriggerGroupInfo->OwnerActor.IsValid())
        {
            bCheckRemove = true;
            continue;
        }
        bool bExecute = false;
        TriggerGroupInfo->LastUpdateTime += DeltaTime;
        while (TriggerGroupInfo->LastUpdateTime >= TriggerGroupInfo->UpdateInterval)
        {
            bExecute = true;
            TriggerGroupInfo->LastUpdateTime -= TriggerGroupInfo->UpdateInterval;
        }
        if (bExecute)
        {
            Execute(TriggerGroupInfo);
        }
    }

    if (bCheckRemove)
    {
        DoRemove();
        bCheckRemove = false;
    }
}


bool UPiratesActorTriggerGroupManager::InBoundsBox(const AActor* Actor, const FVector& Location, float Radius)
{
    if (!Actor)
    {
        return false;
    }

    float Yaw = Actor->GetActorRotation().Yaw;
    FVector Origin, Extent;
    Actor->GetActorBounds(true, Origin, Extent);

    FVector2D Points[4];
    Points[0] = FVector2D(Origin.X - Extent.X - Radius, Origin.Y - Extent.Y - Radius);
    Points[1] = FVector2D(Origin.X - Extent.X - Radius, Origin.Y + Extent.Y + Radius);
    Points[2] = FVector2D(Origin.X + Extent.X + Radius, Origin.Y + Extent.Y + Radius);
    Points[3] = FVector2D(Origin.X + Extent.X + Radius, Origin.Y - Extent.Y - Radius);

    FVector2D Temp;
    for (int ii = 0; ii < 4; ii++)
    {
        Temp.X = Points[ii].X - Origin.X;
        Temp.Y = Points[ii].Y - Origin.Y;
        Temp = Temp.GetRotated(Yaw);
        Points[ii].X = Temp.X + Origin.X;
        Points[ii].Y = Temp.Y + Origin.Y;
    }

    float a = (Points[1].X - Points[0].X) * (Location.Y - Points[0].Y)
        - (Points[1].Y - Points[0].Y) * (Location.X - Points[0].X);
    float b = (Points[2].X - Points[1].X) * (Location.Y - Points[1].Y)
        - (Points[2].Y - Points[1].Y) * (Location.X - Points[1].X);
    float c = (Points[3].X - Points[2].X) * (Location.Y - Points[2].Y)
        - (Points[3].Y - Points[2].Y) * (Location.X - Points[2].X);
    float d = (Points[0].X - Points[3].X) * (Location.Y - Points[3].Y)
        - (Points[0].Y - Points[3].Y) * (Location.X - Points[3].X);

    return ((a > 0 && b > 0 && c > 0 && d > 0) 
        || (a < 0 && b < 0 && c < 0 && d < 0));
}

void UPiratesActorTriggerGroupManager::Execute(TSharedPtr<FActorTriggerGroupInfo>& TriggerGroupInfo)
{
    int GroupId = TriggerGroupInfo->GroupId;
    uint32 ActorUniqueId = TriggerGroupInfo->OwnerActor->GetUniqueID();
    FVector Location = TriggerGroupInfo->OwnerActor->GetActorLocation();
    bool IsCheckBounds = TriggerGroupInfo->bCheckBounds;
    float RadiusSquared = TriggerGroupInfo->RadiusSquared;
    float Radius = 0;
    if (IsCheckBounds)
    {
        Radius = FMath::Sqrt(RadiusSquared);
    }
    FVector2D BoundPoints[4];

    for (int i = TriggerGroupInfo->AreaInfos.Num() - 1; i >= 0; i--)
    {
        FActorTriggerInfo& ActorAreaInfo = TriggerGroupInfo->AreaInfos[i];
        if (!ActorAreaInfo.Actor.IsValid())
        {
            bCheckRemove = true;
            continue;
        }
        bool bIn = false;
        FVector Center = ActorAreaInfo.Actor->GetActorLocation();
        if (IsCheckBounds)
        {
            bIn = InBoundsBox(ActorAreaInfo.Actor.Get(), Location, Radius);
        }
        else
        {
            bIn = FVector::DistSquaredXY(Center, Location) <= RadiusSquared;
        }
        if (bIn && TriggerGroupInfo->OffsetHeight > 0)
        {
            bIn = FMath::Abs(Location.Z - Center.Z) <= TriggerGroupInfo->OffsetHeight;
        }
        if (bIn != ActorAreaInfo.bIn)
        {
            ActorAreaInfo.bIn = bIn;
            if (bIn)
            {
                Delegate->OnActorEnterTriggerGroup.ExecuteIfBound(GroupId, ActorUniqueId, ActorAreaInfo.Actor->GetUniqueID());
            }
            else
            {
                Delegate->OnActorLeaveTriggerGroup.ExecuteIfBound(GroupId, ActorUniqueId, ActorAreaInfo.Actor->GetUniqueID());
            }
        }
    }
}