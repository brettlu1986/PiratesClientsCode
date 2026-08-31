// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/NetworkManagerBase.h"
#include "Common.h"


#include "ProtobufCodec.h"
#include "ProtobufDispatcher.h"
#include "ProtobufMessageRef.h"

#include "Interfaces/IPv4/IPv4Address.h"

DEFINE_LOG_CATEGORY_STATIC(NetworkManagerBaseLog, Log, All);

UNetworkManagerBase::UNetworkManagerBase(const FObjectInitializer& ObjectInitializer) 
    : Super(ObjectInitializer)
    , MsgRef(nullptr)
	, EnableLog(true)
{
}

void UNetworkManagerBase::Init()
{
    Codec = MakeShareable(new ProtobufCodec());
    Dispatcher = MakeShareable(new ProtobufDispatcher);
    MsgRef = NewObject<UProtobufMessageRef>();
}

void UNetworkManagerBase::Uninit()
{
    Codec->ClearProtoFileInfo();
}

FString UNetworkManagerBase::ConvertIPToString(uint32 IPv4)
{
    // WARNING： FIPv4Address中有判断Endian，客户端需要和服务端一致
    FIPv4Address Address(IPv4);
    return Address.ToString();
}

void UNetworkManagerBase::SetIgnoreMessageLog(const TArray<FName>& Names)
{
	IgnoreMessages.Empty(Names.Num());
	IgnoreMessages.Append(Names);
}

void UNetworkManagerBase::SetProtoIds(const TMap<uint16, FString>& Ids)
{
    Codec->SetProtoIds(Ids);
}

void UNetworkManagerBase::RegisterUnregisteredMessages()
{
    auto Callback = [this](auto senderId, auto message) {
        this->OnMessage(senderId, message);
    };
    const auto& FileDescriptors = Codec->GetFileDescriptorArray();
    for (auto &FileDescriptor : FileDescriptors)
    {
        const auto MsgTypeCount = FileDescriptor->message_type_count();
        for (int i = 0; i < MsgTypeCount; ++i)
        {
            auto Descriptor = FileDescriptor->message_type(i);
            if (!Dispatcher->HasRegistered(Descriptor))
            {
                Dispatcher->Register(Descriptor, Callback);
            }
        }
    }
}

void UNetworkManagerBase::PrintLog(const TCHAR* Info, const google::protobuf::Message* Message)
{
	if (!EnableLog)
	{
		return;
	}
	check(Info && Message);

	FName Name(UTF8_TO_TCHAR(Message->GetDescriptor()->name().c_str()));
	if (IgnoreMessages.Find(Name))
	{
		return;
	}

	UE_LOG(NetworkManagerBaseLog, Log, TEXT("%s Message[%s] ByteSize: %d, Data:\n%s"), Info,
		*Name.ToString(), Message->ByteSize(), UTF8_TO_TCHAR(Message->Utf8DebugString().c_str()));
}

void UNetworkManagerBase::OnMessage(int32 SenderId, const google::protobuf::Message* Message)
{    
}

void UNetworkManagerBase::SetProtoFile(const FString& FileName)
{
    check(FileName.Len() > 0);

    Codec->SetProtoFile(FileName, google::protobuf::DescriptorPool::generated_pool(),
        google::protobuf::MessageFactory::generated_factory());

    RegisterUnregisteredMessages();
}

void UNetworkManagerBase::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
    Super::AddReferencedObjects(InThis, Collector);
    UNetworkManagerBase* This = CastChecked<UNetworkManagerBase>(InThis);
    Collector.AddReferencedObject(This->MsgRef, This);
}
