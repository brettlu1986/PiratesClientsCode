#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "Templates/SubclassOf.h"
#include "EnvironmentQuery/EnvQueryContext.h"
#include "EnvironmentQuery/EnvQueryTest.h"
#include "EnvQueryTest_ShipLocationReachability.generated.h"


UCLASS()
class UEnvQueryTest_ShipLocationReachability : public UEnvQueryTest
{
	GENERATED_UCLASS_BODY()

    /** context */
    UPROPERTY(EditDefaultsOnly, Category = ShipLocationReachability)
    TSubclassOf<UEnvQueryContext> Self;

    UPROPERTY(EditDefaultsOnly, Category = ShipLocationReachability)
    bool ScoreRandomized = false;


	virtual void RunTest(FEnvQueryInstance& QueryInstance) const override;
	virtual FText GetDescriptionTitle() const override;
	virtual FText GetDescriptionDetails() const override;
};
