// Fill out your copyright notice in the Description page of Project Settings.

#include "KMTimerManager.h"
#include "EngineExt.h"
#include "AutoStopTimer.h"

struct UKMTimerManager::Impl
{
	TMap<int32, UKMTimerUnit *>		TimerUnits;
	TArray<UAutoStopTimer *>		AutoStopTimerList;
	UKMTimerManager					*Owner;
	Impl(UKMTimerManager *P) : Owner(P)
	{

	}

	void AddReferencedObjects(FReferenceCollector& Collector)
	{
		for (auto Pair = TimerUnits.CreateIterator(); Pair; ++Pair)
		{
			Collector.AddReferencedObject(Pair->Value, Owner);
		}
        
        for (int Index = AutoStopTimerList.Num() - 1; Index >= 0; --Index)
        {
            auto Timer = AutoStopTimerList[Index];
            if (IsValid(Timer) && Timer->IsValidLowLevel())
            {
                if (Timer->IsTimeOut())
                {
                    AutoStopTimerList.RemoveAt(Index);
                }
                else
                {
                    Collector.AddReferencedObject(Timer, Owner);
                }
            }
        }
	}

	int32 GetTimerHandleID(const FTimerHandle& TimerHandle)
	{

		return FCString::Atoi(*TimerHandle.ToString());
	}

	void NotifyCallBack(int32 TimerHandleID)
	{
		UKMTimerUnit** ItrTimerUnit = TimerUnits.Find(TimerHandleID);
		if (nullptr != ItrTimerUnit)
		{
			UKMTimerUnit* TimerUnit = *ItrTimerUnit;
			if (TimerUnit->CallBackFunc != nullptr)
			{
				TimerUnit->CallBackFunc();
			}
			TimerUnits.Remove(TimerHandleID);
		}
	}

	void SetTimer(FTimerHandle TimerHandle, TimerCallBackFunc CallBack, float InRate)
	{
		UKMTimerUnit *TimerUnit = NewObject<UKMTimerUnit>(Owner);
		TimerUnit->CallBackFunc = CallBack;
		TimerUnit->NotifyManagerFunc = [this](int32 TimerHandleID) {
			this->NotifyCallBack(TimerHandleID);
		};
		Owner->GetWorld()->GetTimerManager().SetTimer(TimerHandle, TimerUnit, &UKMTimerUnit::OnTimerEndCallBack, InRate, false);
		// 必须先SetTimer，才能得到新的HandleID
		TimerUnit->TimerHandleID = GetTimerHandleID(TimerHandle);
		TimerUnits.Add(TimerUnit->TimerHandleID, TimerUnit);
	}

	void ClearTimer(FTimerHandle& TimerHandle)
	{
		auto HandleId = GetTimerHandleID(TimerHandle);
		auto TimerUnitItr = TimerUnits.Find(HandleId);
		if (TimerUnitItr != nullptr)
		{
			TimerUnits.Remove(HandleId);
		}
        Owner->GetWorld()->GetTimerManager().ClearTimer(TimerHandle);
	}
};


UKMTimerManager::UKMTimerManager(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
, impl(MakeShareable(new Impl(this)))
{

}

void UKMTimerManager::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	UKMTimerManager* This = CastChecked<UKMTimerManager>(InThis);
	This->impl->AddReferencedObjects(Collector);
	Super::AddReferencedObjects(This, Collector);
}

void UKMTimerManager::SetTimer(const FTimerHandle& TimerHandle, TimerCallBackFunc CallBack, float InRate)
{
	impl->SetTimer(TimerHandle, CallBack, InRate);
}

void UKMTimerManager::ClearTimer(FTimerHandle& TimerHandle)
{
	impl->ClearTimer(TimerHandle);
}

void UKMTimerManager::SetAutoStopTimer(FTimerDelegate const &InDelegate, float Interval, float TotalTime, const TFunction<void()> &OnComplete)
{
	if (InDelegate.IsBound())
	{
		UWorld *World = GEngine->GetWorldFromContextObject(InDelegate.GetUObject(), EGetWorldErrorMode::ReturnNull);
		if (IsValid(World))
		{
			FTimerHandle InOutHandle;
			World->GetTimerManager().SetTimer(InOutHandle, InDelegate, Interval, true);

			AddNewActivateTimer(InOutHandle, TotalTime, OnComplete);
		}
	}
}

void UKMTimerManager::SetAutoStopTimer(UObject* Object, FString FunctionName, float Interval, float TotalTime)
{
    SetAutoStopTimer_Internal(Object, FunctionName, Interval, TotalTime);
}

void UKMTimerManager::SetAutoStopTimerDelegate(FTimerDynamicDelegate Delegate, float Interval, float TotalTime)
{
	if (Delegate.IsBound())
	{
		SetAutoStopTimerDelegate_Internal(Delegate, Interval, TotalTime);
	}
}

void UKMTimerManager::SetAutoStopTimer_Internal(UObject* Object, const FString &FunctionName, float Interval, float TotalTime)
{
	FName const FunctionFName(*FunctionName);

	if (Object)
	{
		UFunction* const Func = Object->FindFunction(FunctionFName);
		if (Func && (Func->ParmsSize > 0))
		{
			// User passed in a valid function, but one that takes parameters
			// FTimerDynamicDelegate expects zero parameters and will choke on execution if it tries
			// to execute a mismatched function
			UE_LOG(LogBlueprintUserMessages, Warning, TEXT("SetTimer passed a function (%s) that expects parameters."), *FunctionName);
			return;
		}
	}

	FTimerDynamicDelegate Delegate;
	Delegate.BindUFunction(Object, FunctionFName);
	SetAutoStopTimerDelegate(Delegate, Interval, TotalTime);
}

void UKMTimerManager::SetAutoStopTimerDelegate_Internal(const FTimerDynamicDelegate &Delegate, float Interval, float TotalTime)
{
	if (Delegate.IsBound())
	{
		const UWorld* const World = GEngine->GetWorldFromContextObject(Delegate.GetUObject(), EGetWorldErrorMode::ReturnNull);
		if (nullptr != World)
		{
			auto& TimerManager = World->GetTimerManager();
			auto InOutHandle = TimerManager.K2_FindDynamicTimerHandle(Delegate);
			TimerManager.SetTimer(InOutHandle, Delegate, Interval, true);

			AddNewActivateTimer(InOutHandle, TotalTime);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning, TEXT("SetTimer passed a bad function (%s) or object (%s)"), *Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}
}

void UKMTimerManager::AddNewActivateTimer(FTimerHandle& InOutHandle, float Duration, TFunction<void()> OnComplete/* = nullptr*/)
{
	UAutoStopTimer *timer = NewObject<UAutoStopTimer>(this);
	timer->InitParams(InOutHandle, Duration, OnComplete);
	impl->AutoStopTimerList.Add(timer);

	timer->Activate();
}

FTimerHandle UKMTimerManager::SetOnceTimerDelegate(FTimerDynamicDelegate Delegate, float Time)
{
	FTimerHandle Handle;
	if (Delegate.IsBound())
	{
		const UWorld* const World = GEngine->GetWorldFromContextObject(Delegate.GetUObject(), EGetWorldErrorMode::ReturnNull);
		if (World && Time > 0)
		{
			FTimerManager& TimerManager = World->GetTimerManager();
			TimerManager.SetTimer(Handle, Delegate, Time, false);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("SetTimer passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}

	return Handle;
}
