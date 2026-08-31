// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameAvatarSystem.generated.h"

UCLASS(Blueprintable)
class COMMON_API UGameAvatarSystem : public UObject
{
	GENERATED_BODY()

public:
    UFUNCTION(BlueprintImplementableEvent, Category = "GameAvatar")
    void Init();

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void Uninit();

    UFUNCTION(BlueprintCallable, Category = "GameAvatar")
    void DefinePart(const FString& PartName, 
        const FString& TabFile,
        int MinID,
        int MaxPart);

protected:
    struct FPartInfo
    {
        FString PartName;
        FString TabFile;
        FString AvatarType;
        int MinID;
        int MaxPart;
        TArray<FString> ProcessNodeNames;
    };
    TArray<FPartInfo> PartInfos;
};