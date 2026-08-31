// Fill out your copyright notice in the Description page of Project Settings.

#include "KMCharacter.h"
#include "EngineExt.h"
#include "DelayCallAction.h"
#include "DelayAction.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Net/UnrealNetwork.h"
#include "Game/GameEngineExt.h"
#include "Game/Delegates/ActorDelegate.h"
#include "SkeletalMeshMerge.h"
#include "Components/KMCharacterMovementComponent.h"
#include "Components/KMCapsuleComponent.h"
#include "KMPlayerController.h"
#include "Game/Actor/KMScriptActorSpawnContext.h"
#include "Shell/EngineExtShell.h"
#include "Shell/EngineExtActorShell.h"
#include "Game/Delegates/KMDelegateManager.h"
// significance
#include "SignificanceManager.h"
// ~significance

// URO
// see FAnimUpdateRateManager
#include "Components/SkinnedMeshComponent.h"
// ~URO

// significance
#ifndef PIR_USE_SIGNIFICANCE
#define PIR_USE_SIGNIFICANCE 1
#endif
// ~significance

// URO
#ifndef PIR_USE_URO
#define PIR_USE_URO 1
#endif
// ~URO

DECLARE_STATS_GROUP(TEXT("KMCharacter"), STATGROUP_KMCharacter, STATCAT_Advanced);
DECLARE_CYCLE_STAT(TEXT("PreBeginPlay"), STAT_KMCharacter_PreBeginPlay, STATGROUP_KMCharacter);
DECLARE_CYCLE_STAT(TEXT("OrignalBeginPlay"), STAT_KMCharacter_OrignalBeginPlay, STATGROUP_KMCharacter);
DECLARE_CYCLE_STAT(TEXT("PostBeginPlay"), STAT_KMCharacter_PostBeginPlay, STATGROUP_KMCharacter);
DECLARE_CYCLE_STAT(TEXT("EndPlay"), STAT_KMCharacter_EndPlay, STATGROUP_KMCharacter);
DECLARE_CYCLE_STAT(TEXT("OnActorChannelOpen"), STAT_KMCharacter_OnActorChannelOpen, STATGROUP_KMCharacter);
DECLARE_CYCLE_STAT(TEXT("TakeDamage"), STAT_KMCharacter_TakeDamage, STATGROUP_KMCharacter);

DEFINE_LOG_CATEGORY_STATIC(KMCharacterLog, Log, All)

// URO
int32 CVarEnableUpdateRateOptimizations = 1;
FAutoConsoleVariableRef CVarEnableUpdateRateOptimizationsRef(
	TEXT("pir.EnableURO"),
	CVarEnableUpdateRateOptimizations,
	TEXT("[Pir] Used to set bEnableUpdateRateOptimizations by cvar, the original value of bEnableUpdateRateOptimizations will be ignored.")
);

static TAutoConsoleVariable<FString> CVarURODistanceFactorThresholds(
	TEXT("pir.URODistanceFactorThresholds"),
	TEXT("0.80,0.32,0.09"),
	TEXT("[Pir] BaseVisibleDistanceFactorThesholds for URO.")
);
// for holding the values parsed form pir.URODistanceFactorThresholds
TArray<FString> URODistanceFactorThresholds;
// ~URO

// significance
int32 KMCharacterDrawDis = 5000;
static TAutoConsoleVariable<int32> CVarKMCharacterDrawDis(
	TEXT("pir.CharacterDrawDis"),
	KMCharacterDrawDis,
	TEXT("[Pir] Base character draw distance.")
);

static const float GSignificance3 = 3.0f; // <35,00
static const float GSignificance2 = 2.0f; // <75,00
static const float GSignificance1 = 1.0f; // <150,00
static const float GSignificance0 = 0.0f; // >=150,00

// ~significance


struct AKMCharacter::FImplement
{
	AKMCharacter* Owner;
	bool EnableMove;
	bool DirectMoving;

