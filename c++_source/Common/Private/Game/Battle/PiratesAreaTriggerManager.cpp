#include "Game/Battle/PiratesAreaTriggerManager.h"
#include "Common.h"
#include "PiratesPlayerController.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Game/Delegates/ActorDelegate.h"
#include "KMActor.h"
#include "KMPawn.h"
#include "KMCharacter.h"

DECLARE_LOG_CATEGORY_CLASS(KMPiratesAreaTriggerManagerLog, Display, All);

UPiratesAreaTriggerManager::UPiratesAreaTriggerManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , EffectiveTime(1.0f)
    , CurrentTime(0.0f)
    , MiscDelegate(nullptr)
    , ActorDelegate(nullptr)
{
    PrimaryComponentTick.bCanEverTick = false;
}

void UPiratesAreaTriggerManager::SetUpdateInterval(float InEffetiveTime)
{
    //Clear();
    EffectiveTime = InEffetiveTime;
}

void UPiratesAreaTriggerManager::Init(UPiratesGameMiscDelegate* InMiscDelegate, UActorDelegate* InActorDelegate)
{
    MiscDelegate = InMiscDelegate;
    ActorDelegate = InActorDelegate;
    ActorDelegate->OnActorDestroyed.AddDynamic(this, &UPiratesAreaTriggerManager::OnActorDestroyed);
}

void UPiratesAreaTriggerManager::Uninit()
{
    Clear();
    ActorDelegate->OnActorDestroyed.RemoveDynamic(this, &UPiratesAreaTriggerManager::OnActorDestroyed);
}

void UPiratesAreaTriggerManager::Clear()
{
    CurrentTime = 0;
    for (int ii=0; ii<Actors.Num(); ii++)
    {
        auto& ActorInfo = Actors[ii];
        ActorInfo.Actor.Reset();
    }
    Actors.Empty();
    Areas.Empty();
}

int UPiratesAreaTriggerManager::Create2DArea(float X, float Y, float Radius)
{
    static int s_AreaId = 0;
    int iIndex = -1;
    for (int ii=0; ii<Areas.Num(); ii++)
    {
        if (Areas[ii].AreaId < 0)
        {
            iIndex = ii;
            break;
        }
    }
    if (iIndex < 0)
    {
        iIndex = Areas.Num();
        Areas.AddUninitialized();

        for (int ii=0; ii<Actors.Num(); ii++)
        {
            Actors[ii].AreaSlots.Add(false);
        }
    }
    
    UPiratesAreaTriggerManager::FAreaInfo& AreaInfo = Areas[iIndex];
    AreaInfo.AreaId = ++s_AreaId;
    AreaInfo.Center = FVector2D(X, Y);
    AreaInfo.RadiusSquared = Radius*Radius;
    AreaMap.Add(AreaInfo.AreaId, iIndex);
    return AreaInfo.AreaId;
}

bool UPiratesAreaTriggerManager::Destroy2DArea(int AreaId)
{
    int* FindIndex = AreaMap.Find(AreaId);
    if (!FindIndex)
    {
        return false;
    }

    int AreaIndex = *FindIndex;
    check(AreaIndex >= 0 && AreaIndex < Areas.Num());
    FAreaInfo& AreaInfo = Areas[AreaIndex];
    check(AreaInfo.AreaId == AreaId);

    // 不删除，这里为了AreaSlot的索引不会错
    AreaInfo.AreaId = -1;
    AreaMap.Remove(AreaId);

    for (int jj = 0; jj < Actors.Num(); jj++)
    {
        Actors[jj].AreaSlots[AreaIndex] = false;
    }
    return true;
}

bool UPiratesAreaTriggerManager::Set2dAreaInfo(int AreaId, float X, float Y, float Radius)
{
    int* FindIndex = AreaMap.Find(AreaId);
    if (!FindIndex)
    {
        return false;
    }

    int AreaIndex = *FindIndex;
    check(AreaIndex >= 0 && AreaIndex < Areas.Num());
    FAreaInfo& AreaInfo = Areas[AreaIndex];
    check(AreaInfo.AreaId == AreaId);

    AreaInfo.Center = FVector2D(X, Y);
    AreaInfo.RadiusSquared = Radius * Radius;
    return true;
}

