#pragma once
#include "Gestures/Base/GestureResult.h"
#include "PinchGestureResult.generated.h"

UCLASS()
class UPinchGestureResult : public UGestureResult
{
    GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float StartDistance;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float DeltaDistance;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float DeltaDistanceFromStart;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float PinchRatio;
};
