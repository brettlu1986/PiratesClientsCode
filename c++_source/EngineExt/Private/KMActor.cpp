// Fill out your copyright notice in the Description page of Project Settings.

#include "KMActor.h"
#include "EngineExt.h"
#include "GameEngineExt.h"
#include "Game/Delegates/ActorDelegate.h"
#include "Net/UnrealNetwork.h"
#include "Game/Actor/KMScriptActorSpawnContext.h"
#include "Game/Delegates/KMDelegateManager.h"

DECLARE_STATS_GROUP(TEXT("KMActor"), STATGROUP_KMActor, STATCAT_Advanced);
DECLARE_CYCLE_STAT(TEXT("PreBeginPlay"), STAT_KMActor_PreBeginPlay, STATGROUP_KMActor);
DECLARE_CYCLE_STAT(TEXT("OrignalBeginPlay"), STAT_KMActor_OrignalBeginPlay, STATGROUP_KMActor);
DECLARE_CYCLE_STAT(TEXT("PostBeginPlay"), STAT_KMActor_PostBeginPlay, STATGROUP_KMActor);
DECLARE_CYCLE_STAT(TEXT("EndPlay"), STAT_KMActor_EndPlay, STATGROUP_KMActor);
DECLARE_CYCLE_STAT(TEXT("OnActorChannelOpen"), STAT_KMActor_OnActorChannelOpen, STATGROUP_KMActor);
DECLARE_CYCLE_STAT(TEXT("PreDestroyed"), STAT_KMActor_PreDestroyed, STATGROUP_KMActor);

DEFINE_LOG_CATEGORY_STATIC(KMActorLog, Log, All)

AKMActor::AKMActor(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , EnableDebugLog(false)
    , LogicInstanceId(-1)
    , IsBeginPlayManually(false)
    , bHasBeginPlayCompletely(false)
    , HasActorChannelOpened(false)
{
    UGameEngineExt* EngineExt = UGameEngineExt::Get(this);
    if (EngineExt)
    {
        EngineExt->GetActorSpawnContext().PopData(InitProtoData, LogicInstanceId, IsBeginPlayManually);
    }

#if WITH_EDITOR
    FCoreUObjectDelegates::OnObjectPropertyChanged.AddUObject(this, &AKMActor::OnObjectPropertyChangedCallback);
#endif
}

#if WITH_EDITOR
void AKMActor::PostInitProperties()
{
    Super::PostInitProperties();

    if (!IsTemplate())
    {
        GEngine->OnLevelActorAttached().Remove(OnLevelActorAttachedHandle);
        OnLevelActorAttachedHandle = GEngine->OnLevelActorAttached().AddUObject(this, &AKMActor::OnLevelActorAttachedCallback);

        GEngine->OnLevelActorDetached().Remove(OnLevelActorDetachedHandle);
        OnLevelActorDetachedHandle = GEngine->OnLevelActorDetached().AddUObject(this, &AKMActor::OnLevelActorDetachedCallback);
    }
}

void AKMActor::BeginDestroy()
{
    Super::BeginDestroy();

    if (!IsTemplate())
    {
        GEngine->OnLevelActorAttached().Remove(OnLevelActorAttachedHandle);
        GEngine->OnLevelActorDetached().Remove(OnLevelActorDetachedHandle);
    }
}
#endif

void AKMActor::OnEditPropertyChanged_Implementation(const FString& PropertyName)
{

}

void AKMActor::OnEditActorAttached_Implementation(const AActor* InParent)
{

}

void AKMActor::OnEditActorDetached_Implementation(const AActor* InParent)
{

}

void AKMActor::SetPropertyReadyOnlyInInstance(const FString& PropertyName)
{
#if WITH_EDITOR
    UClass* ThisClass = GetClass();
    FName TempPropertyName(*PropertyName);
    for (TFieldIterator<FProperty> itrProperty(ThisClass, EFieldIteratorFlags::ExcludeSuper, EFieldIteratorFlags::ExcludeDeprecated); itrProperty; ++itrProperty)
    {
        FProperty* Property = *itrProperty;
        if (TempPropertyName == Property->GetFName())
        {
            Property->SetPropertyFlags(Property->GetPropertyFlags() | CPF_BlueprintVisible);
            break;
        }
    }
#endif
}

#if WITH_EDITOR
void AKMActor::OnObjectPropertyChangedCallback(UObject* Object, struct FPropertyChangedEvent& PropertyChangedEvent)
{
    while (Object)
    {
        if (Object == this)
        {
            FString PropertyName;
            if (PropertyChangedEvent.Property)
            {
                PropertyChangedEvent.Property->GetName(PropertyName);
            }
            OnEditPropertyChanged(PropertyName);
            break;
        }
        Object = Object->GetOuter();
    }
}

void AKMActor::OnLevelActorAttachedCallback(AActor* InActor, const AActor* InParent)
{
    if (InActor == this)
    {
        OnEditActorAttached(InParent);
    }
}

void AKMActor::OnLevelActorDetachedCallback(AActor* InActor, const AActor* InParent)
{
    if (InActor == this)
    {
        OnEditActorDetached(InParent);
    }
}

#endif

bool AKMActor::NeedReplicate_Implementation(const FName& PropertyName)
{
    return false;
}

void AKMActor::BeginPlayManually()
{
    if(!IsBeginPlayManually)
    {
        return;
    }

    IsBeginPlayManually = false;
    BeginPlay();
}

void AKMActor::PreBeginPlay()
{
    check(!bHasBeginPlayCompletely);
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    UActorDelegate* ActorDelegate = Game ? Game->GetKMDelegateManager()->Actor : nullptr;
    if (ActorDelegate)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMActor_PreBeginPlay);
        FPrintTimeHelper T(*FString::Printf(TEXT("AKMPawn::PreBeginPlay [%s]"), *GetName()), EnableDebugLog);
        ActorDelegate->OnPawnPreBeginPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
    }
}

