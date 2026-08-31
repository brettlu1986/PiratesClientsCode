#include "AI/Tests/EnvQueryTest_IsGoodsValid.h"
#include "AI/EnvQuery/EnvQueryItemType_Goods.h"

UEnvQueryTest_IsGoodsValid::UEnvQueryTest_IsGoodsValid(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
    Cost = EEnvTestCost::Low;
    ValidItemType = UEnvQueryItemType_Goods::StaticClass();
    SetWorkOnFloatValues(false);
}

void UEnvQueryTest_IsGoodsValid::RunTest(FEnvQueryInstance& QueryInstance) const
{
    UObject* QueryOwner = QueryInstance.Owner.Get();
    if (QueryOwner == nullptr)
    {
        return;
    }

    BoolValue.BindData(QueryOwner, QueryInstance.QueryID);
    bool bWantValid = BoolValue.GetValue();
 

    for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
    {
        FEnvQueryGoodsItemData GoodsData = UEnvQueryItemType_Goods::GetValue(QueryInstance.RawData.GetData() + QueryInstance.Items[It.GetIndex()].DataOffset);
        bool bValid = TestGoods(QueryOwner, GoodsData.InstanceId, GoodsData.Location);
        It.SetScore(TestPurpose, FilterType, bValid, bWantValid);
    }
}
FText UEnvQueryTest_IsGoodsValid::GetDescriptionDetails() const
{
    return DescribeBoolTestParams(TEXT("goods is valid"));
}
