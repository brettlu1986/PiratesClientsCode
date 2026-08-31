#include "Components/HumanAimComponent.h"
#include "Common.h"
#include "GameFramework/Character.h"
#include "AIController.h"

UHumanAimComponent::UHumanAimComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    PrimaryComponentTick.bCanEverTick = false;
}

ACharacter* UHumanAimComponent::GetCharacter()
{
    AAIController* AIController = GetAIController();
    if (AIController)
    {
        return AIController->GetCharacter();
    }
    return nullptr;
}

AAIController* UHumanAimComponent::GetAIController()
{
    return Cast<AAIController>(GetOwner());
}


void UHumanAimComponent::UpdateRotation()
{
    AAIController* AIController = GetAIController();
    if (AIController && bIsAiming)
    {
        if (IsValid(FocusTarget))
        {
            FVector   ActorLocation;
            FRotator  ActorRotator;
            FocusTarget->GetActorEyesViewPoint(ActorLocation, ActorRotator);
            StartAim(ActorLocation);
        }
        AIController->SetControlRotation(ViewRotation);
    }
}

void UHumanAimComponent::StartAim(const FVector& Location)
{
    ACharacter* Character = GetCharacter();
    if (Character)
    {
        FVector  EyeLocation;
        FRotator EyeRotator;
        Character->GetActorEyesViewPoint(EyeLocation, EyeRotator);
        ViewRotation = (Location - EyeLocation).GetSafeNormal().Rotation();
        bIsAiming = true;
        ViewRotation.DiagnosticCheckNaN();
    }
}

void UHumanAimComponent::AimTarget(AActor* Target)
{
    if (Target && !Target->IsPendingKill())
    {
        FocusTarget = Target;
        bIsAiming = true;
    }
}

void UHumanAimComponent::StopAim()
{
    bIsAiming = false;
    FocusTarget = NULL;
}