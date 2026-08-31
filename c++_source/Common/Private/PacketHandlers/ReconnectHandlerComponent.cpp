#include "PacketHandlers/ReconnectHandlerComponent.h"
#include "Common.h"

#include "Engine/NetConnection.h"
#include "Net/Core/Misc/PacketAudit.h"
#include "Network/GameIpNetDriver.h"
#include "PacketHandlers/ReconnectHandlerComponent.h"

/**
* Client - Reconnect notification packet :
* [ReconnectBit][ReservedBit][64:PlayerId][32:Token]
*/

DEFINE_LOG_CATEGORY(LogReconnect);

#define RECONNECT_PACKET_SIZE_BITS	98

ReconnectHandlerComponent::ReconnectHandlerComponent()
    : HandlerComponent(FName(TEXT("ReconnectHandlerComponent")))
{
    SetActive(true);
}

void ReconnectHandlerComponent::SetDriver(UNetDriver* InDriver)
{
    Driver = InDriver;
}

bool ReconnectHandlerComponent::SendReconnectInfo(uint64 PlayerId, uint32 Token)
{
    bool bSend = false;
    if (Handler->Mode == Handler::Mode::Client)
    {
        UNetConnection* ServerConn = (Driver != nullptr ? Driver->ServerConnection : nullptr);

        if (ServerConn != nullptr)
        {
            FBitWriter InitialPacket(RECONNECT_PACKET_SIZE_BITS + 1 /* Termination bit */);
            uint8 bReconnectPacket = 1;
            InitialPacket.WriteBit(bReconnectPacket);

            uint8 bReserved = 0;
            InitialPacket.WriteBit(bReserved);

            InitialPacket << PlayerId;
            InitialPacket << Token;

            CapReconnectPacket(InitialPacket);

            // Disable PacketHandler parsing, and send the raw packet
            Handler->SetRawSend(true);

            if (ServerConn->Driver->IsNetResourceValid())
            {
                FOutPacketTraits Traits;
                ServerConn->LowLevelSend(InitialPacket.GetData(), InitialPacket.GetNumBits(), Traits);
                bSend = true;
            }

            Handler->SetRawSend(false);
            UE_LOG(LogReconnect, Log, TEXT("SendReconnectInfo succeed, playerid: %d, token: %d"), PlayerId, Token);
        }
        else
        {
            UE_LOG(LogReconnect, Error, TEXT("Tried to send reconnect packet without a server connection."));
        }
    }
    return bSend;
}

void ReconnectHandlerComponent::CapReconnectPacket(FBitWriter& ReconnectPacket)
{
    check(ReconnectPacket.GetNumBits() == RECONNECT_PACKET_SIZE_BITS);

    FPacketAudit::AddStage(TEXT("PostPacketHandler"), ReconnectPacket);

    // Add a termination bit, the same as the UNetConnection code does
    ReconnectPacket.WriteBit(1);
}

void ReconnectHandlerComponent::Incoming(FBitReader& Packet)
{
    bool bReconnectPacket = !Packet.IsError() && CheckReconnectBit(Packet)
        // Only accept reconnect packets of precisely the right size
        && Packet.GetBitsLeft() == RECONNECT_PACKET_SIZE_BITS;
    if (bReconnectPacket)
    {
        uint64 PlayerId;
        uint32 Token;
        if (ParseReconnectPacket(Packet, PlayerId, Token))
        {
            UE_LOG(LogReconnect, Log, TEXT("Incoming: Reading reconnect packet. Ignore."));
        }
        else
        {
            UE_LOG(LogReconnect, Warning, TEXT("Incoming: ParseReconnectPacket failed."));
        }
    }
}

void ReconnectHandlerComponent::IncomingConnectionless(const TSharedPtr<const FInternetAddr>& Address, FBitReader& Packet)
{
    bool bReconnectPacket = !Packet.IsError() && CheckReconnectBit(Packet) 
        // Only accept reconnect packets of precisely the right size
        && Packet.GetBitsLeft() == RECONNECT_PACKET_SIZE_BITS;

    if (bReconnectPacket)
    {
        uint64 PlayerId;
        uint32 Token;
        bReconnectPacket = ParseReconnectPacket(Packet, PlayerId, Token);
        if (bReconnectPacket)
        {
            UE_LOG(LogReconnect, Log, TEXT("Incoming: Reading reconnect packet."));
            if (Handler->Mode == Handler::Mode::Server)
            {                
                for (auto& Info : ReconnectInfos)
                {
                    if (Info.PlayerId == PlayerId && Info.Token == Token)
                    {
                        Info.Address = Address->ToString(true);
                        return;
                    }
                }

                ReconnectInfo Info;
                Info.Address = Address->ToString(true);
                Info.PlayerId = PlayerId;
                Info.Token = Token;
                ReconnectInfos.Emplace(Info);
            }
        }
        else
        {
            Packet.SetError();
            UE_LOG(LogReconnect, Warning, TEXT("IncomingConnectionless: Error reading reconnect packet."));
        }
    }
}

bool ReconnectHandlerComponent::ParseReconnectPacket(FBitReader& Packet, uint64& OutPlayerId, uint32& OutToken)
{
    uint8 bReconnectPacket = Packet.ReadBit();
    check(!!bReconnectPacket);
    Packet.ReadBit(); // Reserved bit

    Packet << OutPlayerId;
    Packet << OutToken;

    return !Packet.IsError();
}

bool ReconnectHandlerComponent::CheckReconnectBit(FBitReader& Packet)
{
    const TArray<uint8>& Buffer = Packet.GetBuffer();
    if (Packet.GetBitsLeft() <= 0)
    {
        return false;
    }
    int64 Pos = Packet.GetPosBits();
    uint8 Bit = !!(Buffer[Pos >> 3] & (1<<(Pos & 7)));
    return !!Bit;
}
