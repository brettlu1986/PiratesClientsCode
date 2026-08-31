#include "Shell/GameDungeonShell.h"
#include "Client.h"
#include "Shell/ClientShell.h"
#include "Pawns/PiratesShipPawn.h"
#include "PiratesLocalPlayer.h"
#include "KMPlayerController.h"

#include "Engine/ActorChannel.h"
#include "Engine/NetDriver.h"
#include "IpConnection.h"
#include "PacketHandlers/ReconnectHandlerComponent.h"
#include "Network/GameIpNetDriver.h"
#include "Network/GameIpConnection.h"

DEFINE_LOG_CATEGORY_STATIC(GameDungeonShellLog, Log, All)

void UGameDungeonShell::CancelPendingNetGame(UObject* WorldContextObject)
{
    if (UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull))
    {
        GEngine->CancelPending(World);
    }
}

bool UGameDungeonShell::DisconnectFromDungeonServer(bool bSmoothTravel)
{
    UWorld* World = GetWorld();
    if (World == nullptr)
        return false;

    GEngine->CancelPending(World);
    GEngine->ShutdownWorldNetDriver(World);
    return true;
}

uint64 UGameDungeonShell::GenerateMockPlayerId()
{
    uint64 PlayerId = 0;
    FGuid Guid = FGuid::NewGuid();
    PlayerId = (uint64)(Guid.A ^ Guid.B) << 31;
    PlayerId |= Guid.C ^ Guid.D;
    return PlayerId;
}

bool UGameDungeonShell::SendReconnectInfo(uint64 PlayerId, uint32 Token)
{
    UWorld* World = GetWorld();
    if (World == nullptr)
        return false;

    UNetDriver* NetDriver = World->GetNetDriver();
    if (!NetDriver)
        return false;

    UIpConnection* IpNetConnection = (UIpConnection*)(NetDriver->ServerConnection);
    if (!IpNetConnection)
        return false;

    if (!IpNetConnection->Handler.IsValid())
        return false;

    TSharedPtr<HandlerComponent> HComponent = IpNetConnection->Handler->GetComponentByName(FName(TEXT("ReconnectHandlerComponent")));
    TSharedPtr<ReconnectHandlerComponent> ReconnectComponent = StaticCastSharedPtr<ReconnectHandlerComponent>(HComponent);
    if (!ReconnectComponent.IsValid())
        return false;

    if (!ReconnectComponent->SendReconnectInfo(PlayerId, Token))
        return false;

    return true;
}

bool UGameDungeonShell::RecreateUDPSocketInClient()
{
    UWorld* World = GetWorld();
    if (World == nullptr)
        return false;

    auto NetDriver = Cast<UGameIpNetDriver>(World->GetNetDriver());
    if (!NetDriver)
        return false;

    return NetDriver->RecreateUDPSocketInClient();
}