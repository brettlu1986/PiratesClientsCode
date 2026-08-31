#include "Loading/KMLevelLoadingVolume.h"
#include "EngineExt.h"

#if !UE_SERVER
#include "OceanSystem.h"
#endif


DEFINE_LOG_CATEGORY_STATIC(LogSubLevelLoading, Log, All);

AKMLevelLoadingVolume::AKMLevelLoadingVolume(const FObjectInitializer& ObjectInitializer)
:Super(ObjectInitializer)
{

}


void AKMLevelLoadingVolume::ActorEnteredVolume1(class AActor* Other)
{
	Super::ActorEnteredVolume(Other);

	IConsoleVariable* FAutoConsoleVariableRef = IConsoleManager::Get().FindConsoleVariable(TEXT("r.PerformanceLevel"));
	int32 PerformanceLevel = FAutoConsoleVariableRef->GetInt();
	if (PerformanceLevel == 0 && IsHighDetail && IsForPort)
	{
		return;
	}

	if (!GetWorld() || !GetWorld()->GetFirstPlayerController())
	{
		return;
	}

	if (bInvolume && isInitaillyLoaded)
	{
		return;
	}

	APlayerController* PC = GetWorld()->GetFirstPlayerController();

	AGameStateBase* GS = GetWorld()->GetGameState();


	APawn* Self = GetWorld()->GetFirstPlayerController()->GetPawn();
	if (Self && Self == Other)
	{
		bInvolume = true;

		FString ActorName = Self->GetName();
		FString VolumeName = this->GetName();

		UE_LOG(LogSubLevelLoading, Log, TEXT("***********************ActorEnteredVolume1:: ActorName: %s VolumeName: %s"), *ActorName, *VolumeName);
		UE_LOG(LogSubLevelLoading, Log, TEXT("***********************ActorEnteredVolume1:: ActorLoc: %s"), *Self->GetActorLocation().ToString());

		//发现已经过了刚进入游戏的状态走正常加载
		//如果处在刚进入游戏的状态暂存bInvolume的状态  ；然后等待外部调用InitialyLoadLevelStreaming进行加载
		//避开刚进入游戏时Loading的高峰期
		if (isInitaillyLoaded)
		{
			FLatentActionInfo ActionInfo;
			ActionInfo.CallbackTarget = this;
			ActionInfo.ExecutionFunction = FName(TEXT("OnLoadCompleted"));

			//if (PerformanceLevelCvar->GetValueOnAnyThread() == 0 && HasLowDetail && !IsForPort)
			//{
			//	UGameplayStatics::LoadStreamLevel(GetWorld(), FName(*LowDetailPath), true, false, ActionInfo);
			//}
			//else
			//{
				UGameplayStatics::LoadStreamLevel(GetWorld(), FName(*LevelStreamingPath), true, false, ActionInfo);
			//}
		}
	}
	//特殊情况添加保护；此情况是gamemode创建character，但并未possess
	else if ((!Self || Self->IsA(ADefaultPawn::StaticClass())) && Other != Self)
	{
		bInvolume = true;

		FString ActorName = Other->GetName();
		FString VolumeName = this->GetName();

		UE_LOG(LogSubLevelLoading, Log, TEXT("***********************ActorEnteredVolume1:: ActorName: %s VolumeName: %s"), *ActorName, *VolumeName);
		UE_LOG(LogSubLevelLoading, Log, TEXT("***********************ActorEnteredVolume1:: ActorLoc: %s"), *Other->GetActorLocation().ToString());

		//发现已经过了刚进入游戏的状态走正常加载
		//如果处在刚进入游戏的状态暂存bInvolume的状态  ；然后等待外部调用InitialyLoadLevelStreaming进行加载
		//避开刚进入游戏时Loading的高峰期
		if (isInitaillyLoaded)
		{
			FLatentActionInfo ActionInfo;
			ActionInfo.CallbackTarget = this;
			ActionInfo.ExecutionFunction = FName(TEXT("OnLoadCompleted"));

			//if (PerformanceLevelCvar->GetValueOnAnyThread() == 0 && HasLowDetail && !IsForPort)
			//{
			//	UGameplayStatics::LoadStreamLevel(GetWorld(), FName(*LowDetailPath), true, false, ActionInfo);
			//}
			//else
			//{
				UGameplayStatics::LoadStreamLevel(GetWorld(), FName(*LevelStreamingPath), true, false, ActionInfo);
			//}
		}
		//记录otheractor的name留到InitialyLoadLevelStreaming判定是否是self
		else
		{
			TempOtherNames.Add(ActorName);
		}
	}
}

