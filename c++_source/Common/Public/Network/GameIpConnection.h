// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "IpConnection.h"
#include "GameIpConnection.generated.h"

UCLASS(config = Engine, transient)
class COMMON_API UGameIpConnection : public UIpConnection
{
    GENERATED_UCLASS_BODY()

public:
    virtual void InitBase(UNetDriver* InDriver, class FSocket* InSocket, const FURL& InURL, EConnectionState InState,
        int32 InMaxPacket = 0, int32 InPacketOverhead = 0) override;
    
    virtual void Tick() override;
    virtual void CleanUp() override;

    virtual void AddCustomHandlers() override;
    
public:
    static void SetPacketEncryptionEnabled(bool Enabled, int32 Seed)
    {
        PacketEncryptionEnabled = Enabled; 
        PacketEncryptionSeed = Seed;
    }
    static const bool GetPacketEncryptionEnabled() { return PacketEncryptionEnabled; }
    static const int32 GetPacketEncryptionSeed() { return PacketEncryptionSeed; }

private:
    void AddReconnectComponentHandler();
    void GenerateAES32Keys(uint8* InOutKeys, int32 Seed);
    void SetPacketEncryptionEnabledImp(bool Enabled, int32 Seed);
    void CheckOutRecInTick();

private:
    UPROPERTY(config)
    float OutRecExpireTime;         // 发送的reliable包过了多长时间没收到ack会重发

    UPROPERTY(config)
    float OutRecCheckInterval;      // OutRec检查的间隔
    float CurrentOutRecCheckTime;

    static bool PacketEncryptionEnabled;
    static int32 PacketEncryptionSeed;
};
