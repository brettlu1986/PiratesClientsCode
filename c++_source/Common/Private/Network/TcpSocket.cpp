#include "Network/TcpSocket.h"
#include "Common.h"
#include "Misc/AssertionMacros.h"
#include "GamePlatformMisc.h"

DECLARE_LOG_CATEGORY_CLASS(LogTcpSocket, Display, All);

static const int32 MESSAGE_LEN_SIZE = sizeof(uint16);
static const int32 MAX_MESSAGE_SIZE = 0xffff;
static const int32 SEND_BUFFER_SIZE = MAX_MESSAGE_SIZE  + MESSAGE_LEN_SIZE;
static const int32 RECV_BUFFER_SIZE = (MAX_MESSAGE_SIZE + MESSAGE_LEN_SIZE) * 4;
static const float MAX_CHECK_NET_STATE_TIME = 2.0f;

UTcpSocket::UTcpSocket(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
    , SocketID(0)
    , Codec(nullptr)
    , SocketSendBufferSize(0)
    , SocketRecvBufferSize(0)
    , ConnectTimeout(1.0f)
    , TimeSinceConnectBegin(0)
    , CheckNetStateTime(0)
    , Socket(nullptr)
    , State(ETcpSocketState::NotConnected)
    , IgnoreSpecificError(false)
    , ConnectionPort(0)
    , UseOpenSSL(false)
{
}

//UTcpSocket::UTcpSocket(FSocket* ConnectedSocket)
//    : UTcpSocket()
//{
//    Socket = TUniquePtr<FSocket>(ConnectedSocket);
//}

//UTcpSocket::~UTcpSocket()
//{
//}

void UTcpSocket::Init(int32 InSocketID,
    const FString& InDescription,
    ProtobufCodec* InCodec,
    int32 InSocketSendBufferSize,
    int32 InSocketRecvBufferSize,
    float InConnectTimeout)
{
    SocketID = InSocketID;
    Description = InDescription;
    Codec = InCodec;
    SocketSendBufferSize = InSocketSendBufferSize;
    SocketRecvBufferSize = InSocketRecvBufferSize;
    ConnectTimeout = InConnectTimeout;
    CheckNetStateTime = 0;
    
    RecvBuffer.Init(RECV_BUFFER_SIZE);
    SendBuffer.Init(SEND_BUFFER_SIZE);
    
    if (!OpenSSLHelper.Init())
    {
        UE_LOG(LogTcpSocket, Fatal, TEXT("Init openssl failed."));
    }    
}

bool UTcpSocket::Connect(const FString& Endpoint)
{
    TSharedRef<FInternetAddr> Address = ISocketSubsystem::Get()->CreateInternetAddr();
    bool bIsIpValid = false;
    Address->SetIp(*Endpoint, bIsIpValid);
    if (!bIsIpValid)
    {
        UE_LOG(LogTcpSocket, Warning, TEXT("[CONN] Failed to connect, invalid endpoint: %s"), *Endpoint);
        return false;
    }

    DomainName = TEXT("");
    ConnectionInfo = Endpoint;
    UseOpenSSL = false;
    return Connect(Address.Get());
}

bool UTcpSocket::Connect(const FString& InDomainName, uint32 Port, bool InUseOpenSSL)
{
    DomainName = InDomainName;
    ConnectionInfo = FString::Printf(TEXT("%s:%d"), *DomainName, Port);
    ConnectionPort = Port;
    UseOpenSSL = InUseOpenSSL;

    FAddressInfoResult Results = ISocketSubsystem::Get()->GetAddressInfo(*InDomainName,
        *FString::Printf(TEXT("%d"), Port),
        EAddressInfoFlags::AllResultsWithMapping | EAddressInfoFlags::OnlyUsableAddresses,
#if PLATFORM_IOS | PLATFORM_MAC
        FNetworkProtocolTypes::IPv6,
#else
        NAME_None,
#endif
        ESocketType::SOCKTYPE_Streaming);

    if (Results.ReturnCode == SE_NO_ERROR && Results.Results.Num() > 0)
    {
        auto Address = Results.Results[0].Address;
        Address->SetPort(Port);
        return Connect(Address.Get());
    }
    else
    {
        UE_LOG(LogTcpSocket, Warning, TEXT("[CONN] Host resolved failed: %s:%d, error code: %d"), *InDomainName, Port, Results.ReturnCode);
        return false;
    }
}

bool UTcpSocket::ConnectIPWithOpenSSL(const FString& Endpoint, const FString& InDomainName)
{
    TSharedRef<FInternetAddr> Address = ISocketSubsystem::Get()->CreateInternetAddr();
    bool bIsIpValid = false;
    Address->SetIp(*Endpoint, bIsIpValid);
    if (!bIsIpValid)
    {
        UE_LOG(LogTcpSocket, Warning, TEXT("[CONN] Failed to connect, invalid endpoint: %s"), *Endpoint);
        return false;
    }

    ConnectionInfo = Endpoint;
    UseOpenSSL = true;
    DomainName = InDomainName;
    return Connect(Address.Get());
}

bool UTcpSocket::Connect(const FInternetAddr& Address)
{
    if (!Address.IsValid())
    {
        ConnectResultDelegate.ExecuteIfBound(*this);
        return false;
    }

    if (State == ETcpSocketState::Connecting)
        return false;

    check(!Socket.IsValid());

    FSocket* NewSocket = CreateSocket();
    check(NewSocket);

    auto ClearSocket = [&] {
        auto SocketSystem = ISocketSubsystem::Get();
        auto ErrorCode = SocketSystem->GetLastErrorCode();
        UE_LOG(LogTcpSocket, Warning, TEXT("[CONN] Failed to connect %s, address: %s, errorCode [%d]"),
            *ConnectionInfo, *Address.ToString(true), (int)ErrorCode);
        delete NewSocket;
        ConnectResultDelegate.ExecuteIfBound(*this);
    };

    if (!NewSocket->Connect(Address))
    {
        ClearSocket();        
        return false;
    }

    if (UseOpenSSL)
    {
#if !(PLATFORM_WINDOWS || PLATFORM_MAC || PLATFORM_IOS || PLATFORM_UNIX || PLATFORM_ANDROID)
        UE_LOG(LogOpenSSLTcpSocket, Fatal, TEXT("OpenSSLTcpSocket does not support this platform."));
        ClearSocket();
        return false;
#endif

        check(DomainName.Len() > 0);
        extern int GetBSDNativeSocket(FSocket* Socket);
        auto RawSocket = GetBSDNativeSocket(NewSocket);

        if (!OpenSSLHelper.Connect(RawSocket, *DomainName))
        {            
            ClearSocket();
            return false;
        }
    }

    UE_LOG(LogTcpSocket, Display, TEXT("[CONN] Connecting %s, address: %s"), *ConnectionInfo, *Address.ToString(true));
    Socket = TUniquePtr<FSocket>(NewSocket);
    TimeSinceConnectBegin = 0;
    CheckNetStateTime = 0;
    State = ETcpSocketState::Connecting;

    return true;
}

void UTcpSocket::Close()
{
    ETcpSocketState OldState = State;

    if (OldState == ETcpSocketState::Connected)
    {
        UE_LOG(LogTcpSocket, Display, TEXT("[CONN] Disconnected from %s"), *ConnectionInfo);
    }

    RecvBuffer.Reset();
    SendBuffer.Reset();
    TimeSinceConnectBegin = 0;
    CheckNetStateTime = 0;
    State = ETcpSocketState::NotConnected;
    Socket = nullptr;
    OpenSSLHelper.Close();
    UseOpenSSL = false;    

    if (OldState == ETcpSocketState::Connected)
    {
        DisconnectDelegate.ExecuteIfBound(*this);
    }
}

bool UTcpSocket::Send(const google::protobuf::Message& Message)
{
    const char* MessageName = Message.GetDescriptor()->name().c_str();

    if (!IsConnected())
    {
        UE_LOG(LogTcpSocket, Display, TEXT("[SEND] Not connected, unable to send: %s"), UTF8_TO_TCHAR(MessageName));
        return false;
    }

    uint8 Buffer[SEND_BUFFER_SIZE];
    int32 OutMessageSize = 0;
    if (!Codec->Encode(Message, Buffer + MESSAGE_LEN_SIZE, sizeof(Buffer) - MESSAGE_LEN_SIZE, OutMessageSize))
    {
        UE_LOG(LogTcpSocket, Warning, TEXT("[SEND] Message is too big to be sent: %s"), UTF8_TO_TCHAR(MessageName));
        return false;
    }

    check(OutMessageSize > 0);
    UE_LOG(LogTcpSocket, Verbose, TEXT("[SEND] %d %s"), OutMessageSize, UTF8_TO_TCHAR(MessageName));

    // Set message frame size
    // Note: this is little endian
    *((uint16*)Buffer) = (uint16)OutMessageSize;
    
    int32 TotalBytesSent = 0;
    int32 RemainBufferSize = OutMessageSize + MESSAGE_LEN_SIZE;
    bool bNeedPushToSendBuffer = SendBuffer.GetUsedSize() > 0;
    if (!bNeedPushToSendBuffer)
    {
        // 尝试发送        
        if (Send(Buffer, RemainBufferSize, TotalBytesSent))
        {
            RemainBufferSize -= TotalBytesSent;
            if (RemainBufferSize > 0)
            {
                // 没发完，Push到SendBuffer里，下帧再发
                bNeedPushToSendBuffer = true;
            }
        }
        else
        {
            // 发失败了，Close在Send里做了，这里就不做了
            UE_LOG(LogTcpSocket, Display, TEXT("[SEND] failed: %s"), UTF8_TO_TCHAR(MessageName));
            return false;
        }
    }

    if (bNeedPushToSendBuffer)
    {
        if (SendBuffer.GetUnusedSize() <= RemainBufferSize)
        {
            // 剩余buffer不够了，重新调整下
            SendBuffer.Reorganize();
            if (SendBuffer.GetUnusedSize() <= RemainBufferSize)
            {
                // 实在没地方存了，直接断
                UE_LOG(LogTcpSocket, Error, TEXT("[SEND] Send [%s] failed, SendBuffer is full !!!"), UTF8_TO_TCHAR(MessageName));
                Close();
                return false;
            }
        }

        SendBuffer.Push(Buffer + TotalBytesSent, RemainBufferSize);
    }    

    return true;
}

void UTcpSocket::Tick(float DeltaTime)
{
    VerifyNetState(DeltaTime);    
    PollConnectionState(DeltaTime);
    Send();
    Recv();
}

inline FSocket* UTcpSocket::CreateSocket() const
{
    FTcpSocketBuilder Builder(Description);
    // Non-blocking is very important!
    Builder.AsNonBlocking();
    Builder.WithSendBufferSize(SocketSendBufferSize);
    Builder.WithReceiveBufferSize(SocketRecvBufferSize);
    return Builder.Build();
}

inline void UTcpSocket::PollConnectionState(float DeltaTime)
{
    if (!Socket.IsValid())
    {
        return;
    }

    if (State == ETcpSocketState::Connecting)
    {
        auto OldState = State;
        auto SocketSystem = ISocketSubsystem::Get();
        ESocketConnectionState ConnectionState = Socket->GetConnectionState();
        switch (ConnectionState)
        {
            case SCS_NotConnected:
                TimeSinceConnectBegin += DeltaTime;
                if (TimeSinceConnectBegin >= ConnectTimeout)
                {
                    UE_LOG(LogTcpSocket, Display, TEXT("[CONN] Connect to %s has timed out"), *ConnectionInfo);
                    State = ETcpSocketState::NotConnected;
                }
                break;
            case SCS_Connected:                
                if (UseOpenSSL)
                {
                    auto OSSLState = OpenSSLHelper.VerifyState();
                    if (OSSLState == EOpenSSLState::ConnectSuccessed)
                    {
                        State = ETcpSocketState::Connected;
                        UE_LOG(LogTcpSocket, Display, TEXT("[CONN] Openssl connected to %s"), *ConnectionInfo);
                    }
                    else if (OSSLState == EOpenSSLState::ConnectFailed)
                    {
                        UE_LOG(LogTcpSocket, Display, TEXT("[CONN] Connect to %s failed, openssl verify failed."), *ConnectionInfo);
                        State = ETcpSocketState::NotConnected;
                    }
                }
                else
                {
                    State = ETcpSocketState::Connected;
                    UE_LOG(LogTcpSocket, Display, TEXT("[CONN] Connected to %s"), *ConnectionInfo);
                }
                break;
            case SCS_ConnectionError:
                UE_LOG(LogTcpSocket, Display, TEXT("[CONN] Failed to connect %s, ErrorCode [%d]"), 
                    *ConnectionInfo,
                    (int)ISocketSubsystem::Get()->GetLastErrorCode());
                State = ETcpSocketState::NotConnected;                
                break;
            default:
                break;
        }

        if (State != OldState)
        {
            if (State == ETcpSocketState::NotConnected)
            {
                Close();
            }
            ConnectResultDelegate.ExecuteIfBound(*this);
        }
    }
}

void UTcpSocket::Recv()
{
    if (!Socket.IsValid() || !IsConnected())
    {
        return;
    }

    int32  BytesRead        = 0;
    uint16 MessageSize      = 0;

    while (true)
    {
        uint8* Buffer = RecvBuffer.GetUnusedBuffer();
        int32 BufferMaxSize = RecvBuffer.GetUnusedSize();
        if (BufferMaxSize == 0)
        {
            RecvBuffer.Reorganize();
            BufferMaxSize = RecvBuffer.GetUnusedSize();
            if (BufferMaxSize == 0)
            {
                // 实在没地方就直接断
                UE_LOG(LogTcpSocket, Error, TEXT("[RECV] RecvBuffer is full !!!"));
                Close();
                break;
            }
        }

        // EOF
        if (!RecvRaw(Buffer, BufferMaxSize, BytesRead))
        {
            if (ISocketSubsystem::Get()->GetLastErrorCode() == SE_EWOULDBLOCK)
            {
                // 缓冲区满了,下帧再说吧
                break;
            }
            else if (IgnoreSpecificError && ISocketSubsystem::Get()->GetLastErrorCode() == SE_ECONNABORTED)
            {
                // 忽略错误，下针再发
                UE_LOG(LogTcpSocket, Warning, TEXT("[RECV] recv failed, ignore ErrorCode [%d]"),
                    (int)ISocketSubsystem::Get()->GetLastErrorCode());
                break;
            }

            UE_LOG(LogTcpSocket, Display, TEXT("[RECV] Socket closed, ErrorCode [%d], NetState [%d]"), 
                (int)ISocketSubsystem::Get()->GetLastErrorCode(), (int)FGamePlatformMisc::CheckNetState());
            
            Close();
            break;
        }

        // No data available
        if (BytesRead == 0)
        {
            break;
        }

        RecvBuffer.Push(BytesRead);

        // Split received data into messages by 2-byte length header, decode and dispatch them.
        while (true)
        {
            // No complete message available because we haven't received the header yet.
            if (RecvBuffer.GetUsedSize() < MESSAGE_LEN_SIZE)
                break;

            const uint8* RecvHead = RecvBuffer.GetUsedBuffer();
            MessageSize = *((const uint16*)RecvHead);
            // Header received, however the message is not complete.
            if (RecvBuffer.GetUsedSize() < MESSAGE_LEN_SIZE + MessageSize)
                break;

            // Deal with complete message.
            Dispatch(0, RecvHead + MESSAGE_LEN_SIZE, MessageSize);
            RecvBuffer.Pop(MESSAGE_LEN_SIZE + MessageSize);
        }
    }
}

void UTcpSocket::Send()
{
    if (!Socket.IsValid() || !IsConnected())
    {
        return;
    }

    if (SendBuffer.GetUsedSize() > 0)
    {
        int ByteSent = 0;
        if (Send(SendBuffer.GetUsedBuffer(), SendBuffer.GetUsedSize(), ByteSent))
        {
            SendBuffer.Pop(ByteSent);
        }
    }
}

bool UTcpSocket::Send(const uint8* Buffer, int32 BufferSize, int32& TotalBytesSent)
{
    if (State != ETcpSocketState::Connected)
        return false;

    const uint8* BufferHead = Buffer;
    int32  BytesRemain = BufferSize;
    int32 BytesSent = 0;
    while (BytesRemain > 0)
    {
        if (SendRaw(BufferHead, BytesRemain, BytesSent))
        {
            BytesRemain -= BytesSent;
            BufferHead += BytesSent;
        }
        else if (ISocketSubsystem::Get()->GetLastErrorCode() == SE_EWOULDBLOCK)
        {
            // 缓冲区满了发不出去，下帧再说吧
            break;
        }
        else if (IgnoreSpecificError && ISocketSubsystem::Get()->GetLastErrorCode() == SE_ECONNABORTED)
        {
            // 忽略错误，下针再发
            UE_LOG(LogTcpSocket, Warning, TEXT("[SEND] send failed, ignore ErrorCode [%d]"),
                (int)ISocketSubsystem::Get()->GetLastErrorCode());
            break;
        }
        else
        {
            UE_LOG(LogTcpSocket, Display, TEXT("[SEND] send failed, ErrorCode [%d]"),
                (int)ISocketSubsystem::Get()->GetLastErrorCode());
            Close();
            return false;
        }
    }
    TotalBytesSent = BufferSize - BytesRemain;
    return true;
}

void UTcpSocket::Dispatch(uint16 MessageID, const uint8* Data, int32 Size)
{
    DispatchDelegate.ExecuteIfBound(GetSocketID(), MessageID, Data, Size);
}

void UTcpSocket::VerifyNetState(float DeltaTime)
{
    if (State != ETcpSocketState::Connected)
    {
        return;
    }

    bool bCheck = false;
    CheckNetStateTime += DeltaTime;
    while (CheckNetStateTime >= MAX_CHECK_NET_STATE_TIME)
    {
        bCheck = true;
        CheckNetStateTime -= MAX_CHECK_NET_STATE_TIME;
    }

    if (!bCheck)
    {
        return;
    }

    // 因为这函数要调用原生接口，所以这里不每针调用
    EGameNetState NetState = FGamePlatformMisc::CheckNetState();
    if (NetState == EGameNetState::DisconnectionState)
    {
        UE_LOG(LogTcpSocket, Warning, TEXT("VerifyNetState socket closed, ErrorCode [%d]"),
            (int)ISocketSubsystem::Get()->GetLastErrorCode());
        Close();
    }
}


bool UTcpSocket::SendRaw(const uint8* Data, int32 BufferSize, int32& BytesSent)
{
    if (UseOpenSSL)
    {                
        return OpenSSLHelper.Send(Data, BufferSize, BytesSent);
    }
    else
    {
        return Socket->Send(Data, BufferSize, BytesSent);
    }    
}

bool UTcpSocket::RecvRaw(uint8* Data, int32 BufferSize, int32& BytesRead)
{
    if (UseOpenSSL)
    {                
        return OpenSSLHelper.Recv(Data, BufferSize, BytesRead);
    }
    else
    {
        return Socket->Recv(Data, BufferSize, BytesRead);
    }    
}