void AKMActor::OrignalBeginPlay()
{
    SCOPE_CYCLE_COUNTER(STAT_KMActor_OrignalBeginPlay);
    check(!bHasBeginPlayCompletely);
    FPrintTimeHelper T(*FString::Printf(TEXT("AKMPawn::OrignalBeginPlay [%s]"), *GetName()), EnableDebugLog);
    Super::BeginPlay();
}

void AKMActor::PostBeginPlay()
{
    check(!bHasBeginPlayCompletely);
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    UActorDelegate* ActorDelegate = Game ? Game->GetKMDelegateManager()->Actor : nullptr;
    if (ActorDelegate)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMActor_PostBeginPlay);
        FPrintTimeHelper T(*FString::Printf(TEXT("AKMPawn::PostBeginPlay [%s]"), *GetName()), EnableDebugLog);
        ActorDelegate->OnPawnPostBeginPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
    }
    bHasBeginPlayCompletely = true;
    IsBeginPlayManually = false;
}

void AKMActor::BeginPlay()
{
    if (IsBeginPlayManually)
    {
        return;
    }

    PreBeginPlay();
    OrignalBeginPlay();
    PostBeginPlay();
}

void AKMActor::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    if (Game)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMActor_EndPlay);
        Game->GetKMDelegateManager()->Actor->OnPawnEndPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
    }

    Super::EndPlay(EndPlayReason);
}

void AKMActor::Destroyed()
{
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    if (Game)
    {
        Game->GetKMDelegateManager()->Actor->OnActorDestroyed.Broadcast(this, GetUniqueID(), LogicInstanceId);
    }
    Super::Destroyed();
}

//void AKMActor::PreReplication(IRepChangedPropertyTracker & ChangedPropertyTracker)
//{
//    Super::PreReplication(ChangedPropertyTracker);
//
//    auto& Reps = GetClass()->ClassReps;
//    for (auto& RepInfo : Reps)
//    {
//        FProperty* Property = RepInfo.Property;
//        if (Property->GetBlueprintReplicationCondition() == ELifetimeCondition::COND_Custom)
//        {
//            bool bReplicate = NeedReplicate(Property->GetFName());
//            for (int32 i = 0; i < Property->ArrayDim; i++)
//            {
//                ChangedPropertyTracker.SetCustomIsActiveOverride(Property->RepIndex + i, bReplicate);
//            }
//        }
//    }
//}

void AKMActor::OnSerializeNewActor(FOutBunch& OutBunch)
{
	OutBunch << LogicInstanceId;
	OutBunch << InitProtoData;
	Super::OnSerializeNewActor(OutBunch);
}

void AKMActor::OnActorChannelOpen(FInBunch& InBunch, UNetConnection* Connection)
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
        SCOPE_CYCLE_COUNTER(STAT_KMActor_OnActorChannelOpen);
		uint32 nUniqueId = GetUniqueID();
        if (EnableDebugLog)
        {
            UE_LOG(KMActorLog, Log, TEXT("OnPawnChannelOpen begin uniqueid: %d, server instanceid: %d"), nUniqueId, LogicInstanceId);
        }

		Game->GetKMDelegateManager()->Actor->OnActorChannelOpen.Broadcast(this, nUniqueId, LogicInstanceId);
        if (EnableDebugLog)
        {
            UE_LOG(KMActorLog, Log, TEXT("OnPawnChannelOpen end uniqueid: %d, server instanceid: %d"), nUniqueId, LogicInstanceId);
        }
	}
}
