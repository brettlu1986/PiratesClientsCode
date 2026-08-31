// Fill out your copyright notice in the Description page of Project Settings.

#include "EnvironmentController.h"
#include "Common.h"
#include "Shell/EngineExtShell.h"
#include "Components/KMCapsuleComponent.h"
#include "Camera/KMGameCameraManager.h"
#include "ExtendBlueprintFunctions.h"
#if WITH_EDITOR
#include "Editor.h"
#endif

DEFINE_LOG_CATEGORY_STATIC(LogKMEnvironmentController, Log, All);

static int32 GXSJMEEnableEnvironmentController = 1;
static FAutoConsoleVariableRef CVarXSJMEEnableEnvironmentController(
	TEXT("xsjme.EnableEnvironmentController"),
	GXSJMEEnableEnvironmentController,
	TEXT("Enable Environment Controller.")
);

const TCHAR EnvironmentControlAttribute[] = TEXT("/Script/Common.EnvironmentControl");

inline
bool CompareEnvironmentParams(UEnvironmentParams& A, UEnvironmentParams& B)
{
	return A.ImportanceLevel > B.ImportanceLevel;
}

static void EnvCtlCVarSinkFunction()
{
	if (!GWorld) return;
	static int32 CachedUseTonemapperFilm = -1;
	int32 bUseTonemapperFilm = -1;
	static const auto VarTonemapperFilm = IConsoleManager::Get().FindTConsoleVariableDataInt(TEXT("r.Mobile.TonemapperFilm"));
	if (VarTonemapperFilm)
	{
		bUseTonemapperFilm = !!VarTonemapperFilm->GetValueOnGameThread();
	}
	if (bUseTonemapperFilm != CachedUseTonemapperFilm)
	{
		for (AActor* Actor : TActorRange<AActor>(GWorld, AEnvironmentController::StaticClass()))
		{
			if (Actor && !Actor->IsPendingKill())
			{
				auto EnvCtl = Cast<AEnvironmentController>(Actor);
				EnvCtl->FogDensityRenderQuality = bUseTonemapperFilm ? 1.0f : EnvCtl->FogDensityQualityScale;
				EnvCtl->RefreshEnvironmentParams();
			}
		}
		CachedUseTonemapperFilm = bUseTonemapperFilm;
	}
}

static FAutoConsoleVariableSink CVarEnvCtlSink(FConsoleCommandDelegate::CreateStatic(&EnvCtlCVarSinkFunction));

// Sets default values
AEnvironmentController::AEnvironmentController(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	FogDensityQualityScale = 1.0f;
	FogDensityRenderQuality = 1.0f;
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	if (HasAnyFlags(RF_ClassDefaultObject))
	{
		return;
	}
#if WITH_EDITOR
	TransitCurrentParams = ConstructBPEnvironmentParams(this, TEXT("CurrentParams"));
	TransitBaseParams = ConstructBPEnvironmentParams(this, TEXT("BaseParams"));
	TransitBaseParams->ImportanceLevel = -1;
#endif
}

void AEnvironmentController::SetEnvironmentParams(UEnvironmentParams* EnvParams, bool Immediately)
{
	if (GXSJMEEnableEnvironmentController == 0) return;
	//ReceiveEnvironmentParams(EnvParams, Immediately);
	UEnvironmentParams* Param = TryGetTopParams();
	if (!Param)
	{
		TakeEnvironmentParams(TransitBaseParams);
		ParamsQueue.Add(TransitBaseParams);
		Param = TransitBaseParams;
	}
	if (IsValid(Param) && IsValid(EnvParams))
	{
		if (Immediately)
		{
			ParamsQueue.Empty();
			if (!bPreviewEnvironment)
			{
				TakeEnvironmentParams(TransitBaseParams);
			}
			ParamsQueue.Add(TransitBaseParams);
			ApplyEnvironmentParams(EnvParams);
		}
		else
		{
			if (EnvParams->ImportanceLevel >= Param->ImportanceLevel)
			{
				TransitTargetParams = EnvParams;
				TransitCurrentParams->ImportanceLevel = TransitTargetParams->ImportanceLevel;
				TakeEnvironmentParams(TransitCurrentParams);
				if (TransitTimeline)
				{
					TransitTimeline->SetPlayRate(1.0f / EnvParams->TransitTime);
					TransitTimeline->PlayFromStart();
				}
				if (FogStartDistanceTimeline && EnvParams->IsUseStartDistanceTransitTime())
				{
					FogStartDistanceTimeline->SetPlayRate(1.0f / EnvParams->StartDistanceTransitTime);
					FogStartDistanceTimeline->PlayFromStart();
				}
			}
		}
		if (!ParamsQueue.Contains(EnvParams))
		{
			ParamsQueue.HeapPush(EnvParams, CompareEnvironmentParams);
		}
	}
}