	FImplement(AKMCharacter* Parent) :
		Owner(Parent), EnableMove(true), DirectMoving(false)//, ActiveSerializeOutBunch(nullptr)
	{
		// significance
#if PIR_USE_SIGNIFICANCE
		SignificanceFunction = [this](USignificanceManager::FManagedObjectInfo* Info, const FTransform& Trans)->float
		{
			check(this && this->Owner && this->Owner->IsValidLowLevel());
			check(this->Owner == Info->GetObject());
			return this->Owner->OnSignificance(this->Owner, Trans);
		};

		PostSignificanceFunction = [this](USignificanceManager::FManagedObjectInfo* Info, float OldValue, float CurentValue, bool bBeingUnregistered)
		{
			check(this->Owner->IsValidLowLevel());
			check(Info->GetObject() == this->Owner);
			this->Owner->OnPostSignificance(this->Owner, OldValue, CurentValue, bBeingUnregistered);
		};
#endif
		// ~significance

		// URO
#if PIR_USE_URO
		if (URODistanceFactorThresholds.Num() == 0)
		{
			FString CVarValue = CVarURODistanceFactorThresholds.GetValueOnGameThread();
			CVarValue.ParseIntoArray(URODistanceFactorThresholds, TEXT(","));
		}
		if (CVarEnableUpdateRateOptimizations != 0)
		{
			check(URODistanceFactorThresholds.Num());
			TArray<UActorComponent*> Comps = Owner->K2_GetComponentsByClass(USkinnedMeshComponent::StaticClass());
			for (auto Comp : Comps)
			{
				((USkinnedMeshComponent*)Comp)->bEnableUpdateRateOptimizations = true;
				((USkinnedMeshComponent*)Comp)->OnAnimUpdateRateParamsCreated.BindLambda([](FAnimUpdateRateParameters* URParam) {
					URParam->BaseVisibleDistanceFactorThesholds.Empty();
					for (auto& Val : URODistanceFactorThresholds)
					{
						URParam->BaseVisibleDistanceFactorThesholds.Add(FMath::Square(FCString::Atof(*Val) / 2));
					}
				});
				/*if (Comp->IsRegistered())
				{
					((USkinnedMeshComponent*)Comp)->RefreshUpdateRateParams();
				}*/
			}
		}
#endif
		// ~URO
	}

	void CombineMesh(TArray<USkeletalMesh*>& Meshes, bool bMergeMaterial)
	{
		USkeletalMeshComponent* SkeletonMesh = Cast<USkeletalMeshComponent>(Owner->GetComponentByClass(USkeletalMeshComponent::StaticClass()));
		ReturnIfNullptr(SkeletonMesh);

		USkeletalMesh* TargetMesh = NewObject<USkeletalMesh>(Owner, USkeletalMesh::StaticClass());
		TargetMesh->Skeleton = SkeletonMesh->SkeletalMesh->Skeleton;

		TArray<FSkelMeshMergeSectionMapping> SkeletonSections;
		FSkelMeshMergeSectionMapping SectionMap;
		if (bMergeMaterial)
		{
			SectionMap.SectionIDs.Reset();
			for (int i = 0; i < Meshes.Num(); i++)
			{
				SectionMap.SectionIDs.Reset();
				if (i > 0)
				{
					SectionMap.SectionIDs.Add(0);
				}
				SkeletonSections.Add(SectionMap);
			}
		}
		FSkeletalMeshMerge MergeMesh(TargetMesh, Meshes, SkeletonSections, 0);
		bool bMergeState = MergeMesh.DoMerge();
		if (bMergeState)
		{
			SkeletonMesh->SetSkeletalMesh(TargetMesh);
		}
	}

	// significance
#if PIR_USE_SIGNIFICANCE
	USignificanceManager::FManagedObjectSignificanceFunction SignificanceFunction;
	USignificanceManager::FManagedObjectPostSignificanceFunction PostSignificanceFunction;
#endif
	// ~significance
};

// Sets default values
AKMCharacter::AKMCharacter(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer.SetDefaultSubobjectClass<UKMCharacterMovementComponent>(ACharacter::CharacterMovementComponentName)
        .SetDefaultSubobjectClass<UKMCapsuleComponent>(ACharacter::CapsuleComponentName))
    //: Super(ObjectInitializer)
    , Impl(MakeShareable(new FImplement(this)))
    , EnableDebugLog(false)
    , LogicInstanceId(-1)
    , IsBeginPlayManually(false)
    , bHasBeginPlayCompletely(false)
    , LastTakeHitTimeTimeout(0.0f)
    , HasActorChannelOpened(false)
    , EnableAttachmentAndMovementRPCDependingOnReplicateMovement(true)
{
    UGameEngineExt* EngineExt = UGameEngineExt::Get(this);
    if (EngineExt)
    {
        EngineExt->GetActorSpawnContext().PopData(InitProtoData, LogicInstanceId, IsBeginPlayManually);
    }
}

void AKMCharacter::SetSkeletalMeshes(const int MergeMaterial, const TArray<FString>& MeshesPath)
{
	TArray<USkeletalMesh*> Meshes;

	//FStringAssetReference GameAssetRef;
	UObject* Object = nullptr;
	USkeletalMesh* SkeletonVisualAsset = nullptr;
	for (int i = 0; i < MeshesPath.Num(); i++)
	{
		//GameAssetRef = MeshesPath[i];
		//Object = GameAssetRef.TryLoad();
        Object = UEngineExtShell::StaticLoadObjectWithoutFlush(MeshesPath[i]);

		if (Object != nullptr)
		{
			SkeletonVisualAsset = Cast<USkeletalMesh>(Object);
			if (SkeletonVisualAsset != nullptr)
			{
				Meshes.Add(SkeletonVisualAsset);
			}
		}
	}

	Impl->CombineMesh(Meshes, (MergeMaterial > 0));
}

