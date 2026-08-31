// Fill out your copyright notice in the Description page of Project Settings.

#include "KMInstancedSceneItemActor.h"
#include "Common.h"
#include "CoreGlobals.h"
#include "Engine/StaticMesh.h"
#include "Shell/EngineExtShell.h"
#include "Components/StaticMeshComponent.h"
#include "Components/InstancedStaticMeshComponent.h"

DEFINE_LOG_CATEGORY_STATIC(LogKMInstancedSceneItemActor, Log, All);

static int32 GPIRShowSceneItem = 1;
static FAutoConsoleVariableRef CVarPIRShowSceneItem(
	TEXT("pir.ShowSceneItem"), GPIRShowSceneItem, TEXT("Show/Hide SceneItem.")
);

static int32 GPIRSceneItemGroup = 1;
static FAutoConsoleVariableRef CVarSceneItemGroup(
	TEXT("pir.SceneItemGroup"), GPIRSceneItemGroup, TEXT("Enable SceneItem Group.")
);

static float GPIRSceneItemUpdateGroupFrequency = 0.33f;
static FAutoConsoleVariableRef CVarSceneItemUpdateGroupFrequency(
	TEXT("pir.SceneItemUpdateGroupFrequency"), GPIRSceneItemUpdateGroupFrequency, TEXT("Enable SceneItem Group.")
);

static int32 GPIRSceneItemGroupLog = 0;
static FAutoConsoleVariableRef CVarSceneItemGroupLog(
	TEXT("pir.SceneItemShowGroupLog"), GPIRSceneItemGroupLog, TEXT("Show SceneItem Group Log.")
);

#if !UE_BUILD_SHIPPING
static int32 GPIRSceneItemDebugOffset = 0;
static FAutoConsoleVariableRef CVarSceneItemDebugOffset(
	TEXT("pir.SceneItemDebugOffset"), GPIRSceneItemDebugOffset, TEXT("Scene Item Debug Offset.")
);
#endif

static const FTransform InvisibleTransform(FRotator::ZeroRotator, FVector(0.0f, -100000.0f, 0.0f), FVector::ZeroVector);

AKMInstancedSceneItemActor::AKMInstancedSceneItemActor()
{
	//FString MeshName;
	//if (GConfig->GetString(TEXT("/Script/Common.KMInstancedSceneItemActor"), TEXT("RepresentMesh"), MeshName, GEngineIni))
	//{
	//	RepresentMesh = Cast<UStaticMesh>(StaticLoadObject(UObject::StaticClass(), nullptr, *MeshName, nullptr, LOAD_None, nullptr));
	//}
	//const TCHAR KMInstancedSceneItemActorlAttribute[] = TEXT("/Script/Common.KMInstancedSceneItemActor");
#if STATS
	PrimaryActorTick.bCanEverTick = true;
#else
	PrimaryActorTick.bCanEverTick = false;
#endif
}

void AKMInstancedSceneItemActor::SetMockMode()
{
	//bMockMode = true;
}

void AKMInstancedSceneItemActor::InitStaticMeshSources(const TArray<FString>& InSourceList)
{
	//SetSourceList(InSourceList);
	//AsyncLoadMeshes();
	//bMockMode = false;
	// Test get mesh before async done
	//for (const FString& Path : InSourceList)
	//{
	//	UStaticMesh* Mesh = GetSceneItemMesh(Path);
	//	if (Mesh)
	//	{
	//		UE_LOG(LogKMInstancedSceneItemActor, Log, TEXT("Loaded Mesh %s"), *Path);
	//	}
	//}
}

float AKMInstancedSceneItemActor::CalcScreenSize(FVector ViewPoint, const FBoxSphereBounds& Bounds) const
{
	// https://wiki.unrealengine.com/Get_Screen-Size_Bounds_of_An_Actor
	float BoundingRadius = FMath::Max(Bounds.SphereRadius, 30.0f);
	float DistanceToObject = FVector::Dist(Bounds.Origin, ViewPoint);
	if (DistanceToObject < 1.0f) return 1.0f;
	float CamInvFov = 0.0f;
	if (UWorld* World = GetWorld())
	{
		if (APlayerCameraManager* Camera = UGameplayStatics::GetPlayerCameraManager(World, 0))
		{
			CamInvFov = 2.0f / FMath::DegreesToRadians(Camera->GetFOVAngle());
		}
	}
	float ScreenSize = FMath::Atan(BoundingRadius / DistanceToObject) * CamInvFov;
	//UE_LOG(LogKMInstancedSceneItemActor, Display, TEXT("CamInvFov = %f"), CamInvFov);
	return ScreenSize;
}

