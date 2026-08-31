
#include "KMRange.generated.h"

USTRUCT(Blueprintable, Meta=(DisplayName="FloatRange"))
struct FKMFloatRange
{
	GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    float Min;

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    float Max;
};

USTRUCT(Blueprintable, Meta = (DisplayName = "IntegerRange"))
struct FKMIntegerRange
{
	GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    int32 Min;

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    int32 Max;
};
