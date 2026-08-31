 //Fill out your copyright notice in the Description page of Project Settings.

#include "KMSignificanceManager.h"
#include "EngineExt.h"
#include "Kismet/GameplayStatics.h"

/** ticking rate */
static TAutoConsoleVariable<float> CVarPirSignificanceTickInterval(
	TEXT("pir.SignificanceTickInterval"),
	0.5f,
	TEXT("Pirates significance manager ticking interval (in seconds). Default 0.5")
);

UKMSignificanceManager::UKMSignificanceManager()
{
}

bool UKMSignificanceManager::Tick(float InDeltaTime)
{
	QUICK_SCOPE_CYCLE_COUNTER(STAT_UKMSignificanceManager_Tick);
	APlayerCameraManager* PlayerCameraManagerPtr = UGameplayStatics::GetPlayerCameraManager(this, 0);
	if (PlayerCameraManagerPtr)
	{
		AActor* ActorTarget = PlayerCameraManagerPtr->GetViewTarget();
		if (ActorTarget)
		{
			Update({ ActorTarget->GetTransform() });
		}
	}
	return true;
}

void UKMSignificanceManager::RegisterObject(UObject* Object, FName Tag, FManagedObjectSignificanceFunction SignificanceFunction,
	EPostSignificanceType InPostSignificanceType, FManagedObjectPostSignificanceFunction InPostSignificanceFunction)
{
	Super::RegisterObject(Object, Tag, SignificanceFunction, InPostSignificanceType, InPostSignificanceFunction);
	// start to tick if not
	if (!TickHandle.IsValid())
	{
		TickHandle = FTicker::GetCoreTicker().AddTicker(
			FTickerDelegate::CreateUObject(this, &UKMSignificanceManager::Tick),
			CVarPirSignificanceTickInterval.GetValueOnGameThread());
	}
}

void UKMSignificanceManager::UnregisterObject(UObject* Object)
{
	check(Object);
	Super::UnregisterObject(Object);

	TArray<USignificanceManager::FManagedObjectInfo*> OutManagedObjects;
	GetManagedObjects(OutManagedObjects);
	
	// stop tick if no object to be handled
	if (OutManagedObjects.Num() == 0)
	{
		FTicker::GetCoreTicker().RemoveTicker(TickHandle);
		TickHandle.Reset();
	}
}

void UKMSignificanceManager::Update(TArrayView<const FTransform> InViewpoints)
{
	Super::Update(InViewpoints);
}