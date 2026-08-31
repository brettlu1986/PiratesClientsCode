// Fill out your copyright notice in the Description page of Project Settings.

#include "KMPawn.h"
#include "EngineExt.h"
#include "GameEngineExt.h"
#include "Game/Delegates/ActorDelegate.h"
#include "Game/Actor/KMScriptActorSpawnContext.h"
#include "GameFramework/DamageType.h"
#include "Net/UnrealNetwork.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Shell/EngineExtShell.h"

DECLARE_STATS_GROUP(TEXT("KMPawn"), STATGROUP_KMPawn, STATCAT_Advanced);
DECLARE_CYCLE_STAT(TEXT("PreBeginPlay"), STAT_KMPawn_PreBeginPlay, STATGROUP_KMPawn);
DECLARE_CYCLE_STAT(TEXT("OrignalBeginPlay"), STAT_KMPawn_OrignalBeginPlay, STATGROUP_KMPawn);
DECLARE_CYCLE_STAT(TEXT("PostBeginPlay"), STAT_KMPawn_PostBeginPlay, STATGROUP_KMPawn);
DECLARE_CYCLE_STAT(TEXT("EndPlay"), STAT_KMPawn_EndPlay, STATGROUP_KMPawn);
DECLARE_CYCLE_STAT(TEXT("OnActorChannelOpen"), STAT_KMPawn_OnActorChannelOpen, STATGROUP_KMPawn);
DECLARE_CYCLE_STAT(TEXT("TakeDamage"), STAT_KMPawn_TakeDamage, STATGROUP_KMPawn);


DEFINE_LOG_CATEGORY_STATIC(KMPawnLog, Log, All)

AKMPawn::AKMPawn(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
    , LogicInstanceId(-1)
    , IsBeginPlayManually(false)
    , bHasBeginPlayCompletely(false)
    , LastTakeHitTimeTimeout(0.0f)
    , HasActorChannelOpened(false)
{
    UGameEngineExt* EngineExt = UGameEngineExt::Get(this);
    if (EngineExt)
    {
        EngineExt->GetActorSpawnContext().PopData(InitProtoData, LogicInstanceId, IsBeginPlayManually);
    }
};

void AKMPawn::BeginPlayManually()
{
    if (!IsBeginPlayManually)
    {
        return;
    }

    IsBeginPlayManually = false;
    BeginPlay();
}

void AKMPawn::PreBeginPlay()
{
    check(!bHasBeginPlayCompletely);
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    UActorDelegate* ActorDelegate = Game ? Game->GetKMDelegateManager()->Actor : nullptr;
    if (ActorDelegate)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMPawn_PreBeginPlay);
        FPrintTimeHelper T(*FString::Printf(TEXT("AKMPawn::PreBeginPlay %s, InstanceId: %d, UniqueId: %d"), *GetName(), GetLogicInstanceId(), GetUniqueID()));
        ActorDelegate->OnPawnPreBeginPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
    }
}

void AKMPawn::OrignalBeginPlay()
{
    SCOPE_CYCLE_COUNTER(STAT_KMPawn_OrignalBeginPlay);
    check(!bHasBeginPlayCompletely);
    FPrintTimeHelper T(*FString::Printf(TEXT("AKMPawn::OrignalBeginPlay %s, InstanceId: %d, UniqueId: %d"), *GetName(), GetLogicInstanceId(), GetUniqueID()));
    Super::BeginPlay();
}

void AKMPawn::PostBeginPlay()
{
    check(!bHasBeginPlayCompletely);
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    UActorDelegate* ActorDelegate = Game ? Game->GetKMDelegateManager()->Actor : nullptr;
    if (ActorDelegate)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMPawn_PostBeginPlay);
        FPrintTimeHelper T(*FString::Printf(TEXT("AKMPawn::PostBeginPlay %s, InstanceId: %d, UniqueId: %d"), *GetName(), GetLogicInstanceId(), GetUniqueID()));
        ActorDelegate->OnPawnPostBeginPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
    }
    bHasBeginPlayCompletely = true;
    IsBeginPlayManually = false;
}

void AKMPawn::BeginPlay()
{
    if (IsBeginPlayManually)
    {
        return;
    }

    PreBeginPlay();
    OrignalBeginPlay();
    PostBeginPlay();
}

void AKMPawn::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    if (Game)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMPawn_EndPlay);
        Game->GetKMDelegateManager()->Actor->OnPawnEndPlay.Broadcast(this, GetUniqueID(), GetLogicInstanceId());
    }

    Super::EndPlay(EndPlayReason);
}

