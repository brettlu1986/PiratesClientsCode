#pragma once

#include "EnvironmentQuery/EnvQueryGenerator.h"
#include "DataProviders/AIDataProvider.h"
#include "EnvQueryGenerator_Covers.generated.h"

/**
 * 
 */
UCLASS()
class UEnvQueryGenerator_Covers : public UEnvQueryGenerator
{
	GENERATED_UCLASS_BODY()

	UPROPERTY(EditDefaultsOnly, Category = Generator)
	FAIDataProviderFloatValue BoxSize;

	UPROPERTY(EditDefaultsOnly, Category = Generator)
	FAIDataProviderFloatValue BoxHeight;

	UPROPERTY(EditDefaultsOnly, Category = Generator)
	TSubclassOf<UEnvQueryContext> GenerateAround;

	virtual void GenerateItems(FEnvQueryInstance& QueryInstance) const override;

    virtual FText GetDescriptionTitle() const override;
    virtual FText GetDescriptionDetails() const override;
};
