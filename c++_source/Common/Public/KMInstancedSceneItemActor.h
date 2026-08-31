// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Engine/StreamableManager.h"
#include "KMInstancedSceneItemActor.generated.h"

DECLARE_STATS_GROUP(TEXT("SceneItem"), STATGROUP_SceneItem, STATCAT_Advanced);
DECLARE_CYCLE_STAT(TEXT("SceneItemActor Tick"), STAT_SceneItemActorTick, STATGROUP_SceneItem);
DECLARE_CYCLE_STAT(TEXT("SceneItemActor UpdateLOD"), STAT_SceneItemActorUpdateLOD, STATGROUP_SceneItem);
DECLARE_DWORD_COUNTER_STAT(TEXT("Item Num"), STAT_SceneItemNum, STATGROUP_SceneItem);
DECLARE_DWORD_COUNTER_STAT(TEXT("Item Tris"), STAT_SceneItemTris, STATGROUP_SceneItem);
DECLARE_DWORD_COUNTER_STAT(TEXT("Item DrawCalls"), STAT_SceneItemDraws, STATGROUP_SceneItem);
DECLARE_DWORD_COUNTER_STAT(TEXT("Grouped Num"), STAT_SceneItemGroupedNum, STATGROUP_SceneItem);
DECLARE_DWORD_COUNTER_STAT(TEXT("Grouped Tris"), STAT_SceneItemGroupedTris, STATGROUP_SceneItem);
DECLARE_DWORD_COUNTER_STAT(TEXT("Cached Num"), STAT_SceneItemCachedNum, STATGROUP_SceneItem);

class UStaticMesh;
class UInstancedStaticMeshComponent;

UCLASS()
class COMMON_API AKMInstancedSceneItemActor : public AActor
{
	GENERATED_BODY()
	AKMInstancedSceneItemActor();

public:
	UFUNCTION(BlueprintCallable)
	static void InitStaticMeshSources(const TArray<FString>& InSourceList);

	UFUNCTION(BlueprintCallable)
	static void SetMockMode();

public:
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
	virtual void Tick(float DeltaSeconds) override;

public:
	UFUNCTION(BlueprintCallable)
	void SpawnSceneItem(AActor* Trigger, const FString& Path, const FTransform& WorldTransform);

	UFUNCTION(BlueprintCallable)
	bool DestroySceneItem(AActor* Trigger);
	
	UFUNCTION(BlueprintCallable)
	void SetHighlighting(AActor* Trigger, bool bVisible);

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UStaticMesh* RepresentMesh = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float GroupScreenSize = 0.01f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float GroupDistance = 10.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float RepresentRatio = 0.6f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float CullDistance = 80000.0f;

private:
	struct ItemGroup
	{
		FBoxSphereBounds Bounds;
		TSet<AActor*> Triggers;
	};

	struct ItemInstance
	{
		ItemInstance(AActor* InItemTrigger, const TSoftObjectPtr<UStaticMesh>& InMesh, const FTransform& InWorldTransform) :
			ItemTrigger(InItemTrigger), Mesh(InMesh), SkeletalMeshComponent(nullptr), Index(-1), WorldTransform(InWorldTransform), Group(nullptr), IsGrouped(false), IsDark(false) {}
		ItemInstance(AActor* InItemTrigger, const TSoftObjectPtr<USkeletalMesh>& InMesh, const FTransform& InWorldTransform) :
			ItemTrigger(InItemTrigger), SkeletalMesh(InMesh), SkeletalMeshComponent(nullptr), Index(-1), WorldTransform(InWorldTransform), Group(nullptr), IsGrouped(false), IsDark(false) {}
		AActor* ItemTrigger;
		TSoftObjectPtr<UStaticMesh> Mesh;
		TSoftObjectPtr<USkeletalMesh> SkeletalMesh;
		USkeletalMeshComponent* SkeletalMeshComponent;
		int32 Index;
		FTransform WorldTransform;
		ItemGroup* Group;
		bool IsGrouped;
		bool IsDark;
	};

	struct DrawComponent
	{
		DrawComponent() : Renderer(nullptr) {}
		UInstancedStaticMeshComponent* Renderer;
		TArray<int32> FreeIndices;
	};