void AKMLevelLoadingVolume::ActorLeavingVolume1(class AActor* Other)
{
	Super::ActorLeavingVolume(Other);

	if (!GetWorld() || !GetWorld()->GetFirstPlayerController())
	{
		return;
	}

	//发现已经过了刚进入游戏的状态走正常卸载
	//避开刚进入游戏时Loading的高峰期
	if (!isInitaillyLoaded && !GIsEditor)
	{
		return;
	}


	APawn* Self = GetWorld()->GetFirstPlayerController()->GetPawn();
	if (Self == Other)
	{
		bInvolume = false;
		FLatentActionInfo ActionInfo;
		ActionInfo.UUID = 2;
		ActionInfo.Linkage = 2;
		ActionInfo.CallbackTarget = this;
		ActionInfo.ExecutionFunction = FName(TEXT("OnUnloadCompleted"));

		IConsoleVariable* FAutoConsoleVariableRef = IConsoleManager::Get().FindConsoleVariable(TEXT("r.PerformanceLevel"));
		int32 PerformanceLevel = FAutoConsoleVariableRef->GetInt();

		if (PerformanceLevel == 0 && HasLowDetail && !IsForPort)
		{
			UGameplayStatics::UnloadStreamLevel(GetWorld(), FName(*LowDetailPath), ActionInfo, false);
		}
		else
		{
			UGameplayStatics::UnloadStreamLevel(GetWorld(), FName(*LevelStreamingPath), ActionInfo, false);
		}
		
	}
}

void AKMLevelLoadingVolume::NotifyActorBeginOverlap(AActor* OtherActor)
{
	ActorEnteredVolume1(OtherActor);
}

void AKMLevelLoadingVolume::NotifyActorEndOverlap(AActor* OtherActor)
{
	ActorLeavingVolume1(OtherActor);
}

void AKMLevelLoadingVolume::BeginPlay()
{
	Super::BeginPlay();

	if (!GetWorld() || !GetWorld()->GetFirstPlayerController() || !GetWorld()->GetFirstPlayerController()->GetPawn())
	{
		return;
	}

	APlayerController* PC = GetWorld()->GetFirstPlayerController();

	AGameStateBase* GS = GetWorld()->GetGameState();


	APawn* Self = GetWorld()->GetFirstPlayerController()->GetPawn();

	if (Self->IsA(ADefaultPawn::StaticClass()))
	{
		return;
	}

	FVector PawnLoc;
	FVector PawnExtend;
	Self->GetActorBounds(true, PawnLoc, PawnExtend);

	FBox PawnBounds = FBox(PawnLoc - PawnExtend, PawnLoc + PawnExtend);

	FVector VolumeLoc;
	FVector VolumeExtend;

	GetActorBounds(true, VolumeLoc, VolumeExtend);

	FBox VolumeBounds = FBox(VolumeLoc - VolumeExtend, VolumeLoc + VolumeExtend);

	//处理PIE特殊情况
	if (VolumeBounds.Intersect(PawnBounds))
	{

		FString ActorName = Self->GetName();
		FString VolumeName = this->GetName();

		UE_LOG(LogSubLevelLoading, Log, TEXT("***********************ActorEnteredVolume1:: ActorName: %s VolumeName: %s"), *ActorName, *VolumeName);
		UE_LOG(LogSubLevelLoading, Log, TEXT("***********************ActorEnteredVolume1:: ActorLoc: %s"), *Self->GetActorLocation().ToString());

		bInvolume = true;
		FLatentActionInfo ActionInfo;
		ActionInfo.UUID = 1;
		ActionInfo.Linkage = 1;
		ActionInfo.CallbackTarget = this;
		ActionInfo.ExecutionFunction = FName(TEXT("OnLoadCompleted"));

		IConsoleVariable* FAutoConsoleVariableRef = IConsoleManager::Get().FindConsoleVariable(TEXT("r.PerformanceLevel"));
		int32 PerformanceLevel = FAutoConsoleVariableRef->GetInt();

		if (PerformanceLevel == 0 && HasLowDetail && !IsForPort)
		{
			UGameplayStatics::LoadStreamLevel(GetWorld(), FName(*LowDetailPath), true, false, ActionInfo);
		}
		else
		{
			UGameplayStatics::LoadStreamLevel(GetWorld(), FName(*LevelStreamingPath), true, false, ActionInfo);
		}
	}
}
// for setting static mesh lod model
void AKMLevelLoadingVolume::OnLoadCompleted()
{
	IConsoleVariable* FAutoConsoleVariableRef = IConsoleManager::Get().FindConsoleVariable(TEXT("r.PerformanceLevel"));
	int32 PerformanceLevel = FAutoConsoleVariableRef->GetInt();

	FString* TargetLevelPath = nullptr;
	if (PerformanceLevel == 0 && HasLowDetail && !IsForPort)
	{
		TargetLevelPath = &LowDetailPath;
	}
	else
	{
		TargetLevelPath = &LevelStreamingPath;
	}
	SetStaticMeshLODModel.ExecuteIfBound(*TargetLevelPath);
	UE_LOG(LogSubLevelLoading, Log, TEXT("AKMLevelLoadingVolume::OnLoadCompleted %s"), *(*TargetLevelPath));

#if !UE_SERVER
	//notify to ocean manager
	//yjz add
	UE_LOG(LogSubLevelLoading, Log, TEXT("AKMLevelLoadingVolume::OnLoadCompleted Notify to OceanSystem"));
	UWorld* World = GetWorld();
	TArray<AActor*> Oceans;
	UGameplayStatics::GetAllActorsOfClass(World, AOceanSystem::StaticClass(), Oceans);
	for (int32 OceanIndex = 0; OceanIndex < Oceans.Num(); ++OceanIndex)
	{
		Cast<AOceanSystem>(Oceans[OceanIndex])->NotifyAfterSubLevelLoading();
	}
#endif

#if 1
	GEngine->Exec(NULL, TEXT(/*"SHOWMEMSTATS"*/"NO"));
#endif
}
//~end

