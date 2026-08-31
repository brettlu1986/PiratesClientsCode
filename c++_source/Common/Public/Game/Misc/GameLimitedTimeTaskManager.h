#pragma once
#include "GameLimitedTimeTaskManager.generated.h"

class COMMON_API FGameLimitedTimeTask
{
public:
    virtual void Process() = 0;
    virtual void Cancel() {};
    virtual const FString GetInfo() const = 0;
    virtual void AddReferencedObjects(FReferenceCollector& Collector) {}
    virtual ~FGameLimitedTimeTask() {}
};

UCLASS(config=Game)
class COMMON_API UGameLimitedTimeTaskManager : public UObject
{
    GENERATED_UCLASS_BODY()

private:
    struct Implement;
    TSharedPtr<Implement> Impl;

public:
    void Init();
    void Uninit();
    int AddTask(FGameLimitedTimeTask* Task, int Priority, bool bAutoDestroy);
    void RemoveTask(int TaskHandle);
    bool FlushTask(int TaskHandle);
    void FlushAll();
    void RemoveAll();
    static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

private:
    UPROPERTY(config)
    float LimitedTimePerFrame;

    UPROPERTY(config)
    float MaxWorkFrameTime;
};