// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/SocketNetworkManager.h"
#include "Common.h"
#include "ProtobufCodec.h"
#include "ProtobufDispatcher.h"
#include "TcpSocket.h"
#include "google/protobuf/util/json_util.h"
#include "Util/MessageLuaUtil.h"
#include "ProtobufMessageRef.h"
#include "Util/LuaTableRef.h"

DECLARE_STATS_GROUP(TEXT("RecvTCPMessage"), STATGROUP_RecvTCPMessage, STATCAT_Advanced);
DEFINE_LOG_CATEGORY_STATIC(SocketNetworkManagerLog, Log, All);

USocketNetworkManager::USocketNetworkManager(const FObjectInitializer& ObjectInitializer) 
    : Super(ObjectInitializer)
    , TempDecodeMessage(nullptr)
    , SendBufferSize(1024*4)
    , RecvBufferSize(1024*8)
    , ConnectTimeout(3.0f)
    , MessageQueueInitSize(1024*8)
    , PacketProcessMaxTimePerTick(0.015f)
    , QueueProcessFactor(1024)
    , EnableMessageQueue(true)
    , EnablePending(false)    
    , WriteIdleTime(0.f)
    , ReadIdleTime(0.f)
{
}

bool USocketNetworkManager::CreateSocket(int32 InSocketID, const FString& InDescription, int32 OverrideSendBufferSize /* = 0 */, int32 OverrideRecvBufferSize /* = 0 */)
{
    for (int ii=0; ii<Sockets.Num(); ii++)
    {
        if (InSocketID == Sockets[ii]->GetSocketID())
        {
            UE_LOG(SocketNetworkManagerLog, Error, TEXT("SendPacket create failed, the socket id [%d] is duplicated."),
                InSocketID);
            return false;
        }
    }
    int32 FinalSendBufferSize = OverrideSendBufferSize > 0 ? OverrideSendBufferSize : SendBufferSize;
    int32 FinalRecvBufferSize = OverrideRecvBufferSize > 0 ? OverrideRecvBufferSize : RecvBufferSize;
    UE_LOG(SocketNetworkManagerLog, Log, TEXT("Send Buffer Size: %d, Recv Buffer Size:%d"), FinalSendBufferSize, FinalRecvBufferSize);

    UTcpSocket* Socket = NewObject<UTcpSocket>();
    Socket->Init(
        InSocketID,
        InDescription,
        Codec.Get(),
        FinalSendBufferSize,
        FinalRecvBufferSize,
        ConnectTimeout);

    Socket->OnConnectResultDelegate().BindUObject(this, &USocketNetworkManager::OnConnectedResultFunc);
    Socket->OnDisconnect().BindUObject(this, &USocketNetworkManager::OnDisconnectedFunc);
    Socket->OnDispatch().BindUObject(this, &USocketNetworkManager::OnDispatch);
    Sockets.Add(Socket);

    return true;
}

bool USocketNetworkManager::DestroySocket(int32 InSocketID)
{
	for (int ii = 0; ii < Sockets.Num(); ii++)
    {
        if (InSocketID == Sockets[ii]->GetSocketID())
        {
			UE_LOG(SocketNetworkManagerLog, Log, TEXT("DestroySocket %d."), InSocketID);
			Sockets[ii]->Close();
            Sockets.RemoveAt(ii);

            return true;
        }
    }
    return false;
}

void USocketNetworkManager::DestroyAllSockets()
{
	UE_LOG(SocketNetworkManagerLog, Log, TEXT("DestroyAllSockets"));
	for (int ii = 0; ii < Sockets.Num(); ii++)
    {
        Sockets[ii]->Close();
    }
    Sockets.Empty();

    WriteIdleDurations.Empty();
    ReadIdleDurations.Empty();
    ClearTempDecodeMessage();
}

void USocketNetworkManager::Init()
{
    Super::Init();
    if (EnableMessageQueue)
    {
        MessageQueue.Init(MessageQueueInitSize);
    }    

    TempDecodeMessage = NewObject<UProtobufMessageRef>(this, TEXT("TempDecodeMessage"));
}

void USocketNetworkManager::Uninit()
{
    ClearTempDecodeMessage();
    DestroyAllSockets();
    Super::Uninit();    
}

void USocketNetworkManager::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);
    TickSockets(DeltaTime);

    if (EnableMessageQueue && !EnablePending)
    {
        float LimitTime = PacketProcessMaxTimePerTick;
        if (MessageQueue.GetQueueSize() >= QueueProcessFactor)
        {
            // 防止包越来越多
            LimitTime *= MessageQueue.GetQueueSize() / (float)QueueProcessFactor;
        }
        ProcessMessageQueue(true, LimitTime);
    }
}

