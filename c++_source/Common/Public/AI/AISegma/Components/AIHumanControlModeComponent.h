#pragma once
#include "AIControlModeComponentBase.h"
#include "Pawns/PiratesHumanCharacter.h"
#include "AIHumanControlModeComponent.generated.h"


UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UAIHumanControlModeComponent : public UAIControlModeComponentBase
{
    GENERATED_UCLASS_BODY()

public:
    virtual void AbortMoving() override;
    virtual bool MoveTo(const FAIMoveRequest& MoveRequest, FPathFollowingRequestResult& Result) override;
    virtual void UpdateControlRotation(const FRotator& NewControlRotation) override;

    virtual void Possess(APawn* InPawn) override;
    virtual void UnPossess() override;

    UFUNCTION(BlueprintCallable, Category = "Human Aim")
    void StartAimLocation(const FVector& Location);

    UFUNCTION(BlueprintCallable, Category = "Human Aim")
    void StopAim();

    UFUNCTION(BlueprintCallable, Category = "Human Aim")
    void StartAimActor(AActor* Actor);

private:

    UFUNCTION()
    void OnReceiveHumanMoveCompleted(EPathFollowingResult::Type Result);

    APiratesHumanCharacter* HumanPawn;
    FRotator    ViewRotation;
    bool	    bAiming;
    AActor*	    FocusActor;
};