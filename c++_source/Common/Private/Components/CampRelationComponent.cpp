// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/CampRelationComponent.h"
#include "Common.h"
#include "Kismet/KismetMathLibrary.h"
#include "ExtendBlueprintFunctions.h"


UCampRelationComponent::UCampRelationComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , CampCount(0)
{
}

void UCampRelationComponent::SetCampRelationMatrix(int32 InCampCount, const TArray<bool>& RelationMatrix)
{
    CampRelationMatrix = RelationMatrix;
    CampCount = InCampCount;
}

bool UCampRelationComponent::IsFriendCampRelation(int32 CampA, int32 CampB) const
{
    if (CampA >= 0 && CampB >= 0)
    {
        int32 RelationIndex = CampA * CampCount + CampB;
        if (CampRelationMatrix.IsValidIndex(RelationIndex))
        {
            return CampRelationMatrix[RelationIndex];
        }
    }
    return false;
}