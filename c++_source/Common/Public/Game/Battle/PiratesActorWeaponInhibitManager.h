#pragma once

#include "PiratesActorWeaponInhibitManager.generated.h"

class UPiratesGameMiscDelegate;

UCLASS()
class COMMON_API UPiratesActorWeaponInhibitManager : public UActorComponent
{
    GENERATED_UCLASS_BODY()

private:
    struct FActorInfo
    {
        TWeakObjectPtr<AActor> Actor;
        FActorInfo() : Actor(nullptr) {}
        float CheckLength;
        float LastDistance;
        // 不同姿势高度不同
        FVector OffsetLocation;
        bool bCurrentInhibit;
    };

public:

    void SetDelegate(UPiratesGameMiscDelegate* BattleDelegate) { Delegate = BattleDelegate; }

    UFUNCTION(BlueprintCallable, Category = "PiratesActorWeaponInhibitManager")
    void SetUpdateInterval(float InEffetiveTime);

    UFUNCTION(BlueprintCallable, Category = "PiratesActorWeaponInhibitManager")
    void Clear();

    UFUNCTION(BlueprintCallable, Category = "PiratesActorWeaponInhibitManager")
    void AddActor(AActor* Actor, float Length, FVector OffsetLocation = FVector::ZeroVector);

    UFUNCTION(BlueprintCallable, Category = "PiratesActorWeaponInhibitManager")
    void RemoveActor(AActor* Actor);

    void Update(float DeltaTime);

private:
    void Execute();

    const bool CheckBoxInside2dArea(const FVector2D* Points, const FVector2D& Center, float RadiusSquared) const;
    bool CaculateBoxPoints(const AActor* Actor, const UBoxComponent* Box, FVector2D* OutPoints);

    UFUNCTION()
    void OnActorDestroyed(AActor* ActorToDestroy);

    void CheckActorInhibit(FActorInfo& ActorInfo);
private:
    float EffectiveTime;
    float CurrentTime;
    TArray<FActorInfo> Actors;      // 因为没几个actor，所以这里用的数组，遍历快
    UPiratesGameMiscDelegate* Delegate;
public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = Appearance)
    FString IgnoreType;
};
