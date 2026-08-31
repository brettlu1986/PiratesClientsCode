#pragma once

#include "CoreMinimal.h"
#include "PacketHandler.h"

class UNetDriver;

DECLARE_LOG_CATEGORY_EXTERN(LogReconnect, Log, All);

struct ReconnectInfo 
{
    FString Address;
    uint64 PlayerId;
    uint32 Token;
};

class COMMON_API ReconnectHandlerComponent : public HandlerComponent
{
public:
    /**
    * Base constructor
    */
    ReconnectHandlerComponent();

    void SetDriver(UNetDriver* InDriver);

    bool SendReconnectInfo(uint64 PlayerId, uint32 Token);

protected:

	virtual bool IsValid() const { return false; }

    virtual void Initialize() override
    {
        Initialized();
    }

    virtual void Incoming(FBitReader& Packet) override;

	virtual void Outgoing(FBitWriter& Packet, FOutPacketTraits& Traits) override {}

    virtual void IncomingConnectionless(const TSharedPtr<const FInternetAddr>& Address, FBitReader& Packet) override;

	virtual void OutgoingConnectionless(const TSharedPtr<const FInternetAddr>& Address, FBitWriter& Packet, FOutPacketTraits& Traits) override {}

    virtual int32 GetReservedPacketBits() const override
    {
        return 1;
    }

    virtual bool CanReadUnaligned() const override
    {
        return true;
    }

private:
    bool ParseReconnectPacket(FBitReader& Packet, uint64& OutPlayerId, uint32& OutToken);
    bool CheckReconnectBit(FBitReader& Packet);

    /**
    * Pads the reconnect packet, to match the PacketBitAlignment of the PacketHandler, so that it will parse correctly.
    *
    * @param ReconnectPacket	The reconnect packet to be aligned.
    */
    void CapReconnectPacket(FBitWriter& ReconnectPacket);

public:
    TArray<ReconnectInfo> ReconnectInfos;

private:
    /** The net driver associated with this handler - for performing connectionless sends */
    UNetDriver * Driver;
};