	struct ItemDrawComponent
	{
		DrawComponent Component;
		DrawComponent DarkComponent;
		UMaterialInstanceDynamic* DarkMaterial;
		float Bright;
		TSet<AActor*> InstancedTriggers;
		TSet<AActor*> GroupedTriggers;
	};

	struct ItemDrawSkeletalComponent
	{
		TArray<USkeletalMeshComponent*> UnloadedSkeletalComponents;
	};

private:
	void UpdateSceneItemLOD();
	void GroupSceneItem(AActor* Trigger);
	void UnGroupSceneItem(AActor* Trigger);
	void SpawnStaticSceneItem(AActor* Trigger, const FString& Path, const FTransform& WorldTransform);
	void SpawnSkeletalSceneItem(AActor* Trigger, const FString& Path, const FTransform& WorldTransform);
	UInstancedStaticMeshComponent* CreateInstancedStaticMeshComponent(UStaticMesh* Mesh, FName Name);
	void CreateInstancedStaticMeshComponent(UStaticMesh* Mesh, FName Name, ItemDrawComponent* OutComponent);
	void CreateInstancedDarkComponent(UStaticMesh* Mesh, FName Name, ItemDrawComponent* OutComponent);
	USkeletalMeshComponent* CreateSkeletalMeshComponent(USkeletalMesh* Mesh, FName Name);
	void RefreshInstancedStaticMesh(UStaticMesh* Mesh);
	void RefreshSkeletalMeshes(USkeletalMesh* Mesh);
	void JointToGroup(ItemInstance& Item, UStaticMesh* Mesh);
	float CalcScreenSize(FVector ViewPoint, const FBoxSphereBounds& Bounds) const;
	void AddTriggerInstance(AActor* Trigger, const FTransform& WorldTransform);
	bool RemoveTriggerInstance(AActor* Trigger);
	int32 AddTriggerInstanceTo(DrawComponent& Component, const FTransform& WorldTransform);
	bool RemoveTriggerInstanceFrom(DrawComponent& Component, int32 Index);

private:
	TMap<TSoftObjectPtr<UStaticMesh>, ItemDrawComponent> MeshDrawComponentMap;
	TMap<TSoftObjectPtr<USkeletalMesh>, ItemDrawSkeletalComponent> SkeletalMeshDrawComponentMap;
	TMap<AActor*, ItemInstance> TriggerItemInstMap;
	TIndirectArray<ItemGroup> ItemGroupList;
	UInstancedStaticMeshComponent* RepresentMeshComponent;
	FTimerHandle UpdateSceneItemLODHandle;
	FBoxSphereBounds RepresentBounds;
	FVector RepresentSize;
	int32 CurrentShowState = 1;
	int32 CurrentGroupState = 1;

private: // UStaticMesh Cache
	void SetSourceList(const TArray<FString>& InSourceList);
	void AsyncLoadMeshes();
	void FinishedLoadMeshes();
	UStaticMesh* SyncLoadMesh(const TSoftObjectPtr<UStaticMesh>& Mesh);
	TSharedPtr<FStreamableHandle> AsyncLoadMesh(const TSoftObjectPtr<UStaticMesh>& Mesh);
	USkeletalMesh* SyncLoadSkeletalMesh(const TSoftObjectPtr<USkeletalMesh>& Mesh);
	TSharedPtr<FStreamableHandle> AsyncLoadSkeletalMesh(const TSoftObjectPtr<USkeletalMesh>& Mesh);
	void NoFlushWaitLoadMeshes(TSharedPtr<FStreamableHandle> Handle);
	void GetMeshResourceSize(UStaticMesh* Mesh, SIZE_T& MeshSize, SIZE_T& MaterialSize, SIZE_T& TextureSize) const;

	UPROPERTY()
	TMap<FString, UStaticMesh*> StaticMeshCache;
	UPROPERTY()
	TMap<FString, USkeletalMesh*> SkeletalMeshCache;
	FStreamableManager StreamableManager;
	struct FResult
	{
		TSoftObjectPtr<UStaticMesh> Mesh;
	};
	TArray<FResult> StaticMeshResultList;
	TSharedPtr<FStreamableHandle> StreamableHandle;
	//static bool bMockMode;
};
