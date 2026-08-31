// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Dom/JsonValue.h"
#include "KMJsonExportComponent.generated.h"


UCLASS(Blueprintable, Transient, meta = (BlueprintSpawnableComponent))
class ENGINEEXT_API UKMJsonExportComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

protected:
    struct FKMJsonNode
    {
        TSharedPtr<FJsonObject> JsonObject;
        TSharedPtr<FJsonValue> JsonValue;
        TArray< TSharedPtr<FJsonValue> >* JsonValueArray;
        FString JsonKeyName;

        int SelfIndex;
        int ParentIndex;
        TArray<int> ChlidIndices;

        FKMJsonNode()
            : JsonValueArray(nullptr)
            , ParentIndex(-1)
        {
        }

        ~FKMJsonNode()
        {
            if (JsonValueArray)
            {
                delete JsonValueArray;
            }
        }
    };

    FKMJsonNode* NewNode(const FString& JsonKeyName, int ParentIndex);

public:
    bool ExportToJsonObject(TSharedPtr<FJsonObject>& OutObject);
    const bool IsCanceled() const { return Canceled; }

public:
    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    bool ExportToJsonString(FString& Out);

    UFUNCTION(BlueprintImplementableEvent, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void OnConstructNodeTree(int RootNodeIndex);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    int AddNode(int ParentNodeIndex, const FString& JsonKeyName);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    int AddArrayNode(int ParentNodeIndex, const FString& JsonKeyName);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void AddPropertyValue(UObject* Object, int ParentNodeIndex, const FString& PropertyName, const FString& JsonKeyName, bool bExcludeFromOtherProperties=true);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void AddAllPropertyValuesOfSelfComponent(int ParentNodeIndex);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void AddAllPropertyValuesOfObject(UObject* Object, int ParentNodeIndex, const FString& StopClassName);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void MarkPropertyNotExport(const FString& PropertyName);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void AddStringValue(int NodeIndex, const FString& JsonKeyName, const FString& Value);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void AddIntValue(int NodeIndex, const FString& JsonKeyName, int Value);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void AddBoolValue(int NodeIndex, const FString& JsonKeyName, bool Value);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void AddFloatValue(int NodeIndex, const FString& JsonKeyName, float Value);

    UFUNCTION(BlueprintCallable, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void Cancel();

protected:
    virtual bool CreateJsonValue(const void* Object, FProperty* Property, TSharedPtr<FJsonValue>& OutJsonValue);
    bool ConstructJsonTree(TSharedPtr<FJsonObject>& OutObject);
    bool AddPropertyValueImp(UObject* Object, int ParentNodeIndex, FProperty* Property, const FString& JsonKeyName);
    bool AddAllPropertyValueInObject(UObject* Object, int ParentNodeIndex, const FString& StopClassName);

protected:
    UPROPERTY(EditAnywhere, Category = "KMJsonExportComponent", meta = (KMJsonNotExport = "true"))
    TArray<FString> PropertiesNotExported;

    TArray<FKMJsonNode> TempNodes;
    bool Canceled;
};
