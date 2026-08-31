#pragma once

#include "EnvironmentQuery/EnvQueryTest.h"
#include "EnvQueryTest_IsGoodsValid.generated.h"


UCLASS(Blueprintable)
class UEnvQueryTest_IsGoodsValid : public UEnvQueryTest
{
    GENERATED_UCLASS_BODY()

    virtual void RunTest(FEnvQueryInstance& QueryInstance) const override;

    virtual FText GetDescriptionDetails() const override;

public:
    UFUNCTION(BlueprintImplementableEvent, Category = "AI|Test")
    bool TestGoods(UObject* Owner, int32 ServerInstanceId, const FVector& Location) const;

};
