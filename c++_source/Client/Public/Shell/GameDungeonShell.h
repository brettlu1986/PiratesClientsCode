#pragma once
#include "KMObject.h"
#include "GameDungeonShell.generated.h"

UCLASS()
class CLIENT_API UGameDungeonShell : public UKMObject
{
    GENERATED_BODY()

public:
    UFUNCTION()
    void CancelPendingNetGame(UObject* WorldContextObject);

    UFUNCTION()
    bool DisconnectFromDungeonServer(bool bSmoothTravel);

    UFUNCTION()
    static uint64 GenerateMockPlayerId();

    UFUNCTION()
    bool SendReconnectInfo(uint64 PlayerId, uint32 Token);

    UFUNCTION()
    bool RecreateUDPSocketInClient();
};