void AKMInstancedSceneItemActor::AddTriggerInstance(AActor* Trigger, const FTransform& WorldTransform)
{
	ItemInstance* ItemPtr = TriggerItemInstMap.Find(Trigger);
	if (ItemPtr)
	{
		ItemDrawComponent* InstDrawPtr = MeshDrawComponentMap.Find(ItemPtr->Mesh);
		if (InstDrawPtr)
		{
			DrawComponent* ComponentPtr = ItemPtr->IsDark ? &InstDrawPtr->DarkComponent : &InstDrawPtr->Component;
			ItemPtr->Index = AddTriggerInstanceTo(*ComponentPtr, WorldTransform);
			InstDrawPtr->InstancedTriggers.Add(Trigger);
		}
	}
}

int32 AKMInstancedSceneItemActor::AddTriggerInstanceTo(DrawComponent& Component, const FTransform& WorldTransform)
{
	int32 Index = -1;
	if (!Component.Renderer)
	{
		return Index;
	}
	if (Component.FreeIndices.Num() > 0)
	{
		Index = Component.FreeIndices.Pop(false);
		Component.Renderer->UpdateInstanceTransform(Index, WorldTransform, true, true, true);
	}
	else
	{
		Index = Component.Renderer->GetInstanceCount();
		Component.Renderer->AddInstanceWorldSpace(WorldTransform);
	}
	return Index;
}

bool AKMInstancedSceneItemActor::RemoveTriggerInstance(AActor* Trigger)
{
	ItemInstance* ItemPtr = TriggerItemInstMap.Find(Trigger);
	if (ItemPtr)
	{
		ItemDrawComponent* InstDrawPtr = MeshDrawComponentMap.Find(ItemPtr->Mesh);
		if (InstDrawPtr)
		{
			if (ItemPtr->Index != -1)
			{
				DrawComponent* ComponentPtr = ItemPtr->IsDark ? &InstDrawPtr->DarkComponent : &InstDrawPtr->Component;
				if (RemoveTriggerInstanceFrom(*ComponentPtr, ItemPtr->Index))
				{
					ItemPtr->Index = -1;
					InstDrawPtr->InstancedTriggers.Remove(Trigger);
					return true;
				}
			}
		}
	}
	return false;
}

bool AKMInstancedSceneItemActor::RemoveTriggerInstanceFrom(DrawComponent& Component, int32 Index)
{
	if (Component.Renderer)
	{
		if (Component.Renderer->UpdateInstanceTransform(Index, InvisibleTransform, true, true, true))
		{
			Component.FreeIndices.Add(Index);
			return true;
		}
	}
	return false;
}

void AKMInstancedSceneItemActor::BeginPlay()
{
	Super::BeginPlay();
	if (RepresentMesh)
	{
		UE_CLOG(!RepresentMesh->RenderData->IsInitialized(), LogKMInstancedSceneItemActor, Display, TEXT("Uninitialized Renderdata for Mesh: %s, Mesh NeedsLoad: %i, Mesh NeedsPostLoad: %i, Mesh Loaded: %i, Mesh NeedInit: %i, Mesh IsDefault: %i")
			, *RepresentMesh->GetFName().ToString()
			, RepresentMesh->HasAnyFlags(RF_NeedLoad)
			, RepresentMesh->HasAnyFlags(RF_NeedPostLoad)
			, RepresentMesh->HasAnyFlags(RF_LoadCompleted)
			, RepresentMesh->HasAnyFlags(RF_NeedInitialization)
			, RepresentMesh->HasAnyFlags(RF_ClassDefaultObject)
		);
		RepresentMeshComponent = CreateInstancedStaticMeshComponent(RepresentMesh, NAME_None);
		RepresentBounds = RepresentMesh->GetBounds();
		RepresentSize = RepresentBounds.GetBox().GetSize();
		RepresentSize.X = RepresentSize.Y = FMath::Max(RepresentSize.X, RepresentSize.Y);
		RepresentSize /= RepresentRatio;
	}
	else
	{
		UE_LOG(LogKMInstancedSceneItemActor, Error, TEXT("SceneItem representMesh is not specified!"));
	}

#if !UE_SERVER
	GetWorldTimerManager().SetTimer(UpdateSceneItemLODHandle, this, &AKMInstancedSceneItemActor::UpdateSceneItemLOD, GPIRSceneItemUpdateGroupFrequency, true);
#endif
}

void AKMInstancedSceneItemActor::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
#if !UE_SERVER
	GetWorldTimerManager().ClearTimer(UpdateSceneItemLODHandle);
#endif
}

void AKMInstancedSceneItemActor::SpawnSceneItem(AActor* Trigger, const FString& Path, const FTransform& WorldTransform)
{
	FString AssetName;
	Path.Split(TEXT("."), nullptr, &AssetName, ESearchCase::CaseSensitive, ESearchDir::FromStart);
	if (AssetName.StartsWith(TEXT("SM_")))
	{
		SpawnStaticSceneItem(Trigger, Path, WorldTransform);
	}
	else if (AssetName.StartsWith(TEXT("SKM_")))
	{
		SpawnSkeletalSceneItem(Trigger, Path, WorldTransform);
	}
}

