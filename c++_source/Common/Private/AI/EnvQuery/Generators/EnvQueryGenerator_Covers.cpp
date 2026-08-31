#include "AI/EnvQuery/Generators/EnvQueryGenerator_Covers.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Querier.h"
#include "AI/AICoverPointsManager.h"
#include "AI/EnvQuery/EnvQueryItemType_Cover.h"
#include "Game/GameCommon.h"


#define LOCTEXT_NAMESPACE "UEnvQueryGenerator_Covers"

UEnvQueryGenerator_Covers::UEnvQueryGenerator_Covers(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
	ItemType = UEnvQueryItemType_Cover::StaticClass();
	GenerateAround = UEnvQueryContext_Querier::StaticClass();
    BoxSize.DefaultValue = 2000.f;
	BoxHeight.DefaultValue = 300.f;
}


void UEnvQueryGenerator_Covers::GenerateItems(FEnvQueryInstance& QueryInstance) const
{
	UObject* BindOwner = QueryInstance.Owner.Get();

    BoxSize.BindData(BindOwner, QueryInstance.QueryID);
	const float BoxW = BoxSize.GetValue();

	BoxHeight.BindData(BindOwner, QueryInstance.QueryID);
	const float BoxH = BoxHeight.GetValue();


	TArray<FVector> ContextLocations;
	QueryInstance.PrepareContext(GenerateAround, ContextLocations);

    UAICoverPointsManager* AICoverPointsManager = UGameCommon::Get(this)->GetAICoverPointsManager();
	if (!AICoverPointsManager)
	{
		UE_LOG(LogTemp, Warning, TEXT("%s Failed to retrieve AICoverPointsManager."), *GetNameSafe(this));
		return;
	}

	for (int32 ContextIndex = 0; ContextIndex < ContextLocations.Num(); ContextIndex++)
	{
		TArray<UCoverPoint*> Covers = AICoverPointsManager->GetCoverWithinBounds(FBoxCenterAndExtent(ContextLocations[ContextIndex], FVector(BoxW, BoxW, BoxH)));
		QueryInstance.AddItemData<UEnvQueryItemType_Cover>(Covers);
	}
}


FText UEnvQueryGenerator_Covers::GetDescriptionTitle() const
{
    FFormatNamedArguments Args;
    Args.Add(TEXT("DescriptionTitle"), Super::GetDescriptionTitle());
    return FText::Format(LOCTEXT("DescriptionGenerateCoverPoints", "{DescriptionTitle}: generate set of cover points"), Args);
};

FText UEnvQueryGenerator_Covers::GetDescriptionDetails() const
{
    FFormatNamedArguments Args;
    Args.Add(TEXT("BoxSize"), FText::FromString(BoxSize.ToString()));
    Args.Add(TEXT("BoxHeight"), FText::FromString(BoxHeight.ToString()));

    FText Desc = FText::Format(LOCTEXT("CoverPointsDescription", "box_size: {BoxSize}, box_height: {BoxHeight}"), Args);

    return Desc;
}

#undef LOCTEXT_NAMESPACE