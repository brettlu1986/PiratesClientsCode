// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/ReplicatedProtoPropertyComponent.h"
#include "Common.h"
#include "Util/LuaTableRef.h"
#include "ProtobufCodec.h"
#include "Util/MessageLuaUtil.h"
#include "Game/GameCommon.h"
#include "RPCNetworkManager.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Shell/EngineExtActorShell.h"


DEFINE_LOG_CATEGORY_STATIC(ReplicatedProtoPropertyComponentLog, Log, All)

// Header :
// Count :多少个replicate 包
// Offset0  : 起始索引
// Size0    : 大小
// ....
// OffsetN
// SizeN

class FProtoPropertyRawHeaderWriter
{
public:
    FProtoPropertyRawHeaderWriter(TArray<uint8>& InData)
        : RawData(&InData)
    {
        check(sizeof(uint32) == 4);
        check(RawData);        
    }
    int GetCount()
    {
        check(RawData->Num());
        return *(uint32*)&RawData->GetData()[0];
    }
    void SetCount(uint32 iCount)
    {
        RawData->Empty(0);
        RawData->AddUninitialized(4*(iCount*2 + 1));
        FMemory::Memcpy((void*)&RawData->GetData()[0], (void*)&iCount, 4);
    }
    void SetDataInfo(int iIndex, uint32 Offset, uint32 DataSize)
    {
        check(iIndex >= 0 && iIndex < GetCount());
        int iStartIndex = 4 + iIndex * 8;
        FMemory::Memcpy((void*)&RawData->GetData()[iStartIndex], (void*)&Offset, 4);
        FMemory::Memcpy((void*)&RawData->GetData()[iStartIndex + 4], (void*)&DataSize, 4);
    }
private:
    TArray<uint8>* RawData;    
};

class FProtoPropertyRawHeaderReader
{
public:
    FProtoPropertyRawHeaderReader(const TArray<uint8>& InData)
        : RawData(&InData)
    {
        check(sizeof(uint32) == 4);
        check(RawData);
    }
    int GetCount()
    {
        check(RawData->Num());
        return *(uint32*)&RawData->GetData()[0];
    }
    int GetOffset(int iIndex)
    {
        check(iIndex >= 0 && iIndex < GetCount());
        return *(uint32*)&RawData->GetData()[4 + iIndex * 8];
    }
    int GetDataSize(int iIndex)
    {
        check(iIndex >= 0 && iIndex < GetCount());
        return *(uint32*)&RawData->GetData()[4 + iIndex * 8 + 4];
    }
private:
    const TArray<uint8>* RawData;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////
UReplicatedProtoPropertyComponent::UReplicatedProtoPropertyComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , Codec(nullptr)
    , bMulticastToClient(true)
    , bSaveRawData(false)
    , bReplicateToClient(true)
{
    PrimaryComponentTick.bCanEverTick = true;
}

void UReplicatedProtoPropertyComponent::TickComponent(float DeltaSeconds, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaSeconds, TickType, ThisTickFunction);
    if (bReplicateToClient)
    {
        ReplicateNow();
    }
}

void UReplicatedProtoPropertyComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    UndefineAllPropeties();
    Super::EndPlay(EndPlayReason);
}

ProtobufCodec* UReplicatedProtoPropertyComponent::GetCodec()
{
    if (!Codec.IsValid())
    {
        Codec = UGameCommon::Get(this)->GetRPCNetworkManager()->GetCodec();
    }
    return Codec.Pin().Get();
}

bool UReplicatedProtoPropertyComponent::DefineProperty(const FName& ProtoName)
{
    for (int ii=0; ii<Properties.Num(); ii++)
    {
        if (Properties[ii]->ProtoName == ProtoName)
        {
            UE_LOG(ReplicatedProtoPropertyComponentLog, Error, TEXT("UReplicatedProtoPropertyComponent::DefineProperty duilicated %s"), *ProtoName.ToString());
            return false;
        }
    }

    UReplicatedProtoPropertyComponent::FPropertyRawData* Data = new UReplicatedProtoPropertyComponent::FPropertyRawData();
    Data->ProtoName = ProtoName;
    Data->bDirty = false;
    Properties.Add(Data);
    return true;
}

bool UReplicatedProtoPropertyComponent::UndefineProperty(const FName& ProtoName)
{
    FPropertyRawData* RawData = nullptr;
    for (int ii = 0; ii < Properties.Num(); ii++)
    {
        RawData = Properties[ii];
        if (RawData->ProtoName == ProtoName)
        {
            for (int jj=0; jj<RepOrder.Num(); jj++)
            {
                if (RepOrder[jj] == RawData)
                {
                    RepOrder.RemoveAt(jj);
                    break;
                }
            }
            Properties.RemoveAt(ii);
            delete RawData;
            return true;
        }
    }
    return true;
}

bool UReplicatedProtoPropertyComponent::SetPropertyValue(const FName& ProtoName, ULuaTableRef* TableRef)
{
    FPropertyRawData* RawData = nullptr;
    for (int ii = 0; ii < Properties.Num(); ii++)
    {
        if (Properties[ii]->ProtoName == ProtoName)
        {
            RawData = Properties[ii];
            break;
        }
    }
    if (RawData == nullptr)
    {
        UE_LOG(ReplicatedProtoPropertyComponentLog, Error, TEXT("UReplicatedProtoPropertyComponent::SetPropertyValue failed, can not find %s."), *ProtoName.ToString());
        return false;
    }
    
    if (RawData->bDirty)
    {
        UE_LOG(ReplicatedProtoPropertyComponentLog, Log, TEXT("UReplicatedProtoPropertyComponent::SetPropertyValue duplicated in same tick, Actor[%d], ProtoName[%s]"), 
            GetOwner()->GetUniqueID(), *ProtoName.ToString());
    }

    // TODO:当同一针一直设时，这里比较费
    FString MessageType = ProtoName.ToString();
    if (!FMessageLuaUtil::LuaTableToArrayData(GetCodec(), MessageType, LUA_TABLE_REF_U2F(TableRef), nullptr, RawData->RawProtoData))
    {
        UE_LOG(ReplicatedProtoPropertyComponentLog, Error, TEXT("UReplicatedProtoPropertyComponent::SetPropertyValue failed, can not convert data %s."), *ProtoName.ToString());
        return false;
    }
    RawData->bDirty = true;

    for (int ii=0; ii<RepOrder.Num(); ii++)
    {
        if (RepOrder[ii] == RawData)
        {
            RepOrder.RemoveAt(ii);
            break;
        }
    }
    RepOrder.Add(RawData);

    return true;
}

