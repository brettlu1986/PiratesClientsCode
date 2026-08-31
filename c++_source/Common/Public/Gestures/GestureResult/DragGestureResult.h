#pragma once
#include "Gestures/Base/GestureResult.h"
#include "DragGestureResult.generated.h"

UCLASS()
class UDragGestureResult : public UGestureResult
{
    GENERATED_BODY()

public:

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	FVector2D CurrentPosition;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	TArray<FVector2D> Positions;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	int32 DataNum;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	FVector2D DeltaPosition;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float DeltaDistance;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	FVector2D DeltaPositionFromStart;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float DeltaDistanceFromStart;
};
