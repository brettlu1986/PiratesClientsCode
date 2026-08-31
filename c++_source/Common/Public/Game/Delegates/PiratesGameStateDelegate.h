#pragma once
#include "KMObject.h"
#include "PiratesGameStateDelegate.generated.h"


UCLASS()
class COMMON_API UPiratesGameStateDelegate : public UKMObject
{
    GENERATED_BODY()

    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnGameStateBeginPlay, AActor*, GameState);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnGameStateEndPlay, AActor*, GameState);
    DECLARE_DYNAMIC_DELEGATE(FOnMatchHasEnded);
    DECLARE_DYNAMIC_DELEGATE(FOnGameStateSerializeNewActor);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnGameStateActorChannelOpen, APiratesGameState*, GameState);
    DECLARE_DYNAMIC_DELEGATE(FOnMatchDisconnected);

public:
    UPROPERTY()
    FOnGameStateSerializeNewActor OnGameStateSerializeNewActor;

    UPROPERTY()
    FOnGameStateActorChannelOpen OnGameStateActorChannelOpen;

    UPROPERTY()
    FOnGameStateBeginPlay OnGameStateBeginPlay;

    UPROPERTY()
    FOnGameStateEndPlay OnGameStateEndPlay;

    UPROPERTY()
    FOnMatchHasEnded OnMatchHasEnded;

    UPROPERTY()
    FOnMatchDisconnected OnMatchDisconnected;
};