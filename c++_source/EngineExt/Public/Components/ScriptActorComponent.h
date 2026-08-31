// Copyright 1998-2016 Epic Games, Inc. All Rights Reserved.

#pragma once
//#include "ScriptActorComponent.generated.h"

//UCLASS()
//class ENGINEEXT_API UScriptActorComponent : public UActorComponent
//{
//    GENERATED_UCLASS_BODY()
//public:
//	void OnActorChannelOpen(class FInBunch& InBunch, class UNetConnection* Connection);
//
//	void OnSerializeNewActor(class FOutBunch& OutBunch);
//
//    void PostNetInit();
//
//	void OnNetCleanup(class UNetConnection* Connection);
//
//    void OnActorBeginPlay();
//
//	const FNetworkGUID& GetNetworkGUID(bool bAutoAssign = true);
//
//    const FString& GetScriptType();
//
//    void SetScriptType(const FString& InScriptType);
//
//    void BroadcastOnActorSpawned();
//
//private:
//	FNetworkGUID NetworkGUID;
//    FString ScriptType;
//    bool HasScriptSpawned;
//    bool HasScriptBegunPlay;
//
//    void WriteCustomDataToBunch(class FOutBunch& OutBunch);
//    void ReadCustomDataFromBunch(class FInBunch& InBunch);
//
//    void WriteEssentialDataToBunch(class FOutBunch& OutBunch);
//    void ReadEssentialDataToBunch(class FInBunch& InBunch);
//
//    class UKMDelegateManager* GetDelegateManager();
//
//    void RegisterOnEndPlayDelegate();
//    void RegisterOnDestroyedDelegate();
//};