void AEnvironmentController::RevertEnvironmentParams(UEnvironmentParams* EnvParams, bool Immediately)
{
	if (GXSJMEEnableEnvironmentController == 0) return;
	//ReceiveRevertEnvironmentParams(EnvParams, Immediately);
	bool Exist = TryPopParams(EnvParams);
	UEnvironmentParams* PrevParam = TryGetTopParams();
	if (Exist && PrevParam)
	{
		if (Immediately)
		{
			ApplyEnvironmentParams(PrevParam);
		}
		else
		{
			if (EnvParams->ImportanceLevel >= TransitCurrentParams->ImportanceLevel)
			{
				TransitTargetParams = PrevParam;
				TransitCurrentParams->ImportanceLevel = TransitTargetParams->ImportanceLevel;
				TakeEnvironmentParams(TransitCurrentParams);
				if (TransitTimeline)
				{
					TransitTimeline->SetPlayRate(1.0f / EnvParams->TransitTime);
					TransitTimeline->PlayFromStart();
				}
				if (FogStartDistanceTimeline && EnvParams->IsUseStartDistanceTransitTime())
				{
					FogStartDistanceTimeline->SetPlayRate(1.0f / EnvParams->StartDistanceTransitTime);
					FogStartDistanceTimeline->PlayFromStart();
				}
			}
		}
	}
}

void AEnvironmentController::SnapEnvironmentParams()
{
	if (GXSJMEEnableEnvironmentController == 0) return;
	//ReceiveSnapEnvironmentParams();
	TakeEnvironmentParams(TransitBaseParams);
}

void AEnvironmentController::RefreshEnvironmentParams()
{
	UEnvironmentParams* TopParams = TryGetTopParams();
	if (TopParams && !IsBaseParams(TopParams))
	{
		ApplyEnvironmentParams(TopParams);
	}
}

bool AEnvironmentController::IsUsingBaseParams() const
{
	return ParamsQueue.Num() <= 1;
}

bool AEnvironmentController::IsBaseParams(UEnvironmentParams* InParams) const
{
	return TransitBaseParams == InParams;
}

void AEnvironmentController::TransitEnvironmentParams(float Factor)
{
	//UE_LOG(LogKMEnvironmentController, Display, TEXT("Current Factor = %f"), Factor);
	if (IsValid(TransitCurrentParams) && IsValid(TransitTargetParams))
	{
		ApplyEnvironmentParams(TransitCurrentParams, TransitTargetParams, Factor);
	}
}

void AEnvironmentController::TransitEnvironmentParamsDone(float Factor)
{
}

void AEnvironmentController::TransitFogStartDistance(float Factor)
{
	if (IsValid(TransitCurrentParams) && IsValid(TransitTargetParams))
	{
		ApplyFogStartDistance(TransitCurrentParams, TransitTargetParams, Factor);
	}
}

void AEnvironmentController::TransitFogStartDistanceDone(float Factor)
{
}

