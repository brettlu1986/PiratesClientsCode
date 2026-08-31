// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMObject.h"
#include "KMTimerManager.generated.h"

/**
 *
 */
typedef TFunction<void()> TimerCallBackFunc;
typedef TFunction<void(int32 TimerHandleID)> TimerNotifyFunc;

class UAutoStopTimer;


UCLASS()
class ENGINEEXT_API UKMTimerUnit : public UObject
{
    GENERATED_BODY()

public:
    void OnTimerEndCallBack()
    {
        if (nullptr != NotifyManagerFunc)
        {
            NotifyManagerFunc(TimerHandleID);
        }
    }

public:
    int32 TimerHandleID;
    TimerCallBackFunc CallBackFunc;
    TimerNotifyFunc NotifyManagerFunc;
};

UCLASS()
class ENGINEEXT_API UKMTimerManager : public UKMObject
{
    GENERATED_UCLASS_BODY()

private:
    struct Impl;
    TSharedPtr<Impl> impl;

public:
    void ClearTimer(FTimerHandle& TimerHandle);
    void SetTimer(const FTimerHandle& TimerHandle, TimerCallBackFunc CallBack, float InRate);

    /**
    * Set a timer to execute delegate. Setting an existing timer will not reset that timer with updated parameters, execute delegate will be only once.
    * @param Event			Event. Can be a K2 function or a Custom Event.
    * @param Time			How long to wait before executing the delegate, in seconds. Setting a timer to <= 0 seconds will do nothing.
    * @return				The timer handle to pass to other timer functions to manipulate this timer.
    */
    UFUNCTION(BlueprintCallable, meta = (DisplayName = "Set Once Timer by Event"), Category = "KMTimerManager")
    FTimerHandle SetOnceTimerDelegate(UPARAM(DisplayName = "Event") FTimerDynamicDelegate Delegate, float Time);

    UFUNCTION(BlueprintCallable, Category = "KMTimerManager")
    void SetAutoStopTimerDelegate(FTimerDynamicDelegate Delegate, float Interval, float TotalTime);

    UFUNCTION(BlueprintCallable, Category = "KMTimerManager")
    void SetAutoStopTimer(UObject* Object, FString FunctionName, float Interval, float TotalTime);

    template< class UserClass >
    void SetAutoStopTimer(UserClass* InObj, const typename FTimerDelegate::TUObjectMethodDelegate< UserClass >::FMethodPtr &InTimerMethod, float Interval, float TotalTime, const TFunction<void()> &OnComplete)
    {
        SetAutoStopTimer(FTimerDelegate::CreateUObject(InObj, InTimerMethod), Interval, TotalTime, OnComplete);
    }

    void SetAutoStopTimer(FTimerDelegate const &InDelegate, float Interval, float TotalTime, const TFunction<void()> &OnComplete);

	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

private:
    void AddNewActivateTimer(FTimerHandle& InOutHandle, float Duration, TFunction<void()> OnComplete = nullptr);
    void SetAutoStopTimerDelegate_Internal(const FTimerDynamicDelegate &Delegate, float Interval, float TotalTime);
    void SetAutoStopTimer_Internal(UObject* Object, const FString &FunctionName, float Interval, float TotalTime);
};
