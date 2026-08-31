// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "ReplicatedProtoPropertyComponent.generated.h"

class ProtobufCodec;

UCLASS(Blueprintable)
class COMMON_API UReplicatedProtoPropertyComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()
private:
    struct FPropertyRawData
    {
        FName ProtoName;
        TArray<uint8> RawProtoData;
        bool bDirty;

        FPropertyRawData(): bDirty(false)
        {}
    };

public:
    virtual void TickComponent(float DeltaSeconds, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason);
    
    bool DefineProperty(const FName& ProtoName);
    bool UndefineProperty(const FName& ProtoName);
    bool SetPropertyValue(const FName& ProtoName, class ULuaTableRef* TableRef);
    void ReplicateNow();
    void ReplicateNowByType(bool bMulticast);
    void MarkAllNeedReplicate();
    void UndefineAllPropeties();
    void SetNeedSaveRawData(bool bSave) { bSaveRawData = bSave; }
    void SetClientRecvType(bool bMulticast) { bMulticastToClient = bMulticast; }
    void ConstructRawData(TArray<uint8>& OutData);
    void ProcessRecvData(const TArray<uint8>& Data);
    void EnableReplicateToClient(bool bSendtoClient) { bReplicateToClient = bSendtoClient; }

private:

    UFUNCTION(Client, Reliable, WithValidation)
    void ClientReceivedData(const TArray<uint8>& Data);

    UFUNCTION(NetMulticast, Reliable, WithValidation)
    void ClientReceivedMulticastData(const TArray<uint8>& Data);

    ProtobufCodec* GetCodec();

private:

    TArray<FPropertyRawData*> Properties;
    TArray<FPropertyRawData*> RepOrder;
    TWeakPtr<ProtobufCodec> Codec;
    bool bMulticastToClient;
    bool bSaveRawData;
    //如果是单机副本为true 否则需要自己开启
    bool bReplicateToClient;
};