void AKMLevelLoadingVolume::OnUnloadCompleted()
{
	//notify to ocean manager
	//yjz add

	UE_LOG(LogSubLevelLoading, Log, TEXT("AKMLevelLoadingVolume::OnUnloadCompleted Notify To Ocean"));

#if !UE_SERVER
	UWorld* World = GetWorld();

	TArray<AActor*> Oceans;

	UGameplayStatics::GetAllActorsOfClass(World, AOceanSystem::StaticClass(), Oceans);

	for (int32 OceanIndex = 0; OceanIndex < Oceans.Num(); ++OceanIndex)
	{
		Cast<AOceanSystem>(Oceans[OceanIndex])->NotifyAfterSubLevelUnloading();
	}
#endif

}

void AKMLevelLoadingVolume::InitialyLoadLevelStreaming()
{
	//if (LevelStreamingPath.Contains(FString(TEXT("08_A_Sub_02")))
	//|| LevelStreamingPath.Contains(FString(TEXT("08_A_Sub_06")))
	//	|| LevelStreamingPath.Contains(FString(TEXT("09_A"))))
	//{
	//	return;
	//}

	IConsoleVariable* FAutoConsoleVariableRef = IConsoleManager::Get().FindConsoleVariable(TEXT("r.PerformanceLevel"));
	int32 PerformanceLevel = FAutoConsoleVariableRef->GetInt();
	if (PerformanceLevel == 0 && IsHighDetail && IsForPort)
	{
		isInitaillyLoaded = true;
		return;
	}

	APawn* Self = GetWorld()->GetFirstPlayerController()->GetPawn();

	if (Self->IsA(ADefaultPawn::StaticClass()))
	{
		isInitaillyLoaded = true;
		return;
	}

	FString ActorName = Self->GetName();
	if (!TempOtherNames.Contains(ActorName))
	{
		isInitaillyLoaded = true;
		return;
	}
	TempOtherNames.Empty();

	if (bInvolume && !isInitaillyLoaded)
	{
		FLatentActionInfo ActionInfo;
        ActionInfo.UUID = 1;
        ActionInfo.Linkage = 1;
		ActionInfo.CallbackTarget = this;
		ActionInfo.ExecutionFunction = FName(TEXT("OnLoadCompleted"));

		if (PerformanceLevel == 0 && HasLowDetail && !IsForPort)
		{
			//LoadPackage(nullptr, *LowDetailPath, LOAD_None);

			UGameplayStatics::LoadStreamLevel(GetWorld(), FName(*LowDetailPath), true, false, ActionInfo);
		}
		else
		{
			//LoadPackage(nullptr, *LevelStreamingPath, LOAD_None);
			UGameplayStatics::LoadStreamLevel(GetWorld(), FName(*LevelStreamingPath), true, false, ActionInfo);
		}
		
	}

	isInitaillyLoaded = true;
}