void AEnvironmentController::NotifyEnvForChangingCharacter(const UObject* WorldContextObject, bool bIsChangingToShip)
{
	AEnvironmentController* EnvCtl = nullptr;
	for (TActorIterator<AActor> It(WorldContextObject->GetWorld(), AEnvironmentController::StaticClass()); It; ++It)
	{
		AActor* Actor = *It;
		if (Actor && !Actor->IsPendingKill())
		{
			EnvCtl = Cast<AEnvironmentController>(Actor);
			break;
		}
	}
	if (EnvCtl)
	{
		if (bIsChangingToShip)
		{
			EnvCtl->RevertAllVolumeParams();
		}
		else
		{
			if (AActor* WatchingPlayer = AKMEnvironmentControlVolume::GetWatchingPlayer(WorldContextObject))
			{
				if (WatchingPlayer != AKMEnvironmentControlVolume::GetCurrentPlayer(WorldContextObject))
				{
					TArray<AActor*> Actors;
					WatchingPlayer->GetOverlappingActors(Actors);
					bool bIsInVolume = false;
					for (auto Actor : Actors)
					{
						if (auto Volume = Cast<AKMEnvironmentControlVolume>(Actor))
						{
							bIsInVolume = true;
							Volume->NotifyActorBeginOverlap(WatchingPlayer);
						}
					}
					if (!bIsInVolume)
					{
						EnvCtl->RevertAllVolumeParams();
					}
				}
			}
		}
	}
}

bool AEnvironmentController::IsCharacterInVolume(const AActor* Character, const UShapeComponent* Shape)
{
	if (Character->IsHidden())
	{
		return false;
	}
	FVector Origin, Extent;
	Character->GetActorBounds(true, Origin, Extent);
	return ShapeEncompassesPoint(Shape, Origin);
}

UEnvironmentParams* AEnvironmentController::ConstructBPEnvironmentParams(UObject* Object, const FName& Name)
{
	UEnvironmentParams* EnvironmentParams = nullptr;
	FString ClassName;
	if (GConfig->GetString(EnvironmentControlAttribute, TEXT("EnvironmentControlParamClassName"), ClassName, GEngineIni))
	{
		//static ConstructorHelpers::FClassFinder<UEnvironmentParams> ClassFinder(*ClassName);
		UClass* EnvClass = LoadClass<UEnvironmentParams>(nullptr, *ClassName);
		if (EnvClass)
		{
			EnvironmentParams = Cast<UEnvironmentParams>(Object->CreateDefaultSubobject(Name, EnvClass, EnvClass, true, false));
		}
	}
	if (!EnvironmentParams)
	{
		UE_LOG(LogKMEnvironmentController, Error, TEXT("KMEnvironmentControlVolume: BP_EnvCtlParams is missing!"));
		EnvironmentParams = Object->CreateDefaultSubobject<UEnvironmentParams>(Name);
	}
	return EnvironmentParams;
}

UEnvironmentParams* AEnvironmentController::NewBPEnvironmentParams(UObject* Object)
{
	UEnvironmentParams* EnvironmentParams = nullptr;
	FString ClassName;
	if (GConfig->GetString(EnvironmentControlAttribute, TEXT("EnvironmentControlParamClassName"), ClassName, GEngineIni))
	{
		//static ConstructorHelpers::FClassFinder<UEnvironmentParams> ClassFinder(*ClassName);
		UClass* EnvClass = LoadClass<UEnvironmentParams>(nullptr, *ClassName);
		if (EnvClass)
		{
			EnvironmentParams = NewObject<UEnvironmentParams>(Object, EnvClass);
		}
	}
	if (!EnvironmentParams)
	{
		UE_LOG(LogKMEnvironmentController, Error, TEXT("KMEnvironmentControlVolume: BP_EnvCtlParams is missing!"));
		EnvironmentParams = NewObject<UEnvironmentParams>(Object);
	}
	return EnvironmentParams;
}

