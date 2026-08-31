#pragma once

//#include "GameFramework/GameState.h"
#include "KMGameState.h"
#include "PiratesGameMode.h"
#include "PiratesGameState.generated.h"


//class APiratesGameGroupPrivateInfo;
class APiratesPlayerState;
class APiratesPlayerController;
class UPiratesGameStateDelegate;
class UCampRelationComponent;
class UCustomReplicationComponent;

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FCampRelationMatrixChanged);

UCLASS(meta=(ChildCanTick))
class COMMON_API APiratesGameState : public AKMGameState
{
    GENERATED_UCLASS_BODY()

public:

    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    virtual void HandleMatchHasEnded() override;
    virtual void DefaultTimer() override;
    virtual void OnSerializeNewActor(class FOutBunch& OutBunch) override;
    virtual void OnActorChannelOpen(class FInBunch& InBunch, class UNetConnection* Connection) override;

public:

    UFUNCTION(BlueprintCallable, Category = "PiratesGameState")
    virtual void Clear();

    UFUNCTION(BlueprintCallable, Category = "PiratesGameState")
    void ResetDefaultTimer(bool bClearElapsedTime = true)
    {
        if (bClearElapsedTime)
            ElapsedTime = 0;

        FTimerManager& TimerManager = GetWorldTimerManager();
        TimerManager.SetTimer(
            TimerHandle_DefaultTimer,
            this,
            &AGameState::DefaultTimer,
            GetWorldSettings()->GetEffectiveTimeDilation() / GetWorldSettings()->DemoPlayTimeDilation,
            true
        );
    }

    UFUNCTION(BlueprintCallable, BlueprintImplementableEvent, Category = "PiratesGameState")
    void BeginProfilerSample(const FString& SampleName);

    UFUNCTION(BlueprintCallable, BlueprintImplementableEvent, Category = "PiratesGameState")
    void EndProfilerSample();

    UFUNCTION(BlueprintCallable, Category = "PiratesGameState")
    void SetCampRelationMatrix(int32 CampCount, const TArray<bool>& RelationMatrix);

    UFUNCTION(BlueprintCallable, Category = "PiratesGameState")
    bool IsFriendCampRelation(int32 CampA, int32 CampB) const;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "PiratesGameState")
    UCampRelationComponent* CampRelationComponent;

    UPROPERTY(VisibleAnywhere, BlueprintAssignable, Category = "PiratesGameState")
    FCampRelationMatrixChanged OnCampRelationMatrixChanged;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "PiratesGameState")
    UCustomReplicationComponent* CustomReplication;
};