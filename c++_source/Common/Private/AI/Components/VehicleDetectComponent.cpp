#include "AI/Components/VehicleDetectComponent.h"
#include "Common.h"
#include "GameFramework/Character.h"
#include "AIController.h"
#include "Game/GameCommon.h"
#include "AI/Vehicle/AIVehicleManager.h"

UVehicleDetectComponent::UVehicleDetectComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    PrimaryComponentTick.bCanEverTick = true;
    SightDistance = 10000;
    SightFOV = 120;
    RefreshInterval = 1.0f;
    TimeToNextRefresh = 0.f;
}


void UVehicleDetectComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
    TimeToNextRefresh -= DeltaTime;
    if (TimeToNextRefresh <= 0)
    {
        UpdateItems();
        TimeToNextRefresh = RefreshInterval;
    }
}

void UVehicleDetectComponent::SetEnable(bool bEnable)
{
    SetComponentTickEnabled(bEnable);
}

void UVehicleDetectComponent::UpdateItems()
{
/*    double StartRecordTime = FPlatformTime::Seconds();*/
    FoundVehicles.Empty(8);
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
    UAIVehicleManager* AIVehicleManager = UGameCommon::Get(this)->GetAIVehicleManager();
    if (!AIVehicleManager || !Pawn)
    {
        return;
    }
    AIVehicleManager->FindVisibleVehicle(Pawn, 0, SightDistance, SightFOV, GetWorld(), FoundVehicles);
//     float fTime = (float)(FPlatformTime::Seconds() - StartRecordTime)*1000.0f;
//     UE_LOG(LogTemp, Log, TEXT("UVehicleDetectComponent time: %f ms"), fTime);
}


const TArray<int32>& UVehicleDetectComponent::GetVehicles() const
{
    return FoundVehicles;
}

