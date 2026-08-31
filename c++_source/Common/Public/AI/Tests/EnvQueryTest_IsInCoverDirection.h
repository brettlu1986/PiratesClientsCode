#pragma once

#include "EnvironmentQuery/EnvQueryTest.h"
#include "EnvQueryTest_IsInCoverDirection.generated.h"

UCLASS()
class UEnvQueryTest_IsInCoverDirection : public UEnvQueryTest
{
	GENERATED_UCLASS_BODY()

	UPROPERTY(EditDefaultsOnly, Category = Trace)
	TSubclassOf<UEnvQueryContext> Context;

	UPROPERTY(EditDefaultsOnly, Category = Trace)
	FAIDataProviderFloatValue MaxEpsilon;

	virtual void RunTest(FEnvQueryInstance& QueryInstance) const override;

    virtual FText GetDescriptionDetails() const override;
};
