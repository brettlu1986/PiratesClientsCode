#include "AI/EnvQuery/Generators/EnvQueryGenerator_Goods.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Querier.h"
#include "AI/EnvQuery/EnvQueryItemType_Goods.h"
#include "Game/GameCommon.h"
#include "Game/Battle/TemplateActorDataManager.h"

#define LOCTEXT_NAMESPACE "UEnvQueryGenerator_Goods"

UEnvQueryGenerator_Goods::UEnvQueryGenerator_Goods(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
    ItemType = UEnvQueryItemType_Goods::StaticClass();
    GenerateAround = UEnvQueryContext_Querier::StaticClass();
    Radius.DefaultValue = 10000.f;
    IsShip.DefaultValue = false;
}


void UEnvQueryGenerator_Goods::GenerateItems(FEnvQueryInstance& QueryInstance) const
{
    UObject* BindOwner = QueryInstance.Owner.Get();

    Radius.BindData(BindOwner, QueryInstance.QueryID);
    const float RadiusValue = Radius.GetValue();

    IsShip.BindData(BindOwner, QueryInstance.QueryID);
    bool bIsShipValue = IsShip.GetValue();
 
    TArray<FVector> ContextLocations;
    QueryInstance.PrepareContext(GenerateAround, ContextLocations);

    UTemplateActorDataManager* TemplateActorDataManager = UGameCommon::Get(this)->GetTemplateActorDataManager();

    if (!TemplateActorDataManager)
    {
        UE_LOG(LogTemp, Warning, TEXT("%s Failed to retrieve TemplateActorDataManager."), *GetNameSafe(this));
        return;
    }

    for (int32 ContextIndex = 0; ContextIndex < ContextLocations.Num(); ContextIndex++)
    {
        TArray<FEnvQueryGoodsItemData> Goods;
        TArray<int32> InstanceIds;
        int32 NumItem = TemplateActorDataManager->FindInstanceIdsInRadius(bIsShipValue, ContextLocations[ContextIndex], RadiusValue, InstanceIds);
        for (const auto& InstanceId : InstanceIds)
        {
            FTemplateActorData* TemplateActorData = TemplateActorDataManager->FindTemplateData(InstanceId);
            FEnvQueryGoodsItemData GoodData;
            GoodData.InstanceId = TemplateActorData->InstanceId;
            GoodData.TemplateId = TemplateActorData->TemplateId;
            GoodData.Location = TemplateActorData->Location;
            Goods.Emplace(GoodData);
        }
        QueryInstance.AddItemData<UEnvQueryItemType_Goods>(Goods);
    }
}


FText UEnvQueryGenerator_Goods::GetDescriptionTitle() const
{
    FFormatNamedArguments Args;
    Args.Add(TEXT("DescriptionTitle"), Super::GetDescriptionTitle());
    return FText::Format(LOCTEXT("DescriptionGenerateGoods", "{DescriptionTitle}: generate set of goods"), Args);
};

FText UEnvQueryGenerator_Goods::GetDescriptionDetails() const
{
    FFormatNamedArguments Args;
    Args.Add(TEXT("Radius"), FText::FromString(Radius.ToString()));
    FText Desc = FText::Format(LOCTEXT("GoodsDescription", "radius: {Radius}"), Args);

    return Desc;
}

#undef LOCTEXT_NAMESPACE