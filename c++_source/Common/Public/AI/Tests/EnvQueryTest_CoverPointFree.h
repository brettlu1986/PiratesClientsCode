#pragma once

#include "EnvironmentQuery/EnvQueryTest.h"
#include "EnvQueryTest_CoverPointFree.generated.h"


UCLASS()
class UEnvQueryTest_CoverPointFree : public UEnvQueryTest
{
	GENERATED_UCLASS_BODY()
	
    UPROPERTY(EditDefaultsOnly, Category = Distance)
    TSubclassOf<UEnvQueryContext> Context;

	virtual void RunTest(FEnvQueryInstance& QueryInstance) const override;
	
    virtual FText GetDescriptionDetails() const override;
};
