#pragma once

#include "Util/LuaTableRef.h"
#include "AI/AIGameCoreProxy/AIGameCoreProxyBase.h"
#include "AIGameCoreProxyTCP.generated.h"


UCLASS(config = Game)
class UAIGameCoreProxyTCP : public UAIGameCoreProxyBase
{
    GENERATED_UCLASS_BODY()

public:

    void Init() override;

    void Start(const FString& EndPoint) override;

    void Stop() override;

    void Uninit() override;

    void Tick(float DelataTime) override;

    UFUNCTION()
    bool SendPacketByTable(const FString& MessageType, ULuaTableRef* TableRef);

protected:
    UFUNCTION()
    void OnReceivedMessage(int32 SocketId, const FString& MessageType, const UProtobufMessageRef* MessageRef);

    UFUNCTION()
    void OnConnectedResult(int32 SocketId, bool bResult);

    UFUNCTION()
    void OnPostDisconnected(int32 SocketId);

    DECLARE_DYNAMIC_DELEGATE(FOnServerDead);

protected:
    UPROPERTY()
    class USocketNetworkManager* NetworkManager;

    UPROPERTY(config)
    float MaxConnectingTime;

    UPROPERTY(config)
    int32 MaxRetryConnectTimes;

    UPROPERTY()
    FOnServerDead OnServerDead;

    FString EndPoint;
    bool bConnected;
    float ReConnectingTime;
    int32 ReConnectedTimes;
};