bool USocketNetworkManager::Connect(int32 InSocketID, const FString& Endpoint)
{
    UTcpSocket* Socket = GetSocket(InSocketID);
    if (Socket)
    {
        UE_LOG(SocketNetworkManagerLog, Log, TEXT("USocketNetworkManager::Connect SocketID [%d], Endpoint [%s]"), InSocketID, *Endpoint);
        return Socket->Connect(Endpoint);
    }
    return false;
}

bool USocketNetworkManager::ConnectWithDomainName(int32 InSocketID, const FString& DomainName, uint32 Port, bool UseOpenSSL)
{
    UTcpSocket* Socket = GetSocket(InSocketID);
    if (Socket)
    {
        UE_LOG(SocketNetworkManagerLog, Log, TEXT("USocketNetworkManager::ConnectWithDomainName SocketID [%d], DomainName [%s], Port [%d], UseOpenssl [%d]"), InSocketID, *DomainName, Port, UseOpenSSL?1:0);
        return Socket->Connect(DomainName, Port, UseOpenSSL);
    }
    return false;
}

bool USocketNetworkManager::ConnectIPWithOpenSSL(int32 InSocketID, const FString& Endpoint, const FString& DomainName)
{
    UTcpSocket* Socket = GetSocket(InSocketID);
    if (Socket)
    {
        UE_LOG(SocketNetworkManagerLog, Log, TEXT("USocketNetworkManager::ConnectIPWithOpenSSL SocketID [%d], Endpoint [%s], DomainName [%s]"), InSocketID, *Endpoint, *DomainName);
        return Socket->ConnectIPWithOpenSSL(Endpoint, DomainName);
    }
    return false;
}

void USocketNetworkManager::Disconnect(int32 InSocketID)
{
    UTcpSocket* Socket = GetSocket(InSocketID);
    if (Socket)
    {
		UE_LOG(SocketNetworkManagerLog, Log, TEXT("USocketNetworkManager::Disconnect [%d]"), InSocketID);
		Socket->Close();
    }
}

bool USocketNetworkManager::IsConnected(int32 InSocketID)
{
    UTcpSocket* Socket = GetSocket(InSocketID);
    if (Socket)
    {
        return Socket->IsConnected();
    }
    return false;
}

bool USocketNetworkManager::SendPacketByTable(int32 InSocketID, const FString& MessageType, ULuaTableRef* TableRef)
{
    auto Message = FMessageLuaUtil::LuaTableToMessage(Codec.Get(), MessageType, LUA_TABLE_REF_U2F(TableRef));
    if (TableRef)
    {
        TableRef->TableRef = nullptr;
    }

    if (Message == nullptr)
    {
        UE_LOG(SocketNetworkManagerLog, Error, TEXT("SendPacket failed, the message type [%s] cannot be found"),
            *MessageType);
        return false;
    }
    bool bRet = SendPacket(InSocketID, Message);
    Codec->DestroyMessage(Message);
    
    return bRet;
}

bool USocketNetworkManager::SendPacket(int32 InSocketID, const google::protobuf::Message* Message)
{
	PrintLog(TEXT("SocketNetworkManager:Send"), Message);

    UTcpSocket* Socket = GetSocket(InSocketID);
    if (Socket)
    {
        bool bRet = Socket->Send(*Message);
        if (bRet)
        {
            float* pWriteIdle = WriteIdleDurations.Find(InSocketID);
            check(pWriteIdle != nullptr);
            *pWriteIdle = 0;
        }
        return bRet;
    }
    return false;
}

void USocketNetworkManager::SetPending(bool bPending)
{
    EnablePending = bPending;
	UE_LOG(SocketNetworkManagerLog, Log, TEXT("SetPending %s"), bPending ? TEXT("true"):TEXT("false"));
}

void USocketNetworkManager::SetIgnoreSpecificError(bool Ignore)
{
    for (int i = 0; i < Sockets.Num(); i++)
    {
        Sockets[i]->SetIgnoreSpecificError(Ignore);
    }
}

void USocketNetworkManager::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
    Super::AddReferencedObjects(InThis, Collector);
    USocketNetworkManager* This = CastChecked<USocketNetworkManager>(InThis);    
    Collector.AddReferencedObjects(This->Sockets, This);
}

void USocketNetworkManager::OnConnectedResultFunc(UTcpSocket& TCPSocket)
{
    bool IsConnected = TCPSocket.IsConnected();
    if (IsConnected)
    {
        int32 SocketID = TCPSocket.GetSocketID();

        check(WriteIdleDurations.Find(SocketID) == nullptr);
        WriteIdleDurations.Add(SocketID);

        check(ReadIdleDurations.Find(SocketID) == nullptr);
        ReadIdleDurations.Add(SocketID);
    }

    OnConnectedResult.ExecuteIfBound(TCPSocket.GetSocketID(), IsConnected);
}

