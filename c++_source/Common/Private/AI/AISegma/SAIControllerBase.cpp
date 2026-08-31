// Fill out your copyright notice in the Description page of Project Settings.

#include "AI/AISegma/SAIControllerBase.h"
#include "Common.h"
#include "Pawns/PiratesShipPawn.h"
#include "Pawns/PiratesHumanCharacter.h"
#include "Perception/AIPerceptionComponent.h"
#include "Perception/AISenseConfig_Sight.h"
#include "Perception/AISenseConfig_Hearing.h"
#include "Perception/AISenseConfig_Damage.h"
#include "AI/Components/PiratesPathFollowingComponent.h"
#include "BrainComponent.h"

DEFINE_LOG_CATEGORY_STATIC(SAIControllerBaseLog, Log, All)

ASAIControllerBase::ASAIControllerBase(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer.SetDefaultSubobjectClass<UPiratesPathFollowingComponent>(TEXT("PathFollowingComponent")))
{
    HumanControlModeComponent = CreateDefaultSubobject<UAIHumanControlModeComponent>(TEXT("HumanControlComponent"));
    ShipControlModeComponent  = CreateDefaultSubobject<UAIShipControlModeComponent>(TEXT("ShipControlComponent"));
}


void ASAIControllerBase::UpdateControlRotation(float DeltaTime, bool bUpdatePawn /* = true */)
{
    FRotator NewControlRotation = GetControlRotation();
    Super::UpdateControlRotation(DeltaTime, bUpdatePawn);
    if (ActiveControlMode)
    {
        ActiveControlMode->UpdateControlRotation(NewControlRotation);
    }
}

void ASAIControllerBase::AbortMoving()
{
    if (ActiveControlMode)
    {
        ActiveControlMode->AbortMoving();
    }
}

FPathFollowingRequestResult ASAIControllerBase::MoveTo(const FAIMoveRequest& MoveRequest, FNavPathSharedPtr* OutPath /* = nullptr */)
{
    FPathFollowingRequestResult ResultData;
    if (ActiveControlMode)
    {
        if (ActiveControlMode->MoveTo(MoveRequest, ResultData))
        {
            return ResultData;
        }
    }
    return Super::MoveTo(MoveRequest, OutPath);
}

void ASAIControllerBase::OnActorInSight_Implementation(AActor* Actor)
{

}

void ASAIControllerBase::OnActorLoseSight_Implementation(AActor* Actor)
{

}

void ASAIControllerBase::OnHeardNoise_Implementation(AActor* Actor, const FVector& Location, const FName& Tag)
{

}

void ASAIControllerBase::OnTookDamage_Implementation(AActor* Actor)
{

}


void ASAIControllerBase::OnTargetPerceptionUpdated(AActor* Actor, FAIStimulus Stimulus)
{
    UAIPerceptionComponent* AIPerceptionComponent = GetAIPerceptionComponent();
    const FActorPerceptionInfo* PerceptionInfo = AIPerceptionComponent->GetActorInfo(*Actor);
    if (PerceptionInfo)
    {
        if (Stimulus.Type == UAISense::GetSenseID(UAISense_Sight::StaticClass()))
        {
            if (Stimulus.IsActive())
            {
                OnActorInSight(Actor);
            }
            else
            {
                OnActorLoseSight(Actor);
            }
        }
        else if(Stimulus.Type == UAISense::GetSenseID(UAISense_Hearing::StaticClass()))
        {
            if (Stimulus.IsActive())
            {
                OnHeardNoise(Actor, PerceptionInfo->GetLastStimulusLocation(), PerceptionInfo->LastSensedStimuli[Stimulus.Type].Tag);
            }
        }

        else if (Stimulus.Type == UAISense::GetSenseID(UAISense_Damage::StaticClass()))
        {
            if (Stimulus.IsActive())
            {
                OnTookDamage(Actor);
            }
        }
    }
}

