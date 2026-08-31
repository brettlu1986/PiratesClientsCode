#include "AI/EnvQuery/EnvQueryItemType_Goods.h"
#include "BehaviorTree/BlackboardComponent.h"
#include "BehaviorTree/Blackboard/BlackboardKeyType_Int.h"
#include "Game/Battle/TemplateActorDataManager.h"
#include "Game/GameCommon.h"


UEnvQueryItemType_Goods::UEnvQueryItemType_Goods(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
    ValueSize = sizeof(FEnvQueryGoodsItemData);
}

FEnvQueryGoodsItemData UEnvQueryItemType_Goods::GetValue(const uint8* RawData)
{
    FEnvQueryGoodsItemData GoodsItemData = GetValueFromMemory<FEnvQueryGoodsItemData>(RawData);
    return GoodsItemData;
}

void UEnvQueryItemType_Goods::SetValue(uint8* RawData, const FEnvQueryGoodsItemData& Value)
{
    SetValueInMemory<FEnvQueryGoodsItemData>(RawData, Value);
}

FVector UEnvQueryItemType_Goods::GetItemLocation(const uint8 * RawData) const
{
    FEnvQueryGoodsItemData GoodsItemData = UEnvQueryItemType_Goods::GetValue(RawData);
    return GoodsItemData.Location;
}

void UEnvQueryItemType_Goods::AddBlackboardFilters(FBlackboardKeySelector& KeySelector, UObject* FilterOwner) const
{
    Super::AddBlackboardFilters(KeySelector, FilterOwner);
    KeySelector.AddIntFilter(FilterOwner, GetClass()->GetFName());
}

bool UEnvQueryItemType_Goods::StoreInBlackboard(FBlackboardKeySelector& KeySelector, UBlackboardComponent* Blackboard, const uint8* RawData) const
{
    bool bStored = Super::StoreInBlackboard(KeySelector, Blackboard, RawData);
    if (!bStored && KeySelector.SelectedKeyType == UBlackboardKeyType_Int::StaticClass())
    {
        FEnvQueryGoodsItemData GoodsItemData = UEnvQueryItemType_Goods::GetValue(RawData);
        Blackboard->SetValue<UBlackboardKeyType_Int>(KeySelector.GetSelectedKeyID(), GoodsItemData.InstanceId);

        bStored = true;
    }

    return bStored;
}