void USocketNetworkManager::OnDisconnectedFunc(UTcpSocket& TCPSocket)
{
    UE_LOG(SocketNetworkManagerLog, Log, TEXT("Call OnPreDisconnected true"));
    OnPreDisconnected.ExecuteIfBound(TCPSocket.GetSocketID());

    bool bPending = EnablePending;
    SetPending(false);
    if (EnableMessageQueue)
    {
        //// force flush
        UE_LOG(SocketNetworkManagerLog, Log, TEXT("Flush messages before disconnected, message count [%d], queue size [%d]"),
            MessageQueue.GetMessageCount(), MessageQueue.GetQueueSize());
        ProcessMessageQueue(false, 0);
        
        // 直接清
        //MessageQueue.Reset();
        check(MessageQueue.GetMessageCount() == 0);
    }

    SetPending(bPending);
    UE_LOG(SocketNetworkManagerLog, Log, TEXT("Call OnPostDisconnected"));
    int32 SocketID = TCPSocket.GetSocketID();
    OnPostDisconnected.ExecuteIfBound(SocketID);

    WriteIdleDurations.Remove(SocketID);
    ReadIdleDurations.Remove(SocketID);
}

void USocketNetworkManager::OnDispatch(int32 SocketID, uint16 MessageID, const uint8* MessageData, int32 Size)
{
    check(MessageData && Size > 0);
    if (EnableMessageQueue)
    {
        MessageQueue.Push(SocketID, MessageID, MessageData, Size);
    }
    else
    {
        DecodeAndDispatch(SocketID, MessageID, MessageData, Size);
    }
}

void USocketNetworkManager::OnMessage(int32 InSocketID, const google::protobuf::Message* Message)
{
	PrintLog(TEXT("SocketNetworkManager:Recv"), Message);
	
    FString MessageType(UTF8_TO_TCHAR(Message->GetDescriptor()->name().c_str()));

#if STATS
    const TStatId StatId = FDynamicStats::CreateStatId<FStatGroup_STATGROUP_RecvTCPMessage>(FName(*MessageType));
    FScopeCycleCounter CycleCounter(StatId);
#endif

    MsgRef->Message = Message;
    OnReceivedMessage.ExecuteIfBound(InSocketID, MessageType, MsgRef);

    float* ReadIdle = ReadIdleDurations.Find(InSocketID);
    if (ReadIdle != nullptr)
    {
        *ReadIdle = 0;
    }
}

void USocketNetworkManager::DecodeAndDispatch(int32 SocketID, uint16 MessageID, const uint8* MessageData, int32 Size)
{
    check(MessageData && Size > 0);
    auto Message = Codec->Decode(MessageData, Size);
    if (Message != nullptr)
    {
        Dispatcher->Dispatch(SocketID, Message);
        UE_LOG(SocketNetworkManagerLog, Verbose, TEXT("[RECV] %d %s"), Size, UTF8_TO_TCHAR(Message->GetDescriptor()->name().c_str()));
        Codec->DestroyMessage(Message);
    }
    else
    {
        UE_LOG(SocketNetworkManagerLog, Warning, TEXT("[RECV] %d Unknown message"), Size);
    }
}

void USocketNetworkManager::TickSockets(float DeltaTime)
{
    int SocketCount = Sockets.Num();
    for (int ii=0; ii<SocketCount; ii++)
    {
        Sockets[ii]->Tick(DeltaTime);
        int32 SocketID = Sockets[ii]->GetSocketID();
        if (IsConnected(SocketID))
        {
            TickIdleTime(DeltaTime, SocketID);
        }
    }
}

void USocketNetworkManager::TickIdleTime(float DeltaTime, int32 SocketID)
{
    float* pWriteIdle = WriteIdleDurations.Find(SocketID);
    check(pWriteIdle != nullptr);
    float* pReadIdle = ReadIdleDurations.Find(SocketID);
    check(pReadIdle != nullptr);
    *pWriteIdle += DeltaTime;
    *pReadIdle += DeltaTime;
    if (WriteIdleTime > 0 && *pWriteIdle >= WriteIdleTime)
    {
        *pWriteIdle = 0;
        OnWriteIdleTimeout.ExecuteIfBound(SocketID, DeltaTime);
    }
    if (ReadIdleTime > 0 && *pReadIdle >= ReadIdleTime)
    {
        *pReadIdle = 0;
        OnReadIdleTimeout.ExecuteIfBound(SocketID, DeltaTime);
    }
}

