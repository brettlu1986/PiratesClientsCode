// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "GameAvatarPartProcessNodeBase.h"
#include "Game/Merge/KMMergeConfig.h"
#include "GameAvatarPartSkeletonMeshNode.generated.h"


UCLASS(Blueprintable)
class COMMON_API UGameAvatarPartSkeletonMeshNode : public UGameAvatarPartProcessNodeBase
{
	GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FString& GetMeshPath() const { return MeshPath; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    USkeletalMeshComponent* GetSkeletalMeshComponent() { return Component; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetRootComponent(USkeletalMeshComponent* Comp) { RootComponent = Comp; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetAutoCreateSkeletalMeshComponent(bool bCreated) { AutoCreateSkeletalMeshComponent = bCreated; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetSlotName(const FName& Name) { SlotName = Name; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    const FName& GetSlotName() const { return SlotName; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetMaterialPath(const FString Name) { MaterialPath = Name; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetMeshPath(const FString Name) { MeshPath = Name; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FString&  GetMaterialPath() const { return MaterialPath; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FCustomizeParameterPair& GetMaterialParam() const { return ParameterPair; }

    virtual void GetAsset_Implementation(UGameAvatarPartProcessNodeBase* From) override;
    virtual void CollectResources_Implementation(TArray<FString>& OutResources) override;

protected:
    virtual bool SetRawData_Implementation(const FString& In) override;
    virtual bool GetRawData_Implementation(FString& Out) override;
    virtual void RefreshSelf_Implementation() override;

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual USkeletalMeshComponent* CreateSkeletalMeshComponent();

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual void LoadSkeletalMesh();

protected:
    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    USkeletalMeshComponent* Component;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    USkeletalMeshComponent* RootComponent;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    FString MeshPath;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    bool AutoCreateSkeletalMeshComponent;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    FName SlotName;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    FString MaterialPath;

    UPROPERTY(BlueprintReadWrite, Category = "GameAvatar")
    FCustomizeParameterPair ParameterPair;
};