bool ASAIControllerBase::IsActorSeen(AActor* Actor) const
{
    const UAIPerceptionComponent* AIPerceptionComponent = GetAIPerceptionComponent();
    if (Actor && AIPerceptionComponent)
    {
        const FActorPerceptionInfo* ActorPerceptionInfo = AIPerceptionComponent->GetActorInfo(*Actor);
        if (ActorPerceptionInfo)
        {
            return ActorPerceptionInfo->IsSenseActive(UAISense::GetSenseID(UAISense_Sight::StaticClass()));
        }
    }
    return false;
}

void ASAIControllerBase::ConfigSight(float InSightRange, float LoseSightRange, float FOV)
{
    FAISenseID Id = UAISense::GetSenseID(UAISense_Sight::StaticClass());
    if (!Id.IsValid())
    {
        return;
    }

    UAIPerceptionComponent* Perception = GetAIPerceptionComponent();
    if (Perception == nullptr)
    {
        return;
    }

    auto Config = Perception->GetSenseConfig(Id);
    if (Config == nullptr)
    {
        return;
    }

    auto ConfigSight = Cast<UAISenseConfig_Sight>(Config);
    ConfigSight->SightRadius = InSightRange;
    ConfigSight->LoseSightRadius = LoseSightRange;
    ConfigSight->PeripheralVisionAngleDegrees = FOV;
    Perception->RequestStimuliListenerUpdate();
    RefreshSight();
}


void ASAIControllerBase::ConfigHeard(float ListenRange)
{
    FAISenseID Id = UAISense::GetSenseID(UAISense_Hearing::StaticClass());
    if (!Id.IsValid())
    {
        return;
    }

    UAIPerceptionComponent* Perception = GetAIPerceptionComponent();
    if (Perception == nullptr)
    {
        return;
    }

    auto Config = Perception->GetSenseConfig(Id);
    if (Config == nullptr)
    {
        return;
    }

    auto ConfigHearing = Cast<UAISenseConfig_Hearing>(Config);
    ConfigHearing->HearingRange = ListenRange;
    Perception->ForgetAll();
    Perception->RequestStimuliListenerUpdate();
}

void ASAIControllerBase::EnablePerception(TSubclassOf<UAISense> SenseClass, bool bEnable)
{
    UAIPerceptionComponent* Perception = GetAIPerceptionComponent();
    if (Perception == nullptr)
    {
        return;
    }
    Perception->SetSenseEnabled(SenseClass, bEnable);
}

void ASAIControllerBase::RefreshSight()
{
    UAIPerceptionComponent* Perception = GetAIPerceptionComponent();
    if (Perception)
    {
        Perception->ForgetAll();
        Perception->RequestStimuliListenerUpdate();
    }
}


FVector ASAIControllerBase::GetLastSoundLocation(AActor* Actor) const
{
    const UAIPerceptionComponent* AIPerceptionComponent = GetAIPerceptionComponent();
    if (AIPerceptionComponent)
    {
        const FActorPerceptionInfo* PerceptionInfo = AIPerceptionComponent->GetActorInfo(*Actor);
        if (PerceptionInfo)
        {
            return PerceptionInfo->GetStimulusLocation(UAISense::GetSenseID(UAISense_Hearing::StaticClass()));
        }
    }
    return FAISystem::InvalidLocation;
}

FName ASAIControllerBase::GetLastStimuliTagBySense(TSubclassOf<UAISense> SenseToUse, AActor* Actor) const
{
    const UAIPerceptionComponent* AIPerceptionComponent = GetAIPerceptionComponent();
    if (AIPerceptionComponent)
    {
        const FAISenseID SenseID = UAISense::GetSenseID(SenseToUse);
        const FActorPerceptionInfo* PerceptionInfo = AIPerceptionComponent->GetActorInfo(*Actor);
        if (PerceptionInfo && PerceptionInfo->LastSensedStimuli.IsValidIndex(SenseID) && PerceptionInfo->LastSensedStimuli[SenseID].GetAge() < FAIStimulus::NeverHappenedAge)
        {
            return PerceptionInfo->LastSensedStimuli[SenseID].Tag;
        }
    }
    return FName();
}


