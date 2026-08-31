#include "AI/Tests/EnvQueryTest_IsCoverPosition.h"
#include "EnvironmentQuery/Items/EnvQueryItemType_VectorBase.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Querier.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Item.h"
#include "EnvironmentQuery/EnvQueryTypes.h"
#include "CollisionQueryParams.h"
#include "Engine/World.h"
#include "AI/EnvQuery/EnvQueryItemType_Cover.h"


UEnvQueryTest_IsCoverPosition::UEnvQueryTest_IsCoverPosition(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
	Cost = EEnvTestCost::High;
	ValidItemType = UEnvQueryItemType_Cover::StaticClass();
	SetWorkOnFloatValues(false);

	Context = UEnvQueryContext_Querier::StaticClass();
	TraceData.SetGeometryOnly();
}

void UEnvQueryTest_IsCoverPosition::RunTest(FEnvQueryInstance& QueryInstance) const
{
	UObject* DataOwner = QueryInstance.Owner.Get();
    ContextHeight.BindData(DataOwner, QueryInstance.QueryID);
	DebugTrace.BindData(DataOwner, QueryInstance.QueryID);

	float ContextZOffset = ContextHeight.GetValue();
	bool Debug = DebugTrace.GetValue();

	TArray<FVector> ContextLocations;
	if (!QueryInstance.PrepareContext(Context, ContextLocations))
	{
		return;
	}

	FCollisionQueryParams TraceParams(TEXT("EnvQueryTrace"), TraceData.bTraceComplex);
	
	TArray<AActor*> IgnoredActors;
	if (QueryInstance.PrepareContext(Context, IgnoredActors))
	{
		TraceParams.AddIgnoredActors(IgnoredActors);
	}

	ECollisionChannel TraceCollisionChannel = UEngineTypes::ConvertToCollisionChannel(TraceData.TraceChannel);

	for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
	{
		UCoverPoint* CurrentCoverPoint = UEnvQueryItemType_Cover::GetValue(QueryInstance.RawData.GetData() + QueryInstance.Items[It.GetIndex()].DataOffset);

		const FVector ItemLocation = GetItemLocation(QueryInstance, It.GetIndex()) + FVector(0, 0, ContextZOffset);

		for (int32 ContextIndex = 0; ContextIndex < ContextLocations.Num(); ContextIndex++)
		{
            bool bHit = RunLineTraceTo(ItemLocation, ContextLocations[ContextIndex], NULL, QueryInstance.World, TraceCollisionChannel, TraceParams, Debug);
			It.SetScore(TestPurpose, FilterType, bHit, true);
		}
	}
}


bool UEnvQueryTest_IsCoverPosition::RunLineTraceTo(const FVector& ItemPos, const FVector& ContextPos, AActor* ItemActor, UWorld* World, enum ECollisionChannel Channel, const FCollisionQueryParams& Params, bool Debug /*= false*/) const
{
	FCollisionQueryParams TraceParams(Params);
	if (Debug)
	{
		const FName TraceTag("UEnvQueryTest_IsCoverPosition");
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
		World->DebugDrawTraceTag = TraceTag;
#endif
		TraceParams.TraceTag = TraceTag;
	}
	TraceParams.AddIgnoredActor(ItemActor);
	const bool bHit = World->LineTraceTestByChannel(ContextPos, ItemPos, Channel, TraceParams);
	return bHit;
}

FText UEnvQueryTest_IsCoverPosition::GetDescriptionDetails() const
{
    return DescribeBoolTestParams(TEXT("coverd"));
}