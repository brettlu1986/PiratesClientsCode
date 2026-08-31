#pragma once

#include "EnvironmentQuery/EnvQueryTest.h"
#include "EnvQueryTest_IsCoverPosition.generated.h"

UCLASS()
class UEnvQueryTest_IsCoverPosition : public UEnvQueryTest
{
	GENERATED_UCLASS_BODY()

	UPROPERTY(EditDefaultsOnly, Category = Trace)
	FEnvTraceData TraceData;

	UPROPERTY(EditDefaultsOnly, Category = Trace)
	TSubclassOf<UEnvQueryContext> Context;

	UPROPERTY(EditDefaultsOnly, Category = Trace)
	FAIDataProviderFloatValue ContextHeight;

	UPROPERTY(EditDefaultsOnly, Category = Trace)
	FAIDataProviderBoolValue DebugTrace;

	virtual void RunTest(FEnvQueryInstance& QueryInstance) const override;

    virtual FText GetDescriptionDetails() const override;

protected:
	bool RunLineTraceTo(const FVector& ItemPos, const FVector& ContextPos, AActor* ItemActor, UWorld* World, enum ECollisionChannel Channel, const FCollisionQueryParams& Params, bool Debug = false) const;
};
