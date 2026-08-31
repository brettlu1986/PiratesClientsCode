// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/RPCNetworkManager.h"
#include "Common.h"
#include "Protobuf.h"
#include "Util/MessageLuaUtil.h"
#include "Network/ReplicatedProtoCallComponent.h"
#include "Misc/ScopeExit.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Util/LuaTableRef.h"
#include "Network/GameIpConnection.h"
#include "Network/GameIpNetDriver.h"

static const int32 RPC_BUFFER_SIZE = 0xffff;

DECLARE_STATS_GROUP(TEXT("RecvRPCMessage"), STATGROUP_RecvRPCMessage, STATCAT_Advanced);
DECLARE_LOG_CATEGORY_CLASS(LogRPCNetworkManager, Log, All);

static inline
UReplicatedProtoCallComponent* s_GetRPCComponent(AActor* Sender)
{
    if (Sender)
    {
        auto RPCComponent = Cast<UReplicatedProtoCallComponent>(Sender->GetComponentByClass(UReplicatedProtoCallComponent::StaticClass()));
        return RPCComponent;
    }

    return nullptr;
}

URPCNetworkManager::URPCNetworkManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , MaxTimeForPacketProcessing(0.005f)
    , QueueProcessFactor(10.0f)
    , EnableLimitPacketProcessing(true)    
{
}

void URPCNetworkManager::Init()
{
    Super::Init();
}

void URPCNetworkManager::Uninit()
{
    ClearPendingPackets();
    Super::Uninit();
}

void URPCNetworkManager::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);

    if (PendingPackets.Num() > 0 && EnableLimitPacketProcessing)
    {
        float RemainTime = MaxTimeForPacketProcessing;
        if (PendingPackets.Num() > QueueProcessFactor)
        {
            // 防止包越来越多
            RemainTime *= PendingPackets.Num() / QueueProcessFactor;
        }

        double StartTime = FPlatformTime::Seconds();
        //double Time1 = StartTime;
        while (PendingPackets.Num() > 0 && RemainTime > 0.0f)
        {
            auto Packet = PendingPackets[0];
            PendingPackets.RemoveAt(0);
            OnDataReceivedImp(Packet->SenderId, Packet->Data);
            PacketPool.Add(Packet);
            double NewTime = FPlatformTime::Seconds();
            RemainTime -= (float)(NewTime - StartTime);
            StartTime = NewTime;
        }
        //UE_LOG(LogTemp, Error, TEXT("Process packet time: %f ms"), (float)(FPlatformTime::Seconds() - Time1)*1000.0f);
    }    
}

UReplicatedProtoCallComponent* URPCNetworkManager::GetRPCComponent(AActor* Sender)
{
    if (Sender)
    {
        auto RPCComponent = Cast<UReplicatedProtoCallComponent>(Sender->GetComponentByClass(UReplicatedProtoCallComponent::StaticClass()));
        return RPCComponent;
    }

    return nullptr;
}

UReplicatedProtoCallComponent* URPCNetworkManager::GetClientRPCComponent()
{
    auto Sender = UGameplayStatics::GetPlayerController(this, 0);
    return s_GetRPCComponent(Sender);
}

UReplicatedProtoCallComponent* URPCNetworkManager::GetServerRPCComponent(uint32 SenderUniqueId)
{
    auto ObjItem = GUObjectArray.IndexToValidObject(SenderUniqueId, false);
    if (!ObjItem || !ObjItem->Object)
        return nullptr;

    auto ObjBase = ObjItem->Object;
    check(ObjBase->GetClass()->IsChildOf(UObject::StaticClass()));
    auto Obj = static_cast<UObject*>(ObjBase);
    auto Sender = Cast<AActor>(Obj);
    return s_GetRPCComponent(Sender);
}

UReplicatedProtoCallComponent* URPCNetworkManager::GetMulticastRPCComponent()
{
    auto Sender = UGameplayStatics::GetGameState(this);
    return s_GetRPCComponent(Sender);
}

void URPCNetworkManager::OnDataReceived(uint32 SenderUniqueId, const TArray<uint8>& Data)
{
    if (EnableLimitPacketProcessing)
    {
        if (PacketPool.Num() == 0)
        {
            const int StepCount = 16;
            for (int ii = 0; ii < StepCount; ii++)
            {
                PacketPool.Emplace(new FPendingData());
            }
        }

        FPendingData* PendingInfo = PacketPool.Pop(false);
        PendingInfo->SenderId = SenderUniqueId;
        PendingInfo->Data.Reserve(Data.Num());
        PendingInfo->Data.SetNumUninitialized(Data.Num(), false);
        FMemory::Memcpy(PendingInfo->Data.GetData(), Data.GetData(), Data.Num());
        PendingPackets.Add(PendingInfo);
    }
    else
    {
        OnDataReceivedImp(SenderUniqueId, Data);
    }
}

