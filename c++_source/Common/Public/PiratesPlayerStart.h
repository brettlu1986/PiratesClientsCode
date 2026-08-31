#pragma once

#include "GameFramework/PlayerStart.h"
#include "PiratesPlayerStart.generated.h"

/**
*
*/
UCLASS()
class COMMON_API APiratesPlayerStart : public APlayerStart
{
    GENERATED_UCLASS_BODY()


public:

    UPROPERTY(EditAnywhere, Category = "PiratesPlayerStart")
    int32 GroupIndex;
    
    UPROPERTY(EditAnywhere, Category = "PiratesPlayerStart")
    TArray<int32> AvaliableTypeIds;

    UPROPERTY(EditAnywhere, Category = "PiratesPlayerStart")
    bool bCanRespawn;

    UPROPERTY(EditAnywhere, Category = "PiratesPlayerStart")
    bool bActive;

    UPROPERTY(EditAnywhere, Category = "PiratesPlayerStart")
    int32 Priority;

    UPROPERTY(VisibleAnywhere, Category = "PiratesPlayerStart")
    int32 UsedTimes;

};