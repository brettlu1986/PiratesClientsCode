// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "GameAvatarPartProcessNodeBase.h"
#include "Game/Merge/KMShipMeshMerge.h"
#include "GameAvatarPartMeshMergeNode.generated.h"


UCLASS(Blueprintable)
class COMMON_API UGameAvatarPartMeshMergeNode : public UGameAvatarPartProcessNodeBase
{
	GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetClearRootComponentMesh(bool bClear) { bClearRootComponentMesh = bClear; }
	//yangjingzhao for 4.20
    //UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual void AddSkeletalMesh(USkeletalMesh* SkeletalMesh, FName BoneName, FTransform Offset, USkeletalMeshComponent* MeshComponent) override;
	//yangjingzhao for 4.20
    //UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual void AddStaticMesh(UStaticMesh* StaticMesh, FName BoneName, FTransform Offset, UStaticMeshComponent* MeshComponent) override;
	//yangjingzhao for 4.20
    //UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual void AddShipFlag(UStaticMesh* StaticMesh, FName BoneName, FTransform Offset, UStaticMeshComponent* MeshComponent) override;

protected:
    virtual void RefreshSelf_Implementation() override;
protected:
    UPROPERTY(BlueprintReadWrite, Category = "GameAvatar")
    USkeletalMeshComponent* RootComponent;
    bool bClearRootComponentMesh;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    USkeletalMeshComponent* SkeletalMeshComponent;

    TArray<FSkeletalMergeParameter> AllSkeletals;
    TArray<FStaticMergeParameter> AllStatics;
    TArray<UStaticMeshComponent*> ShipFlags;
    TArray<UMeshComponent*> AllComopnents;
    TArray<UStaticMeshComponent*> AllStaticMeshComponents;

   // USkeletalMeshComponent* SkeletalMeshComponent;
    UStaticMeshComponent* ShipFlagComponent;
    UStaticMeshComponent* MergeStaticMeshComponent;
    UPROPERTY(BlueprintReadWrite, Category = "GameAvatar")
    bool bUsedMerge;
    UPROPERTY(BlueprintReadWrite, Category = "GameAvatar")
    FName ShipBaseSlot;
};