#pragma once


#include "EnvironmentQuery/Items/EnvQueryItemType_VectorBase.h"
#include "EnvQueryItemType_Goods.generated.h"

struct FBlackboardKeySelector;
class UBlackboardComponent;

struct FEnvQueryGoodsItemData
{
    int32   InstanceId;
    uint32  TemplateId;
    FVector Location;

    FEnvQueryGoodsItemData() :
        InstanceId(0),
        TemplateId(0),
        Location(FVector::ZeroVector)
    {

    }
};

UCLASS()
class UEnvQueryItemType_Goods : public UEnvQueryItemType_VectorBase
{
    GENERATED_UCLASS_BODY()

public:
    typedef FEnvQueryGoodsItemData FValueType;

    static FEnvQueryGoodsItemData GetValue(const uint8* RawData);
    static void SetValue(uint8* RawData, const FEnvQueryGoodsItemData& Value);

    virtual FVector GetItemLocation(const uint8* RawData) const override;

    virtual void AddBlackboardFilters(FBlackboardKeySelector& KeySelector, UObject* FilterOwner) const override;
    virtual bool StoreInBlackboard(FBlackboardKeySelector& KeySelector, UBlackboardComponent* Blackboard, const uint8* RawData) const override;
};
