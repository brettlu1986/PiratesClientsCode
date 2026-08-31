#pragma once
#include "GameFramework/OnlineSession.h"
#include "PiratesOnlineSession.generated.h"

UCLASS()
class COMMON_API UPiratesOnlineSession : public UOnlineSession
{
    GENERATED_BODY()

public:
    // 与DedicatedServer断开连接后不进行travel，等着hub回消息
    virtual void HandleDisconnect(UWorld *World, class UNetDriver *NetDriver) override {}
};