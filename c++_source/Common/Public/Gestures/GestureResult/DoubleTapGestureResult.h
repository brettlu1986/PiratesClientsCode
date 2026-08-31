#pragma once
#include "Gestures/Base/GestureResult.h"
#include "DoubleTapGestureResult.generated.h"

UCLASS()
class UDoubleTapGestureResult : public UGestureResult
{
    GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	TArray<FVector2D> Positions;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	FVector2D DeltaPosition;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float DeltaDistance;
};
