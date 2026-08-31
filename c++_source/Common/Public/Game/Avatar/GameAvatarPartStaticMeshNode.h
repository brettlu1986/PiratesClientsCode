// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "GameAvatarPartProcessNodeBase.h"
#include "GameAvatarPartStaticMeshNode.generated.h"


UCLASS(Blueprintable)
class COMMON_API UGameAvatarPartStaticMeshNode : public UGameAvatarPartProcessNodeBase
{
	GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetAutoCreateStaticMeshComponent(bool bCreated) { AutoCreateStaticMeshComponent = bCreated; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetStaticMeshComponent(UStaticMeshComponent* Component) { StaticMeshComponent = Component; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetRelativeLocation(const FVector& Loc) { Location = Loc; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FVector& GetRelativeLocation() const { return Location; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    FVector GetWorldLocation() const;

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetRelativeRotation(const FRotator& Rot) { Rotation = Rot; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FRotator& GetRelativeRotation() const { return Rotation; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    FRotator GetWorldRotation() const;

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetRelativeScale(const FVector& TempScale) { Scale = TempScale; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FVector& GetRelativeScale() const { return Scale; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    FVector GetWorldScale() const;

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetMeshPath(const FString& Path) { MeshPath = Path; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FString& GetMeshPath() const { return MeshPath; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetTransformComponent(USceneComponent* Component);

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    USceneComponent* GetTransformComponent() { return TransformComponent; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetSlotName(const FName& Name) { SlotName = Name; }

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    const FName& GetSlotName() const { return SlotName; }

    virtual void GetAsset_Implementation(UGameAvatarPartProcessNodeBase* From) override;
    virtual void CollectResources_Implementation(TArray<FString>& OutResources) override;
protected:
    virtual bool SetRawData_Implementation(const FString& In) override;
    virtual bool GetRawData_Implementation(FString& Out) override;
    virtual void RefreshSelf_Implementation() override;
    void Reset();

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    virtual UStaticMeshComponent* CreateStaticMeshComponent();

protected:
    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    UStaticMeshComponent* StaticMeshComponent;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    FString MeshPath;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    FVector Location;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    FRotator Rotation;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    FVector Scale;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    bool AutoCreateStaticMeshComponent;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    USceneComponent* TransformComponent;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    FName SlotName;
};