void AKMPawn::OnSerializeNewActor(FOutBunch& OutBunch)
{
    OutBunch << LogicInstanceId;
    OutBunch << InitProtoData;
    Super::OnSerializeNewActor(OutBunch);
}

void AKMPawn::OnActorChannelOpen(FInBunch& InBunch, UNetConnection* Connection)
{
    if (InBunch.bClose || InBunch.AtEnd())
    {
        Super::OnActorChannelOpen(InBunch, Connection);
        return;
    }

    InBunch << LogicInstanceId;
    InBunch << InitProtoData;
    Super::OnActorChannelOpen(InBunch, Connection);

    if (HasActorChannelOpened)
    {
        return;
    }
    HasActorChannelOpened = true;

    UGameEngineExt* Game = UGameEngineExt::Get(this);
    if (Game)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMPawn_OnActorChannelOpen);
        uint32 nUniqueId = GetUniqueID();
        UE_LOG(KMPawnLog, Log, TEXT("OnPawnChannelOpen begin uniqueid: %d, server instanceid: %d"), nUniqueId, LogicInstanceId);
        Game->GetKMDelegateManager()->Actor->OnActorChannelOpen.Broadcast(this, nUniqueId, LogicInstanceId);
        UE_LOG(KMPawnLog, Log, TEXT("OnPawnChannelOpen end uniqueid: %d, server instanceid: %d"), nUniqueId, LogicInstanceId);
    }
}

void AKMPawn::Destroyed()
{
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    if (Game)
    {
        Game->GetKMDelegateManager()->Actor->OnActorDestroyed.Broadcast(this, GetUniqueID(), LogicInstanceId);
    }
    Super::Destroyed();
}

float AKMPawn::TakeDamage(float DamageAmount, struct FDamageEvent const& DamageEvent, class AController* EventInstigator, AActor* DamageCauser)
{
    SCOPE_CYCLE_COUNTER(STAT_KMPawn_TakeDamage);

	// 虚幻这个模块的事件发的太乱了，稍微整理了下
	float ActualDamage = Super::TakeDamage(DamageAmount, DamageEvent, EventInstigator, DamageCauser);
	UDamageType const* const DamageTypeCDO = DamageEvent.DamageTypeClass ? DamageEvent.DamageTypeClass->GetDefaultObject<UDamageType>() : GetDefault<UDamageType>();
	if (DamageEvent.IsOfType(FPointDamageEvent::ClassID))
	{
		FPointDamageEvent* const PointDamageEvent = (FPointDamageEvent*)&DamageEvent;
		FHitResult const& Hit = PointDamageEvent->HitInfo;
		OnTakePointDamageEx.Broadcast(this, ActualDamage, DamageTypeCDO, EventInstigator, DamageCauser, Hit);
	}
	else if (DamageEvent.IsOfType(FRadialDamageEvent::ClassID))
	{
		FRadialDamageEvent* const RadialDamageEvent = (FRadialDamageEvent*)&DamageEvent;
        FHitResult Hit;
        bool bResult = UEngineExtShell::GetNearestHitResult(DamagedChannel, RadialDamageEvent->ComponentHits, DamageCauser->GetActorLocation(), Hit);
        if (bResult)
        {
            OnTakeRadialDamageEx.Broadcast(this, ActualDamage, DamageTypeCDO, EventInstigator, DamageCauser, Hit);
        }
	}
	else
	{
		OnTakeCommonDamageEx.Broadcast(this, ActualDamage, DamageTypeCDO, EventInstigator, DamageCauser);
	}

    HitInfo.ActualDamage = ActualDamage;
    HitInfo.Instigator = EventInstigator ? EventInstigator->GetPawn() : nullptr;
    HitInfo.DamageCauser = DamageCauser;
    HitInfo.DamageTypeClass = DamageEvent.DamageTypeClass;
    HitInfo.EnsureReplication();
    LastTakeHitTimeTimeout = GetWorld()->GetTimeSeconds() + 0.5f;

	return ActualDamage;
}

void AKMPawn::GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME_CONDITION(AKMPawn, HitInfo, COND_Custom);
}

void AKMPawn::PreReplication(IRepChangedPropertyTracker & ChangedPropertyTracker)
{
    Super::PreReplication(ChangedPropertyTracker);

    DOREPLIFETIME_ACTIVE_OVERRIDE(AKMPawn, HitInfo, GetWorld() && GetWorld()->GetTimeSeconds() < LastTakeHitTimeTimeout);
}

void AKMPawn::OnRep_HitInfo()
{
    OnRepHitInfo.Broadcast(this, HitInfo.ActualDamage,
        HitInfo.Instigator.Get(), HitInfo.DamageCauser.Get(), HitInfo.DamageTypeClass);
}