bool UPiratesAreaTriggerManager::AddActorBox(AActor * Actor, UBoxComponent* Box)
{
    int InstanceId = 0;
    if (AKMCharacter* Character = Cast<AKMCharacter>(Actor))
    {
        InstanceId = Character->GetLogicInstanceId();
    }
    else if (AKMPawn* Pawn = Cast<AKMPawn>(Actor))
    {
        InstanceId = Pawn->GetLogicInstanceId();
    }
    else if (AKMActor* KMActor = Cast<AKMActor>(Actor))
    {
        InstanceId = KMActor->GetLogicInstanceId();
    }
    else
    {
        return false;
    }

    for (int ii = 0; ii < Actors.Num(); )
    {
        auto& ActorInfo = Actors[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            Actors.RemoveAt(ii);
            continue;
        }
        
        if (ActorInfo.Actor == Actor)
        {
            return true;
        }
        ii++;
    }

    // 这里特意不计算，等tick时在算，防止这里算完触发OnEnter
    Actors.AddDefaulted();
    UPiratesAreaTriggerManager::FActorInfo& Info = Actors[Actors.Num() - 1];
    Info.Actor = Actor;
    Info.LogicInstanceId = InstanceId;
    Info.BoxComponent = Box;    

    FScriptBitArray& BitSet = Info.AreaSlots;
    int32 iCount = Areas.Num();
    BitSet.Empty(iCount);
    for (int ii=0; ii<iCount; ii++)
    {
        BitSet.Add(false);
    }

    return true;
}

bool UPiratesAreaTriggerManager::AddActor(AActor* Actor)
{
    return AddActorBox(Actor, nullptr);
}

void UPiratesAreaTriggerManager::RemoveActor(AActor * Actor)
{
    if (!Actor)
    {
        return;
    }

    for (int ii = 0; ii < Actors.Num();)
    {
        auto& ActorInfo = Actors[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            Actors.RemoveAt(ii);
            continue;
        }
        
        if (ActorInfo.Actor == Actor)
        {
            auto& Bits = ActorInfo.AreaSlots;
            for (int jj=0; jj<Areas.Num(); jj++)
            {
                if (Bits[jj])
                {
                    MiscDelegate->OnActorLeaveArea.ExecuteIfBound(ActorInfo.LogicInstanceId, Areas[jj].AreaId);
                }
            }
            Actors.RemoveAt(ii);
            break;
        }
        ii++;
    }
}

bool UPiratesAreaTriggerManager::IsActorInArea(AActor* Actor, int AreaId)
{
    bool bIn = false;

    if (!Actor)
    {
        return bIn;
    }

    int* FindIndex = AreaMap.Find(AreaId);
    if (!FindIndex)
    {
        return bIn;
    }

    int AreaIndex = *FindIndex;
    check(AreaIndex >= 0 && AreaIndex < Areas.Num());
    FAreaInfo& AreaInfo = Areas[AreaIndex];
    check(AreaInfo.AreaId == AreaId);


    for (int ii = 0; ii < Actors.Num(); ii++)
    {
        auto& ActorInfo = Actors[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            continue;
        }

        if (ActorInfo.Actor == Actor)
        {
            FScriptBitArray& Bits = ActorInfo.AreaSlots;
            FVector Location = ActorInfo.Actor->GetActorLocation();
            FVector2D Location2D(Location.X, Location.Y);
            FVector2D BoxPoints[4];
            if (CaculateBoxPoints(ActorInfo.Actor.Get(), ActorInfo.BoxComponent.Get(), BoxPoints))
            {
                bIn = CheckBoxInside2dArea(BoxPoints, AreaInfo.Center, AreaInfo.RadiusSquared);
            }
            else
            {
                bIn = FVector2D::DistSquared(AreaInfo.Center, Location2D) <= AreaInfo.RadiusSquared;
            }
            
            break;
        }
    }

    return bIn;
}

void UPiratesAreaTriggerManager::PrintAreaTriggerInfo(int AreaId)
{
    int* FindIndex = AreaMap.Find(AreaId);
    if (!FindIndex)
    {
        return;
    }

    int AreaIndex = *FindIndex;
    check(AreaIndex >= 0 && AreaIndex < Areas.Num());
    FAreaInfo& AreaInfo = Areas[AreaIndex];
    check(AreaInfo.AreaId == AreaId);


    UE_LOG(KMPiratesAreaTriggerManagerLog, Display, TEXT("Area Trigger Center=%s, RadiusSquare=%f"), *AreaInfo.Center.ToString(), AreaInfo.RadiusSquared);
    for (int ii = 0; ii < Actors.Num(); ii++)
    {
        FActorInfo& ActorInfo = Actors[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            continue;
        }
        FScriptBitArray& Bits = ActorInfo.AreaSlots;
        FVector Location = ActorInfo.Actor->GetActorLocation();
        FVector2D Location2D(Location.X, Location.Y);
        bool bIn = FVector2D::DistSquared(AreaInfo.Center, Location2D) <= AreaInfo.RadiusSquared;

        UE_LOG(KMPiratesAreaTriggerManagerLog, Display, TEXT("Area Actor InstanceId=%d, Location=%s, bIn=%d, calcIn=%d"), ActorInfo.LogicInstanceId, *Location.ToString(), Bits[AreaIndex] ? 1 : 0, bIn ? 1 : 0);
    }
}