// Called when the game starts or when spawned
void AEnvironmentController::BeginPlay()
{
	Super::BeginPlay();
	bPreviewEnvironment = false;
	TransitCurrentParams = NewBPEnvironmentParams(this);
	TransitBaseParams = NewBPEnvironmentParams(this);
	TransitBaseParams->ImportanceLevel = -1;
	MakeDefaultTransitCurve();
	MakeTransitTimeline();
	MakeFogStartDistanceTimeline();
	if (TransitTimeline)
	{
		TransitTimeline->RegisterComponent();
	}
	if (FogStartDistanceTimeline)
	{
		FogStartDistanceTimeline->RegisterComponent();
	}
	TakeEnvironmentParams(TransitBaseParams);
	static const auto VarTonemapperFilm = IConsoleManager::Get().FindTConsoleVariableDataInt(TEXT("r.Mobile.TonemapperFilm"));
	if (VarTonemapperFilm)
	{
		bool bUseTonemapperFilm = !!VarTonemapperFilm->GetValueOnGameThread();
		if (!bUseTonemapperFilm)
		{
			FogDensityRenderQuality = FogDensityQualityScale;
		}
	}
}

// Called every frame
void AEnvironmentController::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	if (TransitTimeline && TransitTimeline->IsRegistered())
	{
		TransitTimeline->TickComponent(DeltaTime, ELevelTick::LEVELTICK_TimeOnly, nullptr);
	}
	if (FogStartDistanceTimeline && FogStartDistanceTimeline->IsRegistered())
	{
		FogStartDistanceTimeline->TickComponent(DeltaTime, ELevelTick::LEVELTICK_TimeOnly, nullptr);
	}
}

void AEnvironmentController::MakeDefaultTransitCurve()
{
	if (IsValid(TransitCurve)) return;
	TransitCurve = NewObject<UCurveFloat>();
	TransitCurve->FloatCurve.AddKey(0.0f, 0.0f);
	TransitCurve->FloatCurve.AddKey(1.0f, 1.0f);
}

void AEnvironmentController::MakeTransitTimeline()
{
	ReturnIfNullptr(TransitCurve);
	if (IsValid(TransitTimeline)) return;
	TransitTimeline = NewObject<UTimelineComponent>(this, TEXT("TransitTimeline"));
	SetupTimeline(TransitTimeline, TEXT("TransitEnvironmentParams"), TEXT("TransitEnvironmentParamsDone"));
}

void AEnvironmentController::MakeFogStartDistanceTimeline()
{
	ReturnIfNullptr(TransitCurve);
	if (IsValid(FogStartDistanceTimeline)) return;
	FogStartDistanceTimeline = NewObject<UTimelineComponent>(this, TEXT("FogStartDistanceTimeline"));
	SetupTimeline(FogStartDistanceTimeline, TEXT("TransitFogStartDistance"), TEXT("TransitFogStartDistanceDone"));
}

void AEnvironmentController::SetupTimeline(UTimelineComponent* Timeline, const FName& UpdateFunction, const FName& FinishedFunction)
{
	Timeline->CreationMethod = EComponentCreationMethod::UserConstructionScript; // Indicate it comes from a blueprint so it gets cleared when we rerun construction scripts
	BlueprintCreatedComponents.Add(Timeline); // Add to array so it gets saved
	Timeline->SetNetAddressable(); // This component has a stable name that can be referenced for replication
	//TransitTimeline->SetPropertySetObject(this); // Set which object the timeline should drive properties on
	//TransitTimeline->SetDirectionPropertyName(TEXT("TimelineDirection"));
	Timeline->SetTimelineLength(1.0f);
	Timeline->SetTimelineLengthMode(TL_LastKeyFrame);
	Timeline->SetPlaybackPosition(0.0f, false);
	//Add the float curve to the timeline and connect it to your timelines's interpolation function
	FOnTimelineFloat TransitDelegate;
	TransitDelegate.BindUFunction(this, UpdateFunction);
	Timeline->AddInterpFloat(TransitCurve, TransitDelegate);
	FOnTimelineEventStatic TransitDoneDelegate;
	TransitDoneDelegate.BindUFunction(this, FinishedFunction);
	Timeline->SetTimelineFinishedFunc(TransitDoneDelegate);
}

UEnvironmentParams* AEnvironmentController::TryGetTopParams()
{
	CleanupParams();
	if (ParamsQueue.Num() > 0)
	{
		return ParamsQueue.HeapTop();
	}
	return nullptr;
}

