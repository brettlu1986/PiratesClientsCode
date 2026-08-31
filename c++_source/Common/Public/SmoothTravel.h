#pragma once
#include "SmoothTravel.generated.h"

UINTERFACE(Blueprintable)
class COMMON_API USmoothTravel : public UInterface
{
    GENERATED_UINTERFACE_BODY()
};

class COMMON_API ISmoothTravel
{
    GENERATED_IINTERFACE_BODY()

public:
    UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Smooth Travel")
    void SmoothTravelSwap(AActor *SwapFrom);

    UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Smooth Travel")
    void SmoothTravelPreTravel();
};