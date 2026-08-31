// Fill out your copyright notice in the Description page of Project Settings.

#include "KMSkeletalMeshComponent.h"
#include "EngineExt.h"

UKMSkeletalMeshComponent::UKMSkeletalMeshComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryComponentTick.bAllowTickOnDedicatedServer = true;
}