void AKMInstancedSceneItemActor::SpawnStaticSceneItem(AActor* Trigger, const FString& Path, const FTransform& WorldTransform)
{
	TSoftObjectPtr<UStaticMesh> Mesh(Path);
	UStaticMesh* StaticMesh = Mesh.Get();
	ItemDrawComponent* InstComponentPtr = MeshDrawComponentMap.Find(Mesh);
	if (!InstComponentPtr)
	{
		InstComponentPtr = &MeshDrawComponentMap.Add(Mesh, ItemDrawComponent{});
		if (StaticMesh)
		{
			CreateInstancedStaticMeshComponent(StaticMesh, *Mesh.GetAssetName(), InstComponentPtr);
		}
		else
		{
			//if (!bMockMode)
			{
				UE_LOG(LogKMInstancedSceneItemActor, Verbose, TEXT("'%s' is not cached, request for loading."), *Mesh.GetLongPackageName());
			}
			if (RepresentMesh)
			{
				AsyncLoadMesh(Mesh);
				CreateInstancedStaticMeshComponent(RepresentMesh, *Mesh.GetAssetName(), InstComponentPtr);
			}
			else
			{
				StaticMesh = SyncLoadMesh(Mesh);
				CreateInstancedStaticMeshComponent(StaticMesh, *Mesh.GetAssetName(), InstComponentPtr);
			}
		}
	}
	ItemInstance& Item = TriggerItemInstMap.Add(Trigger, ItemInstance{ Trigger, Mesh, WorldTransform });
	AddTriggerInstance(Trigger, WorldTransform);
	if (StaticMesh)
	{
		JointToGroup(Item, StaticMesh);
	}
}

void AKMInstancedSceneItemActor::SpawnSkeletalSceneItem(AActor* Trigger, const FString& Path, const FTransform& WorldTransform)
{
	TSoftObjectPtr<USkeletalMesh> Mesh(Path);
	ItemInstance& Item = TriggerItemInstMap.Add(Trigger, ItemInstance{ Trigger, Mesh, WorldTransform });
	USkeletalMesh* SkeletalMesh = Mesh.Get(); 
	if (SkeletalMesh)
	{
		Item.SkeletalMeshComponent = CreateSkeletalMeshComponent(SkeletalMesh, *Mesh.GetAssetName());
	}
	else
	{
		UE_LOG(LogKMInstancedSceneItemActor, Verbose, TEXT("'%s' is not cached, request for loading."), *Mesh.GetLongPackageName());
		if (RepresentMesh)
		{
			ItemDrawSkeletalComponent& InstComponent = SkeletalMeshDrawComponentMap.FindOrAdd(Mesh);
			InstComponent.UnloadedSkeletalComponents.Add(Item.SkeletalMeshComponent);
			Item.SkeletalMeshComponent = CreateSkeletalMeshComponent(nullptr, *Mesh.GetAssetName());
			AsyncLoadSkeletalMesh(Mesh);
		}
		else
		{
			SkeletalMesh = SyncLoadSkeletalMesh(Mesh);
			Item.SkeletalMeshComponent = CreateSkeletalMeshComponent(SkeletalMesh, *Mesh.GetAssetName());
		}
	}
	Item.SkeletalMeshComponent->SetWorldTransform(WorldTransform);
}

UInstancedStaticMeshComponent* AKMInstancedSceneItemActor::CreateInstancedStaticMeshComponent(UStaticMesh* Mesh, FName Name)
{
	UInstancedStaticMeshComponent* Component = NewObject<UInstancedStaticMeshComponent>(this, Name);
	Component->SetFlags(RF_Transactional);
	//Component->SetCullDistance(CullDistance); // Cull distance do not work with UpdateLOD, so disable it.
	Component->SetRenderCustomDepth(false);
	Component->SetStaticMesh(Mesh);
	Component->SetCastShadow(false);
	// We do not need collision and physics. Collision bounding is located in BP_SceneItem_Trigger.
	Component->SetSimulatePhysics(false);
	Component->SetCollisionResponseToAllChannels(ECR_Ignore);
	Component->RegisterComponent();
	Component->AttachToComponent(GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform);
	// Avoid frequently calling CreateAllInstanceBodies() when RemoveInstance.
	// See UInstancedStaticMeshComponent::RemoveInstanceInternal
	Component->DestroyPhysicsState();
	return Component;
}

void AKMInstancedSceneItemActor::CreateInstancedStaticMeshComponent(UStaticMesh* Mesh, FName Name, ItemDrawComponent* OutComponent)
{
	UInstancedStaticMeshComponent* Component = CreateInstancedStaticMeshComponent(Mesh, Name);
	OutComponent->Component.Renderer = Component;
	OutComponent->Bright = 0.0f;
	if (Mesh != RepresentMesh) 
	{
		CreateInstancedDarkComponent(Mesh, Name, OutComponent);
	}
}

