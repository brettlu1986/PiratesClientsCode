#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "Templates/SubclassOf.h"
#include "EnvironmentQuery/EnvQueryContext.h"
#include "EnvironmentQuery/EnvQueryTest.h"
#include "EnvQueryTest_ShipBestLocation.generated.h"


UCLASS()
class UEnvQueryTest_ShipBestLocation : public UEnvQueryTest
{
	GENERATED_UCLASS_BODY()

	///** testing mode */
	//UPROPERTY(EditDefaultsOnly, Category=Distance)
	//TEnumAsByte<EEnvTestDistance::Type> TestMode;

	/** context */
	UPROPERTY(EditDefaultsOnly, Category= ShipBestLocation)
	TSubclassOf<UEnvQueryContext> Self;

    /** context */
    UPROPERTY(EditDefaultsOnly, Category = ShipBestLocation)
    TSubclassOf<UEnvQueryContext> Target;

	virtual void RunTest(FEnvQueryInstance& QueryInstance) const override;

	virtual FText GetDescriptionTitle() const override;
	virtual FText GetDescriptionDetails() const override;


    // XWH: Override these methods to customized the best location strategy.
    virtual FVector GetPredictiveSelfDirection(AActor* selfActor, AActor* targetActor, FVector itemLocation) const;
    virtual FVector GetPredictiveTargetDirection(AActor* selfActor, AActor* targetActor, FVector itemLocation) const;
    virtual FVector GetPredictiveTargetLocation(AActor* selfActor, AActor* targetActor, FVector itemLocation) const;

    virtual float EvaluateSituation(AActor* selfActor, AActor* targetActor,
        FVector selfDirection, FVector selfLocation,
        FVector targetDirection, FVector targetLocation) const;
};