bool AEnvironmentController::TryPopParams(UEnvironmentParams* Params)
{
	CleanupParams();
	if (ParamsQueue.Num() > 0)
	{
		int32 Index = ParamsQueue.IndexOfByKey(Params);
		if (ParamsQueue.IsValidIndex(Index))
		{
			ParamsQueue.HeapRemoveAt(Index, CompareEnvironmentParams);
			return true;
		}
	}
	return false;
}

void AEnvironmentController::CleanupParams()
{
	auto It = ParamsQueue.CreateIterator();
	It.SetToEnd();
	bool Removed = false;
	for (--It; It;)
	{
		if (!IsValid(*It))
		{
			It.RemoveCurrent();
			Removed = true;
		}
		else
		{
			--It;
		}
	}
	if (Removed)
	{
		ParamsQueue.Heapify(CompareEnvironmentParams);
	}
}

void AEnvironmentController::RevertAllVolumeParams()
{
	CleanupParams();
	TArray<UEnvironmentParams*> VolumeParams;
	for (auto Params : ParamsQueue)
	{
		if (IsValid(Params) && Params->bIsVolumeParam)
		{
			VolumeParams.Add(Params);
		}
	}
	for (auto Params : VolumeParams)
	{
		RevertEnvironmentParams(Params, false);
	}
}

bool AEnvironmentController::ShapeEncompassesPoint(const UShapeComponent* Shape, FVector Point, float SphereRadius, float* OutDistanceToPoint)
{
#if WITH_PHYSX
	FVector ClosestPoint;
	float DistanceSqr;

	if (Shape->GetSquaredDistanceToCollision(Point, DistanceSqr, ClosestPoint) == false)
	{
		if (OutDistanceToPoint)
		{
			*OutDistanceToPoint = -1.f;
		}
		return false;
	}
#else
	FBoxSphereBounds Bounds = Shape->CalcBounds(Shape->GetComponentTransform());
	const float DistanceSqr = Bounds.GetBox().ComputeSquaredDistanceToPoint(Point);
#endif

	if (OutDistanceToPoint)
	{
		*OutDistanceToPoint = FMath::Sqrt(DistanceSqr);
	}

	return DistanceSqr >= 0.f && DistanceSqr <= FMath::Square(SphereRadius);
}

void UEnvironmentParams::BeginPlay()
{
	Super::BeginPlay();
	if (!EnvCtl.IsValid())
	{
		FindEnvironmentController(GetWorld());
	}
}

void UEnvironmentParams::SetEnvironmentParams()
{
	if (EnvCtl.IsValid())
	{
		EnvCtl->SetEnvironmentParams(this, false);
	}
}

void UEnvironmentParams::RevertEnvironmentParams()
{
	if (EnvCtl.IsValid())
	{
		EnvCtl->RevertEnvironmentParams(this, false);
	}
}

bool UEnvironmentParams::IsUseStartDistanceTransitTime() const
{
	return StartDistanceTransitTime > 0.01f;
}

AEnvironmentController* UEnvironmentParams::GetEnvironmentController() const
{
	if (EnvCtl.IsValid())
	{
		return EnvCtl.Get();
	}
	return nullptr;
}

void UEnvironmentParams::FindEnvironmentController(UWorld* World)
{
	if (!World) return;
	for (TActorIterator<AActor> It(World, AEnvironmentController::StaticClass()); It; ++It)
	{
		AActor* Actor = *It;
		if (Actor && !Actor->IsPendingKill())
		{
			EnvCtl = Cast<AEnvironmentController>(Actor);
			break;
		}
	}
}

TWeakObjectPtr<AEnvironmentController> UEnvironmentParams::GetEnvCtl() const
{
	return EnvCtl;
}