void AKMInstancedSceneItemActor::CreateInstancedDarkComponent(UStaticMesh* Mesh, FName Name, ItemDrawComponent* OutComponent)
{
	if (UMaterialInterface* SourceMaterial = Mesh->GetMaterial(0))
	{
		if (SourceMaterial->GetScalarParameterValue(TEXT("Bright"), OutComponent->Bright))
		{
			FName DarkName = *FString::Printf(TEXT("%s_Dark"), *Name.ToString());
			UInstancedStaticMeshComponent* DarkComponent = CreateInstancedStaticMeshComponent(Mesh, DarkName);
			OutComponent->DarkComponent.Renderer = DarkComponent;
			OutComponent->DarkMaterial = DarkComponent->CreateDynamicMaterialInstance(0, SourceMaterial);
			OutComponent->DarkMaterial->SetScalarParameterValue(TEXT("Bright"), 0.0f);
		}
	}
}

USkeletalMeshComponent* AKMInstancedSceneItemActor::CreateSkeletalMeshComponent(USkeletalMesh* Mesh, FName Name)
{
	USkeletalMeshComponent* Component = NewObject<USkeletalMeshComponent>(this);
	Component->SetFlags(RF_Transactional);
	Component->SetCullDistance(CullDistance);
	Component->SetRenderCustomDepth(false);
	Component->SetSkeletalMesh(Mesh);
	Component->SetCastShadow(false);
	// We do not need collision and physics. Collision bounding is located in BP_SceneItem_Trigger.
	Component->SetSimulatePhysics(false);
	Component->SetCollisionResponseToAllChannels(ECR_Ignore);
	Component->RegisterComponent();
	Component->AttachToComponent(GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform);
	// Avoid frequently calling CreateAllInstanceBodies() when RemoveInstance.
	// See UInstancedStaticMeshComponent::RemoveInstanceInternal
	Component->DestroyPhysicsState();
	return Component;
}

void AKMInstancedSceneItemActor::RefreshInstancedStaticMesh(UStaticMesh* Mesh)
{
	ReturnIfNullptr(RepresentMesh);
	TSoftObjectPtr<UStaticMesh> MeshPtr = Mesh;
	ItemDrawComponent* Ptr = MeshDrawComponentMap.Find(MeshPtr);
	if (Ptr)
	{
		if (Ptr->Component.Renderer)
		{
			Ptr->Component.Renderer->SetStaticMesh(Mesh);
		}
		if (!Ptr->DarkComponent.Renderer)
		{
			CreateInstancedDarkComponent(Mesh, *MeshPtr.GetAssetName(), Ptr);
		}
		for (AActor* Trigger : Ptr->InstancedTriggers)
		{
			ItemInstance* ItemPtr = TriggerItemInstMap.Find(Trigger);
			if (ItemPtr)
			{
				JointToGroup(*ItemPtr, Mesh);
			}
		}
	}
}

void AKMInstancedSceneItemActor::RefreshSkeletalMeshes(USkeletalMesh* Mesh)
{
	ReturnIfNullptr(RepresentMesh);
	TSoftObjectPtr<USkeletalMesh> MeshPtr = Mesh;
	ItemDrawSkeletalComponent* Ptr = SkeletalMeshDrawComponentMap.Find(MeshPtr);
	if (Ptr)
	{
		for (USkeletalMeshComponent* Component : Ptr->UnloadedSkeletalComponents)
		{
			Component->SetSkeletalMesh(Mesh);
		}
	}
	SkeletalMeshDrawComponentMap.Remove(MeshPtr);
}

void AKMInstancedSceneItemActor::JointToGroup(ItemInstance& Item, UStaticMesh* Mesh)
{
	// Joint to group
	FBoxSphereBounds Bounds = Mesh->GetBounds().TransformBy(Item.WorldTransform);
	bool GroupFound = false;
	for (auto It = ItemGroupList.CreateIterator(); It; ++It)
	{
		if (FBoxSphereBounds::SpheresIntersect(FSphere(Bounds.Origin, GroupDistance), It->Bounds))
		{
			It->Triggers.Add(Item.ItemTrigger);
			It->Bounds = It->Bounds + Bounds;
			Item.Group = &(*It);
			GroupFound = true;
			break;
		}
	}
	if (!GroupFound)
	{
		Item.Group = new ItemGroup{ Bounds, {Item.ItemTrigger} };
		ItemGroupList.Add(Item.Group);
	}
}