void ASAIControllerBase::FellOutOfWorld(const class UDamageType& dmgType)
{
    UE_LOG(SAIControllerBaseLog, Log, TEXT("ASAIControllerBase->FellOutOfWorld"));
}

void ASAIControllerBase::OutsideWorldBounds()
{
    UE_LOG(SAIControllerBaseLog, Log, TEXT("ASAIControllerBase->OutsideWorldBounds"));
}

void ASAIControllerBase::OnPossess(APawn* InPawn)
{
    Super::OnPossess(InPawn);
    APiratesHumanCharacter* HumanPawn = Cast<APiratesHumanCharacter>(GetPawn());
    if (HumanPawn)
    {
        ActiveControlMode = HumanControlModeComponent;
    }
    APiratesShipPawn* ShipPawn = Cast<APiratesShipPawn>(GetPawn());
    if (ShipPawn)
    {
        ActiveControlMode = ShipControlModeComponent;
    }
    if (ActiveControlMode)
    {
        ActiveControlMode->Possess(InPawn);
    }
    UAIPerceptionComponent* Perception = GetAIPerceptionComponent();
    if (Perception)
    {
        const TArray<FAISenseID> ValidAISenseIDs = {
            UAISense::GetSenseID(UAISense_Sight::StaticClass()),
            UAISense::GetSenseID(UAISense_Hearing::StaticClass()),
            UAISense::GetSenseID(UAISense_Damage::StaticClass()),
        };
        for (auto SenseID : ValidAISenseIDs)
        {
            const UAISenseConfig* SenseConfig = Perception->GetSenseConfig(SenseID);
            if (SenseConfig)
            {
                Perception->SetSenseEnabled(SenseConfig->GetSenseImplementation(), SenseConfig->IsEnabled());
                UE_LOG(SAIControllerBaseLog, Log, TEXT("Set Sense %s Enable"), *SenseConfig->GetSenseName());
            }
        }
        Perception->OnTargetPerceptionUpdated.AddDynamic(this, &ASAIControllerBase::OnTargetPerceptionUpdated);
    }
}

void ASAIControllerBase::OnUnPossess()
{
    if (ActiveControlMode)
    {
        ActiveControlMode->UnPossess();
    }
    ActiveControlMode = nullptr;
    UAIPerceptionComponent* Perception = GetAIPerceptionComponent();
    if (Perception)
    {
        const TArray<FAISenseID> ValidAISenseIDs = {
            UAISense::GetSenseID(UAISense_Sight::StaticClass()),
            UAISense::GetSenseID(UAISense_Hearing::StaticClass()),
            UAISense::GetSenseID(UAISense_Damage::StaticClass()),
        };
        for (auto SenseID : ValidAISenseIDs)
        {
            const UAISenseConfig* SenseConfig = Perception->GetSenseConfig(SenseID);
            if (SenseConfig)
            {
                Perception->SetSenseEnabled(SenseConfig->GetSenseImplementation(), false);
                UE_LOG(SAIControllerBaseLog, Log, TEXT("Set Sense %s Disable"), *SenseConfig->GetSenseName());
            }
        }
        Perception->OnTargetPerceptionUpdated.RemoveDynamic(this, &ASAIControllerBase::OnTargetPerceptionUpdated);
    }
    Super::OnUnPossess();

}


void ASAIControllerBase::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    Super::EndPlay(EndPlayReason);
#if UE_EDITOR
    UE_LOG(SAIControllerBaseLog, Log, TEXT("ASAIControllerBase::EndPlay Reason %d"), (int32)EndPlayReason);
#endif
}