AKMEnvironmentControlVolume::AKMEnvironmentControlVolume(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	if (HasAnyFlags(RF_ClassDefaultObject))
	{
		return;
	}
	//Thickness = 500.0f;
	bForceApplyEnvironment = false;
	bGenerateOverlapEventsDuringLevelStreaming = false;
#if WITH_EDITOR
	EnvironmentParams = AEnvironmentController::ConstructBPEnvironmentParams(this, TEXT("EnvironmentParams"));
	check(EnvironmentParams);
	EnvironmentParams->ImportanceLevel = 1;
	if (!GConfig->GetString(EnvironmentControlAttribute, TEXT("EnvironmentControlGlobalLight"), GlobalLightClassName, GEngineIni))
	{
		UE_LOG(LogKMEnvironmentController, Error, TEXT("KMEnvironmentControlVolume: BP GlobalLight is missing!"));
	}
	USelection::SelectionChangedEvent.AddUObject(this, &AKMEnvironmentControlVolume::OnObjectSelected);
	FEditorDelegates::PreSaveWorld.AddUObject(this, &AKMEnvironmentControlVolume::OnPreSaveWorld);
#endif
}

AKMEnvironmentControlVolume::~AKMEnvironmentControlVolume()
{
#if WITH_EDITOR
	USelection::SelectionChangedEvent.RemoveAll(this);
	FEditorDelegates::PreSaveWorld.RemoveAll(this);
#endif
}

void AKMEnvironmentControlVolume::OnConstruction(const FTransform& Transform)
{
	Super::OnConstruction(Transform);
	// Init brush collision response.
	UBrushComponent* VolumeBrush = GetBrushComponent();
	if (VolumeBrush)
	{
		VolumeBrush->SetCollisionObjectType(ECC_WorldDynamic);
		VolumeBrush->SetCollisionResponseToAllChannels(ECR_Ignore);
		VolumeBrush->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
		//VolumeBrush->SetCollisionResponseToChannel(ECC_Vehicle, ECR_Overlap);
	}
}

void AKMEnvironmentControlVolume::BeginPlay()
{
	Super::BeginPlay();
	if (!EnvironmentParams)
	{
		EnvironmentParams = AEnvironmentController::NewBPEnvironmentParams(this);
		EnvironmentParams->ImportanceLevel = 1;
	}
	check(EnvironmentParams);
	EnvironmentParams->bIsVolumeParam = true;
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	if (!EnvCtl.IsValid())
	{
		EnvironmentParams->FindEnvironmentController(GetWorld());
		EnvCtl = EnvironmentParams->GetEnvCtl();
	}
	if (EnvCtl.IsValid())
	{
		// Verify if player was born in this volume
		if (!bForceApplyEnvironment)
		{
			if (AActor* Player = GetCurrentPlayer(this))
			{
				if (IsOverlappingActor(Player))
				{
					//Super::NotifyActorBeginOverlap(Player);
					OverlappingPlayer = Player;
					EnvCtl->SetEnvironmentParams(EnvironmentParams, true);
				}
				else
				{
					//Super::NotifyActorEndOverlap(Player);
				}
			}
		}
	}
}

void AKMEnvironmentControlVolume::PostUnregisterAllComponents()
{
	Super::PostUnregisterAllComponents();
#if WITH_EDITOR
	RevertPreviewParams();
#endif
}

void AKMEnvironmentControlVolume::NotifyActorBeginOverlap(AActor* OtherActor)
{
	Super::NotifyActorBeginOverlap(OtherActor);
	check(EnvironmentParams);
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	if (EnvCtl.IsValid())
	{
		if (!bForceApplyEnvironment)
		{
			AActor* Player = GetCurrentPlayer(this);
			if (OtherActor == Player)
			{
				OverlappingPlayer = Player;
				EnvCtl->SetEnvironmentParams(EnvironmentParams, false);
			}
			else if (OtherActor == GetWatchingPlayer(this))
			{
				EnvCtl->SetEnvironmentParams(EnvironmentParams, false);
			}
			else if (Player == nullptr) // Changing from human to ship.
			{
				EnvCtl->SetEnvironmentParams(EnvironmentParams, false);
			}
		}
	}
}

