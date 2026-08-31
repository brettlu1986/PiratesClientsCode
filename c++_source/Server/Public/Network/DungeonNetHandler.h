#pragma once
#include "KMObject.h"
#include "DungeonNetHandler.generated.h"

class USocketNetworkManager;

UCLASS()
class SERVER_API UDungeonNetHandler : public UKMObject
{
    GENERATED_UCLASS_BODY()

public:
    bool InitializeNetwork(USocketNetworkManager * NetManager);

private:
    UFUNCTION()
    void OnConnectedResultFunc(int32 SocketId, bool bResult);

    UFUNCTION()
    void OnDisconnectedFunc(int32 SocketId);

    void SendRegisterMessage(int32 SocketId);
};