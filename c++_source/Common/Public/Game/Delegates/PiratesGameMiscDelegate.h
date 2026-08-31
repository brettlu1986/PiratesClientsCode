#pragma once

#include "PiratesGameMiscDelegate.generated.h"

UCLASS()
class COMMON_API UPiratesGameMiscDelegate : public UObject
{
    GENERATED_BODY()

	DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnActorEnterArea, int, LogicInstanceId, int32, AreaId);
	DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnActorLeaveArea, int, LogicInstanceId, int32, AreaId);

    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnActorEnterTriggerGroup, int32, GroupId, uint32, UniqueId, uint32, TargetUniqueId);
    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnActorLeaveTriggerGroup, int32, GroupId, uint32, UniqueId, uint32, TargetUniqueId);

    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnActorEnterVolume, uint32, UniqueId, const TArray<int>&, VolumeIds);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnActorLeaveVolume, uint32, UniqueId, const TArray<int>&, VolumeIds);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnActorGridTypeChanged, uint32, UniqueId, EPiratesGridRegionType, Type);
	DECLARE_DYNAMIC_DELEGATE(FOnAbortNavMove);
	DECLARE_DYNAMIC_DELEGATE(FOnRequestExitGame);
	DECLARE_DYNAMIC_DELEGATE(FOnEnterCinematicMode);
	DECLARE_DYNAMIC_DELEGATE(FOnExitCinematicMode);
    DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnClientPlayerSelfReady);
	DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnSerializeNewActor, AActor*, Actor, uint32, UniqueId);

    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnParachutingEnd, uint32, UniqueId, bool, IsTransport, const FVector&, TransportLocation);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnParachutingReachSeaLevel, uint32, UniqueId);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnAirDropEnd, uint32, UniqueId);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnDoorSwitched, uint32, DoorUniqueId, uint32, CauserIdUniqueId);

    DECLARE_DYNAMIC_DELEGATE_FiveParams(FOnBombTriggerCreated, int32, CauseId, int32, BuffId, uint32, UniqueId, const FVector&, Location, float, Radius);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnBombTriggerPreDestroy, uint32, UniqueId);

    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnPlaySound, uint8, SoundType, const FVector&, Location, uint32, SoundSourceUniqueID);
    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnHitDestructibleObject, AActor*, Actor, int32, Damage, UObject*, DamageType);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnMeshChangedDestructibleObject, AActor*, Actor, int32, MeshIndex);

	DECLARE_DYNAMIC_DELEGATE(FOnRepPropTypeMismatch);

    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnActorEnterTrigger, int32, OwnerUniqueId, int32, UniqueId);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnActorLeaveTrigger, int32, OwnerUniqueId, int32, UniqueId);

    DECLARE_DYNAMIC_DELEGATE(FOnApplicationWillDeactivateDelegate);
    DECLARE_DYNAMIC_DELEGATE(FOnApplicationWillEnterBackgroundDelegate);
    DECLARE_DYNAMIC_DELEGATE(FOnApplicationHasEnteredForegroundDelegate);

	DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnAnyUITouchEnded, const FGeometry&, Geometry, const FPointerEvent&, PointerEvent);

    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnActorInhibitAttack, AActor*, Actor, bool, bInhibit, float, Distance);
    DECLARE_DYNAMIC_DELEGATE(FOnUninitLua);

    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnIpConnectionTimeout, bool, bTimeout);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnRepControllerPropertyCRC, const TArray<int>&, CRCs);

    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnSpawnSmoke, const FVector&, Location, float, Radius, float, ExistTime);

	DECLARE_DYNAMIC_DELEGATE(FOnViewportResized);

