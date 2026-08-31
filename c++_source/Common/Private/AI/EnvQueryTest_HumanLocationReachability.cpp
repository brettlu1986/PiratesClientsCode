// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "AI/EnvQueryTest_HumanLocationReachability.h"
#include "Common.h"
#include "AI/EnvQueryTest_HumanLocationReachability.h"
#include "EnvironmentQuery/Items/EnvQueryItemType_VectorBase.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Querier.h"
#include "Components/HumanMovementComponent.h"
#include "Pawns/PiratesHumanCharacter.h"
#include "Shell/CommonShell.h"
#include "Game/Battle/PiratesGridTypeManager.h"


UEnvQueryTest_HumanLocationReachability::UEnvQueryTest_HumanLocationReachability(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
	Self = UEnvQueryContext_Querier::StaticClass();
	Cost = EEnvTestCost::Low;
	ValidItemType = UEnvQueryItemType_VectorBase::StaticClass();
}

void UEnvQueryTest_HumanLocationReachability::RunTest(FEnvQueryInstance& QueryInstance) const
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
	TArray<AActor*> ContextSelfHumans;
	if (!QueryInstance.PrepareContext(Self, ContextSelfHumans))
	{
		return;
	}

	APiratesHumanCharacter* HumanPawn = Cast<APiratesHumanCharacter>(ContextSelfHumans[0]);
	if (!HumanPawn)
	{
		return;
	}

	// Run the test for all the items.
	for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
	{
		FVector ItemLocation = GetItemLocation(QueryInstance, It.GetIndex());
		EPiratesGridRegionType RegionType = UCommonShell::GetCommon(GWorld)->GetGridTypeManager()->GetRegionType(ItemLocation.X, ItemLocation.Y);
		float score = (EPiratesGridRegionType::Land == RegionType || EPiratesGridRegionType::Shore == RegionType) ? 1.0f : 0;
		It.SetScore(TestPurpose, FilterType, score, MinThresholdValue, MaxThresholdValue);
	}

}

FText UEnvQueryTest_HumanLocationReachability::GetDescriptionTitle() const
{
	FString Desc;
	Desc = TEXT("HumanLocationReachability");
	return FText::FromString(Desc);
}

FText UEnvQueryTest_HumanLocationReachability::GetDescriptionDetails() const
{
	return FText();
}



