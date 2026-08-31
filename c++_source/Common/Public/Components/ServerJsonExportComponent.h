// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMJsonExportComponent.h"
#include "ServerJsonExportComponent.generated.h"

UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UServerJsonExportComponent : public UKMJsonExportComponent
{
    GENERATED_UCLASS_BODY()

public:
    const FString& GetJsonFilePostfix() const { return JsonFilePostfix; }
    const FString& GetJsonTypeName() const { return JsonTypeName; }
    const bool NeedExportToLuaFile() const { return ExportToLuaFile; }

    UFUNCTION(BlueprintCallable, Category = "UServerJsonExportComponent", meta = (CallInEditor = "true"))
    void SetExportToLuaFile(bool ExportToLua) { ExportToLuaFile = ExportToLua; }

protected:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "UServerJsonExportComponent", meta = (KMJsonNotExport = "true"))
    FString JsonFilePostfix;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "UServerJsonExportComponent", meta = (KMJsonNotExport = "true"))
    FString JsonTypeName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "UServerJsonExportComponent", meta = (KMJsonNotExport = "true"))
    bool ExportToLuaFile;
};