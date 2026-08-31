#include "AI/Components/OceanGridDetectComponent.h"
#include "Common.h"
#include "GameFramework/Character.h"
#include "AIController.h"
#include "Game/GameCommon.h"
#include "AI/OceanGrid/AIOceanGridManagerRoot.h"
#include "AI/OceanGrid/AIOceanGridCell.h"

UOceanGridDetectComponent::UOceanGridDetectComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    PrimaryComponentTick.bCanEverTick = true;
    SightDistance = 10000;
    SightFOV = 120;
    RefreshInterval = 1.0f;
    TimeToNextRefresh = 0.f;
}


void UOceanGridDetectComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
    TimeToNextRefresh -= DeltaTime;
    if (TimeToNextRefresh <= 0)
    {
        UpdateItems();
        TimeToNextRefresh = RefreshInterval;
    }
}

void UOceanGridDetectComponent::SetEnable(bool bEnable)
{
    SetComponentTickEnabled(bEnable);
}

void UOceanGridDetectComponent::UpdateItems()
{
    Torpedos.Empty(8);
    AAIController* Controller = Cast<AAIController>(GetOwner());
    APawn* Pawn = nullptr;
    if (!Controller)
    {
        Pawn = Cast<APawn>(GetOwner());
    }
    else
    {
        Pawn = Controller->GetPawn();
    }
    UAIOceanGridManagerRoot* AIOceanGridManager = UGameCommon::Get(this)->GetAIOceanGridManager();
    if (!AIOceanGridManager || !Pawn)
    {
        return;
    }
    TArray<int32> TorpedoIds;
    AIOceanGridManager->FindTorpedo(Pawn,  SightDistance, SightFOV, GetWorld(), TorpedoIds);
    for (auto TorpedoId : TorpedoIds)
    {
        const FAIOceanItem<FAITorpedo>* Torpedo = AIOceanGridManager->GetTorpedo(TorpedoId);
        if (Torpedo && Torpedo->ItemData.TorpedoActor.IsValid() && !Torpedo->ItemData.TorpedoActor->IsPendingKill())
        {
            Torpedos.Emplace(Torpedo->ItemData.TorpedoActor);
        }
    }
}


