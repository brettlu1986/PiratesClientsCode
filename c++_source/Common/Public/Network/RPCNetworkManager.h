// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Network/NetworkManagerBase.h"
#include "CustomReplicationComponent.h"
#include "RPCNetworkManager.generated.h"

class UReplicatedProtoCallComponent;

UCLASS()
class COMMON_API URPCNetworkManager : public UNetworkManagerBase
{
    GENERATED_UCLASS_BODY()

    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnRPCMessageReceived, uint32, InterfaceUniqueId, const FString&, MessageType, const UProtobufMessageRef*, MessageRef);

public:
    virtual void Init() override;
    virtual void Uninit() override;
    virtual void Tick(float DeltaTime) override;

    UFUNCTION()
    bool SendToServer(const FString& MessageType, ULuaTableRef* MessageBodyTableRef);
    UFUNCTION()
    bool SendToClient(uint32 SenderUniqueId, const FString& MessageType, ULuaTableRef* MessageBodyTableRef);
    UFUNCTION()
    bool Multicast(const FString& MessageType, ULuaTableRef* MessageBodyTableRef, bool bSendToServer);
    //UFUNCTION()
    //bool MulticastReliablely(const FString& MessageType, ULuaTableRef* MessageBodyTableRef);

    void OnDataReceived(uint32 SenderUniqueId, const TArray<uint8>& Data);

    UFUNCTION()
    UReplicatedProtoCallComponent* GetClientRPCComponent();
    
    UFUNCTION()
    UReplicatedProtoCallComponent* GetServerRPCComponent(uint32 SenderUniqueId);

    UFUNCTION()
    UReplicatedProtoCallComponent* GetMulticastRPCComponent();

    UFUNCTION()
    UReplicatedProtoCallComponent* GetRPCComponent(AActor* Sender);

    UPROPERTY()
    FOnRPCMessageReceived OnRPCMessageReceived;

public:
    virtual void OnMessage(int32 SenderId, const google::protobuf::Message* Message) override;

private:
    bool ConvertLuaTableToProtoData(const FString& MessageType, ULuaTableRef* MessageBodyTableRef, TArray<uint8>& OutDataArray);

    //////////////////////////////////////////////////////////////////////////
public:
    UFUNCTION()
    void AddCustomReplicationDefineInfo(const FName& Name, const TArray<FCustomReplicationPropertyDefine>& Defines);

    UFUNCTION()
    void ClearCustomReplicationDefineInfo();

    UFUNCTION()
    const int32 GetCustomReplicationDefineInfoCRC(const FName& Name) const;

    const TArray<FCustomReplicationPropertyDefine>* GetCustomReplicationDefineInfo(const FName& Name) const;

    UFUNCTION()
    void SetMaxTimeForPacketProcessing(float Time) { MaxTimeForPacketProcessing = Time; }

    UFUNCTION()
    void SetQueueProcessFactor(float Factor) { QueueProcessFactor = Factor; }

    UFUNCTION()
    void SetLimitPacketProcessingEnabled(bool Enable) { EnableLimitPacketProcessing = Enable; }

    UFUNCTION()
    void SetPacketEncryptionEnabled(bool Enabled, int32 Seed);

    UFUNCTION()
    void SetActorAsyncCreatingEnabled(bool Enabled);

    UFUNCTION()
    void ClearPendingPackets();

private:
    TMap<FName, FCustomReplicationComponentInfo> CustomReplicationDefineInfo;

private:
    void OnDataReceivedImp(uint32 SenderUniqueId, const TArray<uint8>& Data);

private:
    struct FPendingData
    {
        uint32 SenderId;
        TArray<uint8> Data;
        FPendingData()
            : SenderId(-1)
        {}
    };
    TArray<FPendingData*, TInlineAllocator<16> > PendingPackets;
    TArray<FPendingData*, TInlineAllocator<16> > PacketPool;    

    float MaxTimeForPacketProcessing;
    float QueueProcessFactor;
    bool EnableLimitPacketProcessing;    
};
