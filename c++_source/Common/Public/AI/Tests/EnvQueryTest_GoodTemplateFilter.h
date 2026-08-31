#pragma once

#include "EnvironmentQuery/EnvQueryTest.h"
#include "EnvQueryTest_GoodTemplateFilter.generated.h"


UCLASS()
class UEnvQueryTest_GoodTemplateFilter : public UEnvQueryTest
{
    GENERATED_UCLASS_BODY()

    UPROPERTY(EditDefaultsOnly, Category = Category)
    FAIDataProviderIntValue HighPriorityTemplateCategory1;

    UPROPERTY(EditDefaultsOnly, Category = Category)
    FAIDataProviderIntValue HighPriorityTemplateCategory2;

    UPROPERTY(EditDefaultsOnly, Category = Category)
    FAIDataProviderIntValue HighPriorityTemplateCategory3;

    virtual void RunTest(FEnvQueryInstance& QueryInstance) const override;

    virtual FText GetDescriptionDetails() const override;
};
