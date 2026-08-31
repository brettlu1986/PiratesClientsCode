// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/GameIpConnection.h"
#include "Common.h"
#include "Shell/CommonShell.h"
#include "Network/GamePackageMap.h"
#include "PiratesLocalPlayer.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameStateDelegate.h"
#include "PacketHandlers/ReconnectHandlerComponent.h"
#include "Network/RPCNetworkManager.h"
#include "EncryptionComponent.h"
#include "Network/GameIpNetDriver.h"

#include "Sockets.h"
#include "IPAddress.h"
#include "SocketSubsystem.h"
#include "Math/RandomStream.h"

DEFINE_LOG_CATEGORY_STATIC(LogGameIpConnection, Log, All)

bool UGameIpConnection::PacketEncryptionEnabled = false;
int32 UGameIpConnection::PacketEncryptionSeed = 0;

UGameIpConnection::UGameIpConnection(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , OutRecExpireTime(2.0f)
    , OutRecCheckInterval(2.0f)
    , CurrentOutRecCheckTime(0.0f)
{

}

void UGameIpConnection::InitBase(UNetDriver* InDriver, class FSocket* InSocket, const FURL& InURL, EConnectionState InState, int32 InMaxPacket, int32 InPacketOverhead)
{
    Super::InitBase(InDriver, InSocket, InURL, InState, InMaxPacket, InPacketOverhead);

    // 将老的删掉，建个自己的
    if (PackageMap)
    {
        PackageMap->MarkPendingKill();
    }

    auto PackageMapClient = NewObject<UGamePackageMap>(this);
    PackageMapClient->Initialize(this, Driver->GuidCache);
    PackageMap = PackageMapClient;

    SetPacketEncryptionEnabledImp(GetPacketEncryptionEnabled(), GetPacketEncryptionSeed());
}

void UGameIpConnection::Tick()
{
    Super::Tick();

    CheckOutRecInTick();
}

void UGameIpConnection::CleanUp()
{
    // 当客户端调用NetDriver的RecreateUDPSocketInClient时，客户端的socket会close，然后创建个新的使用，
    // 客户端底层socket关闭后，server的socket中可能还有数据没处理完，此时server在调用recvfrom时，
    // 就会产生SE_ECONNRESET或者SE_UDP_ERR_PORT_UNREACH，具体解释参考：https://stackoverflow.com/questions/33053507/econnreset-in-send-linux-c
    // 此时netdriver会认为此种情况可能是DOS攻击，会将connection cleanup掉（搜Received ICMP port unreachable from client %s.  Disconnecting. 这块处理的），
    // 但是对重连来讲这里的SocketError可以忽略，底下这块代码就是处理此种情况
    auto SocketSubsystem = ISocketSubsystem::Get();
    if (SocketSubsystem && State == USOCK_Open)
    {
        auto Error = SocketSubsystem->GetLastErrorCode();
        if (Error == SE_ECONNRESET || Error == SE_UDP_ERR_PORT_UNREACH)
        {
            auto GameNetDriver = Cast<UGameIpNetDriver>(GetDriver());
            if (GameNetDriver && GameNetDriver->GetServerConnection() != this && !GameNetDriver->AllowPlayerPortUnreach)
            {
                FString OriginalRemoteAddress = RemoteAddressToString();
                GameNetDriver->ProcessReconnectInfos();
                FString NewRemoteAddress = RemoteAddressToString();
                if (NewRemoteAddress != OriginalRemoteAddress)
                {
                    // Address地址变了，说明重连了，所以直接退出去，忽略cleanup
                    UE_LOG(LogGameIpConnection, Log, TEXT("Ignore net driver cleanup when reconnecting."));
                    return;
                }
            }
        }
    }

    Super::CleanUp();
}

void UGameIpConnection::AddCustomHandlers()
{
    Super::AddCustomHandlers();
    AddReconnectComponentHandler();
}

void UGameIpConnection::AddReconnectComponentHandler()
{
    bool bEnabled;
    if (!GConfig->GetBool(TEXT("/Script/Common.CustomPacketHandlers"), TEXT("bEnableReconnectComponentHandler"), bEnabled, GEngineIni))
    {
        UE_LOG(LogGameIpConnection, Warning, TEXT("The [/Script/Common.CustomPacketHandlers]:bEnableReconnectComponentHandler flag has not been set"));
        bEnabled = false;
    }

    if (!bEnabled)
    {
        UE_LOG(LogGameIpConnection, Log, TEXT("UGameIpConnection::AddReconnectComponentHandler do NOT add ReconnectComponentHandler."));
        return;
    }

    if (!Handler.IsValid())
    {
        UE_LOG(LogGameIpConnection, Warning, TEXT("UGameIpConnection::AddReconnectComponentHandler add failed. Handler not valid."));
        return;
    }

    // Add handling for the stateless reconnect, for connectionless packets, as the outermost layer
    TSharedPtr<HandlerComponent> NewComponent =
        Handler->AddHandler(TEXT("Common.ReconnectHandlerComponentFactory(ReconnectHandlerComponent)"), true);

    TSharedPtr<ReconnectHandlerComponent> ReconnectComponent = StaticCastSharedPtr<ReconnectHandlerComponent>(NewComponent);
    if (!ReconnectComponent.IsValid())
    {
        UE_LOG(LogGameIpConnection, Warning, TEXT("UGameIpConnection::AddReconnectComponentHandler add failed. ReconnectComponent not valid."));
        return;
    }

    ReconnectComponent->SetDriver(Driver);
}

void UGameIpConnection::GenerateAES32Keys(uint8* InOutKeys, int32 Seed)
{
    FRandomStream RandomHelper(Seed);
    for (int ii=0; ii<32; ii+=4)
    {
        *(uint32*)&InOutKeys[ii] = RandomHelper.GetUnsignedInt();       // 客户端和服务器都是小端
    }
}

void UGameIpConnection::SetPacketEncryptionEnabledImp(bool Enabled, int32 Seed)
{
    if (!Handler.IsValid())
    {
        return;
    }

    auto EncryptionComponent = Handler->GetEncryptionComponent();
    if (!EncryptionComponent.IsValid())
    {
        return;
    }

    if (Enabled)
    {
        uint8 Keys[32];
        GenerateAES32Keys(Keys, Seed);

        FEncryptionData EncryptionData;
        EncryptionData.Key.Append(&Keys[0], sizeof(Keys));
        EncryptionComponent->SetEncryptionData(EncryptionData);
        EncryptionComponent->EnableEncryption();
    }
    else
    {
        EncryptionComponent->DisableEncryption();
    }    
}

void UGameIpConnection::CheckOutRecInTick()
{
    /*
    当重连（或者网络不好）时，某个acto rep给客户端某个channel open的包以及部分服务器推给客户端的reliable包丢了，
    然后服务器在没发现的情况下继续往客户端推包，但因为客户端发现sequence对不上，所以缓存下来，
    此时如果每次收到reliable的rpc时也收到了之前那个没open的channel的非reliable包（可能是位置同步），
    这就会导致处理包的skipAck生效(搜log Received unreliable bunch before open (Channel %d Current Sequence %i))，
    此时客户端就算收到了服务器的包也不会回ack，这样就导致了服务器一直收不到客户端的ack，走不了nak的流程，所以无法重发之前的包

    此函数的目的就是定时强制重发没有收到ack的包
    */

    CurrentOutRecCheckTime += FrameTime;
    if (CurrentOutRecCheckTime < OutRecCheckInterval)
    {
        return;
    }
    while (CurrentOutRecCheckTime >= OutRecCheckInterval)
    {
        CurrentOutRecCheckTime -= OutRecCheckInterval;
    }

    float DriverTime = Driver->GetElapsedTime();
    FString Desc = Describe();
    for (auto& Channel : Channels)
    {
        if (Channel)
        {
            for (FOutBunch* Out = Channel->OutRec; Out; Out = Out->Next)
            {
                if (!Out->ReceivedAck && DriverTime - Out->Time >= OutRecExpireTime)
                {
                    UE_LOG(LogGameIpConnection, Log, TEXT("Channel %i ack timeout, resending %i, desc: %s"), Channel->ChIndex, Out->ChSequence, *Desc);
                    check(Out->bReliable);
                    SendRawBunch(*Out, 0);
                }
            }
        }
    }
}