// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameAvatarPartProcessNodeBase.generated.h"

class UGameAvatarComponentBase;

UCLASS(Blueprintable)
class COMMON_API UGameAvatarPartProcessNodeBase : public UObject
{
	GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    UGameAvatarPartProcessNodeBase* GetParentNode() { return Parent; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    AActor* GetActor() { return Actor; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FName& GetDataKeyName() const { return DataKeyName; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    bool NeedSaveToTabFile() { return NeedSave; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    UGameAvatarPartProcessNodeBase* FindChild(const FName& TempDataKeyName);
    
    void Init(AActor* TempActor, const FName& TempDataKeyName,
        UGameAvatarPartProcessNodeBase* TempParent,
        bool TempPassDirtyToParent, bool TempPassDirtyToChildren, 
        bool NeedSaveToTabFile);

    void Uninit();

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    bool ApplyRawData(const FString& In);

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    bool GetRawData(FString& Out);

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void Refresh(bool bIncludeChildren, bool bRecursion, bool bForceRefreshSelf);

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void CollectResources(TArray<FString>& OutResources);

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void DebugCostTime(float TotalCost);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void MarkDirty();

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    bool IsDirty() { return Dirty; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void GetChildren(TArray<UGameAvatarPartProcessNodeBase*>& Out, bool bRecursion);

    virtual UWorld* GetWorld() const override;

	UFUNCTION(BlueprintCallable, Category = "GameAvatar")
	void SetPartID(int nInID);

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    int GetPartID();

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetPartPriority(int nPriority);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    int GetPartPriority();

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetPartMergeFlag(bool bMerge);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    bool GetPartMergeFlag();


    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void GetAsset(UGameAvatarPartProcessNodeBase* From);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual void AddSkeletalMesh(USkeletalMesh* SkeletalMesh, FName BoneName, FTransform Offset, USkeletalMeshComponent* MeshComponent) {}

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual void AddStaticMesh(UStaticMesh* StaticMesh, FName BoneName, FTransform Offset,UStaticMeshComponent* MeshComponent) {}

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual void AddShipFlag(UStaticMesh* StaticMesh, FName BoneName, FTransform Offset, UStaticMeshComponent* MeshComponent) {}

    virtual void SetForceStreaming();
protected:
    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    bool SetRawData(const FString& In);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void AddChild(UGameAvatarPartProcessNodeBase* Child);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void RemoveChild(UGameAvatarPartProcessNodeBase* Child);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void ClearDirty() { Dirty = false; }

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void RefreshSelf();

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void OnInit();

    UFUNCTION(BlueprintNativeEvent, Category = "GameAvatar")
    void OnUninit();

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    UWorld* GetCurrentWorld();


protected:
    bool NeedSave;
    FName DataKeyName;
    AActor* Actor;
    UGameAvatarPartProcessNodeBase* Parent;
    bool PassDirtyToParent;
    bool PassDrityToChildren;
    bool Dirty;
    bool Processing;
    int  Priority;
    bool IsMerge;
	int	 PartID;


    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    TArray<UGameAvatarPartProcessNodeBase*> Children;
};