void AKMCharacter::BeginPlayManually()
{
    if (!IsBeginPlayManually)
    {
        return;
    }

    IsBeginPlayManually = false;
    BeginPlay();
}

void AKMCharacter::PreBeginPlay()
{
    check(!bHasBeginPlayCompletely);
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    UActorDelegate* ActorDelegate = Game ? Game->GetKMDelegateManager()->Actor : nullptr;
    if (ActorDelegate)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMCharacter_PreBeginPlay);
        FPrintTimeHelper T(*FString::Printf(TEXT("AKMCharacter::PreBeginPlay %s, InstanceId: %d, UniqueId: %d"), *GetName(), GetLogicInstanceId(), GetUniqueID()), EnableDebugLog);
        ActorDelegate->OnPawnPreBeginPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
    }
}

void AKMCharacter::OrignalBeginPlay()
{
    SCOPE_CYCLE_COUNTER(STAT_KMCharacter_OrignalBeginPlay);
    check(!bHasBeginPlayCompletely);
    FPrintTimeHelper T(*FString::Printf(TEXT("AKMCharacter::OrignalBeginPlay %s, InstanceId: %d, UniqueId: %d"), *GetName(), GetLogicInstanceId(), GetUniqueID()), EnableDebugLog);
    Super::BeginPlay();
}

void AKMCharacter::PostBeginPlay()
{
    check(!bHasBeginPlayCompletely);
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    UActorDelegate* ActorDelegate = Game ? Game->GetKMDelegateManager()->Actor : nullptr;
    if (ActorDelegate)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMCharacter_PostBeginPlay);
        FPrintTimeHelper T(*FString::Printf(TEXT("AKMCharacter::PostBeginPlay %s, InstanceId: %d, UniqueId: %d"), *GetName(), GetLogicInstanceId(), GetUniqueID()), EnableDebugLog);
        ActorDelegate->OnPawnPostBeginPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
    }
    bHasBeginPlayCompletely = true;
    IsBeginPlayManually = false;
}

float AKMCharacter::TakeDamage(float DamageAmount, struct FDamageEvent const& DamageEvent, class AController* EventInstigator, AActor* DamageCauser)
{
    SCOPE_CYCLE_COUNTER(STAT_KMCharacter_TakeDamage);

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

void AKMCharacter::BeginPlay()
{
    if (IsBeginPlayManually)
    {
        return;
    }

    PreBeginPlay();
    OrignalBeginPlay();
    PostBeginPlay();
}

void AKMCharacter::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    if (Game)
    {
        SCOPE_CYCLE_COUNTER(STAT_KMCharacter_EndPlay);
        Game->GetKMDelegateManager()->Actor->OnPawnEndPlay.Broadcast(this, GetUniqueID(), GetLogicInstanceId());
    }

    Super::EndPlay(EndPlayReason);
}

void AKMCharacter::OnSerializeNewActor(FOutBunch& OutBunch)
{
    OutBunch << LogicInstanceId;
    OutBunch << InitProtoData;
    Super::OnSerializeNewActor(OutBunch);
}

void AKMCharacter::OnActorChannelOpen(FInBunch& InBunch, UNetConnection* Connection)
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
        SCOPE_CYCLE_COUNTER(STAT_KMCharacter_OnActorChannelOpen);
        uint32 nUniqueId = GetUniqueID();
        if (EnableDebugLog)
        {
            UE_LOG(KMCharacterLog, Log, TEXT("OnCharacterChannelOpen begin uniqueid: %d, server instanceid: %d"), nUniqueId, LogicInstanceId);
        }
        Game->GetKMDelegateManager()->Actor->OnActorChannelOpen.Broadcast(this, nUniqueId, LogicInstanceId);
        if (EnableDebugLog)
        {
            UE_LOG(KMCharacterLog, Log, TEXT("OnCharacterChannelOpen end uniqueid: %d, server instanceid: %d"), nUniqueId, LogicInstanceId);
        }
    }
}

void AKMCharacter::GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME_CONDITION(AKMCharacter, HitInfo, COND_Custom);
}

