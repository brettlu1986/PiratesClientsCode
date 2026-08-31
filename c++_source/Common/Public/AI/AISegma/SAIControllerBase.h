#pragma once

#include "Components/HumanAimComponent.h"
#include "AI/AISegma/Components/AIHumanControlModeComponent.h"
#include "AI/AISegma/Components/AIShipControlModeComponent.h"
#include "AI/AISegma/Components/AIControlModeComponentBase.h"
#include "AIController.h"
#include "Perception/AIPerceptionTypes.h"
#include "MapNavGridPathFollowingComponent.h"
#include "SAIControllerBase.generated.h"

UCLASS()
class COMMON_API ASAIControllerBase : public AAIController
{
    GENERATED_BODY()

protected:

    ASAIControllerBase(const FObjectInitializer& ObjectInitializer);
    void UpdateControlRotation(float DeltaTime, bool bUpdatePawn = true) override;
    virtual void FellOutOfWorld(const class UDamageType& dmgType) override;
    virtual void OutsideWorldBounds() override;
    virtual void OnPossess(APawn* InPawn) override;
    virtual void OnUnPossess() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

public:
    FPathFollowingRequestResult MoveTo(const FAIMoveRequest& MoveRequest, FNavPathSharedPtr* OutPath = nullptr) override;

    UFUNCTION(BlueprintNativeEvent, Category = "AI")
    void OnActorInSight(AActor* Actor);

    UFUNCTION(BlueprintNativeEvent, Category = "AI")
    void OnActorLoseSight(AActor* Actor);

    UFUNCTION(BlueprintNativeEvent, Category = "AI")
    void OnHeardNoise(AActor* Actor, const FVector& Location, const FName& Tag);

    UFUNCTION(BlueprintNativeEvent, Category = "AI")
    void OnTookDamage(AActor* Actor);

    ///////////////////////////////////////////////////////////////////
    UFUNCTION(BlueprintCallable, Category = "AI")
    void AbortMoving();

    UFUNCTION(BlueprintPure, Category = "AI")
    bool IsActorSeen(AActor* Actor) const;

    UFUNCTION(BlueprintCallable, Category = "AI")
    void ConfigSight(float InSightRange, float LoseSightRange, float FOV);

    UFUNCTION(BlueprintCallable, Category = "AI")
    void ConfigHeard(float ListenRange);

    UFUNCTION(BlueprintCallable, Category = "AI")
    void EnablePerception(TSubclassOf<UAISense> SenseClass, bool bEnable);

    UFUNCTION(BlueprintCallable, Category = "AI")
    void RefreshSight();

    UFUNCTION(BlueprintPure, Category = "AI")
    FVector GetLastSoundLocation(AActor* Actor) const;

    UFUNCTION(BlueprintPure, Category = "AI")
    FName GetLastStimuliTagBySense(TSubclassOf<UAISense> SenseToUse, AActor* Actor) const;

    /////////////////////////////////////////////////////////////

protected:
    UFUNCTION()
    void OnTargetPerceptionUpdated(AActor* Actor, FAIStimulus Stimulus);

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    UAIHumanControlModeComponent*	HumanControlModeComponent;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    UAIShipControlModeComponent*	ShipControlModeComponent;

    UAIControlModeComponentBase*    ActiveControlMode;
};
