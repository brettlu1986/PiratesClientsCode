#pragma once

#include "GestureBase.h"
#include "GestureResult.generated.h"

UCLASS(BlueprintType)
class UGestureResult : public UObject
{
    GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "GestureResult")
	EGestureType GestureType;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "GestureResult")
	int Priority;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "GestureResult")
	float ElapsedTime;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "GestureResult")
	TEnumAsByte<ETouchIndex::Type> FingerIndex;
};