void URPCNetworkManager::OnDataReceivedImp(uint32 SenderUniqueId, const TArray<uint8>& Data)
{
    const int32 DataSize = Data.Num();
    auto Message = Codec->Decode(Data.GetData(), DataSize);
    if (Message != nullptr)
    {
        Dispatcher->Dispatch(SenderUniqueId, Message);
        Codec->DestroyMessage(Message);
    }
    else
    {
        UE_LOG(LogRPCNetworkManager, Warning, TEXT("[RECV] %d Unknown message"), DataSize);
    }
}

void URPCNetworkManager::OnMessage(int32 SenderId, const google::protobuf::Message* Message)
{
	PrintLog(*FString::Printf(TEXT("RPCNetworkManager:Recv [%d] "), SenderId), Message);

    FString MessageType(UTF8_TO_TCHAR(Message->GetDescriptor()->name().c_str()));

#if STATS
    const TStatId StatId = FDynamicStats::CreateStatId<FStatGroup_STATGROUP_RecvRPCMessage>(FName(*MessageType));
    FScopeCycleCounter CycleCounter(StatId);
#endif

    MsgRef->Message = Message;
    OnRPCMessageReceived.ExecuteIfBound(SenderId, MessageType, MsgRef);
}

bool URPCNetworkManager::SendToServer(const FString& MessageType, ULuaTableRef* MessageBodyTableRef)
{
    TArray<uint8> DataArray;
	FString DebugInfo;
	bool bPrintLog = EnableLog && nullptr == IgnoreMessages.Find(*MessageType);
    bool Ret = FMessageLuaUtil::LuaTableToArrayData(
        Codec.Get(),
        MessageType,
        LUA_TABLE_REF_U2F(MessageBodyTableRef),
        bPrintLog ? &DebugInfo : nullptr,
        DataArray);

    if (Ret)
    {
        auto RPCComponent = GetClientRPCComponent();		
        if (RPCComponent)
        {
            if (bPrintLog)
            {
                UE_LOG(LogRPCNetworkManager, Log, TEXT("RPCNetworkManager:SendToServer Message [%d] [%s], %s"),
                    RPCComponent->GetOwner()->GetUniqueID(), *MessageType, *DebugInfo);
            }
            RPCComponent->SendToServer(DataArray);
        }
        else
        {
            Ret = false;
        }
    }
    return Ret;
}

bool URPCNetworkManager::SendToClient(uint32 SenderUniqueId, const FString& MessageType, ULuaTableRef* MessageBodyTableRef)
{
    TArray<uint8> DataArray;
	FString DebugInfo;
	bool bPrintLog = EnableLog && nullptr == IgnoreMessages.Find(*MessageType);
    bool Ret = FMessageLuaUtil::LuaTableToArrayData(
        Codec.Get(),
        MessageType,
        LUA_TABLE_REF_U2F(MessageBodyTableRef),
        bPrintLog ? &DebugInfo : nullptr,
        DataArray);

    if (Ret)
    {
		if (bPrintLog)
		{
			UE_LOG(LogRPCNetworkManager, Log, TEXT("RPCNetworkManager:SendToClient[%d] Message[%s], %s"),
                SenderUniqueId, *MessageType, *DebugInfo);
		}
        auto RPCComponent = GetServerRPCComponent(SenderUniqueId);
        if (RPCComponent)
            RPCComponent->SendToClient(DataArray);
        else
            Ret = false;
    }
    return Ret;
}

