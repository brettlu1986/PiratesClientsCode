
#include "DyadicArray.generated.h"

USTRUCT(Blueprintable)
struct FDyadicArrayFloatItem
{
	GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    TArray<float> Items;
};

USTRUCT(Blueprintable)
struct FDyadicArrayIntItem
{
	GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	TArray<int32> Items;
};