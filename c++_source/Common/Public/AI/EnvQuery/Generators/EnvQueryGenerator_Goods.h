#pragma once

#include "EnvironmentQuery/EnvQueryGenerator.h"
#include "DataProviders/AIDataProvider.h"
#include "EnvQueryGenerator_Goods.generated.h"


UCLASS()
class UEnvQueryGenerator_Goods : public UEnvQueryGenerator
{
    GENERATED_UCLASS_BODY()

    UPROPERTY(EditDefaultsOnly, Category = Generator)
    FAIDataProviderFloatValue Radius;

    UPROPERTY(EditDefaultsOnly, Category = Generator)
    FAIDataProviderBoolValue IsShip;

    UPROPERTY(EditDefaultsOnly, Category = Generator)
    TSubclassOf<UEnvQueryContext> GenerateAround;

    virtual void GenerateItems(FEnvQueryInstance& QueryInstance) const override;

    virtual FText GetDescriptionTitle() const override;
    virtual FText GetDescriptionDetails() const override;
};