bool AKMInstancedSceneItemActor::DestroySceneItem(AActor* Trigger)
{
	ItemInstance* ItemPtr = TriggerItemInstMap.Find(Trigger);
	if (ItemPtr)
	{
		ItemDrawComponent* InstComponentPtr = MeshDrawComponentMap.Find(ItemPtr->Mesh);
		if (InstComponentPtr)
		{
			// Remove from group
			if (ItemPtr->Group)
			{
				ItemPtr->Group->Triggers.Remove(Trigger);
				if (ItemPtr->Group->Triggers.Num() == 0)
				{
					for (auto It = ItemGroupList.CreateConstIterator(); It; ++It)
					{
						if (&(*It) == ItemPtr->Group)
						{
							ItemGroupList.RemoveAtSwap(It.GetIndex());
							//FString Msg = FString::Printf(TEXT("Group Destroy: %s"), *ItemPtr->Mesh->GetName());
							//UE_LOG(LogKMInstancedSceneItemActor, Display, TEXT("%s"), *Msg);
							//GEngine->AddOnScreenDebugMessage(-1, 1.5f, FColor::Orange, Msg);
							break;
						}
					}
				}
			}
			InstComponentPtr->GroupedTriggers.Remove(Trigger);
			// Remove instance
			RemoveTriggerInstance(Trigger);
			TriggerItemInstMap.Remove(Trigger);
		}
		else if (IsValid(ItemPtr->SkeletalMeshComponent))
		{
			ItemPtr->SkeletalMeshComponent->DestroyComponent();
		}
	}

	return false;
}

void AKMInstancedSceneItemActor::SetHighlighting(AActor* Trigger, bool bVisible)
{
	ItemInstance* ItemPtr = TriggerItemInstMap.Find(Trigger);
	if (ItemPtr)
	{
		ItemDrawComponent* InstComponentPtr = MeshDrawComponentMap.Find(ItemPtr->Mesh);
		if (InstComponentPtr)
		{
			if (bVisible && ItemPtr->IsDark)
			{
				RemoveTriggerInstance(Trigger);
				ItemPtr->IsDark = false;
				AddTriggerInstance(Trigger, ItemPtr->WorldTransform);
			}
			else if (!bVisible && !ItemPtr->IsDark)
			{
				RemoveTriggerInstance(Trigger);
				ItemPtr->IsDark = true;
				AddTriggerInstance(Trigger, ItemPtr->WorldTransform);
			}
			//InstComponentPtr->Material->SetScalarParameterValue(TEXT("Bright"), bVisible ? InstComponentPtr->Bright : 0.0f);
		}
	}
}

void AKMInstancedSceneItemActor::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
#if STATS && !UE_SERVER
	SCOPE_CYCLE_COUNTER(STAT_SceneItemActorTick);
	ReturnIfNullptr(RepresentMesh);
	int32 StatNum = 0, StatTris = 0, StatDraws = 0;
	int32 StatGroupedNum = 0, StatGroupedTris = 0;
	for (auto& P : MeshDrawComponentMap)
	{
		ItemDrawComponent& DrawComponent = P.Value;
		UInstancedStaticMeshComponent* InstComponent = DrawComponent.Component.Renderer;
		if (!InstComponent->GetStaticMesh()) continue;
		int32 DrawCount = InstComponent->GetInstanceCount() - DrawComponent.Component.FreeIndices.Num();
		if (UInstancedStaticMeshComponent* DarkInstComponent = DrawComponent.DarkComponent.Renderer)
		{
			if (DarkInstComponent->GetStaticMesh())
			{
				DrawCount += DarkInstComponent->GetInstanceCount() - DrawComponent.DarkComponent.FreeIndices.Num();
			}
		}
		StatNum += DrawCount;
		if (DrawCount > 0)
		{
			++StatDraws;
			for (auto& LODResource : InstComponent->GetStaticMesh()->RenderData->LODResources)
			{
				StatTris += LODResource.GetNumTriangles() * DrawCount;
			}
		}
		StatGroupedNum += DrawComponent.GroupedTriggers.Num();
		for (AActor* Actor : DrawComponent.GroupedTriggers)
		{
			ItemInstance* ItemInstancePtr = TriggerItemInstMap.Find(Actor);
			if (ItemInstancePtr && ItemInstancePtr->Mesh.IsValid())
			{
				for (auto& LODResource : ItemInstancePtr->Mesh->RenderData->LODResources)
				{
					StatGroupedTris += LODResource.GetNumTriangles();
				}
			}
		}
	}
	INC_DWORD_STAT_BY(STAT_SceneItemNum, StatNum);
	INC_DWORD_STAT_BY(STAT_SceneItemTris, StatTris);
	INC_DWORD_STAT_BY(STAT_SceneItemDraws, StatDraws);
	INC_DWORD_STAT_BY(STAT_SceneItemGroupedNum, StatGroupedNum);
	INC_DWORD_STAT_BY(STAT_SceneItemGroupedTris, StatGroupedTris);
	INC_DWORD_STAT_BY(STAT_SceneItemCachedNum, StaticMeshCache.Num());
	if (CurrentShowState != GPIRShowSceneItem)
	{
		CurrentShowState = GPIRShowSceneItem;
		for (auto& Pair : MeshDrawComponentMap)
		{
			UInstancedStaticMeshComponent* InstComponent = Pair.Value.Component.Renderer;
			InstComponent->SetVisibility(CurrentShowState != 0);
		}
		if (RepresentMeshComponent)
		{
			RepresentMeshComponent->SetVisibility(CurrentShowState != 0);
		}
	}
	if (CurrentGroupState != GPIRSceneItemGroup)
	{
		CurrentGroupState = GPIRSceneItemGroup;
		if (CurrentGroupState == 0)
		{
			GetWorldTimerManager().PauseTimer(UpdateSceneItemLODHandle);
			// Ungroup all
			for (auto& P : TriggerItemInstMap)
			{
				UnGroupSceneItem(P.Key);
			}
			if (RepresentMeshComponent)
			{
				RepresentMeshComponent->ClearInstances();
			}
		}
		else
		{
			GetWorldTimerManager().UnPauseTimer(UpdateSceneItemLODHandle);
		}
	}
