#include "AI/Tests/EnvQueryTest_IsInCoverDirection.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Querier.h"
#include "EnvironmentQuery/Items/EnvQueryItemType_VectorBase.h"
#include "AI/Tests/EnvQueryTest_IsCoverPosition.h"
#include "AI/EnvQuery/EnvQueryItemType_Cover.h"


UEnvQueryTest_IsInCoverDirection::UEnvQueryTest_IsInCoverDirection(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
	Cost = EEnvTestCost::Low;
	ValidItemType = UEnvQueryItemType_Cover::StaticClass();
	SetWorkOnFloatValues(false);

	Context = UEnvQueryContext_Querier::StaticClass();
}

void UEnvQueryTest_IsInCoverDirection::RunTest(FEnvQueryInstance& QueryInstance) const
{
	UObject* DataOwner = QueryInstance.Owner.Get();
	BoolValue.BindData(DataOwner, QueryInstance.QueryID);
	MaxEpsilon.BindData(DataOwner, QueryInstance.QueryID);

	const bool bExpectedInCoverDirection = BoolValue.GetValue();
	const float MaxEps = MaxEpsilon.GetValue();

	TArray<FVector> ContextLocations;
	if (!QueryInstance.PrepareContext(Context, ContextLocations))
	{
		return;
	}

	for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
	{
		UCoverPoint* CoverPoint = UEnvQueryItemType_Cover::GetValue(QueryInstance.RawData.GetData() + QueryInstance.Items[It.GetIndex()].DataOffset);

		if (CoverPoint)
		{
			const FVector CoverDirection = CoverPoint->DirectionToWall;
			const float CoverDirectionSize = CoverDirection.Size(); 
			const FVector CoverPosition = CoverPoint->Location; 
			for (int32 ContextIndex = 0; ContextIndex < ContextLocations.Num(); ContextIndex++)
			{
				const FVector ContextLocation = ContextLocations[ContextIndex]; 
				FVector DirectionCoverToContext = ContextLocation - CoverPosition; 

                int32 CosData = FVector::DotProduct(CoverDirection, DirectionCoverToContext) / (CoverDirectionSize*DirectionCoverToContext.Size());
                check(CosData >= -1.0f && CosData <= 1.f)
                bool bIsInCoverDirection = CosData > 1 - MaxEps;
				It.SetScore(TestPurpose, FilterType, bIsInCoverDirection, bExpectedInCoverDirection);
			}
		}		
	}
}

FText UEnvQueryTest_IsInCoverDirection::GetDescriptionDetails() const
{
    return DescribeBoolTestParams(TEXT("in cover direction"));
}