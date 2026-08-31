// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "ActorDelegate.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnKMActorBeginPlay, AActor*, Actor, uint32, UniqueId, int, InstanceId);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnKMActorEndPlay, AActor*, Actor, uint32, UniqueId, int, InstanceId);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnActorChannelOpen, AActor*, Actor, uint32, UniqueId, int, InstanceId);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnActorDestroyed, AActor*, Actor, uint32, UniqueId, int, InstanceId);

UCLASS()
class ENGINEEXT_API UActorDelegate : public UObject
{
    GENERATED_BODY()

public:
    UPROPERTY()
    FOnKMActorBeginPlay OnPawnPreBeginPlay;

    UPROPERTY()
    FOnKMActorBeginPlay OnPawnPostBeginPlay;

    UPROPERTY()
    FOnKMActorEndPlay OnPawnEndPlay;

    UPROPERTY()
    FOnKMActorBeginPlay OnControllerPreBeginPlay;

    UPROPERTY()
    FOnKMActorBeginPlay OnControllerPostBeginPlay;

    UPROPERTY()
    FOnKMActorEndPlay OnControllerEndPlay;

    UPROPERTY()
    FOnActorChannelOpen OnActorChannelOpen;

    UPROPERTY()
    FOnActorDestroyed OnActorDestroyed;

    UPROPERTY()
    FOnKMActorEndPlay OnPawnFellOutOfWorld;

    UPROPERTY()
    FOnKMActorBeginPlay OnPawnLeavingGame;
};