#endif 
}

void AKMInstancedSceneItemActor::UpdateSceneItemLOD()
{
#if !UE_SERVER
	SCOPE_CYCLE_COUNTER(STAT_SceneItemActorUpdateLOD);
	if (!RepresentMesh) return;
	if (!RepresentMeshComponent) return;
	if (CurrentGroupState == 0) return;
	UWorld* World = GetWorld();
	if (!World) return;
	APlayerCameraManager* Camera = UGameplayStatics::GetPlayerCameraManager(World, 0);
	if (!Camera) return;
	FVector Location = Camera->GetCameraLocation();
	int32 RepresentInstNum = 0;
	bool bRenderStageDirty = false;
	for (auto It = ItemGroupList.CreateConstIterator(); It; ++It)
	{
		bool IsInView = FVector::DotProduct(It->Bounds.Origin - Camera->GetCameraLocation(), Camera->GetActorForwardVector()) > 0.0f;
		if (/*IsInView && */CalcScreenSize(Camera->GetCameraLocation(), It->Bounds) > GroupScreenSize)
		{
			for (AActor* Trigger : It->Triggers)
			{
				UnGroupSceneItem(Trigger);
			}
		}
		else
		{
			for (AActor* Trigger : It->Triggers)
			{
				GroupSceneItem(Trigger);
			}
			// Replace group item mesh to represent mesh
			FVector GroupScale = It->Bounds.GetBox().GetSize() / RepresentSize;
			FVector GroupOffset = RepresentBounds.Origin * GroupScale;
#if !UE_BUILD_SHIPPING
			if (GPIRSceneItemDebugOffset != 0)
			{
				GroupOffset = FVector::ZeroVector;
			}
#endif
			FTransform Transform(FQuat::Identity, It->Bounds.Origin - GroupOffset, GroupScale);
			FTransform RepresentTransform;
			if (RepresentMeshComponent->GetInstanceTransform(RepresentInstNum, RepresentTransform, true))
			{
				if (RepresentTransform.GetLocation() != Transform.GetLocation() || RepresentTransform.GetScale3D() != Transform.GetScale3D())
				{
					RepresentMeshComponent->UpdateInstanceTransform(RepresentInstNum, Transform, true, false, true);
					bRenderStageDirty = true;
					if (GPIRSceneItemGroupLog != 0)
					{
						UE_LOG(LogKMInstancedSceneItemActor, Log, TEXT("Update Represent at index: %d"), RepresentInstNum);
					}
				}
			}
			else
			{
				RepresentMeshComponent->AddInstanceWorldSpace(Transform);
				bRenderStageDirty = true;
				if (GPIRSceneItemGroupLog != 0)
				{
					UE_LOG(LogKMInstancedSceneItemActor, Log, TEXT("Append Represent at index: %d"), RepresentInstNum);
				}
			}
			++RepresentInstNum;
		}
	}
	// Remove ungrouped present mesh insts
	for (int32 Index = RepresentMeshComponent->GetInstanceCount() - 1; Index >= RepresentInstNum; Index--)
	{
		RepresentMeshComponent->RemoveInstance(Index);
		bRenderStageDirty = true;
		if (GPIRSceneItemGroupLog != 0)
		{
			UE_LOG(LogKMInstancedSceneItemActor, Log, TEXT("Remove Represent at index: %d"), Index);
		}
	}
	if (bRenderStageDirty)
	{
		RepresentMeshComponent->MarkRenderStateDirty();
	}
	if (GPIRSceneItemGroupLog != 0)
	{
		GEngine->AddOnScreenDebugMessage(1, 1.0f, FColor::Yellow, FString::Printf(TEXT("Represent Num: %d"), RepresentMeshComponent->GetInstanceCount()));
	}
#endif
}

