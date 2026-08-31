// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ActorComponent.h"
#include "Engine/StreamableManager.h"
#include "GameAvatarComponentBase.generated.h"


struct FGameAvatarPartTabFileData;
class UGameAvatarPartProcessNodeBase;
class UAvatarAssetLoader;
class UGameAvatarComponentBase;


UCLASS()
class UAvatarAssetLoader : public UObject
{
    GENERATED_UCLASS_BODY()
public:

    bool Init(UGameAvatarComponentBase* ComponentBase);
    void Uninit();
    bool LoadAssetsAsync(const TArray<FString>& Assets);
    void Clear();
    void BeginDestroy() override;

private:
    void OnVerifyAllAssetLoaded();

    UFUNCTION()
    void OnAssetLoadFinished();

private:
    const int32 AsyncLoadPriority = 100;

private:
    UGameAvatarComponentBase* GameAvatarComponentBase;
    FStreamableManager AssetLoader;
    TMap<FName, TSharedPtr<FStreamableHandle>> AsyncLoadHandlers;
    uint32 bInited : 1;
};


UCLASS(Blueprintable)
class COMMON_API UGameAvatarComponentBase : public UActorComponent
{
	GENERATED_UCLASS_BODY()

public:
    DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnCommitFinishDelegate);
    UPROPERTY()
    FOnCommitFinishDelegate OnCommitFinishDelegate;

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    UGameAvatarPartProcessNodeBase* AddNode(
        UGameAvatarPartProcessNodeBase* Parent,
        const FName& PartName,
        const FName& DataKeyName,
        TSubclassOf<UGameAvatarPartProcessNodeBase> UC,
        bool PassDirtyToParent,
        bool PassDirtyToChildren,
        bool NeedSaveToTabFile);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    UGameAvatarPartProcessNodeBase* AddRootNode();

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    UGameAvatarPartProcessNodeBase* GetRootNode() { return RootNode; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    bool AddPartByName(const FName& PartName, int PartID, bool bCommit, int nPriority = 0, bool bMerged = true);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    bool AddPartByType(int PartType, int PartID, bool bCommit);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    bool AddPartByID(int PartID, bool bCommit);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    bool RemovePartByName(const FName& PartName, bool bCommit);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    bool RemovePartByType(int PartType, bool bCommit);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    bool RemovePartByID(int PartID, bool bCommit);

    UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "GameAvatar")
    void Refresh();

    UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "GameAvatar")
    void Commit();

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void CommitAsync();

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    UGameAvatarPartProcessNodeBase* ApplyNodeRawData(const FName& PartName, const FName& DataKeyName, const FString& RawData);

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void SetOwnerActorOfNode(AActor* Owner) { OwnerActorOfNode = Owner; }

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void ForceLoadPartsMips();

    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    AActor* GetOwnerActorOfNode() { return OwnerActorOfNode; }

    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    void Uninit();

    void OnAsyncAssetsLoaded();
protected:
    void CollectResource();

    typedef TArray<UGameAvatarPartProcessNodeBase*> TPartNodeArray;
    typedef TArray<FString> TPendingLoadResourceArray;
    TMap<FName, TPartNodeArray> NodeOfPartMap;
    TMap<FName, const FGameAvatarPartTabFileData*> ActivedParts;
    
    AActor* OwnerActorOfNode;
    TPendingLoadResourceArray PendingLoadResources;

    UPROPERTY()
    UAvatarAssetLoader* AvatarAssetLoader;

    UPROPERTY(BlueprintReadOnly, Category = "GameAvatar")
    UGameAvatarPartProcessNodeBase* RootNode;
};