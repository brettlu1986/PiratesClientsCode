#pragma once
#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "HumanAimComponent.generated.h"

class ACharacter;
class AAIController;

UCLASS()
class COMMON_API UHumanAimComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
   
    UFUNCTION(BlueprintCallable, Category = "Human AI Aim")
    void StartAim(const FVector& Location);

    UFUNCTION(BlueprintCallable, Category = "Human AI Aim")
    void StopAim();

    UFUNCTION(BlueprintCallable, Category = "Human AI Aim")
    void AimTarget(AActor* Target);

    void UpdateRotation();

private:
    ACharacter* GetCharacter();
    AAIController*  GetAIController();

    FRotator    ViewRotation;
    bool	    bIsAiming;
    AActor*	    FocusTarget;
};
