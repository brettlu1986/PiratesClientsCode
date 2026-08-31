#pragma once

#include "KMObject.h"
#include "PiratesMovementDelegate.generated.h"

UCLASS()
class COMMON_API UPiratesMovementDelegate : public UKMObject
{
    GENERATED_BODY()    
    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FMovementIllegalDetectionDelegate, AActor*, Actor);
    
public:
    UPROPERTY()
    FMovementIllegalDetectionDelegate OnMovementIllegalDetection;
};
