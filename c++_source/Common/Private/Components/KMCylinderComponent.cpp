// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/KMCylinderComponent.h"
#include "Common.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Shell/CommonShell.h"

const float TICK_TIME = 0.3f;

//DEFINE_LOG_CATEGORY_STATIC(CyliderLog, Log, All)

UKMCylinderComponent::UKMCylinderComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , Deviation(0.f)
    , IsUseDefaultCollision(false)
{
}

void UKMCylinderComponent::OnComponentDestroyed(bool bDestroyingHierarchy)
{
    ClearEnteredTriggerActor();

    Super::OnComponentDestroyed(bDestroyingHierarchy);
}

void UKMCylinderComponent::ClearEnteredTriggerActor()
{
    UCommonShell* CommonShell = UCommonShell::GetCommon(this);
    if (!IsValid(CommonShell))
    {
        return;
    }
    UGameDelegateManager* GameDelegateMgr = CommonShell->GetGameDelegateManager();
    if (IsValid(GameDelegateMgr))
    {
        UPiratesGameMiscDelegate* GameMisc = GameDelegateMgr->GameMisc;
        AActor* const MyActor = GetOwner();
        for (auto Iter = EnteredTriggerActors.CreateIterator(); Iter; ++Iter)
        {
            AActor* Actor = Iter->Key.Get();
            if (Iter->Value)
            {
                GameMisc->ActorLeaveTrigger(MyActor, Actor);
            }
        }
    }
}

void UKMCylinderComponent::SetSize(float Radius, bool bUpdateOverlaps)
{
    SetCapsuleRadius(Radius, bUpdateOverlaps);
}

void UKMCylinderComponent::SetEnabled(bool bEnabled)
{
    if (bEnabled)
    {
        SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
        PrimaryComponentTick.bCanEverTick = true;
        SetComponentTickInterval(TICK_TIME);
        SetComponentTickEnabled(true);
    }
    else
    {
        ClearEnteredTriggerActor();
        PrimaryComponentTick.bCanEverTick = false;
        SetComponentTickEnabled(false);
        SetCollisionEnabled(ECollisionEnabled::NoCollision);
    }
}

void UKMCylinderComponent::SetDeviation(float Value)
{
    Deviation = Value;
}

bool UKMCylinderComponent::IsInCylinderBounds(AActor* Actor)
{
    if (Actor == nullptr)
    {
        return false;
    }

    AActor* const MyActor = GetOwner();
    float MyZ = MyActor->GetActorLocation().Z;
    float ActorZ = Actor->GetActorLocation().Z;
    
    //UE_LOG(CyliderLog, Log, TEXT("IsInCylinderBounds myz %f, actorz %f"), MyZ, ActorZ);

    return ActorZ >= MyZ - Deviation && ActorZ <= MyZ + Deviation;
}

bool UKMCylinderComponent::AddEnterTriggerActor(AActor* Actor, bool bIsInBounds)
{
    if (!Actor)
    {
        return false;
    }

    if (EnteredTriggerActors.Find(Actor))
    {
        return false;
    }

    EnteredTriggerActors.Add(Actor, bIsInBounds);

    return true;
}

bool UKMCylinderComponent::RemoveEnterTriggerActor(AActor* Actor)
{
    if (!Actor)
    {
        return false;
    }
    if (!EnteredTriggerActors.Find(Actor))
    {
        return false;
    }

    EnteredTriggerActors.Remove(Actor);
    return true;
}

bool UKMCylinderComponent::VerifyInCylinderBounds(AActor* Actor)
{
    bool IsInBounds = IsInCylinderBounds(Actor);
    AddEnterTriggerActor(Actor, IsInBounds);

    return IsInBounds;
}

void UKMCylinderComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
    UCommonShell* CommonShell = UCommonShell::GetCommon(this);
    if (!IsValid(CommonShell))
        return;
    
    UGameDelegateManager* GameDelegateMgr = CommonShell->GetGameDelegateManager();
    if (!IsValid(GameDelegateMgr))
        return;

    UPiratesGameMiscDelegate* GameMisc = GameDelegateMgr->GameMisc;

    AActor* const MyActor = GetOwner();

    for (auto Iter = EnteredTriggerActors.CreateIterator(); Iter; ++Iter)
    {
        AActor* Actor = Iter->Key.Get();
        bool IsInBounds = IsInCylinderBounds(Actor);
        if (IsInBounds == Iter->Value)
        {
            continue;
        }
        Iter->Value = IsInBounds;
        if (IsInBounds)
        {
            GameMisc->ActorEnterTrigger(MyActor, Actor);
        }
        else
        {
            GameMisc->ActorLeaveTrigger(MyActor, Actor);
        }
    }
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
}

// void UKMCylinderComponent::BeginComponentOverlap(const FOverlapInfo& OtherOverlap, bool bDoNotifies)
// {
//     Super::BeginComponentOverlap(OtherOverlap, bDoNotifies);
// }
// 
// void UKMCylinderComponent::EndComponentOverlap(const FOverlapInfo& OtherOverlap, bool bDoNotifies, bool bSkipNotifySelf)
// {
//     Super::EndComponentOverlap(OtherOverlap, bDoNotifies, bSkipNotifySelf);
// }
// 
// bool UKMCylinderComponent::UpdateOverlapsImpl(TArray<FOverlapInfo> const* NewPendingOverlaps, bool bDoNotifies, const TArray<FOverlapInfo>* OverlapsAtEndLocation)
// {
//     return Super::UpdateOverlapsImpl(NewPendingOverlaps, bDoNotifies, OverlapsAtEndLocation);
// }

void UKMCylinderComponent::OnActorBeginOverlap(AActor* Actor)
{
    //UE_LOG(CyliderLog, Log, TEXT("OnActorBeginOverlap"));
    if (!IsUseDefaultCollision)
    {
        if (!VerifyInCylinderBounds(Actor))
        {
            return;
        }
    }

    UCommonShell* CommonShell = UCommonShell::GetCommon(this);
    if (IsValid(CommonShell))
    {
        UGameDelegateManager* GameDelegateMgr = CommonShell->GetGameDelegateManager();
        if (IsValid(GameDelegateMgr))
        {
            GameDelegateMgr->GameMisc->ActorEnterTrigger(GetOwner(), Actor);
        }
    }
}

void UKMCylinderComponent::OnActorEndOverlap(AActor* Actor)
{
    //UE_LOG(CyliderLog, Log, TEXT("OnActorEndOverlap"));
    if (!IsUseDefaultCollision)
    {
        if (!RemoveEnterTriggerActor(Actor))
        {
            return;
        }
    }

    UCommonShell* CommonShell = UCommonShell::GetCommon(this);
    if (IsValid(CommonShell))
    {
        UGameDelegateManager* GameDelegateMgr = CommonShell->GetGameDelegateManager();
        if (IsValid(GameDelegateMgr))
        {
            GameDelegateMgr->GameMisc->ActorLeaveTrigger(GetOwner(), Actor);
        }
    }
}

void UKMCylinderComponent::SetUseDefaultCollision(bool bValue)
{
    IsUseDefaultCollision = bValue;
    ClearEnteredTriggerActor();
}
