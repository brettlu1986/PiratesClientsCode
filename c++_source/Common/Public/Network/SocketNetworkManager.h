// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "NetworkManagerBase.h"
#include "SocketMessageQueue.h"
#include "TcpSocket.h"
#include "SocketNetworkManager.generated.h"


class UTcpSocket;
namespace google
{
    namespace protobuf
    {
        class Message;
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////
UCLASS(config=Game)
class COMMON_API USocketNetworkManager : public UNetworkManagerBase
{
    GENERATED_UCLASS_BODY()

private:    
    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnReceivedMessage, int32, SocketId, const FString&, MessageType, const UProtobufMessageRef*, MessageRef);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnConnectedResult, int32, SocketId, bool, bResult);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnDisconnected, int32, SocketId);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnIdleTimeout, int32, SockeId, float, DeltaTime);

public:
    virtual bool CreateSocket(int32 InSocketID, const FString& InDescription, int32 OverrideSendBufferSize = 0, int32 OverrideRecvBufferSize = 0);
    virtual bool DestroySocket(int32 InSocketID);
    virtual void DestroyAllSockets();
    virtual void Init() override;
    virtual void Uninit() override;
    virtual void Tick(float DeltaTime) override;

    UFUNCTION()
    virtual bool Connect(int32 InSocketID, const FString& Endpoint);
    UFUNCTION()
    virtual bool ConnectWithDomainName(int32 InSocketID, const FString& DomainName, uint32 Port, bool UseOpenSSL);
    UFUNCTION()
    virtual bool ConnectIPWithOpenSSL(int32 InSocketID, const FString& Endpoint, const FString& DomainName);
    UFUNCTION()
    virtual void Disconnect(int32 InSocketID);
    UFUNCTION()
    virtual bool IsConnected(int32 InSocketID);
    UFUNCTION()
    virtual bool SendPacketByTable(int32 InSocketID, const FString& MessageType, ULuaTableRef* TableRef);
    UFUNCTION()
    virtual void SetPending(bool bPending);
    UFUNCTION()
    void SetIgnoreSpecificError(bool Ignore);

    virtual bool SendPacket(int32 InSocketID, const google::protobuf::Message* Message);
    static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

    UFUNCTION()
    virtual FString MessageToBase64String(const FString& MessageType, ULuaTableRef* TableRef);

    UFUNCTION()
    virtual bool Base64StringToMessage(const FString& MessageType, const FString& Content, UProtobufMessageRef*& OutMessageRef);

    UFUNCTION()
    virtual void SetIdleTime(float InWaitIdleTime, float InReadIdleTime);
protected:
    // 用于 Base64StringToMessage 存储解码后 Message
    UPROPERTY(transient)
    UProtobufMessageRef* TempDecodeMessage;

    virtual void ClearTempDecodeMessage();

public:
    UPROPERTY()
    FOnConnectedResult OnConnectedResult;
    UPROPERTY()
    FOnDisconnected OnPostDisconnected;
    UPROPERTY()
    FOnDisconnected OnPreDisconnected;
    UPROPERTY()
    FOnReceivedMessage OnReceivedMessage;
    UPROPERTY()
    FOnIdleTimeout OnWriteIdleTimeout;
    UPROPERTY()
    FOnIdleTimeout OnReadIdleTimeout;

protected:
    virtual void OnConnectedResultFunc(UTcpSocket& TCPSocket);
    virtual void OnDisconnectedFunc(UTcpSocket& TCPSocket);
    virtual void OnDispatch(int32 SocketID, uint16 MessageID, const uint8* MessageData, int32 Size);
    virtual void TickSockets(float DeltaTime);
    virtual void TickIdleTime(float DeltaTime, int32 SocketID);
    virtual void ProcessMessageQueue(bool UseTimelimit, float TimeLimit);
    virtual UTcpSocket* GetSocket(int32 InSocketID);
    virtual void OnMessage(int32 InSocketID, const google::protobuf::Message* Message) override;
    virtual void DecodeAndDispatch(int32 SocketID, uint16 MessageID, const uint8* MessageData, int32 Size);

protected:
    TArray<UTcpSocket*> Sockets;
    FSocketMessageQueue MessageQueue;

    UPROPERTY(config)
    int32 SendBufferSize;
    UPROPERTY(config)
    int32 RecvBufferSize;
    UPROPERTY(config)
    float ConnectTimeout;
    UPROPERTY(config)
    int32 MessageQueueInitSize;
    UPROPERTY(config)
    float PacketProcessMaxTimePerTick;
    UPROPERTY(config)
    int32 QueueProcessFactor;
    UPROPERTY(config)
    bool EnableMessageQueue;
    UPROPERTY(config)
    bool EnablePending;
    UPROPERTY(config)
    float WriteIdleTime;
    UPROPERTY(config)
    float ReadIdleTime;

    TMap<int32, float> WriteIdleDurations;
    TMap<int32, float> ReadIdleDurations;
};
