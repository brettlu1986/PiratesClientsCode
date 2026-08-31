#pragma once
#include "Gestures/Base/GestureResult.h"
#include "TapGestureResult.generated.h"

UCLASS()
class UTapGestureResult : public UGestureResult
{
    GENERATED_BODY()

public:

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	TArray<FVector2D> Positions;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	int32 DataNum;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	FVector2D DeltaPositionFromStart;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float DeltaDistanceFromStart;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	FVector2D Position;
};