void AKMEnvironmentControlVolume::NotifyActorEndOverlap(AActor* OtherActor)
{
	Super::NotifyActorEndOverlap(OtherActor);
	check(EnvironmentParams);
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	if (EnvCtl.IsValid())
	{
		if (!bForceApplyEnvironment)
		{
			AActor* Player = GetCurrentPlayer(this);
			if (Player == OtherActor)
			{
				if (!Player->IsHidden())
				{
					FVector Origin, Extent;
					Player->GetActorBounds(true, Origin, Extent);
					if (EncompassesPoint(Origin)) // Do not fire when actor is still in volume
					{
						return;
					}
				}
				EnvCtl->RevertEnvironmentParams(EnvironmentParams, false);
			}
			else if (OtherActor == GetWatchingPlayer(this))
			{
				EnvCtl->RevertEnvironmentParams(EnvironmentParams, false);
			}
		}
	}
}

FBox AKMEnvironmentControlVolume::GetComponentsBoundingBox(bool bNonColliding, bool bIncludeFromChildActors) const
{
	if (IsRunningCommandlet())
	{
		FBox Box(ForceInit);
		UBrushComponent* BrushData = GetBrushComponent();
		if (BrushData)
		{
			FTransform Transform(BrushData->GetRelativeRotation(), BrushData->GetRelativeLocation(), BrushData->GetRelativeScale3D());
			FBoxSphereBounds Bounds = BrushData->CalcBounds(Transform);
			Box += Bounds.GetBox();
		}
		return Box;
	}
	return Super::GetComponentsBoundingBox(bNonColliding, bIncludeFromChildActors);
}

void AKMEnvironmentControlVolume::SetEnvironment()
{
	check(EnvironmentParams);
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	if (!EnvCtl.IsValid())
	{
		EnvironmentParams->FindEnvironmentController(GetWorld());
		EnvCtl = EnvironmentParams->GetEnvCtl();
	}
	if (EnvCtl.IsValid())
	{
		EnvCtl->SetEnvironmentParams(EnvironmentParams, true);
	}
}

void AKMEnvironmentControlVolume::RevertEnvironment()
{
	check(EnvironmentParams);
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	if (!EnvCtl.IsValid())
	{
		EnvironmentParams->FindEnvironmentController(GetWorld());
		EnvCtl = EnvironmentParams->GetEnvCtl();
	}
	if (EnvCtl.IsValid())
	{
		EnvCtl->RevertEnvironmentParams(EnvironmentParams, true);
	}
}

AActor* AKMEnvironmentControlVolume::GetCurrentPlayer(const UObject* WorldContextObject)
{
	return UExtendBlueprintFunctions::GetHumanCharacter(UGameplayStatics::GetPlayerPawn(WorldContextObject, 0));
	//APlayerController* PlayerController = World->GetFirstPlayerController();
	//if (PlayerController && !PlayerController->IsPendingKill())
	//{
	//	APawn* Pawn = PlayerController->GetPawn();
	//	if (Pawn && !Pawn->IsPendingKill())
	//	{
	//		return Pawn;
	//	}
	//	if (auto VehicleController = Cast<APiratesVehicleController>(PlayerController))
	//	{
	//		AActor* Actor = VehicleController->GetCurrentPlayerTarget();
	//		if (Actor && !Actor->IsPendingKill())
	//		{
	//			return Actor;
	//		}
	//	}
	//}
}

AActor* AKMEnvironmentControlVolume::GetWatchingPlayer(const UObject* WorldContextObject)
{
	if (auto CameraManager = Cast<AKMGameCameraManager>(UGameplayStatics::GetPlayerCameraManager(WorldContextObject, 0)))
	{
		return UExtendBlueprintFunctions::GetHumanCharacter(CameraManager->GetCameraTargetPawn());
	}
	return nullptr;
}

