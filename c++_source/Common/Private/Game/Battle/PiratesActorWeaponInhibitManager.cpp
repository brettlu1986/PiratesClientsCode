#include "Game/Battle/PiratesActorWeaponInhibitManager.h"
#include "Common.h"
#include "PiratesPlayerController.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"


UPiratesActorWeaponInhibitManager::UPiratesActorWeaponInhibitManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , EffectiveTime(1.0f)
    , CurrentTime(0.0f)
    , Delegate(nullptr)
{
    PrimaryComponentTick.bCanEverTick = false;
}

void UPiratesActorWeaponInhibitManager::SetUpdateInterval(float InEffetiveTime)
{
    Clear();
    EffectiveTime = InEffetiveTime;
}

void UPiratesActorWeaponInhibitManager::Clear()
{
    CurrentTime = 0;
    for (int ii=0; ii<Actors.Num(); ii++)
    {
        auto& ActorInfo = Actors[ii];
        ActorInfo.Actor.Reset();
    }
    Actors.Empty();
}


void UPiratesActorWeaponInhibitManager::AddActor(AActor* Actor, float Length, FVector OffsetLocation)
{
    if (Actor == nullptr)
        return;
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
            if (Length == 0) 
            {
                Actors.RemoveAt(ii);
                continue;
            }
            ActorInfo.CheckLength = Length;
            if (!OffsetLocation.IsZero())
            {
                ActorInfo.OffsetLocation = OffsetLocation;
            }

            return;
        }
        ii++;
    }
    if (Length <= 0)
        return;
    Actors.AddDefaulted();
    UPiratesActorWeaponInhibitManager::FActorInfo& Info = Actors[Actors.Num() - 1];
    Info.Actor = Actor;
    Info.CheckLength = Length;
    Info.OffsetLocation = OffsetLocation;
    Info.bCurrentInhibit = false;
    //Actor->OnDestroyed.AddDynamic(this, &UPiratesActorWeaponInhibitManager::OnActorDestroyed);
}

void UPiratesActorWeaponInhibitManager::RemoveActor(AActor * Actor)
{
    if (!Actor)
    {
        return;
    }
    for (int ii=0; ii<Actors.Num();)
    {
        auto& ActorInfo = Actors[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            Actors.RemoveAt(ii);
            continue;
        }
        
        if (ActorInfo.Actor == Actor)
        {
            //Actor->OnDestroyed.RemoveDynamic(this, &UPiratesActorWeaponInhibitManager::OnActorDestroyed);
            Actors.RemoveAt(ii);
            break;
        }
        ii++;
    }
}

void UPiratesActorWeaponInhibitManager::Update(float DeltaTime)
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

void UPiratesActorWeaponInhibitManager::Execute()
{
    for (int ii = 0; ii < Actors.Num();)
    {
        FActorInfo& ActorInfo = Actors[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            Actors.RemoveAt(ii);
            continue;
        }

        CheckActorInhibit(ActorInfo);
        ii++;
    }
}

void UPiratesActorWeaponInhibitManager::CheckActorInhibit(FActorInfo& ActorInfo)
{
    QUICK_SCOPE_CYCLE_COUNTER(STAT_UPiratesActorWeaponInhibit_Tick);
    //FVector Start = PlayerSelf->K2_GetActorLocation();  
    FVector Start = ActorInfo.Actor->GetActorTransform().TransformPosition(ActorInfo.OffsetLocation);
    //FVector Start = PlayerSelf->GetMesh()->GetSocketLocation(SocketName);
    FRotator Rot = ActorInfo.Actor->GetActorRotation();
    Rot.Pitch = 0;
    Rot.Roll = 0;
    FVector End = Start + ActorInfo.CheckLength * Rot.Vector();
    FHitResult HitResult;
    TArray<AActor*> ActorsToIgnore;
    ActorsToIgnore.Add(ActorInfo.Actor.Get());
    TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
    ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
    bool bHit = UKismetSystemLibrary::LineTraceSingleForObjects(ActorInfo.Actor.Get(), Start, End, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::Type::None, HitResult, true);
    //bool bHit = UKismetSystemLibrary::LineTraceSingleForObjects(PlayerSelf, Start, End, TraceObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::Type::ForOneFrame, HitResult, true);

    if (bHit)
    {
        UPhysicalMaterial* const HitPhysMat = HitResult.PhysMaterial.Get();

        if (HitPhysMat->GetName() == IgnoreType)
            bHit = false;

    }

    if (bHit != ActorInfo.bCurrentInhibit)
    {
        ActorInfo.bCurrentInhibit = bHit;
        if (bHit)
        {
            ActorInfo.LastDistance = HitResult.Distance;
        }
        Delegate->OnActorInhibitAttack.ExecuteIfBound(ActorInfo.Actor.Get(), bHit, HitResult.Distance);
    }
    else if (bHit && fabs(ActorInfo.LastDistance - HitResult.Distance) > 0.1f)
    {
        ActorInfo.LastDistance = HitResult.Distance;
        Delegate->OnActorInhibitAttack.ExecuteIfBound(ActorInfo.Actor.Get(), bHit, HitResult.Distance);
        ActorInfo.LastDistance = HitResult.Distance;
    }
}


void UPiratesActorWeaponInhibitManager::OnActorDestroyed(AActor* ActorToDestroy)
{
    RemoveActor(ActorToDestroy);
}
