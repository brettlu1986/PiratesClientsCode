#include "AI/Components/GoodsDetectComponent.h"
#include "Common.h"
#include "GameFramework/Character.h"
#include "AIController.h"
#include "Game/GameCommon.h"
#include "Game/Battle/TemplateActorDataManager.h"

UGoodsDetectComponent::UGoodsDetectComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    PrimaryComponentTick.bCanEverTick = true;
    SightDistance = 10000;
    SightFOV = 120;
    RefreshInterval = 0.2f;
    TimeToNextRefresh = 0.f;
    bIsShip = false;
    MaxVisibelItemNum = 0;
}


void UGoodsDetectComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
    TimeToNextRefresh -= DeltaTime;
    if (TimeToNextRefresh <= 0)
    {
        UpdateItems();
        TimeToNextRefresh = RefreshInterval;
    }
}

FORCEINLINE bool IsBetter(const FGoodsInfo& A, const FGoodsInfo& B)
{
    return A.DistanceSQ < B.DistanceSQ;
}


int32 UGoodsDetectComponent::GetMinPriorityItemIndex() const
{
    int32 MinPriorityIndex = -1;
    int32 CurrentIndex = 0;
    for (const FGoodsInfo& Info : FoundItems)
    {
        if (MinPriorityIndex < 0 || IsBetter(FoundItems[MinPriorityIndex], Info))
        {
            MinPriorityIndex = CurrentIndex;
        }
        CurrentIndex++;
    }
    return MinPriorityIndex;
}

void UGoodsDetectComponent::ClearAllGlobalItem()
{
    GlobalItems.Empty();
}

void UGoodsDetectComponent::AddGlobalItem(int32 InstanceID, const FVector& Location, int32 TemplateID)
{
	for (const auto& Item : GlobalItems)
	{
        if (Item.InstanceID == InstanceID)
        {
            return;
        }
	}
    FGoodsInfo NewGoodsInfo;
    NewGoodsInfo.InstanceID = InstanceID;
    NewGoodsInfo.Location = Location;
    NewGoodsInfo.TemplateID = TemplateID;
    GlobalItems.Emplace(NewGoodsInfo);
}

void UGoodsDetectComponent::UpdateItems()
{
//    double StartRecordTime = FPlatformTime::Seconds();
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
    UTemplateActorDataManager* TemplateActorDataManager = UGameCommon::Get(this)->GetTemplateActorDataManager();
    if (!TemplateActorDataManager || !Pawn)
    {
        return;
    }
    FoundItems.Empty(16);
    uint32 MinPriorityIndex = -1;
    FVector OwnerLocation = Pawn->GetActorLocation();
    TArray<int32> InstanceIds;
    int32 NumItem = TemplateActorDataManager->FindInstanceIdsInRadius(bIsShip, OwnerLocation, SightDistance, InstanceIds);
    const float LimitDistanceSquared = SightDistance * SightDistance;
    FVector  EyePosition;
    FRotator EyeRotator;
    Pawn->GetActorEyesViewPoint(EyePosition, EyeRotator);
    const FVector OwnerFowardDir = EyeRotator.Vector().GetSafeNormal2D();
    const float LimitDot = FMath::Cos(SightFOV * 0.5f * PI / (180.f));
    const float ItemBoundSize = bIsShip ? 500 : 50;
    const float ItemBoundSizeSQ = ItemBoundSize * ItemBoundSize;

    auto TestItemFunc = [&](int32 InstanceID, const FVector& Location,
        int32 TemplateID) {
            float SquaredDistance = FVector::DistSquaredXY(OwnerLocation, Location);
            float Dot = FVector::DotProduct(OwnerFowardDir, (Location - OwnerLocation).GetSafeNormal2D());
            if (SquaredDistance <= LimitDistanceSquared && Dot >= LimitDot)
            {
                FHitResult OutHit;
                FCollisionQueryParams TraceParams;
                TraceParams.bFindInitialOverlaps = false;
                TraceParams.AddIgnoredActor(Pawn);
                FVector TraceEnd = EyePosition;
                FVector TraceStart = Location;
                TraceStart.Z += ItemBoundSize;
                if (SquaredDistance > ItemBoundSizeSQ)
                {
                    TraceStart = TraceStart + (TraceEnd - TraceStart).GetSafeNormal() * ItemBoundSize;
                }
                const bool bHit = GetWorld()->LineTraceSingleByChannel(OutHit, TraceStart, TraceEnd, ECollisionChannel::ECC_WorldStatic, TraceParams);
				if (!bHit)
				{
					FGoodsInfo Info;
					Info.InstanceID = InstanceID;
					Info.Location = Location;
					Info.TemplateID = TemplateID;
					Info.DistanceSQ = SquaredDistance;
					Info.Dot = Dot;

					if (MaxVisibelItemNum < 0)
					{
						FoundItems.Emplace(Info);
					}
					else if (FoundItems.Num() < MaxVisibelItemNum)
					{
						FoundItems.Emplace(Info);
						MinPriorityIndex = GetMinPriorityItemIndex();
					}
					else if (IsBetter(Info, FoundItems[MinPriorityIndex]))
					{
						FoundItems[MinPriorityIndex] = Info;
						MinPriorityIndex = GetMinPriorityItemIndex();
					}
				}
            }
    };

    for (const auto& Item : GlobalItems)
    {
		TestItemFunc(Item.InstanceID, Item.Location, Item.TemplateID);
    }

    for (const auto& InstanceId : InstanceIds)
    {
        FTemplateActorData* TemplateActorData = TemplateActorDataManager->FindTemplateData(InstanceId);
        TestItemFunc(TemplateActorData->InstanceId, TemplateActorData->Location,
            TemplateActorData->TemplateId);
    }
//     float fTime = (float)(FPlatformTime::Seconds() - StartRecordTime)*1000.0f;
//     UE_LOG(LogTemp, Log, TEXT("UGoodsDetectComponent time: %f ms"), fTime);
}


const TArray<FGoodsInfo>& UGoodsDetectComponent::GetItems() const
{
    return FoundItems;
}