public:
    UPROPERTY()
    FOnActorEnterVolume OnActorEnterVolume;

    UPROPERTY()
    FOnActorLeaveVolume OnActorLeaveVolume;

    UPROPERTY()
    FOnActorGridTypeChanged OnActorGridTypeChanged;

    UPROPERTY()
    FOnActorEnterArea OnActorEnterArea;

    UPROPERTY()
    FOnActorLeaveArea OnActorLeaveArea;

    UPROPERTY()
    FOnActorEnterTriggerGroup OnActorEnterTriggerGroup;

    UPROPERTY()
    FOnActorLeaveTriggerGroup OnActorLeaveTriggerGroup;

	UPROPERTY()
	FOnAbortNavMove OnAbortNavMove;

	UPROPERTY()
	FOnRequestExitGame OnRequestExitGame;

	UPROPERTY()
	FOnEnterCinematicMode OnEnterCinematicMode;

	UPROPERTY()
	FOnExitCinematicMode OnExitCinematicMode;

	UPROPERTY()
	FOnSerializeNewActor OnSerializeNewActor;

    UPROPERTY()
    FOnParachutingEnd OnParachutingEnd;

    UPROPERTY()
    FOnParachutingReachSeaLevel OnParachutingReachSeaLevel;

    UPROPERTY()
    FOnAirDropEnd OnAirDropEnd;

    UPROPERTY()
    FOnDoorSwitched OnDoorSwitched;

    UPROPERTY()
    FOnBombTriggerCreated OnBombTriggerCreated;

    UPROPERTY()
    FOnBombTriggerPreDestroy OnBombTriggerPreDestroy;

    UPROPERTY(BlueprintReadWrite, BlueprintAssignable)
    FOnClientPlayerSelfReady OnClientPlayerSelfReady;

    UPROPERTY()
    FOnPlaySound OnPlaySound;

    UPROPERTY()
    FOnHitDestructibleObject OnHitDestructibleObject;

    UPROPERTY()
    FOnMeshChangedDestructibleObject OnMeshChangedDestructibleObject;

	UPROPERTY()
	FOnRepPropTypeMismatch OnRepPropTypeMismatch;

    UPROPERTY()
    FOnActorEnterTrigger OnActorEnterTrigger;
    UPROPERTY()
    FOnActorLeaveTrigger OnActorLeaveTrigger;

    UPROPERTY()
    FOnApplicationWillDeactivateDelegate OnApplicationWillDeactivateDelegate;

    UPROPERTY()
    FOnApplicationWillEnterBackgroundDelegate OnApplicationWillEnterBackgroundDelegate;

    UPROPERTY()
    FOnApplicationHasEnteredForegroundDelegate OnApplicationHasEnteredForegroundDelegate;

	UPROPERTY()
	FOnAnyUITouchEnded OnAnyUITouchEnded;

    UPROPERTY()
    FOnActorInhibitAttack OnActorInhibitAttack;

    UPROPERTY()
    FOnUninitLua OnUninitLua;

    UPROPERTY()
    FOnIpConnectionTimeout OnIpConnectionTimeout;

    UPROPERTY()
    FOnRepControllerPropertyCRC OnRepControllerPropertyCRC;

    UPROPERTY()
    FOnSpawnSmoke OnSpawnSmoke;

	UPROPERTY()
    FOnViewportResized OnViewportResized;

