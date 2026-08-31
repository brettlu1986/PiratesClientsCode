#pragma once

#include "PiratesAreaTriggerManager.generated.h"

class UPiratesGameMiscDelegate;
class UActorDelegate;

UCLASS()
class COMMON_API UPiratesAreaTriggerManager : public UActorComponent
{
    GENERATED_UCLASS_BODY()

private:
    struct FActorInfo
    {
        FScriptBitArray AreaSlots;
        TWeakObjectPtr<AActor> Actor;
        int LogicInstanceId;
        TWeakObjectPtr<UBoxComponent> BoxComponent;
        FActorInfo() 
            : Actor(nullptr)
            , LogicInstanceId(0)
            {
            }
    };
    struct FAreaInfo
    {
        int AreaId;
        FVector2D Center;
        double RadiusSquared;
    };

public:
    void Init(UPiratesGameMiscDelegate* InMiscDelegate, UActorDelegate* InActorDelegate);
    void Uninit();

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    void SetUpdateInterval(float InEffetiveTime);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    void Clear();

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    int Create2DArea(float X, float Y, float Radius);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    bool Destroy2DArea(int AreaId);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    bool Set2dAreaInfo(int AreaId, float X, float Y, float Radius);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    bool AddActorBox(AActor* Actor, UBoxComponent* Box);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    bool AddActor(AActor* Actor);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    void RemoveActor(AActor* Actor);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    void PrintAreaTriggerInfo(int AreaId);

    void Update(float DeltaTime);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    bool IsActorInArea(AActor* Actor, int AreaId);
private:
    void Execute();

    const bool CheckBoxInside2dArea(const FVector2D* Points, const FVector2D& Center, float RadiusSquared) const;
    bool CaculateBoxPoints(const AActor* Actor, const UBoxComponent* Box, FVector2D* OutPoints);

    UFUNCTION()
    void OnActorDestroyed(AActor* ActorToDestroy, uint32 UniqueId, int InstanceId);
private:
    float EffectiveTime;
    float CurrentTime;
    TArray<FActorInfo> Actors;      // 因为没几个actor，所以这里用的数组，遍历快
    TArray<FAreaInfo> Areas;        // 区域个数更少
    TMap<int, int> AreaMap;
    UPiratesGameMiscDelegate* MiscDelegate;
    UActorDelegate* ActorDelegate;
};
