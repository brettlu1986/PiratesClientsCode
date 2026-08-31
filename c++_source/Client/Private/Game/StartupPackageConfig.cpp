// Fill out your copyright notice in the Description page of Project Settings.

#include "StartupPackageConfig.h"
#include "Client.h"
#include "HAL/Runnable.h"
#include "HAL/RunnableThread.h"
#include "GameClient.h"

#ifndef PIR_STARTUPPACKAGES_USETHREAD
#define PIR_STARTUPPACKAGES_USETHREAD 0
#endif

DEFINE_LOG_CATEGORY_STATIC(LogStartupPackage, Log, All)

#if PIR_STARTUPPACKAGES_USETHREAD
class FPackageLoadingTask
{
public:
	FPackageLoadingTask(FString InPackageName)
		: PackageName(InPackageName)
	{

	}
	static const TCHAR* GetTaskName()
	{
		return TEXT("PackageLoadingTask");
	}
	static TStatId GetStatId()
	{
		RETURN_QUICK_DECLARE_CYCLE_STAT(FPackageLoadingTask, STATGROUP_TaskGraphTasks);
	}
	static ENamedThreads::Type GetDesiredThread()
	{
		return ENamedThreads::GameThread;
	}
	static ESubsequentsMode::Type GetSubsequentsMode() { return ESubsequentsMode::TrackSubsequents; }

	void DoTask(ENamedThreads::Type CurrentThread, const FGraphEventRef& MyCompletionGraphEvent)
	{
		UGameAssetCache* AssetCache = ((UStartupPackageConfig*)GetDefault<UStartupPackageConfig>())->GetGameClient()->GetAssetCache();
		UObject* ObjectPtr = ::StaticFindObject(UObject::StaticClass(), nullptr, *PackageName);
		if (ObjectPtr)
		{
			if (!AssetCache->FindAssetCache(ObjectPtr))
			{
				UE_LOG(LogStartupPackage, Log, TEXT("[PIR] Frame : %u, Found Object : %s"), GFrameCounter, *PackageName);
				AssetCache->AddCachedAsset(ObjectPtr);
			}
		}
		else
		{
			QUICK_SCOPE_CYCLE_COUNTER(STAT_FPackageLoadingTask_StaticLoadObject);
			ObjectPtr = ::StaticLoadObject(UObject::StaticClass(), nullptr, *PackageName);
			if (ObjectPtr && !AssetCache->FindAssetCache(ObjectPtr))
			{
				UE_LOG(LogStartupPackage, Display, TEXT("[PIR] Frame : %u, Load Object : %s"), GFrameCounter, *PackageName);
				AssetCache->AddCachedAsset(ObjectPtr);
			}
		}
	}
private:
	FString PackageName;
};

class FStartupPackageLoadingRunnable : public FRunnable
{
public:
	FStartupPackageLoadingRunnable(TArray<FString>& InPackageList, int32 StartIdx)
		: LastPackageIdx(StartIdx)
		, StopRequestCounter(0)
	{
		PackageListPtr = &InPackageList;
		Thread = MakeShareable(FRunnableThread::Create(this, TEXT("StartupPackageLoadingRunnable")));
	}
	~FStartupPackageLoadingRunnable()
	{
		if (Thread.IsValid())
		{
			Thread->Kill();
		}
	}
	virtual uint32 Run() override
	{
		while (!IsFinished() && !IsCanceled())
		{
			UE_LOG(LogStartupPackage, Log, TEXT("[PIR] Create Loading Task For Startup Package : %d"), LastPackageIdx);
			LoadingTaskCompletionEvents.Add(
				TGraphTask<FPackageLoadingTask>::CreateTask(nullptr, ENamedThreads::AnyThread).ConstructAndDispatchWhenReady((*PackageListPtr)[LastPackageIdx])
			);
			
			while (!LoadingTaskCompletionEvents.Last()->IsComplete())
			{
				FPlatformProcess::Sleep(0.033f);
			}

			++LastPackageIdx;
		}
		return 0;
	}
	virtual void Stop() override
	{
		StopRequestCounter.Increment();
	}
	virtual bool Init() override
	{
		return true;
	}
	virtual void Exit() override
	{
		UE_LOG(LogStartupPackage, Log, TEXT("FStartupPackageLoadingRunnable Exit."));
	}
private:
	int32 LastPackageIdx;
	FThreadSafeCounter StopRequestCounter;
	TArray<FString>* PackageListPtr;
	TSharedPtr<FRunnableThread> Thread;
	FGraphEventArray LoadingTaskCompletionEvents;

