// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "GameAvatarPartProcessNodeBase.h"
#include "GameAvatarPartGroupNode.generated.h"


UCLASS(Blueprintable)
class COMMON_API UGameAvatarPartGroupNode : public UGameAvatarPartProcessNodeBase
{
	GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintPure, Category = "GameAvatar")
    UGameAvatarPartProcessNodeBase* GetActivedNode() { return ActivedNode; }

protected:
    virtual void Refresh_Implementation(bool bIncludeChildren, bool bRecursion, bool bForceRefreshSelf) override;
    virtual bool SetRawData_Implementation(const FString& In) override;

protected:
    UPROPERTY()
    UGameAvatarPartProcessNodeBase* ActivedNode;

    UPROPERTY()
    bool NeedRefreshAll;
};