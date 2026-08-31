// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Delegates/ClientDelegateManager.h"
#include "Client.h"
#include "Game/Delegates/ClientSdkDelegate.h"
#include "Game/Delegates/GVoiceSdkNotifyDelegate.h"

void UClientDelegateManager::Init()
{
    Super::Init();
    SdkDelegate = NewObject<UClientSdkDelegate>(this);
    GVoiceSdkNotifyDelegate = NewObject<UGVoiceSdkNotifyDelegate>(this);
}