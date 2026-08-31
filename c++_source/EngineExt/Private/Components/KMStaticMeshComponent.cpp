// Fill out your copyright notice in the Description page of Project Settings.

#include "KMStaticMeshComponent.h"
#include "EngineExt.h"

UKMStaticMeshComponent::UKMStaticMeshComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryComponentTick.bAllowTickOnDedicatedServer = true;
}