void UPiratesAreaTriggerManager::Update(float DeltaTime)
{
    bool bExecute = false;
    CurrentTime += DeltaTime;
    while (CurrentTime >= EffectiveTime)
    {
        bExecute = true;
        CurrentTime -= EffectiveTime;
    }
    if (bExecute)
    {
        Execute();
    }
}

void UPiratesAreaTriggerManager::Execute()
{
    FVector2D BoxPoints[4];
    //int nActorCount = Actors.Num();
    //int nAreaCount = Areas.Num();
    for (int ii = 0; ii < Actors.Num();)
    {
        FActorInfo& ActorInfo = Actors[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            Actors.RemoveAt(ii);
            continue;
        }
        
        FScriptBitArray& Bits = ActorInfo.AreaSlots;
        FVector Location = ActorInfo.Actor->GetActorLocation();
        FVector2D Location2D(Location.X, Location.Y);        
        bool bIn = false;
        bool bCheckBox = CaculateBoxPoints(ActorInfo.Actor.Get(), ActorInfo.BoxComponent.Get(), BoxPoints);
        
        for (int jj=0; jj< Areas.Num(); jj++)
        {
            auto& AreaInfo = Areas[jj];
            if (AreaInfo.AreaId < 0)
            {
                continue;
            }
                
            if (bCheckBox)
            {
                bIn = CheckBoxInside2dArea(BoxPoints, AreaInfo.Center, AreaInfo.RadiusSquared);
            }
            else
            {
                bIn = FVector2D::DistSquared(AreaInfo.Center, Location2D) <= AreaInfo.RadiusSquared;
            }
            
            if (Bits[jj] != bIn)
            {
                Bits[jj] = bIn;
                if (bIn)
                {
                    MiscDelegate->OnActorEnterArea.ExecuteIfBound(ActorInfo.LogicInstanceId, AreaInfo.AreaId);
                }
                else
                {
                    MiscDelegate->OnActorLeaveArea.ExecuteIfBound(ActorInfo.LogicInstanceId, AreaInfo.AreaId);
                }
            }
        }
        ii++;
    }
}

void UPiratesAreaTriggerManager::OnActorDestroyed(AActor* ActorToDestroy, uint32 UniqueId, int InstanceId)
{
    RemoveActor(ActorToDestroy);
}

const bool UPiratesAreaTriggerManager::CheckBoxInside2dArea(const FVector2D* Points, const FVector2D& Center, float RadiusSquared) const
{
    for (int ii=0; ii<4; ii++)
    {
        if (FVector2D::DistSquared(Center, Points[ii]) > RadiusSquared)
        {
            return false;
        }
    }
    return true;
}

bool UPiratesAreaTriggerManager::CaculateBoxPoints(const AActor* Actor, const UBoxComponent* Box, FVector2D* OutPoints)
{
    if (!Box | !Actor)
    {
        return false;
    }

    float Yaw = Actor->GetActorRotation().Yaw;
    FBox BoxData = Box->Bounds.GetBox();
    auto& Min = BoxData.Min;
    auto& Max = BoxData.Max;
    FVector2D BoxCenter((Min.X+Max.X)/2, (Min.Y+Max.Y)/2);
    OutPoints[0] = FVector2D(Min.X, Min.Y);
    OutPoints[1] = FVector2D(Min.X, Max.Y);
    OutPoints[2] = FVector2D(Max.X, Max.Y);
    OutPoints[3] = FVector2D(Max.X, Min.Y);

    FVector2D Temp;
    for (int ii=0; ii<4; ii++)
    {
        Temp = OutPoints[ii] - BoxCenter;
        Temp = Temp.GetRotated(Yaw);
        OutPoints[ii] = Temp + BoxCenter;
    }
    return true;
}