void AKMInstancedSceneItemActor::GroupSceneItem(AActor* Trigger)
{
	ReturnIfNullptr(RepresentMesh);
	ItemInstance* ItemPtr = TriggerItemInstMap.Find(Trigger);
	if (ItemPtr && !ItemPtr->IsGrouped)
	{
		ItemDrawComponent* InstComponentPtr = MeshDrawComponentMap.Find(ItemPtr->Mesh);
		if (InstComponentPtr)
		{
			if (RemoveTriggerInstance(Trigger))
			{
				InstComponentPtr->GroupedTriggers.Add(Trigger);
			}
		}
		ItemPtr->IsGrouped = true;
	}
}

void AKMInstancedSceneItemActor::UnGroupSceneItem(AActor* Trigger)
{
	ReturnIfNullptr(RepresentMesh);
	ItemInstance* ItemPtr = TriggerItemInstMap.Find(Trigger);
	if (ItemPtr && ItemPtr->IsGrouped)
	{
		ItemDrawComponent* InstComponentPtr = MeshDrawComponentMap.Find(ItemPtr->Mesh);
		if (InstComponentPtr)
		{
			AddTriggerInstance(Trigger, ItemPtr->WorldTransform);
		}
		InstComponentPtr->GroupedTriggers.Remove(Trigger);
		ItemPtr->IsGrouped = false;
	}
}

void AKMInstancedSceneItemActor::SetSourceList(const TArray<FString>& InSourceList)
{
	for (const FString& Path : InSourceList)
	{
		if (!StaticMeshCache.Contains(Path))
		{
			StaticMeshCache.Add(Path, nullptr);
		}
	}
}

void AKMInstancedSceneItemActor::AsyncLoadMeshes()
{
	TArray<FSoftObjectPath> RequestList;
	StaticMeshResultList.Empty();
	for (const auto& Pair : StaticMeshCache)
	{
		const FString& SourcePath = Pair.Key;
		UStaticMesh* StaticMesh = Pair.Value;
		if (!StaticMesh) // not cached yet
		{
			FSoftObjectPath SoftPath = SourcePath;
			RequestList.Add(SoftPath);
			//UE_LOG(LogKMInstancedSceneItemActor, Log, TEXT("Async loading: %s"), *SourcePath);
			StaticMeshResultList.Add(FResult{ TSoftObjectPtr<UStaticMesh>(SoftPath) });
		}
	}
	if (RequestList.Num() > 0)
	{
		UE_LOG(LogKMInstancedSceneItemActor, Log, TEXT("Request async loading static mesh: %d total."), StaticMeshResultList.Num());
		StreamableHandle = StreamableManager.RequestAsyncLoad(RequestList, FStreamableDelegate::CreateUObject(this, &AKMInstancedSceneItemActor::FinishedLoadMeshes));
	}
}

void AKMInstancedSceneItemActor::FinishedLoadMeshes()
{
	int32 FailedCount = 0;
	SIZE_T LoadedBytes = 0, LoadedMeshBytes = 0, LoadedMaterialBytes = 0, LoadedTextureBytes = 0;
	for (const FResult& Result : StaticMeshResultList)
	{
		UStaticMesh** MeshPtr = StaticMeshCache.Find(Result.Mesh.GetLongPackageName());
		if (MeshPtr && !(*MeshPtr))
		{
			UStaticMesh* LoadedMesh = Result.Mesh.Get();
			if (LoadedMesh)
			{
				*MeshPtr = LoadedMesh;
				GetMeshResourceSize(LoadedMesh, LoadedMeshBytes, LoadedMaterialBytes, LoadedTextureBytes);
			} 
			else
			{
				++FailedCount;
			}
			//UE_LOG(LogKMInstancedSceneItemActor, Log, TEXT("Finished loading: %s"), *Result.Path);
		}
	}
	LoadedBytes = LoadedMeshBytes + LoadedMaterialBytes + LoadedTextureBytes;
	UE_LOG(LogKMInstancedSceneItemActor, Log, TEXT("Finished loading static mesh: %d succeed, %d total, memory used: %.3fMB.(Mesh: %.3fMB, Material: %.3fMB, Texture: %.3fMB)"), 
		StaticMeshCache.Num() - FailedCount, StaticMeshCache.Num(), LoadedBytes / (1024.0f * 1024.0f), LoadedMeshBytes / (1024.0f * 1024.0f), LoadedMaterialBytes / (1024.0f * 1024.0f), LoadedTextureBytes / (1024.0f * 1024.0f));
	StaticMeshResultList.Empty();	
	StreamableHandle = nullptr; // Reset the handle
}

UStaticMesh* AKMInstancedSceneItemActor::SyncLoadMesh(const TSoftObjectPtr<UStaticMesh>& Mesh)
{
	// Load mesh synchronous if representMesh is not specified. WARNING! This is not the common case, specify representMesh in blueprint.
	UE_LOG(LogKMInstancedSceneItemActor, Warning, TEXT("Synchronous loading '%s', specify representMesh in blueprint to enable Asynchronous loading!"), *Mesh.GetLongPackageName());
	UStaticMesh* LoadedMesh = Mesh.LoadSynchronous();
	FString Path = Mesh.GetLongPackageName();
	StaticMeshCache.FindOrAdd(Path) = LoadedMesh;
	return LoadedMesh;
}

