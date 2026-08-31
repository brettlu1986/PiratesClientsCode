// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CampRelationComponent.generated.h"

UCLASS(ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))
class COMMON_API UCampRelationComponent : public UActorComponent
{
	GENERATED_UCLASS_BODY()
	
public:


    UFUNCTION(BlueprintCallable, Category = "Camp Relation")
    void SetCampRelationMatrix(int32 CampCount, const TArray<bool>& RelationMatrix);

    UFUNCTION(BlueprintCallable, Category = "Camp Relation")
    bool IsFriendCampRelation(int32 CampA, int32 CampB) const;

private:
    TArray<bool>   CampRelationMatrix;
    int  CampCount;
};
