#pragma once

#include "KMObject.h"
#include "PiratesGameNetDelegate.generated.h"

UCLASS()
class COMMON_API UPiratesGameNetDelegate : public UKMObject
{
    GENERATED_BODY()
    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnClientReconnectDelegate, FString, Address, uint64, PlayerId, uint32, Token);
    DECLARE_DYNAMIC_DELEGATE_SixParams(FOnRecvActorInfoBeforeNetInit, UObject*, ActorChannel, AActor*, Actor, int, LogicInstanceId, UObject*, ProtobufMessageRef, uint32, ActorNetGuid, bool, LoadAsync);

public:
    UPROPERTY()
    FOnClientReconnectDelegate OnClientReconnect;

    UPROPERTY()
    FOnRecvActorInfoBeforeNetInit OnRecvActorInfoBeforeNetInit;
};
