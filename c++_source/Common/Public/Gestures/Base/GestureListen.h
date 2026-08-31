#pragma once

#include "GestureBase.h"
#include "GestureResult.h"
#include "GestureListen.generated.h"

//手势监听类
UCLASS()
class UGestureListen : public UObject
{
	GENERATED_UCLASS_BODY()
public:
    virtual ~UGestureListen();

    virtual void Init();

    //执行手势解析
    void Execute();

    //停止当前手势解析
    void Cancel();

    void Tick(float DeltaSeconds);

    void TouchStart(ETouchIndex::Type FingerIndex, FVector Location);

    void TouchStop(ETouchIndex::Type FingerIndex, FVector Location);

    void TouchMove(ETouchIndex::Type FingerIndex, FVector Location);

protected:

    virtual void ReportActive(UGestureResult* Result);

    virtual void ReportDeactive(UGestureResult* Result);

    virtual void OnTouchStart(const ETouchIndex::Type FingerIndex){};

    virtual void OnTouchMove(const ETouchIndex::Type FingerIndex){};

    virtual void OnTouchStop(const ETouchIndex::Type FingerIndex){};

public:
    // 当前手势优先级
    int32 Priority;
    // 可触发的距离阀值
    float DistanceLimit;
    // 可触发的速度阀值
    float SpeedTimeLimit;

    FGestureResultDelegate OnActiveDelegate;

    FGestureResultDelegate OnDeactiveDelegate;

protected:
    float TotalElapseTime;

    bool IsExecuting;

    EGestureType OwnerType;

    TMap<ETouchIndex::Type, FFingerInfo> FingerInfoMap;
};
