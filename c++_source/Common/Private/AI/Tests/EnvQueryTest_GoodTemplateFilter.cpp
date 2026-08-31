#include "AI/Tests/EnvQueryTest_GoodTemplateFilter.h"
#include "AI/EnvQuery/EnvQueryItemType_Goods.h"
#include "Game/Battle/TemplateActorDataManager.h"
#include "Game/GameCommon.h"

UEnvQueryTest_GoodTemplateFilter::UEnvQueryTest_GoodTemplateFilter(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
    Cost = EEnvTestCost::Low;
    ValidItemType = UEnvQueryItemType_Goods::StaticClass();
    SetWorkOnFloatValues(true);
    HighPriorityTemplateCategory1.DefaultValue = 0;
    HighPriorityTemplateCategory2.DefaultValue = 0;
    HighPriorityTemplateCategory3.DefaultValue = 0;
}

void UEnvQueryTest_GoodTemplateFilter::RunTest(FEnvQueryInstance& QueryInstance) const
{
    UObject* DataOwner = QueryInstance.Owner.Get();
    FloatValueMin.BindData(DataOwner, QueryInstance.QueryID);
    float MinThresholdValue = FloatValueMin.GetValue();

    FloatValueMax.BindData(DataOwner, QueryInstance.QueryID);
    float MaxThresholdValue = FloatValueMax.GetValue();

    HighPriorityTemplateCategory1.BindData(DataOwner, QueryInstance.QueryID);
    int32 HighPriorityTemplateCategoryValue1 = HighPriorityTemplateCategory1.GetValue();

    HighPriorityTemplateCategory2.BindData(DataOwner, QueryInstance.QueryID);
    int32 HighPriorityTemplateCategoryValue2 = HighPriorityTemplateCategory2.GetValue();

    HighPriorityTemplateCategory3.BindData(DataOwner, QueryInstance.QueryID);
    int32 HighPriorityTemplateCategoryValue3 = HighPriorityTemplateCategory3.GetValue();

    UTemplateActorDataManager* TemplateActorDataManager = UGameCommon::Get(this)->GetTemplateActorDataManager();

    auto GetTemplateCategory = [](int32 nTemplateId, int32& nMainCategory, int32& nSubCategory) {
        nSubCategory    = nTemplateId  / 10000;
        nMainCategory   = nSubCategory / 100;
    };
    TMap<int32, float> HighPriorityTemplateArray;
    HighPriorityTemplateArray.Emplace(HighPriorityTemplateCategoryValue1, 1.0f);
    HighPriorityTemplateArray.Emplace(HighPriorityTemplateCategoryValue2, 0.6f);
    HighPriorityTemplateArray.Emplace(HighPriorityTemplateCategoryValue3, 0.3f);

    for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
    {
        FEnvQueryGoodsItemData GoodsData = UEnvQueryItemType_Goods::GetValue(QueryInstance.RawData.GetData() + QueryInstance.Items[It.GetIndex()].DataOffset);
        float Score = 0;
        if (GoodsData.TemplateId > 0)
        {
            int32 nMainCategory = 0;
            int32 nSubCategory = 0;
            GetTemplateCategory(GoodsData.TemplateId, nMainCategory, nSubCategory);
            for (const auto& HighPriorityPair : HighPriorityTemplateArray)
            {
                int32 HighPriorityId = HighPriorityPair.Key;
                if (HighPriorityId == nMainCategory ||
                    HighPriorityId == nSubCategory || HighPriorityId == GoodsData.TemplateId)
                {
                    Score = HighPriorityPair.Value;
                    break;
                }
            }
        }
        It.SetScore(TestPurpose, FilterType, Score, MinThresholdValue, MaxThresholdValue);
    }
}

FText UEnvQueryTest_GoodTemplateFilter::GetDescriptionDetails() const
{
    return DescribeFloatTestParams();
}