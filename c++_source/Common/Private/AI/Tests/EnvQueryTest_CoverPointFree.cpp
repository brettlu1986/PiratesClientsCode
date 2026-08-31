#include "AI/Tests/EnvQueryTest_CoverPointFree.h"
#include "CoverPoint.h"
#include "AI/EnvQuery/EnvQueryItemType_Cover.h"
#include "AI/AICoverPointsManager.h"
#include "AIController.h"

UEnvQueryTest_CoverPointFree::UEnvQueryTest_CoverPointFree(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
	Cost = EEnvTestCost::Low;
	ValidItemType = UEnvQueryItemType_Cover::StaticClass();
	SetWorkOnFloatValues(false);
}

void UEnvQueryTest_CoverPointFree::RunTest(FEnvQueryInstance& QueryInstance) const
{
    TArray<AActor*> Queriers;
    if (!QueryInstance.PrepareContext(Context, Queriers))
    {
        return;
    }
    APawn* QueryPawn = Cast<APawn>(Queriers[0]);
    for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
    {
        UCoverPoint* CurrentCoverPoint = UEnvQueryItemType_Cover::GetValue(QueryInstance.RawData.GetData() + QueryInstance.Items[It.GetIndex()].DataOffset);
        bool IsFree = CurrentCoverPoint->IsCoverFree() || CurrentCoverPoint->Occupier ==
           Cast<AAIController>(QueryPawn->GetController());

        It.SetScore(TestPurpose, FilterType, IsFree, true);
    }
}

FText UEnvQueryTest_CoverPointFree::GetDescriptionDetails() const
{
    return DescribeBoolTestParams(TEXT("free"));
}