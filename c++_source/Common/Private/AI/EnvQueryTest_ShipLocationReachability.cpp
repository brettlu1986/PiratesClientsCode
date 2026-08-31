// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "AI/EnvQueryTest_ShipLocationReachability.h"
#include "Common.h"
#include "AI/EnvQueryTest_ShipLocationReachability.h"
#include "EnvironmentQuery/Items/EnvQueryItemType_VectorBase.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Querier.h"
#include "Components/ShipMovementComponent.h"
#include "Pawns/PiratesShipPawn.h"


UEnvQueryTest_ShipLocationReachability::UEnvQueryTest_ShipLocationReachability(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
    Self = UEnvQueryContext_Querier::StaticClass();
	Cost = EEnvTestCost::Low;
	ValidItemType = UEnvQueryItemType_VectorBase::StaticClass();
}

void UEnvQueryTest_ShipLocationReachability::RunTest(FEnvQueryInstance& QueryInstance) const
{
	UObject* QueryOwner = QueryInstance.Owner.Get();
	if (QueryOwner == nullptr)
	{
		return;
	}

	FloatValueMin.BindData(QueryOwner, QueryInstance.QueryID);
	float MinThresholdValue = FloatValueMin.GetValue();

	FloatValueMax.BindData(QueryOwner, QueryInstance.QueryID);
	float MaxThresholdValue = FloatValueMax.GetValue();


    // Get context.
    TArray<AActor*> ContextSelfShips;
    if (!QueryInstance.PrepareContext(Self, ContextSelfShips))
    {
        return;
    }

    APiratesShipPawn* ShipPawn = Cast<APiratesShipPawn>(ContextSelfShips[0]);
    if (!ShipPawn)
    {
        return;
    }

    // Run the test for all the items.
	for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
	{
		FVector ItemLocation = GetItemLocation(QueryInstance, It.GetIndex());

        float score = ShipPawn->IsLocationReachable(ItemLocation) ? 1.0f : 0 - 1.0f;
        score += ScoreRandomized ? FMath::FRandRange(0, 0.1) : 0;
        It.SetScore(TestPurpose, FilterType, score, MinThresholdValue, MaxThresholdValue);
	}

}

FText UEnvQueryTest_ShipLocationReachability::GetDescriptionTitle() const
{
	FString Desc;
    Desc = TEXT("Reachability");

    return FText::FromString(FString::Printf(TEXT("Reachability")));

	//return FText::FromString(FString::Printf(TEXT("%s%s: to %s"), 
	//	*Super::GetDescriptionTitle().ToString(), *ModeDesc,
	//	*UEnvQueryTypes::DescribeContext(DistanceTo).ToString()));
}

FText UEnvQueryTest_ShipLocationReachability::GetDescriptionDetails() const
{
	//return DescribeFloatTestParams();
    return FText();
}