TSharedPtr<FStreamableHandle> AKMInstancedSceneItemActor::AsyncLoadMesh(const TSoftObjectPtr<UStaticMesh>& Mesh)
{
	UE_LOG(LogKMInstancedSceneItemActor, Verbose, TEXT("Asynchronous loading '%s' Start."), *Mesh.GetLongPackageName());
	TWeakObjectPtr<AKMInstancedSceneItemActor> Actor(this);
	return StreamableManager.RequestAsyncLoad(Mesh.ToSoftObjectPath(), [Actor, Mesh]()
	{
		if (Actor.IsValid())
		{
			UStaticMesh* LoadedMesh = Mesh.Get();
			if (LoadedMesh)
			{
				FString Path = Mesh.GetLongPackageName();
				Actor->StaticMeshCache.FindOrAdd(Path) = LoadedMesh;
				Actor->RefreshInstancedStaticMesh(LoadedMesh);
				UE_LOG(LogKMInstancedSceneItemActor, Verbose, TEXT("Asynchronous loading '%s' Done."), *Mesh.GetLongPackageName());
			}
		}
	});
}

USkeletalMesh* AKMInstancedSceneItemActor::SyncLoadSkeletalMesh(const TSoftObjectPtr<USkeletalMesh>& Mesh)
{
	UE_LOG(LogKMInstancedSceneItemActor, Warning, TEXT("Synchronous loading '%s', specify representMesh in blueprint to enable Asynchronous loading!"), *Mesh.GetLongPackageName());
	USkeletalMesh* LoadedMesh = Mesh.LoadSynchronous();
	FString Path = Mesh.GetLongPackageName();
	SkeletalMeshCache.FindOrAdd(Path) = LoadedMesh;
	return LoadedMesh;
}

TSharedPtr<FStreamableHandle> AKMInstancedSceneItemActor::AsyncLoadSkeletalMesh(const TSoftObjectPtr<USkeletalMesh>& Mesh)
{
	UE_LOG(LogKMInstancedSceneItemActor, Verbose, TEXT("Asynchronous loading '%s' Start."), *Mesh.GetLongPackageName());
	TWeakObjectPtr<AKMInstancedSceneItemActor> Actor(this);
	return StreamableManager.RequestAsyncLoad(Mesh.ToSoftObjectPath(), [Actor, Mesh]()
	{
		if (Actor.IsValid())
		{
			USkeletalMesh* LoadedMesh = Mesh.Get();
			if (LoadedMesh)
			{
				FString Path = Mesh.GetLongPackageName();
				Actor->SkeletalMeshCache.FindOrAdd(Path) = LoadedMesh;
				Actor->RefreshSkeletalMeshes(LoadedMesh);
				UE_LOG(LogKMInstancedSceneItemActor, Verbose, TEXT("Asynchronous loading '%s' Done."), *Mesh.GetLongPackageName());
			}
		}
	});
}

void AKMInstancedSceneItemActor::NoFlushWaitLoadMeshes(TSharedPtr<FStreamableHandle> Handle)
{
	SetAsyncLoadingReturnImmediatelyWhenAnyPackageFinished(true);
	if (Handle.IsValid())
	{
		while (!Handle->HasLoadCompleted())
		{
			ProcessAsyncLoading(false, false, 0.0f);
		}
	}
	SetAsyncLoadingReturnImmediatelyWhenAnyPackageFinished(false);
	FinishedLoadMeshes();
}

void AKMInstancedSceneItemActor::GetMeshResourceSize(UStaticMesh* Mesh, SIZE_T& MeshSize, SIZE_T& MaterialSize, SIZE_T& TextureSize) const
{
	MeshSize += Mesh->GetResourceSizeBytes(EResourceSizeMode::Exclusive);
	for (FStaticMaterial& Material : Mesh->StaticMaterials)
	{
		TArray<UTexture*> Textures;
		if (Material.MaterialInterface)
		{
			Material.MaterialInterface->GetUsedTextures(Textures, EMaterialQualityLevel::High, true, ERHIFeatureLevel::ES3_1, true);
			MaterialSize += Material.MaterialInterface->GetResourceSizeBytes(EResourceSizeMode::Exclusive);
			for (UTexture* Texture : Textures)
			{
				if (Texture)
				{
					TextureSize += Texture->GetResourceSizeBytes(EResourceSizeMode::Exclusive);
				}
			}
			Textures.Empty(Textures.Num());
		}
	}
}

//bool AKMInstancedSceneItemActor::bMockMode = false;

//void AKMInstancedSceneItemActor::AddReferencedObjects(FReferenceCollector& Collector)
//{
//    Collector.AddReferencedObjects(StaticMeshCache);
//}
