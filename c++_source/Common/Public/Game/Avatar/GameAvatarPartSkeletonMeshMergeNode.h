// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Game/Merge/KMCharacterMeshMerge.h"
#include "GameAvatarPartSkeletonMeshNode.h"
#include "Game/Merge/KMMergeConfig.h"
#include "GameAvatarPartSkeletonMeshMergeNode.generated.h"


UCLASS(Blueprintable)
class COMMON_API UGameAvatarPartSkeletonMeshMergeNode : public UGameAvatarPartSkeletonMeshNode
{
	GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetClearRootComponentMesh(bool bClear) { bClearRootComponentMesh = bClear; }


protected:
    virtual void RefreshSelf_Implementation() override;

	USkeletalMesh* RefreshLoadMesh(UGameAvatarPartSkeletonMeshNode* MeshNode);

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void SetMeshMaterial(USkeletalMesh* SkeletalMesh, const FString& InMaterialPath);

    virtual void SetForceStreaming() override;

protected:
    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    USkeleton* RootSkeleton;

	UPROPERTY()
    TArray<USkeletalMeshComponent*> SkeletalMeshComponents;

    UPROPERTY(BlueprintReadWrite, Category = "GameAvatar")
    bool bMergeSkeletalMesh;

	//UPROPERTY()
	//UMaterialInterface* DynamicMaterialIns;

	bool bClearRootComponentMesh;

	// Skeletal Mesh Merging
	// for waiting the merging result
	FTimerHandle TimerHandle;
	// a future carrying the merging result
	TFuture<FMergingResult> ResultFuture;
	// all processes that must be carried in game thread
	void FinalizeMerge();
	// engine default merging implementation
	void EngineDefaultMerge(TArray<USkeletalMesh*>& InSrcMeshes);
	// master pose way
	void UseMasterPose(TArray<FUnMergedSkeletalMeshPart>& InSrcMeshes);
	//use unmerged skeletalmesh
	void UseUnMergedMesh(TArray<FUnMergedSkeletalMeshPart>& InSrcMeshes);
	USkeletalMeshComponent* UseUnmergeMasterPose(FUnMergedSkeletalMeshPart* Part);


	// are meshes ready to be merged
	bool CheckSrcMeshValidity(const TArray<USkeletalMesh*>& InMeshes);

	bool CheckIsHairMesh(USkeletalMesh* InMesh);

	bool CheckIsHeadMesh(USkeletalMesh* InMesh);

	void UROForHair(USkeletalMeshComponent* InCom);

	void ComponentCustomize(USkeletalMeshComponent* InCom);

private:
	// create textures for merging and collect source textures
	UPROPERTY()
	TArray<FMergedTexture> MergedTextures;

	UPROPERTY()
	TArray<FGatheredSourceTexture> SourceTextures;
	
	UPROPERTY()
	bool bMergedFirstTime;

	UPROPERTY()
	TArray<FUnMergedSkeletalMeshPart> UnMergesMeshes;

	UPROPERTY()
	TArray<USkeletalMesh*> Meshes;

	UPROPERTY()
	FString HairCopyPoseAB;

    UPROPERTY()
    bool bForceStreaming;

	UPROPERTY()
	TArray<FCustomizeParameterPair> ParaPairs;

	// ~
};