void UReplicatedProtoPropertyComponent::ConstructRawData(TArray<uint8>& OutData)
{
    // 先收集个数
    int iCount = RepOrder.Num();
    if (iCount == 0)
    {
        return;
    }

    // 拼data
    int iDirtyIndex = 0;    
    FProtoPropertyRawHeaderWriter HeaderWriter(OutData);
    HeaderWriter.SetCount(iCount);
    for (int ii = 0; ii < iCount; ii++)
    {
        FPropertyRawData* RawData = RepOrder[ii];
        check(RawData->bDirty);
        if (RawData->RawProtoData.Num())
        {
            HeaderWriter.SetDataInfo(iDirtyIndex++, (uint32)OutData.Num(), RawData->RawProtoData.Num());
            OutData.Append(RawData->RawProtoData);
            if (!bSaveRawData)
            {
                RawData->RawProtoData.SetNumUnsafeInternal(0);
            }
        }
        RawData->bDirty = false;
    }
    RepOrder.Empty();
}

void UReplicatedProtoPropertyComponent::ReplicateNow()
{
    int iCount = RepOrder.Num();
    if (iCount == 0)
    {
        return;
    }

    static TArray<uint8> Data;
    Data.SetNumUnsafeInternal(0);
    ConstructRawData(Data);

    UE_LOG(ReplicatedProtoPropertyComponentLog, Log, TEXT("ReplicateNow name [%s] netguid: %d, data size: %d, multicast: %d"),
        *GetOwner()->GetName(),
        UEngineExtActorShell::GetActorNetGuid(GetOwner()),
        Data.Num(),
        bMulticastToClient ?1:0);

    if (bMulticastToClient)
    {
        ClientReceivedMulticastData(Data);
    }
    else
    {
        ClientReceivedData(Data);
    }   
}

void UReplicatedProtoPropertyComponent::ReplicateNowByType(bool bMulticast)
{
    bool bOldType = bMulticastToClient;
    bMulticastToClient = bMulticast;
    ReplicateNow();
    bMulticastToClient = bOldType;
}

void UReplicatedProtoPropertyComponent::MarkAllNeedReplicate()
{
    RepOrder.Empty();
    int iCount = Properties.Num();
    for (int ii = 0; ii < iCount; ii++)
    {
        FPropertyRawData* RawData = Properties[ii];
        if (RawData->RawProtoData.Num() > 0)
        {
            RepOrder.Add(RawData);
            RawData->bDirty = true;
        }        
    }
}

void UReplicatedProtoPropertyComponent::UndefineAllPropeties()
{
    for (int ii = 0; ii < Properties.Num(); ii++)
    {
        delete Properties[ii];
    }
    Properties.Empty();
    RepOrder.Empty();    
}

bool UReplicatedProtoPropertyComponent::ClientReceivedData_Validate(const TArray<uint8>& Data)
{
    return Data.Num() > 0;
}

void UReplicatedProtoPropertyComponent::ClientReceivedData_Implementation(const TArray<uint8>& Data)
{
    if (!UKismetSystemLibrary::IsDedicatedServer(this))
    {
        ProcessRecvData(Data);
    }    
}

bool UReplicatedProtoPropertyComponent::ClientReceivedMulticastData_Validate(const TArray<uint8>& Data)
{
    return Data.Num() > 0;
}

void UReplicatedProtoPropertyComponent::ClientReceivedMulticastData_Implementation(const TArray<uint8>& Data)
{
    if (!UKismetSystemLibrary::IsDedicatedServer(this))
    {
        ProcessRecvData(Data);
    }    
}

void UReplicatedProtoPropertyComponent::ProcessRecvData(const TArray<uint8>& Data)
{
    auto Decoder = GetCodec();
    if (Decoder == nullptr)
    {
        UE_LOG(ReplicatedProtoPropertyComponentLog, Error, TEXT("UReplicatedProtoPropertyComponent::ClientReceivedData failed, has no codec."));
        return;
    }

    URPCNetworkManager* NetworkManager = UGameCommon::Get(this)->GetRPCNetworkManager();
    FProtoPropertyRawHeaderReader HeaderReader(Data);
    int iCount = HeaderReader.GetCount();
    for (int ii = 0; ii < iCount; ii++)
    {
        int iOffset = HeaderReader.GetOffset(ii);
        int iDataSize = HeaderReader.GetDataSize(ii);
        check(iOffset >= 0 && iOffset < Data.Num());
        check(iDataSize < Data.Num());

        auto Message = Decoder->Decode(&Data[iOffset], iDataSize);
        if (Message == nullptr)
        {
            UE_LOG(ReplicatedProtoPropertyComponentLog, Error, TEXT("UReplicatedProtoPropertyComponent::Decode failed."));
            continue;
        }

        NetworkManager->OnMessage(GetOwner()->GetUniqueID(), Message);
        Decoder->DestroyMessage(Message);
    }
}