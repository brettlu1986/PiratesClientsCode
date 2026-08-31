// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/ReplicatedProtoCallComponent.h"
#include "Common.h"
#include "RPCNetworkManager.h"
#include "Kismet/GameplayStatics.h"
#include "Game/GameCommon.h"
#include "RPCNetworkManager.h"

DEFINE_LOG_CATEGORY_STATIC(ReplicatedProtoCallComponentLog, Log, All)

UReplicatedProtoCallComponent::UReplicatedProtoCallComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{}

void UReplicatedProtoCallComponent::SendToServer(const TArray<uint8>& Data)
{
    ServerReceivedData(Data);
}

void UReplicatedProtoCallComponent::SendToClient(const TArray<uint8>& Data)
{
    ClientReceivedData(Data);
}

void UReplicatedProtoCallComponent::Multicast(const TArray<uint8>& Data)
{
    ClientReceivedMulticastData(Data);
}

void UReplicatedProtoCallComponent::MulticastReliablely(const TArray<uint8>& Data)
{
    ClientReceivedReliableMulticastData(Data);
}

bool UReplicatedProtoCallComponent::ServerReceivedData_Validate(const TArray<uint8>& Data)
{
    return Data.Num() > 0;
}

void UReplicatedProtoCallComponent::ServerReceivedData_Implementation(const TArray<uint8>& Data)
{
    //UE_LOG(ReplicatedProtoCallComponentLog, Verbose, TEXT("Server received data %p"), this);
    auto NetworkManager = UGameCommon::Get(this)->GetRPCNetworkManager();
    NetworkManager->OnDataReceived(GetOwner()->GetUniqueID(), Data);
}

void UReplicatedProtoCallComponent::ClientReceivedData_Implementation(const TArray<uint8>& Data)
{
    //UE_LOG(ReplicatedProtoCallComponentLog, Verbose, TEXT("Client received data %p"), this);
    auto NetworkManager = UGameCommon::Get(this)->GetRPCNetworkManager();
    NetworkManager->OnDataReceived(GetOwner()->GetUniqueID(), Data);
}

void UReplicatedProtoCallComponent::ClientReceivedMulticastData_Implementation(const TArray<uint8>& Data)
{
    //UE_LOG(ReplicatedProtoCallComponentLog, Verbose, TEXT("Client received multicast data %p"), this);
    auto NetworkManager = UGameCommon::Get(this)->GetRPCNetworkManager();
    NetworkManager->OnDataReceived(GetOwner()->GetUniqueID(), Data);
}

void UReplicatedProtoCallComponent::ClientReceivedReliableMulticastData_Implementation(const TArray<uint8>& Data)
{
    //UE_LOG(ReplicatedProtoCallComponentLog, Verbose, TEXT("Client received reliable multicast data %p"), this);
    auto NetworkManager = UGameCommon::Get(this)->GetRPCNetworkManager();
    NetworkManager->OnDataReceived(GetOwner()->GetUniqueID(), Data);
}


#include "CustomReplicationComponent.h"
void UReplicatedProtoCallComponent::VerifyClientReplicationProperty_Implementation(AActor* Owner, uint32 NetGuid, int RepType, uint64 StateId, uint64 History, const TArray<uint16>& Data)
{
#if WITH_VERIFY_DATA
    if (Owner == nullptr)
    {
        UE_LOG(ReplicatedProtoCallComponentLog, Warning, TEXT("VerifyClientReplicationProperty cannot find owner, netguid: %d, stateid: %d, history: %d, property count: %d"), 
            NetGuid, StateId, History, Data.Num());
        return;
    }
    auto Component = Owner->FindComponentByClass<UCustomReplicationComponent>();
    if (Component == nullptr)
    {
        UE_LOG(ReplicatedProtoCallComponentLog, Warning, TEXT("VerifyClientReplicationProperty cannot find component, netguid: %d, stateid: %d, history: %d, property count: %d"),
            NetGuid, StateId, History, Data.Num());
        return;
    }

    Component->VerifyClientData(NetGuid, RepType, StateId, History, Data);
#endif
}

bool UReplicatedProtoCallComponent::VerifyClientReplicationProperty_Validate(AActor* Owner, uint32 NetGuid, int RepType, uint64 StateId, uint64 History, const TArray<uint16>& Data)
{
    //return Data.Num() > 0;
    return true;
}

void UReplicatedProtoCallComponent::SendToClientTestData(int TestDataSize)
{
    TArray<uint8> TestData;
    TestData.Reserve(TestDataSize);
    for (int ii=0; ii< TestDataSize; ii++)
    {
        TestData.Add(ii);
    }
    ClientReceivedTestData(TestData);    
}

void UReplicatedProtoCallComponent::SendToServerTestData(int TestDataSize)
{
    TArray<uint8> TestData;
    TestData.Reserve(TestDataSize);
    for (int ii = 0; ii < TestDataSize; ii++)
    {
        TestData.Add(ii);
    }
    ServerReceivedTestData(TestData);
}

void UReplicatedProtoCallComponent::ClientReceivedTestData_Implementation(const TArray<uint8>& Data)
{
    UE_LOG(ReplicatedProtoCallComponentLog, Log, TEXT("Client received test data, len: %d"), Data.Num());
}

bool UReplicatedProtoCallComponent::ServerReceivedTestData_Validate(const TArray<uint8>& Data)
{
    return Data.Num() > 0;
}

void UReplicatedProtoCallComponent::ServerReceivedTestData_Implementation(const TArray<uint8>& Data)
{
    UE_LOG(ReplicatedProtoCallComponentLog, Log, TEXT("Server received test data, len: %d"), Data.Num());
}