bool URPCNetworkManager::Multicast(const FString& MessageType, ULuaTableRef* MessageBodyTableRef, bool bSendToServer)
{
    //AGameModeBase* GameMode = UGameplayStatics::GetGameMode(this);
    //if (!GameMode)
    //{
    //    return false;
    //}

    TArray<uint8> DataArray;
	FString DebugInfo;
	bool bPrintLog = EnableLog && nullptr == IgnoreMessages.Find(*MessageType);
    bool Ret = FMessageLuaUtil::LuaTableToArrayData(
        Codec.Get(),
        MessageType,
        LUA_TABLE_REF_U2F(MessageBodyTableRef),
        bPrintLog ? &DebugInfo : nullptr,
        DataArray);

    if (Ret)
    {
		if (bPrintLog)
		{
			UE_LOG(LogRPCNetworkManager, Log, TEXT("RPCNetworkManager:Multicast Message[%s], %s"),
				*MessageType, *DebugInfo);
		}

        UWorld* World = GetWorld();
        if (World && World->IsGameWorld())
        {
            if (UKismetSystemLibrary::IsStandalone(World))
            {
                auto RPCComponent = GetMulticastRPCComponent();
                if (RPCComponent)
                    RPCComponent->Multicast(DataArray);
                else
                    Ret = false;
            }
            else if(UKismetSystemLibrary::IsDedicatedServer(World))
            {
                for (FConstPlayerControllerIterator Iterator = World->GetPlayerControllerIterator(); Iterator; ++Iterator)
                {
                    APlayerController* PC = Iterator->Get();
                    UReplicatedProtoCallComponent* Component = s_GetRPCComponent(PC);
                    if (Component)
                        Component->SendToClient(DataArray);
                    else
                        Ret = false;
                }
				if (bSendToServer)
				{
					auto Sender = UGameplayStatics::GetGameState(this);
					OnDataReceived(Sender->GetUniqueID(), DataArray);
				}
            }
        }
    }
    return Ret;
}
//
//bool URPCNetworkManager::MulticastReliablely(const FString& MessageType, ULuaTableRef* MessageBodyTableRef)
//{
//    TArray<uint8> DataArray;
//    FString DebugInfo;
//    bool bPrintLog = EnableLog && nullptr == IgnoreMessages.Find(*MessageType);
//    bool Ret = FMessageLuaUtil::LuaTableToArrayData(
//        Codec.Get(),
//        MessageType,
//        LUA_TABLE_REF_U2F(MessageBodyTableRef),
//        bPrintLog ? &DebugInfo : nullptr,
//        DataArray);
//
//    if (Ret)
//    {
//        if (bPrintLog)
//        {
//            UE_LOG(LogRPCNetworkManager, Log, TEXT("RPCNetworkManager:MulticastReliablely Message[%s], %s"),
//                *MessageType, *DebugInfo);
//        }
//
//        UWorld* World = GetWorld();
//        if (World && World->IsGameWorld())
//        {
//            auto RPCComponent = GetMulticastRPCComponent();
//            if (RPCComponent)
//                RPCComponent->MulticastReliablely(DataArray);
//            else
//                Ret = false;
//        }
//    }
//    return Ret;
//}

// 这函数得在玩家连接前调用
void URPCNetworkManager::SetPacketEncryptionEnabled(bool Enabled, int32 Seed)
{
    UGameIpConnection::SetPacketEncryptionEnabled(Enabled, Seed);

#if ENABLE_GAME_MESSAGE_OBFUSCATION
    Codec->SetObfuscationEnabled(Enabled);     // 为了应付it策略
#endif
}

void URPCNetworkManager::SetActorAsyncCreatingEnabled(bool Enabled)
{
    auto Driver = Cast<UGameIpNetDriver>(GetWorld()->GetNetDriver());
    if (Driver)
    {
        Driver->SetActorAsyncCreatingEnabled(Enabled);
    }
}

void URPCNetworkManager::ClearPendingPackets()
{
    for (int ii = 0; ii < PendingPackets.Num(); ii++)
    {
        delete PendingPackets[ii];
    }
    PendingPackets.Empty();
    for (int ii = 0; ii < PacketPool.Num(); ii++)
    {
        delete PacketPool[ii];
    }
    PacketPool.Empty();
}

//////////////////////////////////////////////////////////////////////////
void URPCNetworkManager::AddCustomReplicationDefineInfo(const FName& Name, const TArray<FCustomReplicationPropertyDefine>& Defines)
{
    auto& Info = CustomReplicationDefineInfo.FindOrAdd(Name);
    Info.Defines = Defines;
}

void URPCNetworkManager::ClearCustomReplicationDefineInfo()
{
    CustomReplicationDefineInfo.Empty();
}

const int32 URPCNetworkManager::GetCustomReplicationDefineInfoCRC(const FName& Name) const
{
    auto* DefineInfo = CustomReplicationDefineInfo.Find(Name);
    if (DefineInfo)
    {
        // 蓝图里寸的是int32，所以这里直接转了一下
        return static_cast<int32>(DefineInfo->GetCRC());
    }
    return 0;
}

const TArray<FCustomReplicationPropertyDefine>* URPCNetworkManager::GetCustomReplicationDefineInfo(const FName& Name) const
{
    auto* DefineInfo = CustomReplicationDefineInfo.Find(Name);
    if (DefineInfo)
    {
        return &DefineInfo->Defines;
    }
    return nullptr;
}