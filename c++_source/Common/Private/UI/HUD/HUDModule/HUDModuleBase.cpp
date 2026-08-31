// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/HUD/HUDModule/HUDModuleBase.h"
#include "Common.h"

UHUDModuleBase::UHUDModuleBase(const FObjectInitializer& ObjectInitializer)
    : Super     (ObjectInitializer)
    , PiratesHUD(Cast<APiratesHUD>(GetOuter()))
{
}

UHUDModuleBase::~UHUDModuleBase()
{
}

void UHUDModuleBase::BeginPlay()
{
	ReceiveBeginPlay();
}

void UHUDModuleBase::Tick(float DeltaSeconds)
{
}

void UHUDModuleBase::DrawHUD(UCanvas *Canvas)
{
}
