#pragma once

#include "UObject/CoreNet.h"
#include "GameFramework/PlayerState.h"
#include "PiratesPlayerState.generated.h"


UCLASS()
class COMMON_API APiratesPlayerState : public APlayerState
{
    GENERATED_UCLASS_BODY()

public:
	UPROPERTY(replicated, BlueprintReadOnly, Category = PlayerState)
	int32 PiratePlayerId;

public:
    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    virtual void OnSerializeNewActor(class FOutBunch& OutBunch) override;
    virtual void OnActorChannelOpen(class FInBunch& InBunch, class UNetConnection* Connection) override;
	virtual void PostNetInit() override;
	virtual void RecalculateAvgPing() override;

protected:
	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;
};