#if WITH_EDITOR
void AKMEnvironmentControlVolume::OnObjectSelected(UObject* Object)
{
	ReturnIfNullptr(EnvironmentParams);
	if (UWorld* World = Object->GetWorld())
	{
		if (World->WorldType != EWorldType::Editor)
		{
			return;
		}
	}
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	FEditorScriptExecutionGuard ScriptGuard;
	if (USelection* Selection = Cast<USelection>(Object))
	{
		if (!EnvCtl.IsValid())
		{
			EnvironmentParams->FindEnvironmentController(GetWorld());
			EnvCtl = EnvironmentParams->GetEnvCtl();
			if (EnvCtl.IsValid())
			{
				EnvCtl->SnapEnvironmentParams();
			}
		}
		if (!EnvCtl.IsValid()) return;
		bool bSelected = false;
		for (int32 Idx = 0; Idx < Selection->Num(); Idx++)
		{
			UObject* SelectedObject = Selection->GetSelectedObject(Idx);
			if (!SelectedObject) continue;
			if (auto Volume = Cast<AKMEnvironmentControlVolume>(SelectedObject))
			{
				if (EnvCtl->IsEnvironmentDirty())
				{
					// In case of select volume while editing Fog/Light color.
					// We need to first apply changes then preview volume params.
					EnvCtl->SnapEnvironmentParams();
					EnvCtl->SetEnvironmentDirty(false);
				}
				Volume->PreviewEnvironmentParams();
				bSelected = true;
			}
			else
			{
				bool bEditing = false;
				auto Fog = Cast<AExponentialHeightFog>(SelectedObject);
				if (!Fog)
				{
					auto ObjectClass = SelectedObject->GetClass();
					FString Name = ObjectClass->GetName();
					if (Name.Equals(GlobalLightClassName))
					{
						bEditing = true;
					}
				}
				else
				{
					bEditing = true;
				}
				if (bEditing)
				{
					// User should edit fog, mark environment dirty to snap new params.
					EnvCtl->RevertEnvironmentParams(EnvironmentParams, true);
					EnvCtl->SetEnvironmentDirty(true);
				}
			}
		}
		if (!bSelected)
		{
			if (EnvCtl->IsEnvironmentDirty())
			{
				EnvCtl->SnapEnvironmentParams();
			}
			else
			{
				EnvCtl->RevertEnvironmentParams(EnvironmentParams, true);
				// Environment dirty means user is editing params. When editing, user might select other actors.
				// If we set dirty to false after snap immediately, it will only keep values at the time of selecting happened.
				// So we should delay setting operations until user selects other volume.
				EnvCtl->SetEnvironmentDirty(false);
			}
		}
	}
}

void AKMEnvironmentControlVolume::PreviewEnvironmentParams()
{
	ReturnIfNullptr(EnvironmentParams);
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	if (!EnvCtl.IsValid()) return;
	if (EnvCtl->bPreviewEnvironment)
	{
		EnvCtl->SetEnvironmentParams(EnvironmentParams, true);
	}
}

void AKMEnvironmentControlVolume::OnPreSaveWorld(uint32 SaveFlags, class UWorld* World)
{
	RevertPreviewParams();
}

void AKMEnvironmentControlVolume::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	ReturnIfNullptr(EnvironmentParams);
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	if (!EnvCtl.IsValid()) return;
	Super::PostEditChangeProperty(PropertyChangedEvent);
	//FName PropertyName = PropertyChangedEvent.Property ? PropertyChangedEvent.Property->GetFName() : NAME_None;
	//if (PropertyName == TEXT("Density") ||
	//	PropertyName == TEXT("InscatteringColor") ||
	//	PropertyName == TEXT("HeightFalloff") ||
	//	PropertyName == TEXT("MaxOpacity") ||
	//	PropertyName == TEXT("StartDistance") ||
	//	PropertyName == TEXT("CutoffDistance")
	//	)
	{
		FEditorScriptExecutionGuard ScriptGuard;
		{
			PreviewEnvironmentParams();
		}
	}
}

void AKMEnvironmentControlVolume::RevertPreviewParams()
{
	ReturnIfNullptr(EnvironmentParams);
	auto EnvCtl = EnvironmentParams->GetEnvCtl();
	if (!EnvCtl.IsValid()) return;
	FEditorScriptExecutionGuard ScriptGuard;
	{
		if (EnvCtl->IsEnvironmentDirty())
		{
			EnvCtl->SnapEnvironmentParams();
			EnvCtl->SetEnvironmentDirty(false);
		}
		EnvCtl->RevertEnvironmentParams(EnvironmentParams, true);
	}
}

#endif
