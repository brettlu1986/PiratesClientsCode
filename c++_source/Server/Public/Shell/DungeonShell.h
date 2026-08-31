#pragma once
#include "KMObject.h"

#include "DMSClient.h"

#include "DungeonShell.generated.h"

UCLASS()
class SERVER_API UDungeonShell : public UKMObject
{
    GENERATED_UCLASS_BODY()

public:
    UFUNCTION()
    void EndGame();

    UFUNCTION()
    bool SetClientConnectionAddress(class APlayerController* PlayerController, FString Address);
};