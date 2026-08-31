// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ServerJsonExportComponent.h"
#include "Common.h"


UServerJsonExportComponent::UServerJsonExportComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , ExportToLuaFile(false)
{
}