	bool IsFinished()
	{
		return LastPackageIdx >= PackageListPtr->Num();
	}

	bool IsCanceled()
	{
		return StopRequestCounter.GetValue() > 0;
	}
};
#endif //~ PIR_STARTUPPACKAGES_USETHREAD

void UStartupPackageConfig::LoadStartupPackage(UGameClient* InGameClient)
{
	UStartupPackageConfig* StartupPackageConfig = (UStartupPackageConfig*)GetDefault<UStartupPackageConfig>();
	StartupPackageConfig->SetGameClient(InGameClient);
	StartupPackageConfig->Start();
}

void UStartupPackageConfig::Shutdown()
{
	UStartupPackageConfig* StartupPackageConfig = (UStartupPackageConfig*)GetDefault<UStartupPackageConfig>();
	if (StartupPackageConfig->TickHandle.IsValid())
	{
		FTicker::GetCoreTicker().RemoveTicker(StartupPackageConfig->TickHandle);
		StartupPackageConfig->TickHandle.Reset();
	}
}

void UStartupPackageConfig::Start()
{
#if !UE_SERVER && 0
	if (!IsRunningDedicatedServer())
	{
		float Timelimite = 3.f;
		float StartTime = FPlatformTime::Seconds();
		float UsedTime = 0.f;
		LastPackageIdx = 0;

		GUObjectArray.OpenDisregardForGC();
		while(LastPackageIdx < DisregardForGC.Num() && UsedTime < 3.f)
		{
			if (LoadPackage(nullptr, *DisregardForGC[LastPackageIdx], LOAD_None))
			{
				UE_LOG(LogStartupPackage, Display, TEXT("[PIR] %d:%s disregard for gc."), LastPackageIdx, *DisregardForGC[LastPackageIdx]);
			}
			++LastPackageIdx;
			UsedTime = FPlatformTime::Seconds() - StartTime;
		}
		GUObjectArray.CloseDisregardForGC();

		if (LastPackageIdx < DisregardForGC.Num())
		{
			UE_LOG(LogStartupPackage, Display, TEXT("[PIR] Append packages left in DisregardForGC to CachedPackages."));
			CachedPackages.Append(DisregardForGC.GetData() + LastPackageIdx, DisregardForGC.Num() - LastPackageIdx);
		}
#if PIR_STARTUPPACKAGES_USETHREAD
		LoadingRunnable = MakeShareable(new FStartupPackageLoadingRunnable(CachedPackages, 0));
#else
		LastPackageIdx = 0;
		if (TickHandle.IsValid())
		{
			FTicker::GetCoreTicker().RemoveTicker(TickHandle);
			TickHandle.Reset();
		}
		TickHandle = FTicker::GetCoreTicker().AddTicker(FTickerDelegate::CreateLambda([this](float DeltaTime)->bool
		{
			if (LastPackageIdx < CachedPackages.Num())
			{
				FString& PackageName = CachedPackages[LastPackageIdx++];
				UGameAssetCache* AssetCache = GameClient->GetAssetCache();
				check(AssetCache);
				UObject* ObjectPtr = ::StaticFindObject(UObject::StaticClass(), nullptr, *PackageName);
				if (ObjectPtr)
				{
					if (!AssetCache->FindAssetCache(ObjectPtr))
					{
						UE_LOG(LogStartupPackage, Log, TEXT("[PIR] Frame : %u, Found Object %d : %s"), GFrameCounter, LastPackageIdx - 1, *PackageName);
						AssetCache->AddCachedAsset(ObjectPtr);
					}
				}
				else
				{
					QUICK_SCOPE_CYCLE_COUNTER(STAT_FPackageLoadingTask_StaticLoadObject);
					ObjectPtr = ::StaticLoadObject(UObject::StaticClass(), nullptr, *PackageName);
					if (ObjectPtr && !AssetCache->FindAssetCache(ObjectPtr))
					{
						UE_LOG(LogStartupPackage, Log, TEXT("[PIR] Frame : %u, Load Object %d : %s"), GFrameCounter, LastPackageIdx - 1, *PackageName);
						AssetCache->AddCachedAsset(ObjectPtr);
					}
				}
				return true;
			}
			UE_LOG(LogStartupPackage, Log, TEXT("[PIR] Ticker Out."));
			return false;
		}));
#endif //~ PIR_STARTUPPACKAGES_USETHREAD
	}
#endif
}
