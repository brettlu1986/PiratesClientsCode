#pragma once
#include "Gestures/Base/GestureResult.h"
#include "FlickGestureResult.generated.h"

UCLASS()
class UFlickGestureResult : public UGestureResult
{
    GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	TArray<FVector2D> Positions;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	FVector2D DeltaPosition;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float DeltaDistance;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	EFlickDirection Direction;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float Degree;
};