void USocketNetworkManager::ProcessMessageQueue(bool UseTimelimit, float TimeLimit)
{
    const uint8* MessageData = nullptr;
    int32 MessageSize = 0;
    int32 SocketID = 0;
    uint16 MessageID = 0;
    double StartTime = FPlatformTime::Seconds();
    float RemainTime = TimeLimit;
    int32 MessageCount = MessageQueue.GetMessageCount();
    while (!EnablePending && (RemainTime > 0 || !UseTimelimit))
    {
        if (!MessageQueue.Pop(SocketID, MessageID, MessageData, MessageSize))
        {
            break;
        }

        DecodeAndDispatch(SocketID, MessageID, MessageData, MessageSize);

        double Now = FPlatformTime::Seconds();
        RemainTime -= (float)(Now - StartTime);
        StartTime = Now;
    }

    int32 RemainCount = MessageQueue.GetMessageCount();
    if (RemainTime <= 0 && RemainCount > 0)
    {
        UE_LOG(SocketNetworkManagerLog, Log, TEXT("USocketNetworkManager process [%d] packets in duration [%f], remain [%d] packets, message queue size: [%d]"), 
            MessageCount - RemainCount, TimeLimit - RemainTime, RemainCount, MessageQueue.GetQueueSize());
    }
}

UTcpSocket* USocketNetworkManager::GetSocket(int32 InSocketID)
{
    for (int i = 0; i < Sockets.Num(); i++)
    {
        if (Sockets[i]->GetSocketID() == InSocketID)
        {
            return Sockets[i];
        }
    }
    return nullptr;
}

FString USocketNetworkManager::MessageToBase64String(const FString& MessageType, ULuaTableRef* TableRef)
{
    uint8 TempBuffer[65535];
    auto Message = FMessageLuaUtil::LuaTableToMessage(Codec.Get(), MessageType, LUA_TABLE_REF_U2F(TableRef));
    if (TableRef)
    {
        TableRef->TableRef = nullptr;
    }
    if (Message == nullptr)
    {
        UE_LOG(SocketNetworkManagerLog, Error, TEXT("USocketNetworkManager::MessageToBase64String failed. Message type [%s]."), *MessageType);
        return TEXT("");
    }

    auto ByteSize = Message->ByteSizeLong();
    if (ByteSize > sizeof(TempBuffer)) 
    {
        UE_LOG(SocketNetworkManagerLog, Error, TEXT("USocketNetworkManager::MessageToBase64String failed. Buffer not enough. Message type [%s]."), *MessageType);
        return TEXT("");
    }

    if (!Message->SerializeToArray(TempBuffer, ByteSize))
    {
        UE_LOG(SocketNetworkManagerLog, Error, TEXT("USocketNetworkManager::MessageToBase64String SerializeToArray failed. Message type [%s]."), *MessageType);
        return TEXT("");
    }

    FString Base64Message = FBase64::Encode(TempBuffer, ByteSize);
    return Base64Message;
}

bool USocketNetworkManager::Base64StringToMessage(const FString& MessageType, const FString& Content, UProtobufMessageRef*& OutMessageRef)
{
    ClearTempDecodeMessage();

    TArray<uint8> ByteArray;
    if (!FBase64::Decode(Content, ByteArray))
    {
        UE_LOG(SocketNetworkManagerLog, Error, TEXT("USocketNetworkManager::Base64StringToMessage failed. Message type [%s]. Message [%s]"),
            *MessageType, *Content);
        return false;
    }

    auto Message = Codec->CreateMessage(TCHAR_TO_UTF8(*MessageType));
    if (!Message)
    {
        UE_LOG(SocketNetworkManagerLog, Error, TEXT("USocketNetworkManager::Base64StringToMessage CreateMessage failed. Message type [%s]. Message [%s]"),
            *MessageType, *Content);
        return false;
    }

    if (!Message->ParseFromArray(ByteArray.GetData(), ByteArray.Num()))
    {
        UE_LOG(SocketNetworkManagerLog, Error, TEXT("USocketNetworkManager::Base64StringToMessage ParseFromString failed. Message type [%s]. Message [%s]."),
            *MessageType, *Content);
        Codec->DestroyMessage(Message);
        return false;
    }

    TempDecodeMessage->Message = Message;
    OutMessageRef = TempDecodeMessage;
    return true;
}

void USocketNetworkManager::ClearTempDecodeMessage()
{
    if (TempDecodeMessage && Codec.IsValid() && TempDecodeMessage->Message)
    {
        Codec->DestroyMessage(TempDecodeMessage->Message);
        TempDecodeMessage->Message = nullptr;
    }
}

void USocketNetworkManager::SetIdleTime(float InWaitIdleTime, float InReadIdleTime)
{
    WriteIdleTime = InWaitIdleTime;
    ReadIdleTime = InReadIdleTime;
}