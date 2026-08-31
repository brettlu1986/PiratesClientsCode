#include "Network/GameIpNetDriver.h"
#include "Common.h"
#include "PacketHandlers/ReconnectHandlerComponent.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Delegates/PiratesGameNetDelegate.h"
#include "Delegates/PiratesGameStateDelegate.h"
#include "SocketSubsystem.h"
#include "IpConnection.h"
#include "IPAddress.h"
#include "Sockets.h"
#include "Network/GamePackageMap.h"
#include "Network/GameActorChannel.h"
#include "GameDelegates.h"

DEFINE_LOG_CATEGORY_STATIC(LogGameIpNetDriver, Log, All)

UGameIpNetDriver::UGameIpNetDriver(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , ReconnectComponent()
    , EnableActorAsyncCreating(false)
    , NeedCallDisconnectDelegate(false)
    , ActorAsyncCreatingTimeLimit(0.020f)
    , ActorAsyncCreatingRemainTime(0.0f)
{
}

void UGameIpNetDriver::PostInitProperties()
{
    Super::PostInitProperties();
    ReplaceActorChannel();
}

void UGameIpNetDriver::PostReloadConfig(FProperty* PropertyToLoad)
{
    Super::PostReloadConfig(PropertyToLoad);
    ReplaceActorChannel();
}

void UGameIpNetDriver::ReplaceActorChannel()
{
    if (!HasAnyFlags(RF_ClassDefaultObject))
    {
        auto& Def = ChannelDefinitionMap.FindChecked(NAME_Actor);
        Def.ChannelClass = UGameActorChannel::StaticClass();
    }
}

/************************************************************************/
/* 在某些情况下，Client一帧调用时间过长,超过1.5秒，在该时间段内，Client不会给Server发包，不会更新Connection->LastReceiveTime，      */
/* 导致该Client的Connection->ViewTarget在ServerReplicateActors_PrepConnections方法中被置空，在没有恢复的情况下（如Client卡住2.5s，在1.5~2.5s间），Server发送  */
/* 所有Reliable Multicast RPC都不会发送给该Client。Override此方法旨在临时解决此问题，最终解决方法还是控制ClientFrameTime  */
/* 不要过大 */
/************************************************************************/
void UGameIpNetDriver::ProcessRemoteFunction(class AActor* Actor, UFunction* Function, void* Parameters, FOutParmRec* OutParms, FFrame* Stack, class UObject* SubObject)
{
    bool bIsServer = IsServer();
    UNetConnection* Connection = NULL;
    if (bIsServer
        && (Function->FunctionFlags & FUNC_NetMulticast)
        && (Function->FunctionFlags & FUNC_NetReliable))
    {
        for (int32 i = 0; i < ClientConnections.Num(); ++i)
        {
            Connection = ClientConnections[i];
            if (Connection)
            {
                if (Connection->ViewTarget == NULL
                    && ((Connection->OwningActor == NULL) || (Connection->PlayerController && Connection->PlayerController->GetViewTarget() == NULL)))
                {
                    continue;
                }

                if (Connection->ViewTarget == NULL)
                {
                    // Different from original handling. 
                    UE_LOG(LogGameIpNetDriver, Log, TEXT("Reliable multicast force executing while connection's ViewTarget is NULL."));
                }

                if (Connection->GetUChildConnection() != NULL)
                {
                    Connection = ((UChildConnection*)Connection)->Parent;
                }
                InternalProcessRemoteFunction(Actor, SubObject, Connection, Function, Parameters, OutParms, Stack, bIsServer);
            }
        }

        // Replicate any RPCs to the replay net driver so that they can get saved in network replays
        UNetDriver* NetDriver = GEngine->FindNamedNetDriver(GetWorld(), NAME_DemoNetDriver);
        if (NetDriver)
        {
            NetDriver->ProcessRemoteFunction(Actor, Function, Parameters, OutParms, Stack, SubObject);
        }
    }
    else
    {
        UIpNetDriver::ProcessRemoteFunction(Actor, Function, Parameters, OutParms, Stack, SubObject);
    }
}

void UGameIpNetDriver::TickDispatch(float DeltaTime)
{    
    if (IsActorAsyncCreatingEnabled())
    {
        ResetActorAsyncCreatingRemainTime();
    }

    Super::TickDispatch(DeltaTime);

    if (IsServer())
    {
        ProcessReconnectInfos();
    }
}

bool UGameIpNetDriver::ShouldQueueBunchesForActorGUID(FNetworkGUID InGUID) const
{    
    if (IsServer())
    {
        return Super::ShouldQueueBunchesForActorGUID(InGUID);
    }
    else
    {
        // 如果有异步加载的package那么都queue，因为不知道哪要用
        // PS：其实这里应该每个channel单独去处理，但因为虚幻没有提供虚接口（UChannel::ReceivedRawBunch），所以无法重载并记录channel所需的netguid，
        // 这里先这样，如果因为这里导致queueBunch集中一针处理导致卡顿，那么在尝试改引擎吧。。
        return /*GuidCache->PendingAsyncPackages.Num() > 0 ||*/
            ActorGUIDForQueueBunches.Find(InGUID) != nullptr;
    }
}

void UGameIpNetDriver::ProcessReconnectInfos()
{
    if (ReconnectComponent.IsValid())
    {
        TSharedPtr<ReconnectHandlerComponent> Handler = ReconnectComponent.Pin();
        if (Handler->ReconnectInfos.Num() > 0)
        {
            auto GameCommon = UGameCommon::Get(this);
            if (GameCommon)
            {
                auto Delegate = GameCommon->GetGameDelegateManager()->GameNet;
                for (auto& ReconnectInfo : Handler->ReconnectInfos)
                {
                    Delegate->OnClientReconnect.ExecuteIfBound(ReconnectInfo.Address, ReconnectInfo.PlayerId, ReconnectInfo.Token);
                }
            }
            else
            {
                UE_LOG(LogGameIpNetDriver, Warning, TEXT("UGameIpNetDriver discard all reconnect message due to null GameCommon."));
            }
            Handler->ReconnectInfos.Reset();
        }
    }
}

bool UGameIpNetDriver::RecreateUDPSocketInClient()
{
    UE_LOG(LogGameIpNetDriver, Log, TEXT("RecreateUDPSocketInClient start %s"), *GetDescription());

    // TODO: 待重新整理

    //ISocketSubsystem* SocketSubsystem = GetSocketSubsystem();
    //if (!SocketSubsystem)
    //{
    //    UE_LOG(LogGameIpNetDriver, Error, TEXT("invalid SocketSubsystem"));
    //    return false;
    //}

    //bool SocketReceiveThreadValid = SocketReceiveThreadRunnable.IsValid();

    //// Close the socket.    
    //UIpConnection* const IpServerConnection = GetServerConnection();
    //auto OldSocket = GetSocket();
    //if (OldSocket && !HasAnyFlags(RF_ClassDefaultObject))
    //{
    //    // Wait for send tasks if needed before closing the socket,
    //    // since at this point CleanUp() may not have been called on the server connection.        
    //    if (IpServerConnection)
    //    {
    //        IpServerConnection->WaitForSendTasks();
    //        IpServerConnection->Socket = nullptr;
    //    }

    //    // If using a recieve thread, shut down the socket, which will signal the thread to exit gracefully, then wait on the thread.
    //    if (SocketReceiveThread.IsValid() && SocketReceiveThreadRunnable.IsValid())
    //    {
    //        SocketReceiveThreadRunnable->bIsRunning = false;
    //        if (!OldSocket->Shutdown(ESocketShutdownMode::Read))
    //        {
    //            const ESocketErrors ShutdownError = SocketSubsystem->GetLastErrorCode();
    //            UE_LOG(LogGameIpNetDriver, Log, TEXT("UIpNetDriver::LowLevelDestroy Socket->Shutdown returned error %s (%d) for %s"), SocketSubsystem->GetSocketError(ShutdownError), static_cast<int>(ShutdownError), *GetDescription());
    //        }

    //        //SCOPE_CYCLE_COUNTER(STAT_IpNetDriver_Destroy_WaitForReceiveThread);
    //        SocketReceiveThread->WaitForCompletion();
    //    }

    //    OldSocket->Shutdown(ESocketShutdownMode::ReadWrite);

    //    if (!OldSocket->Close())
    //    {
    //        UE_LOG(LogGameIpNetDriver, Log, TEXT("closesocket error (%i)"), (int32)SocketSubsystem->GetLastErrorCode());
    //    }

    //    // Free the memory the OS allocated for this socket
    //    SocketSubsystem->DestroySocket(NewSocket);
    //    NewSocket = NULL;
    //    UE_LOG(LogGameIpNetDriver, Log, TEXT("%s socket recreated"), *GetDescription());
    //}

    ////////////////////////////////////////////////////////////////////////////
    //bool bReuseAddressAndPort = true;

    //// Create the socket that we will use to communicate with
    //auto NewSocket = CreateSocket();
    //SetSocketAndLocalAddress(NewSocket);

    //if (IpServerConnection)
    //{
    //    IpServerConnection->Socket = NewSocket;
    //}    

    //if (NewSocket == NULL)
    //{
    //    NewSocket = 0;
    //    UE_LOG(LogGameIpNetDriver, Error, TEXT("%s: socket failed (%i)"), SocketSubsystem->GetSocketAPIName(), (int32)SocketSubsystem->GetLastErrorCode());
    //    return false;
    //}
    //if (SocketSubsystem->RequiresChatDataBeSeparate() == false &&
    //    NewSocket->SetBroadcast() == false)
    //{
    //    UE_LOG(LogGameIpNetDriver, Error, TEXT("%s: setsockopt SO_BROADCAST failed (%i)"), SocketSubsystem->GetSocketAPIName(), (int32)SocketSubsystem->GetLastErrorCode());
    //    return false;
    //}

    //if (NewSocket->SetReuseAddr(bReuseAddressAndPort) == false)
    //{
    //    UE_LOG(LogGameIpNetDriver, Log, TEXT("setsockopt with SO_REUSEADDR failed"));
    //}

    //if (NewSocket->SetRecvErr() == false)
    //{
    //    UE_LOG(LogGameIpNetDriver, Log, TEXT("setsockopt with IP_RECVERR failed"));
    //}

    //// Increase socket queue size, because we are polling rather than threading
    //// and thus we rely on the OS socket to buffer a lot of data.
    //int32 RecvSize = ClientDesiredSocketReceiveBufferBytes;
    //int32 SendSize = ClientDesiredSocketSendBufferBytes;
    //NewSocket->SetReceiveBufferSize(RecvSize, RecvSize);
    //NewSocket->SetSendBufferSize(SendSize, SendSize);
    //UE_LOG(LogInit, Log, TEXT("%s: NewSocket queue %i / %i"), SocketSubsystem->GetSocketAPIName(), RecvSize, SendSize);

    //// Bind socket to our port.
    //LocalAddr = SocketSubsystem->GetLocalBindAddr(*GLog);

    //LocalAddr->SetPort(GetClientPort());

    //int32 AttemptPort = LocalAddr->GetPort();
    //int32 BoundPort = SocketSubsystem->BindNextPort(NewSocket, *LocalAddr, MaxPortCountToTry + 1, 1);
    //if (BoundPort == 0)
    //{
    //    UE_LOG(LogGameIpNetDriver, Error, TEXT("%s: binding to port %i failed (%i)"), SocketSubsystem->GetSocketAPIName(), AttemptPort,
    //        (int32)SocketSubsystem->GetLastErrorCode());
    //    return false;
    //}
    //if (NewSocket->SetNonBlocking() == false)
    //{
    //    UE_LOG(LogGameIpNetDriver, Error, TEXT("%s: SetNonBlocking failed (%i)"), SocketSubsystem->GetSocketAPIName(),
    //        (int32)SocketSubsystem->GetLastErrorCode());
    //    return false;
    //}

    //// If the cvar is set and the socket subsystem supports it, create the receive thread.
    ////if (CVarNetIpNetDriverUseReceiveThread.GetValueOnAnyThread() != 0 && SocketSubsystem->IsSocketWaitSupported())
    //if (SocketReceiveThreadValid && SocketSubsystem->IsSocketWaitSupported())
    //{
    //    //SocketReceiveThreadRunnable = MakeUnique<FReceiveThreadRunnable>(this);
    //    //SocketReceiveThread.Reset(FRunnableThread::Create(SocketReceiveThreadRunnable.Get(), *FString::Printf(TEXT("IpNetDriver Receive Thread"), *NetDriverName.ToString())));
    //    UE_LOG(LogGameIpNetDriver, Fatal, TEXT("SocketReceiveThreadRunnable create failed: %s"), *GetDescription());
    //    return false;
    //}

    //// Success.
    //UE_LOG(LogGameIpNetDriver, Log, TEXT("RecreateUDPSocketInClient succeed %s, new port: %d"), *GetDescription(), BoundPort);
    return true;
}

void UGameIpNetDriver::AddCustomStatelessHandlers()
{
    Super::AddCustomStatelessHandlers();
    AddReconnectComponentHandler();
}

void UGameIpNetDriver::AddReconnectComponentHandler()
{
    bool bEnabled;
    if (!GConfig->GetBool(TEXT("/Script/Common.CustomPacketHandlers"), TEXT("bEnableReconnectComponentHandler"), bEnabled, GEngineIni))
    {
        UE_LOG(LogGameIpNetDriver, Warning, TEXT("The [/Script/Common.CustomPacketHandlers]:bEnableReconnectComponentHandler flag has not been set"));
        bEnabled = false;
    }

    if (!bEnabled)
    {
        UE_LOG(LogGameIpNetDriver, Log, TEXT("UGameIpNetDriver::AddReconnectComponentHandler do NOT add ReconnectComponentHandler."));
        return;
    }

    if (!ConnectionlessHandler.IsValid())
    {
        UE_LOG(LogGameIpNetDriver, Warning, TEXT("UGameIpNetDriver::AddReconnectComponentHandler add failed. ConnectionlessHandler not valid."));
        return;
    }

    // Add handling for the stateless connect reconnect, for connectionless packets, as the outermost layer
    TSharedPtr<HandlerComponent> NewComponent =
        ConnectionlessHandler->AddHandler(TEXT("Common.ReconnectHandlerComponentFactory(ReconnectHandlerComponent)"), true);

    ReconnectComponent = StaticCastSharedPtr<ReconnectHandlerComponent>(NewComponent);
    if (!ReconnectComponent.IsValid())
    {
        UE_LOG(LogGameIpNetDriver, Warning, TEXT("UGameIpNetDriver::AddReconnectComponentHandler add failed. ReconnectComponent not valid."));
        return;
    }

    ReconnectComponent.Pin()->SetDriver(this);
    UE_LOG(LogGameIpNetDriver, Log, TEXT("UGameIpNetDriver::AddReconnectComponentHandler add successfully."));
}

void UGameIpNetDriver::SetActorAsyncCreatingEnabled(bool Enabled)
{
    EnableActorAsyncCreating = Enabled;
    GuidCache->SetAsyncLoadMode(Enabled ? FNetGUIDCache::EAsyncLoadMode::ForceEnable : FNetGUIDCache::EAsyncLoadMode::UseCVar);
}

bool UGameIpNetDriver::InitBase(bool bInitAsClient, FNetworkNotify* InNotify, const FURL& URL, bool bReuseAddressAndPort, FString& Error)
{
    bool Ret = Super::InitBase(bInitAsClient, InNotify, URL, bReuseAddressAndPort, Error);
    if (Ret && !OnDisconnectHandle.IsValid())
    {
        NeedCallDisconnectDelegate = false;
        OnDisconnectHandle = FGameDelegates::Get().GetHandleDisconnectDelegate().AddUObject(this, &UGameIpNetDriver::OnDisconnect);
    }
    return Ret;
}

void UGameIpNetDriver::PostTickFlush()
{
    Super::PostTickFlush();

    if (NeedCallDisconnectDelegate)
    {
        NeedCallDisconnectDelegate = false;
        if (auto GameCommon = UGameCommon::Get(this))
        {
            if (auto DelegateManager = GameCommon->GetGameDelegateManager())
            {
                DelegateManager->GameState->OnMatchDisconnected.ExecuteIfBound();
            }
        }
    }
}

void UGameIpNetDriver::Shutdown()
{
    if (OnDisconnectHandle.IsValid())
    {
        FGameDelegates::Get().GetHandleDisconnectDelegate().Remove(OnDisconnectHandle);
        OnDisconnectHandle.Reset();
    }

    Super::Shutdown();
}

void UGameIpNetDriver::OnDisconnect(UWorld* InWorld, UNetDriver* NetDriver)
{
    if (this == NetDriver)
    {
        NeedCallDisconnectDelegate = true;
    }
}