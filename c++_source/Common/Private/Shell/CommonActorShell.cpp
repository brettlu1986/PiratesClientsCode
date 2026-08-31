// Fill out your copyright notice in the Description page of Project Settings.

#include "Shell/CommonActorShell.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Game/Actor/KMScriptActorSpawnContext.h"
#include "Network/ReplicatedProtoPropertyComponent.h"
#include "TabFile/GameAvatarPartTabFile.h"

#include "ProtobufDispatcher.h"
#include "ProtobufCodec.h"
#include "Network/ProtobufMessageRef.h"
#include "Util/LuaTableRef.h"
#include "Util/MessageLuaUtil.h"

#include "KMActor.h"
#include "KMCharacter.h"
#include "KMPlayerController.h"
#include "KMPawn.h"


DECLARE_LOG_CATEGORY_CLASS(LogCommonActorShell, Display, All);

UCommonActorShell::UCommonActorShell(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , ActorSpawnContext(nullptr)
{
    MsgRef = NewObject<UProtobufMessageRef>();
}

void UCommonActorShell::Init(FKMScriptActorSpawnContext* Context, TWeakPtr<ProtobufCodec> InCodec)
{
    ActorSpawnContext = Context;
    Codec = InCodec;
}

void UCommonActorShell::Uninit()
{
    if (Codec.IsValid() && MsgRef->Message)
    {
        Codec.Pin()->DestroyMessage(MsgRef->Message);
        MsgRef->Message = nullptr;
    }
}

void UCommonActorShell::SetActorSpawnInitData(const FString& ProtoName, ULuaTableRef* TableRef, 
    int InstanceId, bool BeginPlayManually)
{
    check(ActorSpawnContext);
    if (ProtoName.Len() > 0)
    {
        FMessageLuaUtil::LuaTableToArrayData(Codec.Pin().Get(), ProtoName, LUA_TABLE_REF_U2F(TableRef), nullptr, ActorSpawnContext->GetData());
    }    
    ActorSpawnContext->SetInstanceId(InstanceId);
    ActorSpawnContext->SetBeginPlayManually(BeginPlayManually);
}

void UCommonActorShell::ResetActorSpawnInitData()
{
    if (ActorSpawnContext)
    {
        ActorSpawnContext->Reset();
    }
}

UProtobufMessageRef* UCommonActorShell::GetActorSpawnInitData(AActor* Actor)
{   
    const TArray<uint8>* pInitData = nullptr;
    if (AKMCharacter* Character = Cast<AKMCharacter>(Actor))
    {
        pInitData = &Character->GetInitProtoData();
    }
    else if (AKMPawn* Pawn = Cast<AKMPawn>(Actor))
    {
        pInitData = &Pawn->GetInitProtoData();
    }
    else if (AKMActor* KMActor = Cast<AKMActor>(Actor))
    {
        pInitData = &KMActor->GetInitProtoData();
    }
    else if (AKMPlayerController* Controller = Cast<AKMPlayerController>(Actor))
    {
        pInitData = &Controller->GetInitProtoData();
    }

    if (pInitData && pInitData->Num() > 0)
    {
        return RawDataToMessageRef(*pInitData);
    }
    return nullptr;
}

void UCommonActorShell::SetControllerReplicatedInitData(AKMPlayerController* Controller,
    const FString& ProtoName, ULuaTableRef* TableRef, int LogicInstanceId)
{
    if (Controller)
    {
        if (ProtoName.Len() > 0)
        {
            FMessageLuaUtil::LuaTableToArrayData(Codec.Pin().Get(), ProtoName, LUA_TABLE_REF_U2F(TableRef), nullptr, Controller->GetInitProtoData());
        }
        Controller->SetLogicInstanceId(LogicInstanceId);
    }
}

UProtobufMessageRef* UCommonActorShell::RawDataToMessageRef(const TArray<uint8>& RawData)
{
    if (!Codec.IsValid())
    {
        return nullptr;
    }

    if (MsgRef->Message)
    {
        Codec.Pin()->DestroyMessage(MsgRef->Message);
        MsgRef->Message = nullptr;
    }

    const int32 DataSize = RawData.Num();
    auto Message = Codec.Pin()->Decode(RawData.GetData(), DataSize);
    if (Message == nullptr)
    {       
        UE_LOG(LogCommonActorShell, Error, TEXT("UCommonActorShell [RECV] %d Unknown message"), DataSize);
        return nullptr;
    }

    MsgRef->Message = Message;
    return MsgRef;
}

bool UCommonActorShell::DefineReplicatedProperty(AActor* Actor, const FName& ProtoName)
{
    auto Component = Actor->FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {
        return Component->DefineProperty(ProtoName);
    }
    
    UE_LOG(LogCommonActorShell, Error, TEXT("UCommonActorShell::DefineActorProperty failed, the actor has no UReplicatedProtoPropertyComponent. ActorUniqueId[%d], ProtoName[%s]"), 
        Actor->GetUniqueID(), *ProtoName.ToString());
    return false;
}

bool UCommonActorShell::UndefineReplicatedProperty(AActor* Actor, const FName& ProtoName)
{
    auto Component = Actor->FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {
        return Component->UndefineProperty(ProtoName);
    }

    UE_LOG(LogCommonActorShell, Error, TEXT("UCommonActorShell::UndefineActorProperty failed, the actor has no UReplicatedProtoPropertyComponent. ActorUniqueId[%d], ProtoName[%s]"),
        Actor->GetUniqueID(), *ProtoName.ToString());
    return false;
}

bool UCommonActorShell::SetReplicatedPropertyValue(AActor* Actor, const FName& ProtoName, ULuaTableRef* TableRef)
{
    auto Component = Actor->FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {
        return Component->SetPropertyValue(ProtoName, TableRef);
    }

    UE_LOG(LogCommonActorShell, Error, TEXT("UCommonActorShell::SetActorPropertyValue failed, the actor has no UReplicatedProtoPropertyComponent. ActorUniqueId[%d], ProtoName[%s]"),
        Actor->GetUniqueID(), *ProtoName.ToString());
    return false;
}

void UCommonActorShell::ReplicateActorPropertyNow(AActor* Actor)
{
    auto Component = Actor->FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {
        return Component->ReplicateNow();
    }

    UE_LOG(LogCommonActorShell, Error, TEXT("UCommonActorShell::ReplicateActorPropertyNow failed, the actor has no UReplicatedProtoPropertyComponent. ActorUniqueId[%d]"),
        Actor->GetUniqueID());
}

void UCommonActorShell::ReplicateActorPropertyNowByType(AActor* Actor, bool bMulticast)
{
    auto Component = Actor->FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {
        return Component->ReplicateNowByType(bMulticast);
    }

    UE_LOG(LogCommonActorShell, Error, TEXT("UCommonActorShell::ReplicateActorPropertyNow failed, the actor has no UReplicatedProtoPropertyComponent. ActorUniqueId[%d]"),
        Actor->GetUniqueID());
}

void UCommonActorShell::MarkAllActorPropertyReplicate(AActor* Actor)
{
    auto Component = Actor->FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {
        return Component->MarkAllNeedReplicate();
    }

    UE_LOG(LogCommonActorShell, Error, TEXT("UCommonActorShell::MarkAllActorPropertyReplicate failed, the actor has no UReplicatedProtoPropertyComponent. ActorUniqueId[%d]"),
        Actor->GetUniqueID());
}

void UCommonActorShell::UndefineAllReplicatedProperties(AActor* Actor)
{
    if (!Actor)
    {
        UE_LOG(LogCommonActorShell, Warning, TEXT("UCommonActorShell::UndefineAllReplicatedProperties failed, Actor nullptr."));
        return;
    }

    auto Component = Actor->FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {
        return Component->UndefineAllPropeties();
    }

    UE_LOG(LogCommonActorShell, Error, TEXT("UCommonActorShell::UndefineAllReplicatedProperties failed, the actor has no UReplicatedProtoPropertyComponent. ActorUniqueId[%d]"),
        Actor->GetUniqueID());
}

const FString& UCommonActorShell::FindAvatarPartData(int nPartId, int nDataIndex) const
{
    const FGameAvatarPartTabFileData* PartData = FGameAvatarPartTabFile::GetSingleton().Find(nPartId);
    if (PartData)
    {
        if (nDataIndex >= 0 && nDataIndex < PartData->Data.Num())
        {
            return PartData->Data[nDataIndex].Value;
        }
    }
    static FString None;
    return None;
}