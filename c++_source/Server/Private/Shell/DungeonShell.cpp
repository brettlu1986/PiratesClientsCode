#include "DungeonShell.h"
#include "Server.h"

#include "GameServer.h"
#include "SocketNetworkManager.h"
#include "DungeonInfoTabFile.h"
#include "TcpSocket.h"
#include "GameFramework/PlayerController.h"
#include "IpConnection.h"
#include "IPAddress.h"

DEFINE_LOG_CATEGORY_STATIC(DungeonShellLog, Log, All);

UDungeonShell::UDungeonShell(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

void UDungeonShell::EndGame()
{
    UGameServer* GameServer = UGameServer::Get(this);
    GameServer->EndGame();
}

bool UDungeonShell::SetClientConnectionAddress(class APlayerController* PlayerController, FString Address)
{
    UWorld* World = GetWorld();
    if (World == nullptr)
        return false;

    UNetDriver* NetDriver = World->GetNetDriver();
    if (!NetDriver)
        return false;

    UNetConnection* PlayerNetConnection = PlayerController->GetNetConnection();
    if (!PlayerNetConnection)
        return false;

    for (int32 i = 0; i < NetDriver->ClientConnections.Num(); i++)
    {
        UNetConnection* NetConnection = NetDriver->ClientConnections[i];
        if (PlayerNetConnection == NetConnection)
        {
            bool ret = false;
            UIpConnection* IpConnection = Cast<UIpConnection>(NetConnection);
            FString OriginalRemoteAddress = IpConnection->RemoteAddressToString();
            if (OriginalRemoteAddress == Address)
            {
                UE_LOG(DungeonShellLog, Log, TEXT("Client connection address not change %s."),
                    *OriginalRemoteAddress);
                ret = true;
            }
            else
            {
                // 曾经尝试以下方式进行重设地址的操作，在不开启 replication graph 的情况下没有问题，但是开启
                // replication graph 后，发现服务器上很多 OnSerializeNewActor 触发，导致客户端多次进行初始化操作出错
                // 所以此处最小化改动，仅拿出 ipconnection 改变其地址，维护内部地址连接索引正确
                //NetDriver->RemoveClientConnection(IpConnection);
                //bool bValidAddress = false;
                //IpConnection->RemoteAddr->SetIp(*Address, bValidAddress);
                //IpConnection->SetReplicationConnectionDriver(nullptr);
                //NetDriver->AddClientConnection(IpConnection);

                auto AddrToRemove = IpConnection->GetRemoteAddr();
                if (AddrToRemove.IsValid())
                {
                    if (NetDriver->MappedClientConnections.Remove(AddrToRemove.ToSharedRef()) != 1)
                    {
                        return false;
                    }
                    //verify(NetDriver->MappedClientConnections.Remove(AddrToRemove.ToSharedRef()) == 1);
                }
                bool bValidAddress = false;
                IpConnection->RemoteAddr->SetIp(*Address, bValidAddress);

                auto ConnAddr = IpConnection->GetRemoteAddr();
                if (ConnAddr.IsValid())
                {
                    NetDriver->MappedClientConnections.Add(ConnAddr.ToSharedRef(), IpConnection);
                }

                if (bValidAddress)
                {
                    UE_LOG(DungeonShellLog, Log, TEXT("Modify client connection address from %s to %s."),
                        *OriginalRemoteAddress, *Address);
                }
                else
                {
                    UE_LOG(DungeonShellLog, Warning, TEXT("Trying to modify client connection failed. From %s to %s."),
                        *OriginalRemoteAddress, *Address);
                }
                ret = bValidAddress;
            }
            return ret;
        }
    }
    return false;
}