public:

	UFUNCTION(BlueprintCallable, Category = "Misc")
	void AbortNavMove()
	{
		if (OnAbortNavMove.IsBound())
		{
			OnAbortNavMove.Execute();
		}
	};

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void ParachutingEnd(AActor* Actor, bool IsTransport, const FVector& TransportLocation)
    {
        if (Actor && OnParachutingEnd.IsBound())
        {
            OnParachutingEnd.Execute(Actor->GetUniqueID(), IsTransport, TransportLocation);
        }
    };
    
    UFUNCTION(BlueprintCallable, Category = "Misc")
    void ParachutingReachSeaLevel(AActor* Actor)
    {
        if (Actor && OnParachutingReachSeaLevel.IsBound())
        {
            OnParachutingReachSeaLevel.Execute(Actor->GetUniqueID());
        }
    };

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void AirDropEnd(AActor* Actor)
    {
        if (Actor && OnAirDropEnd.IsBound())
        {
            OnAirDropEnd.Execute(Actor->GetUniqueID());
        }
    };

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void DoorSwitched(AActor* Actor, int32 CauserId)
    {
        if (Actor && OnDoorSwitched.IsBound())
        {
            OnDoorSwitched.Execute(Actor->GetUniqueID(), CauserId);
        }
    }

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void BombTriggerCreated(AActor* Actor, int32 CauserId, int32 BuffId, float Radius)
    {
        if (Actor && OnBombTriggerCreated.IsBound())
        {
            OnBombTriggerCreated.Execute(CauserId, BuffId, Actor->GetUniqueID(), Actor->GetActorLocation(), Radius);
        }
    }
    UFUNCTION(BlueprintCallable, Category = "Misc")
    void BombTriggerPreDestroy(AActor* Actor)
    {
        if (Actor && OnBombTriggerPreDestroy.IsBound())
        {
            OnBombTriggerPreDestroy.Execute(Actor->GetUniqueID());
        }
    }

    UFUNCTION(BlueprintCallable, Category = "Misc")
	void EnterCinematicMode()
	{
		if (OnEnterCinematicMode.IsBound())
		{
			OnEnterCinematicMode.Execute();
		}
	};

	UFUNCTION(BlueprintCallable, Category = "Misc")
	void ExitCinematicMode()
	{
		if (OnExitCinematicMode.IsBound())
		{
			OnExitCinematicMode.Execute();
		}
	};

	UFUNCTION(BlueprintCallable, Category = "Misc")
    void PlaySound(uint8 SoundType, const FVector& Location, AActor* SoundSource)
    {
        if (OnPlaySound.IsBound())
        {
			uint32 SoundSourceUniqueID = 0;
			if (SoundSource)
			{
				SoundSourceUniqueID = SoundSource->GetUniqueID();
			}
            OnPlaySound.Execute(SoundType, Location, SoundSourceUniqueID);
        }
    };

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void HitDestructibleObject(AActor* Actor, int32 Damage, UObject* DamageType)
    {
        if (Actor  && DamageType && OnHitDestructibleObject.IsBound())
        {
            OnHitDestructibleObject.Execute(Actor, Damage, DamageType);
        }
    };

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void MeshChangeDestructibleObject(AActor* Actor, int32 MeshIndex)
    {
        if (Actor)
        {
            OnMeshChangedDestructibleObject.Execute(Actor, MeshIndex);
        }
    };

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void ActorEnterTrigger(AActor* ActorOwner, AActor* Actor)
    {
        if (Actor && ActorOwner && OnActorEnterTrigger.IsBound())
        {
            OnActorEnterTrigger.Execute(ActorOwner->GetUniqueID(), Actor->GetUniqueID());
        }
    }

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void ActorLeaveTrigger(AActor* ActorOwner, AActor* Actor)
    {
        if (Actor && ActorOwner && OnActorLeaveTrigger.IsBound())
        {
            OnActorLeaveTrigger.Execute(ActorOwner->GetUniqueID(), Actor->GetUniqueID());
        }
    }

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void OnRecvRepControllerPropertyCRC(const TArray<int>& CRCs)
    {
        OnRepControllerPropertyCRC.ExecuteIfBound(CRCs);
    }

    UFUNCTION(BlueprintCallable, Category = "Misc")
    void SpawnSmoke(const FVector& Location, float Radius, float ExistTime)
    {
        OnSpawnSmoke.ExecuteIfBound(Location, Radius, ExistTime);
    }

	void ViewportResized(FViewport* Viewport, uint32 Unused)
	{
        OnViewportResized.ExecuteIfBound();
	}

public:
    void Init();

    static void OnApplicationWillDeactivateHandle();
    static void OnApplicationWillEnterBackgroundHandle();
    static void OnApplicationHasEnteredForegroundHandle();
};