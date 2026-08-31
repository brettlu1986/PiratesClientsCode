#pragma once

#include "EnvironmentQuery/EnvQueryTest.h"
#include "EnvQueryTest_CanShot.generated.h"

UCLASS()
class UEnvQueryTest_CanShot : public UEnvQueryTest
{
    GENERATED_UCLASS_BODY()


    UPROPERTY(EditDefaultsOnly, Category = Trace)
    TSubclassOf<UEnvQueryContext> Context;

    UPROPERTY(EditDefaultsOnly, Category = Trace)
    TSubclassOf<UEnvQueryContext> IngnoreContext;

    UPROPERTY(EditDefaultsOnly, Category = Trace)
    FAIDataProviderFloatValue ItemHeightOffset;

    UPROPERTY(EditDefaultsOnly, Category = Trace)
    FAIDataProviderFloatValue SphereRadius;

    UPROPERTY(EditDefaultsOnly, Category = Trace)
    TArray<TEnumAsByte<EObjectTypeQuery> > ObjectTypes;

    virtual void RunTest(FEnvQueryInstance& QueryInstance) const override;

    virtual FText GetDescriptionDetails() const override;

protected:
    bool RunLineTraceTo(const FVector& ItemPos, AActor* ContextActor, UWorld* World, int32 SphereSize, const TArray<TEnumAsByte<EObjectTypeQuery> > & ObjectTypes, 
        const TArray<AActor*>& IngoreActors) const;
};
