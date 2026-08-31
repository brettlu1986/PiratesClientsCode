// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "GameAvatarPartStaticMeshNode.h"
#include "GameAvatarPartStaticMeshMergeNode.generated.h"


UCLASS(Blueprintable)
class COMMON_API UGameAvatarPartStaticMeshMergeNode : public UGameAvatarPartStaticMeshNode
{
	GENERATED_UCLASS_BODY()

protected:
    virtual void RefreshSelf_Implementation() override;

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void GetMergedNodes(TArray<UGameAvatarPartStaticMeshNode*>& Out);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetIncludebRecursionChildren(bool bRecursion) { IncludebRecursionChildren = bRecursion; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    static void MergeMesh(const TArray<UStaticMesh*>& MeshesToMerge, const TArray<FTransform>& ToWorldTransforms, const FVector& Pivot, UStaticMesh*& OutMesh);

protected:
    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    UStaticMesh* GetNodeStaticMesh(UGameAvatarPartStaticMeshNode* Node);

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    FTransform GetNodeWorldTransform(UGameAvatarPartStaticMeshNode* Node);

    // Temp
    //UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    //UInstancedStaticMeshComponent* InstanceMeshComponent;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    bool IncludebRecursionChildren;
};