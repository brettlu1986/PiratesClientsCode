#pragma once

#include "CoreMinimal.h"
#include "AISmokeManager.generated.h"

USTRUCT(BlueprintType)
struct FAISmoke
{
    GENERATED_BODY()

    UPROPERTY(BlueprintReadOnly)
    FVector Location;

    UPROPERTY(BlueprintReadOnly)
    float Radius;

    UPROPERTY(BlueprintReadOnly)
    float RemainTime;
};

UCLASS()
class COMMON_API UAISmokeManager : public UObject
{
public:
    GENERATED_UCLASS_BODY()

    UFUNCTION(BlueprintCallable, Category = "AISmokeManager")
    void AddSmoke(const FVector& Location, float Radius, float ExistTime);

    void Tick(float Delta);

    UFUNCTION(BlueprintPure, Category = "AISmokeManager")
    void QuerySmoke(const FVector& Location, float Radius, TArray<FAISmoke>& OutSmokes) const;

protected:

    typedef TArray<FAISmoke> SmokeArray;
    SmokeArray Smokes;
};