// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMObject.h"
#include "ProtobufCodec.h"
#include "ProtobufMessageRef.h"
#include "ProtobufDispatcher.h"
#include "NetworkManagerBase.generated.h"

//////////////////////////////////////////////////////////////////////////////////////////////////////////
UCLASS()
class COMMON_API UNetworkManagerBase : public UKMObject
{
    GENERATED_UCLASS_BODY()

public:
    virtual void Init();
    virtual void Uninit();
    virtual void Tick(float DeltaTime) {}

    UFUNCTION()
    void SetProtoFile(const FString& FileName);
    
    UFUNCTION()
    FString ConvertIPToString(uint32 IPv4);

	UFUNCTION()
	void SetEnableLog(bool Enable) { EnableLog = Enable; }

	UFUNCTION()
	void SetIgnoreMessageLog(const TArray<FName>& Names);

    UFUNCTION()
    void SetProtoIds(const TMap<uint16, FString>& Ids);

    TWeakPtr<ProtobufCodec> GetCodec() const { return Codec; }
    TWeakPtr<ProtobufDispatcher> GetDispatcher() const { return Dispatcher; }

    static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

private:

    void RegisterUnregisteredMessages();

protected:
	void PrintLog(const TCHAR* Prefix, const google::protobuf::Message* Message);
    virtual void OnMessage(int32 SenderId, const google::protobuf::Message* Message);

protected:

    TSharedPtr<ProtobufCodec> Codec;
    TSharedPtr<ProtobufDispatcher> Dispatcher;
    UProtobufMessageRef* MsgRef;

	bool EnableLog;
	TSet<FName> IgnoreMessages;
};
