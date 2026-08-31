#pragma once


#include "PiratesActorTriggerGroupManager.generated.h"

class UPiratesGameMiscDelegate;

UCLASS()
class COMMON_API UPiratesActorTriggerGroupManager : public UActorComponent
{
    GENERATED_UCLASS_BODY()

private:


    struct FActorTriggerInfo
    {
        TWeakObjectPtr<AActor> Actor;
        bool bIn;
        bool bRemove;

        FActorTriggerInfo()
            : bIn(false)
            , bRemove(false)
        {
        }

        FActorTriggerInfo(AActor* InActor)
            : Actor(InActor)
            , bIn(false)
            , bRemove(false)
        {}
    };

    struct FActorTriggerGroupInfo
    {
        TWeakObjectPtr<AActor> OwnerActor;
        int GroupId;        
        float RadiusSquared;
        float OffsetHeight;
        bool bCheckBounds;
        float LastUpdateTime;
        float UpdateInterval;
        float bRemove;
        TArray<FActorTriggerInfo> AreaInfos;
        FActorTriggerGroupInfo()
            : GroupId(0)            
            , RadiusSquared(0)
            , OffsetHeight(-1)
            , bCheckBounds(false)
            , LastUpdateTime(0)
            , UpdateInterval(1)
            , bRemove(false)
        {
        }
    };


public:

    void SetDelegate(UPiratesGameMiscDelegate* BattleDelegate) { Delegate = BattleDelegate; }

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    void Clear();

    void Update(float DeltaTime);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    int CreateTriggerGroup(AActor* pActor, float Radius, float UpdateInterval, bool IsCheckBounds);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    int CreateTriggerGroupWithOffsetHeight(AActor* pActor, float Radius, float UpdateInterval, float OffsetHeight, bool IsCheckBounds);
 
    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    bool DestroyTriggerGroup(int GroupId);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    bool AddTriggerInGroup(int GroupId, AActor* pActor);

    UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
    bool RemoveTriggerInGroup(int GroupId, AActor* pActor);

private:
    void Execute(TSharedPtr<FActorTriggerGroupInfo>& TriggerGroupInfo);
    bool InBoundsBox(const AActor* Actor, const FVector& Location, float Radius);

    int GenerateGroup();

    int FindGroupIndex(int GroupId);

    void DoRemove();

private:
    UPiratesGameMiscDelegate* Delegate;
    TArray<TSharedPtr<FActorTriggerGroupInfo>> ActorTriggerGroupInfos;
    int MaxGroupId;
    bool bCheckRemove;
};
