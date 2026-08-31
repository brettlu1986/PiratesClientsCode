#include "AI/AIGameCoreProxy/AIGameCoreProxyTCP.h"
#include "Engine.h"
#include "Network/SocketNetworkManager.h"

static const int32 DefaultSocketID = 0;
static const int32 SendBufferSize  = 1024 * 1024;

UAIGameCoreProxyTCP::UAIGameCoreProxyTCP(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer),
    NetworkManager(nullptr),
    MaxConnectingTime(5),
    MaxRetryConnectTimes(-1),
    bConnected(false),
    ReConnectingTime(0),
    ReConnectedTimes(0)
{
   
}

void UAIGameCoreProxyTCP::Init()
{
    NetworkManager = NewObject<USocketNetworkManager>();
    NetworkManager->Init();
    NetworkManager->CreateSocket(DefaultSocketID, TEXT("Game Core Proxy Client"), SendBufferSize);
    NetworkManager->OnReceivedMessage.BindDynamic(this, &UAIGameCoreProxyTCP::OnReceivedMessage);
    NetworkManager->OnConnectedResult.BindDynamic(this, &UAIGameCoreProxyTCP::OnConnectedResult);
    NetworkManager->OnPostDisconnected.BindDynamic(this, &UAIGameCoreProxyTCP::OnPostDisconnected);
    
}

void UAIGameCoreProxyTCP::Start(const FString& InEndPoint)
{
    if (NetworkManager)
    {
        EndPoint = InEndPoint;
        if (NetworkManager->Connect(DefaultSocketID, InEndPoint))
        {
            ReConnectingTime = MaxConnectingTime;
            UE_LOG(LogTemp, Log, TEXT("UAIGameCoreProxyTCP:try to connect end point -> %s"), *InEndPoint);
        }
    }
}

void UAIGameCoreProxyTCP::Stop()
{
    EndPoint.Empty();
    ReConnectingTime = 0;
    ReConnectedTimes = 0;
    if (NetworkManager)
    {
        NetworkManager->Disconnect(DefaultSocketID);
    }
    UE_LOG(LogTemp, Log, TEXT("UAIGameCoreProxyTCP:stopped"));
}


void UAIGameCoreProxyTCP::Uninit()
{
    if (NetworkManager)
    {
        NetworkManager->OnReceivedMessage.Unbind();
        NetworkManager->DestroyAllSockets();
        NetworkManager->Uninit();
    }
}

void UAIGameCoreProxyTCP::Tick(float DelataTime)
{
    if (NetworkManager)
    {
        NetworkManager->Tick(DelataTime);
        if (!bConnected && !EndPoint.IsEmpty() && ReConnectingTime > 0)
        {
            ReConnectingTime -= DelataTime;
            if (ReConnectingTime <= 0)
            {
                if (ReConnectedTimes < MaxRetryConnectTimes)
                {
                    ReConnectedTimes++;
                    UE_LOG(LogTemp, Log, TEXT("UAIGameCoreProxyTCP:reconnect %d time in %f seconds."), ReConnectedTimes, MaxConnectingTime);
                    Start(EndPoint);
                }
                else
                {
                    UE_LOG(LogTemp, Log, TEXT("UAIGameCoreProxyTCP:over max retry times, do not connect any more."));
                    OnServerDead.ExecuteIfBound();
                }
            }
        }
    }
}


void UAIGameCoreProxyTCP::OnReceivedMessage(int32 SocketId, const FString& MessageType, const UProtobufMessageRef* MessageRef)
{
    
}

void UAIGameCoreProxyTCP::OnConnectedResult(int32 SocketId, bool bResult)
{
    bConnected = bResult;
    if (bConnected)
    {
        ReConnectingTime = 0;
        ReConnectedTimes = 0;
        UE_LOG(LogTemp, Log, TEXT("UAIGameCoreProxyTCP:connection connected"));
    }
}

void UAIGameCoreProxyTCP::OnPostDisconnected(int32 SocketId)
{
    bConnected = false;
    ReConnectingTime = MaxConnectingTime;
    ReConnectedTimes = 0;
    UE_LOG(LogTemp, Log, TEXT("UAIGameCoreProxyTCP:connection lost"));
}

bool UAIGameCoreProxyTCP::SendPacketByTable(const FString& MessageType, ULuaTableRef* TableRef)
{
    if (NetworkManager && bConnected)
    {
        NetworkManager->SendPacketByTable(DefaultSocketID, MessageType, TableRef);
        return true;
    }
    return false;
}
