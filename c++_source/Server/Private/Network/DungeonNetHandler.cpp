#include "Network/DungeonNetHandler.h"
#include "Server.h"
#include "Game/GameServer.h"
#include "ProtobufDispatcher.h"
#include "Network/SocketNetworkManager.h"

DEFINE_LOG_CATEGORY_STATIC(DungeonNetHandlerLog, Log, All);

UDungeonNetHandler::UDungeonNetHandler(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

bool UDungeonNetHandler::InitializeNetwork(USocketNetworkManager * NetManager)
{
    if (NetManager == nullptr)
    {
        return false;
    }
    
    NetManager->OnConnectedResult.BindUFunction(this, TEXT("OnConnectedResultFunc"));
    NetManager->OnPostDisconnected.BindUFunction(this, TEXT("OnDisconnectedFunc"));

    return true;
}

void UDungeonNetHandler::OnConnectedResultFunc(int32 SocketId, bool bResult)
{
    if (bResult)
    {
        SendRegisterMessage(SocketId);
        UE_LOG(DungeonNetHandlerLog, Log, TEXT("UDungeonNetHandler::OnConnectedResultFunc Success. SocketId: %d"), SocketId);
    }
    else
    {
        UE_LOG(DungeonNetHandlerLog, Warning, TEXT("UDungeonNetHandler::OnConnectedResultFunc Failed. SocketId: %d"), SocketId);
    }
}

void UDungeonNetHandler::OnDisconnectedFunc(int32 SocketId)
{
    UE_LOG(DungeonNetHandlerLog, Warning, TEXT("UDungeonNetHandler::OnDisconnectedFunc SocketId: %d"), SocketId);
}

void UDungeonNetHandler::SendRegisterMessage(int32 SocketId)
{
    UGameServer* GameServer = UGameServer::Get(this);

    auto DungeonNetManager = GameServer->GetDungeonNetManager();
    auto Codec = DungeonNetManager->GetCodec().Pin();
    auto Message = Codec->CreateMessage("d2s_Register");

    auto Descriptor = Message->GetDescriptor();
    auto Field_TemplateId   = Descriptor->FindFieldByName("template_id");
    auto Field_Ticket       = Descriptor->FindFieldByName("ticket");
    auto Field_UdpIpv4      = Descriptor->FindFieldByName("udp_ipv4");
    auto Field_UdpPort      = Descriptor->FindFieldByName("udp_port");

    checkf(Field_TemplateId != NULL, TEXT("d2s_Register miss template_id field."));
    checkf(Field_Ticket     != NULL, TEXT("d2s_Register miss ticket field."));
    checkf(Field_UdpIpv4    != NULL, TEXT("d2s_Register miss udp_ipv4 field."));
    checkf(Field_UdpPort    != NULL, TEXT("d2s_Register miss udp_port field."));

    auto Reflection = Message->GetReflection();
    Reflection->SetInt32(Message, Field_TemplateId, GameServer->GetDungeonTemplateId());
    Reflection->SetString(Message, Field_Ticket, TCHAR_TO_UTF8(*GameServer->GetTicket()));
    Reflection->SetUInt32(Message, Field_UdpIpv4, GameServer->GetDungeonServerAddress().Value);
    Reflection->SetUInt32(Message, Field_UdpPort, GameServer->GetDungeonServerUdpPort());

    DungeonNetManager->SendPacket(SocketId, Message);
    Codec->DestroyMessage(Message);
}
