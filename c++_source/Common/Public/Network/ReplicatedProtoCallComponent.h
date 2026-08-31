// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "ReplicatedProtoCallComponent.generated.h"

UCLASS(Blueprintable)
class COMMON_API UReplicatedProtoCallComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
    void SendToServer(const TArray<uint8>& Data);
    void SendToClient(const TArray<uint8>& Data);
    void Multicast(const TArray<uint8>& Data);
    void MulticastReliablely(const TArray<uint8>& Data);

private:
    UFUNCTION(Server, Reliable, WithValidation)
    void ServerReceivedData(const TArray<uint8>& Data);

    UFUNCTION(Client, Reliable)
    void ClientReceivedData(const TArray<uint8>& Data);

    UFUNCTION(NetMulticast, Unreliable)
    void ClientReceivedMulticastData(const TArray<uint8>& Data);

    UFUNCTION(NetMulticast, Reliable)
    void ClientReceivedReliableMulticastData(const TArray<uint8>& Data);


public:
    // 临时放这里，bug查完就删
    UFUNCTION(Server, Reliable, WithValidation)
    void VerifyClientReplicationProperty(AActor* Owner, uint32 NetGuid, int RepType, uint64 StateId, uint64 History, const TArray<uint16>& Data);

public:
    UFUNCTION()
    void SendToClientTestData(int TestDataSize);

    UFUNCTION()
    void SendToServerTestData(int TestDataSize);

private:
    UFUNCTION(Server, Reliable, WithValidation)
    void ServerReceivedTestData(const TArray<uint8>& Data);

    UFUNCTION(Client, Reliable)
    void ClientReceivedTestData(const TArray<uint8>& Data);
};
