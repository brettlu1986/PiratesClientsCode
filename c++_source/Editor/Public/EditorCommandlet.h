// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Commandlets/Commandlet.h"
#include "EditorCommandlet.generated.h"

/**
 * 
 */
UCLASS()
class EDITOR_API UEditorCommandlet : public UCommandlet
{
    GENERATED_BODY()

    virtual int32 Main(const FString& Params) override;
};