void AKMCharacter::PreReplication(IRepChangedPropertyTracker & ChangedPropertyTracker)
{
    Super::PreReplication(ChangedPropertyTracker);

    DOREPLIFETIME_ACTIVE_OVERRIDE(AKMCharacter, HitInfo, GetWorld() && GetWorld()->GetTimeSeconds() < LastTakeHitTimeTimeout);

    if (EnableAttachmentAndMovementRPCDependingOnReplicateMovement)
    {
#define DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(c, v, active) \
{ \
	static FProperty* sp##v = GetReplicatedProperty(StaticClass(), c::StaticClass(), TEXT(#v)); \
	for (int32 i = 0; i < sp##v->ArrayDim; i++) \
	{ \
		ChangedPropertyTracker.SetCustomIsActiveOverride(this, sp##v->RepIndex + i, active); \
	} \
}

        bool EnableReplicate = IsReplicatingMovement();
        if (!EnableReplicate)
        {
            // 因为父类里已经设置过这俩的active属性，所以这里只需要在!IsReplicatingMovement设置即可
            DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(AActor, AttachmentReplication, false);
            DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, RepRootMotion, false);
        }

        DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, RepRootMotion, EnableReplicate);
        DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, ReplicatedBasedMovement, EnableReplicate);
        DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, ReplicatedServerLastTransformUpdateTimeStamp, EnableReplicate);
        DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, ReplicatedMovementMode, EnableReplicate);
        DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, bIsCrouched, EnableReplicate);
        DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, bProxyIsJumpForceApplied, EnableReplicate);
        DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, AnimRootMotionTranslationScale, EnableReplicate);
        DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK(ACharacter, ReplayLastTransformUpdateTimeStamp, EnableReplicate);

#undef DOREPLIFETIME_ACTIVE_OVERRIDE_NO_CHECK
    }
}

void AKMCharacter::Destroyed()
{
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    if (Game)
    {
        Game->GetKMDelegateManager()->Actor->OnActorDestroyed.Broadcast(this, GetUniqueID(), LogicInstanceId);
    }
    Super::Destroyed();
}

void AKMCharacter::OnRep_HitInfo()
{
    OnRepHitInfo.Broadcast(this, HitInfo.ActualDamage,
        HitInfo.Instigator.Get(), HitInfo.DamageCauser.Get(), HitInfo.DamageTypeClass);
}

void AKMCharacter::FellOutOfWorld(const class UDamageType& dmgType)
{
    if (HasAuthority() || GetLocalRole() == ROLE_None)
    {
        UGameEngineExt* Game = UGameEngineExt::Get(this);
        if (Game)
        {
            Game->GetKMDelegateManager()->Actor->OnPawnFellOutOfWorld.Broadcast(this, GetUniqueID(), GetLogicInstanceId());
        }
    }

    //上层逻辑来处理。
    //Super::FellOutOfWorld(dmgType);
}

void AKMCharacter::OutsideWorldBounds()
{
    if (HasAuthority() || GetLocalRole() == ROLE_None)
    {
        UGameEngineExt* Game = UGameEngineExt::Get(this);
        if (Game)
        {
            Game->GetKMDelegateManager()->Actor->OnPawnFellOutOfWorld.Broadcast(this, GetUniqueID(), GetLogicInstanceId());
        }
    }

    //上层逻辑来处理。
    //Super::OutsideWorldBounds();
}

// significance
void AKMCharacter::RegisterToSignificance()
{
#if PIR_USE_SIGNIFICANCE
	USignificanceManager::Get(GetWorld())->RegisterObject(this, SignificanceTag,
		Impl->SignificanceFunction, USignificanceManager::EPostSignificanceType::Sequential, Impl->PostSignificanceFunction);
	UE_LOG(KMCharacterLog, Log, TEXT("[PIR] RegisterToSignificance Finished : %s."), *GetPathName());
#endif
}

void AKMCharacter::UnRegisterFromSignificance()
{
#if PIR_USE_SIGNIFICANCE
	USignificanceManager::Get(GetWorld())->UnregisterObject(this);
	UE_LOG(KMCharacterLog, Log, TEXT("[PIR] UnRegisterFromSignificance Finished : %s."), *GetPathName());
#endif
}

void AKMCharacter::HideComponentsInGame(bool Flag)
{
	check(false);
	SetHideActorComsInGame(Flag);
	SetActorHiddenInGame(Flag);
}

int AKMCharacter::GetCharacterDrawDis()
{
	return CVarKMCharacterDrawDis.GetValueOnGameThread();
}


void AKMCharacter::ResetSkeletalMeshComponentDrawDistance()
{
	UEngineExtActorShell::ResetDrawDistanceWithCharacterValue(this);
}
// ~significance

void AKMCharacter::SetReplicateMovement(bool bInReplicateMovement)
{
    Super::SetReplicateMovement(bInReplicateMovement);

    VerifyMovementSyncChange();
}

void AKMCharacter::PostNetReceive()
{
    Super::PostNetReceive();

    VerifyMovementSyncChange();
}

void AKMCharacter::VerifyMovementSyncChange()
{
    if (EnableAttachmentAndMovementRPCDependingOnReplicateMovement)
    {
        if (auto Component = Cast<UKMCharacterMovementComponent>(GetCharacterMovement()))
        {
            Component->SetMovementSyncEnabled(IsReplicatingMovement());
        }
    }
}