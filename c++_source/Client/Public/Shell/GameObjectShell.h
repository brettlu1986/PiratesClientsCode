// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "UObject/NoExportTypes.h"
#include "GameObjectShell.generated.h"

/**
 * 
 */
UCLASS()
class CLIENT_API UGameObjectShell : public UObject
{
    GENERATED_BODY()

    UFUNCTION()
    UObject* CreateObject(UClass* Class);
	
    UFUNCTION()
    void ReleaseObject(UObject* Object);

    UFUNCTION()
    void ClearAllObjects();

    virtual UWorld* GetWorld() const override;
private:
    UPROPERTY()
    TArray<UObject*> Objects;
};
