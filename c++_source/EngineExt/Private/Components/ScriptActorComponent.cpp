// Copyright 1998-2016 Epic Games, Inc. All Rights Reserved.

#include "Components/ScriptActorComponent.h"
#include "EngineExt.h"
#include "Game/GameEngineExt.h"
#include "Game/Delegates/ActorDelegate.h"
#include "Game/Delegates/KMDelegateManager.h"
//
//typedef int8 ActorInitDataFlag;
//static ActorInitDataFlag ACTOR_INIT_DATA_FLAG_BEGIN = -1;
//static ActorInitDataFlag ACTOR_INIT_DATA_FLAG_END = -2;
//static ActorInitDataFlag ACTOR_INIT_DATA_FLAG_HAS_NEXT = -3;
//
//DEFINE_LOG_CATEGORY_STATIC(ScriptActorCompLog, Log, All);
//
//UScriptActorComponent::UScriptActorComponent(const FObjectInitializer& ObjectInitializer)
//    : Super(ObjectInitializer), HasScriptSpawned(false), HasScriptBegunPlay(false)
//{
//}
//
//const FString& UScriptActorComponent::GetScriptType()
//{
//    return ScriptType;
//}
//
//void UScriptActorComponent::SetScriptType(const FString& InScriptType)
//{
//    this->ScriptType = InScriptType;
//}
//
//void UScriptActorComponent::OnActorBeginPlay()
//{
//    if (!HasScriptSpawned || HasScriptBegunPlay)
//    {
//        return ;
//    }
//
//    AActor* Owner = GetOwner();
//    auto DelegateMgr = GetDelegateManager();
//    if (IsValid(DelegateMgr))
//    {
//        DelegateMgr->Actor->OnKMActorBeginPlay.ExecuteIfBound(Owner->GetUniqueID());
//    }
//    RegisterOnEndPlayDelegate();
//    HasScriptBegunPlay = true;
//}
//
//void UScriptActorComponent::RegisterOnEndPlayDelegate()
//{
//    AActor* Owner = GetOwner();
//    static FName Name_ProcessOnEndPlay = FName("ProcessOnEndPlay");
//    auto DelegateMgr = GetDelegateManager();
//    if (!Owner->OnEndPlay.Contains(DelegateMgr->Actor, Name_ProcessOnEndPlay))
//    {
//        FScriptDelegate Delegate;
//        Delegate.BindUFunction(DelegateMgr->Actor, Name_ProcessOnEndPlay);
//        Owner->OnEndPlay.Add(Delegate);
//    }
//}
//
//void UScriptActorComponent::RegisterOnDestroyedDelegate()
//{
//    AActor* Owner = GetOwner();
//    static FName Name_ProcessOnDestroyed = FName("ProcessOnDestroyed");
//    auto DelegateMgr = GetDelegateManager();
//    if (!Owner->OnDestroyed.Contains(DelegateMgr->Actor, Name_ProcessOnDestroyed))
//    {
//        FScriptDelegate Delegate;
//        Delegate.BindUFunction(DelegateMgr->Actor, Name_ProcessOnDestroyed);
//        Owner->OnDestroyed.Add(Delegate);
//    }
//}
//
//void UScriptActorComponent::OnActorChannelOpen(class FInBunch& InBunch, class UNetConnection* Connection)
//{
//    AActor* Owner = GetOwner();
//	if (!Owner->HasAuthority())
//	{
//        ActorInitDataFlag Flag;
//        InBunch << Flag;
//        if (ACTOR_INIT_DATA_FLAG_BEGIN == Flag)
//        {
//            ReadEssentialDataToBunch(InBunch);
//            //ReadCustomDataFromBunch(InBunch);
//        }
//	}
//}
//
//void UScriptActorComponent::OnSerializeNewActor(class FOutBunch& OutBunch)
//{
//    AActor* Owner = GetOwner();
//	if (Owner->HasAuthority())
//	{
//		
//		OutBunch << ACTOR_INIT_DATA_FLAG_BEGIN;
//		
//        WriteEssentialDataToBunch(OutBunch);
//        //WriteCustomDataToBunch(OutBunch);
//
//		//OutBunch << ACTOR_INIT_DATA_FLAG_END;
//	}
//}
//
//void UScriptActorComponent::PostNetInit()
//{
//    BroadcastOnActorSpawned();
//}
//
//void UScriptActorComponent::BroadcastOnActorSpawned()
//{
//    AActor* Owner = GetOwner();
//    auto DelegateMgr = GetDelegateManager();
//    if (IsValid(DelegateMgr))
//    {
//		RegisterOnDestroyedDelegate();
//        DelegateMgr->Actor->OnKMActorSpawned.ExecuteIfBound(Owner, Owner->GetUniqueID(), ScriptType);
//        HasScriptSpawned = true;
//    }
//}
//
//void UScriptActorComponent::WriteCustomDataToBunch(class FOutBunch& OutBunch)
//{
//    AActor* Owner = GetOwner();
//    auto DelegateMgr = GetDelegateManager();
//    auto InitData = DelegateMgr->Actor->OnInquiryActorInitData.Execute(Owner->GetUniqueID());
//    OutBunch << ACTOR_INIT_DATA_FLAG_HAS_NEXT;
//    OutBunch << const_cast<FString&>(InitData);
//}
//
//void UScriptActorComponent::ReadCustomDataFromBunch(class FInBunch& InBunch)
//{
//    AActor* Owner = GetOwner();
//    auto DelegateMgr = GetDelegateManager();
//    auto NetGuid = GetNetworkGUID(false);
//
//    ActorInitDataFlag Flag;
//    InBunch << Flag;
//    while (ACTOR_INIT_DATA_FLAG_HAS_NEXT == Flag)
//    {
//        FString ActorInitData;
//        InBunch << ActorInitData;
//        if (NetGuid.IsValid())
//        {
//            if (IsValid(DelegateMgr))
//            {
//                DelegateMgr->Actor->OnReceivedActorInitData.ExecuteIfBound(NetGuid.Value, ActorInitData);
//            }
//        }
//        else
//        {
//            UE_LOG(ScriptActorCompLog, Error, TEXT("OnActorChannelOpen FAILED! Invalid NetGUID in class %s."), *Owner->GetClass()->GetName());
//        }
//
//        InBunch << Flag;
//    }
//}
//
//void UScriptActorComponent::WriteEssentialDataToBunch(class FOutBunch& OutBunch)
//{
//    OutBunch << ScriptType;
//}
//
//void UScriptActorComponent::ReadEssentialDataToBunch(class FInBunch& InBunch)
//{
//    InBunch << ScriptType;
//}
//
//void UScriptActorComponent::OnNetCleanup(class UNetConnection* Connection)
//{
//
//}
//
//const FNetworkGUID& UScriptActorComponent::GetNetworkGUID(bool bAutoAssign/* = true*/)
//{
//    AActor* Owner = GetOwner();
//	if (!NetworkGUID.IsValid())
//	{
//		auto NetDriver = Owner->GetNetDriver();
//		if (NetDriver)
//		{
//			if (bAutoAssign)
//			{
//				NetworkGUID = NetDriver->GuidCache->GetOrAssignNetGUID(Owner);
//			}
//			else
//			{
//				NetworkGUID = NetDriver->GuidCache->GetNetGUID(Owner);
//			}
//		}
//		else
//		{
//			NetworkGUID = FNetworkGUID(1);
//		}
//	}
//	return NetworkGUID;
//}
//
//UKMDelegateManager* UScriptActorComponent::GetDelegateManager()
//{
//    AActor* Owner = GetOwner();
//    return UGameEngineExt::Get(Owner)->GetKMDelegateManager();
//}
