// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Engine/BlueprintGeneratedClass.h"
#include "ComponentDataSerializer.generated.h"

class USCS_Node;

USTRUCT(BlueprintType)
struct COMMON_API FGameComponentSavedData
{
    GENERATED_USTRUCT_BODY();

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
    FName VariableName;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
    UClass* Class;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
    int TagFlag;

    //UPROPERTY()
    //FString ClassPathName;

    //UPROPERTY()
    //EObjectFlags TemplateFlags;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
    FName ParentComponentName;

    UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
    FName AttachToName;

    UPROPERTY()
    FBlueprintCookedComponentInstancingData InstancedData;

    UPROPERTY()
    TArray<uint8> RawData;

    UPROPERTY()
    TArray<FName> Names;

    UPROPERTY()
    TArray<UObject*> Objects;

    FGameComponentSavedData()
        : Class(nullptr)
        , TagFlag(0)        
        //, TemplateFlags(RF_Public | RF_Transactional | RF_ArchetypeObject | RF_WasLoaded | RF_LoadCompleted)        
    {
    }

    inline const int GetAdditionalMemorySize() const
    {
        return InstancedData.ChangedPropertyList.GetAllocatedSize()
            + RawData.GetAllocatedSize()
            + Names.GetAllocatedSize()
            + Objects.GetAllocatedSize();
    }

    inline const FString GetInfo() const
    {
        return FString::Printf(TEXT("name: %s, class: %s, tag: %d, parent: %s, attachto: %s"),
            *VariableName.ToString(),
            *Class->GetName(),
            TagFlag,
            *ParentComponentName.ToString(),
            *AttachToName.ToString());
    }
};

UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UComponentDataSerializer : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Game", meta = (CallInEditor = "true"))
    bool Save(UClass* ActorClass);

    UFUNCTION(BlueprintCallable, Category = "Game")
    bool LoadSyn(const TArray<FName>& Tags, bool bBeginPlay);

    UFUNCTION(BlueprintCallable, Category = "Game")
    bool LoadAsyn(const TArray<FName>& Tags, int Priority, bool ManualBeginPlay, bool SeparateBeginPlay);

    UFUNCTION(BlueprintCallable, Category = "Game")
    void FlushAsynRequests();

    UFUNCTION(BlueprintCallable, Category = "Game")
    void CancelAsynRequests();

public:
    UPROPERTY(EditDefaultsOnly)
    TArray<FName> SavedTags;

private:
    int GetTagFlag(const FName& Tag);
    int GetTagFlag(int SavedTagIndex);
    void TryActorBeginPlayManually();
    int GetComponentExportedTag(UActorComponent* Component);
    UActorComponent* CreateComponent(FGameComponentSavedData& Data);    
    int CollectDataIndicesByTag(const TArray<FGameComponentSavedData>& AllDatas, const TArray<FName>& Tags, int* OutDataIndices);
    virtual void OnComponentDestroyed(bool bDestroyingHierarchy) override;
    virtual void Serialize(FArchive& Ar) override;

#if WITH_EDITOR
    void DestroyOldEditorComponents();
#endif

private:
    UPROPERTY(VisibleDefaultsOnly)
    TArray<FGameComponentSavedData> ComponentDatas;

    UPROPERTY(Transient)
    TArray<UActorComponent*> TempInstancedComponents;

    TArray<int> TaskHandles;
    TArray<uint8> TaskRawMemory;
    bool bFinished;
};