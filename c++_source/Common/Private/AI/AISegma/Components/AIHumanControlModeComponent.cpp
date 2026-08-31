#include "AI/AISegma/Components/AIHumanControlModeComponent.h"
#include "Common.h"
#include "BrainComponent.h"

UAIHumanControlModeComponent::UAIHumanControlModeComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer),HumanPawn(nullptr),
    ViewRotation(FRotator::ZeroRotator),
    bAiming(false),
    FocusActor(nullptr)
{
    PrimaryComponentTick.bCanEverTick = false;
}

void UAIHumanControlModeComponent::AbortMoving()
{
    if (HumanPawn)
    {
        HumanPawn->AbortNavMove();
    }
}

bool UAIHumanControlModeComponent::MoveTo(const FAIMoveRequest& MoveRequest, FPathFollowingRequestResult& Result)
{
    if (HumanPawn && HumanPawn->GetHumanMovementComponent()->IsSwimming())
    {
        Result.MoveId = FAIRequestID::AnyRequest;
        Result.Code = HumanPawn->SwimNavMove(MoveRequest.GetDestination(), MoveRequest.GetAcceptanceRadius());
        return true;
    }
    return false;
}

void UAIHumanControlModeComponent::UpdateControlRotation(const FRotator& NewControlRotation)
{
    AAIController* AIController = Cast<AAIController>(GetOwner());
    if (AIController && bAiming)
    {
        if (IsValid(FocusActor))
        {
            FVector   ActorLocation;
            FRotator  ActorRotator;
            FocusActor->GetActorEyesViewPoint(ActorLocation, ActorRotator);
            StartAimLocation(ActorLocation);
        }
        AIController->SetControlRotation(ViewRotation);
    }
}

void UAIHumanControlModeComponent::OnReceiveHumanMoveCompleted(EPathFollowingResult::Type Result)
{
    bool bIsSuccess = Result == EPathFollowingResult::Success;
    AAIController* AIController = Cast<AAIController>(GetOwner());
    FAIMessage Msg(UBrainComponent::AIMessage_MoveFinished, AIController, FAIRequestID::AnyRequest, bIsSuccess);
    FAIMessage::Send(AIController, Msg);
    UE_LOG(LogTemp, Log, TEXT("OnReceiveHumanMoveCompleted %s"),
        bIsSuccess ? TEXT("true") : TEXT("false"));
}


void UAIHumanControlModeComponent::Possess(APawn* InPawn)
{
    HumanPawn = Cast<APiratesHumanCharacter>(InPawn);
    HumanPawn->GetHumanMovementComponent()->OnHumanPathMoveFinished.AddDynamic(this, &UAIHumanControlModeComponent::OnReceiveHumanMoveCompleted);
}

void UAIHumanControlModeComponent::UnPossess()
{
    HumanPawn->GetHumanMovementComponent()->OnHumanPathMoveFinished.RemoveDynamic(this, &UAIHumanControlModeComponent::OnReceiveHumanMoveCompleted);
    HumanPawn = nullptr;
}


void UAIHumanControlModeComponent::StartAimLocation(const FVector& Location)
{
    if (HumanPawn)
    {
        FVector  EyeLocation;
        FRotator EyeRotator;
        HumanPawn->GetActorEyesViewPoint(EyeLocation, EyeRotator);
        ViewRotation = (Location - EyeLocation).GetSafeNormal().Rotation();
        bAiming = true;
        ViewRotation.DiagnosticCheckNaN();
    }
}

void UAIHumanControlModeComponent::StartAimActor(AActor* Actor)
{
    if (Actor && !Actor->IsPendingKill())
    {
        FocusActor = Actor;
        bAiming = true;
    }
}

void UAIHumanControlModeComponent::StopAim()
{
    bAiming = false;
    FocusActor = NULL;
}