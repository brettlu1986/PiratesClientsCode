// Fill out your copyright notice in the Description page of Project Settings.

#include "GameplayExtensions.h"
#include "Common.h"
#include "ExtendBlueprintFunctions.h"
#include "JsonConverter/JsonConvertScriptStruct.h"
#include "Particles/ParticleSystemComponent.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Kismet/KismetMathLibrary.h"
#include "LevelUtils.h"
#include "Engine/LevelScriptBlueprint.h"
//#include "../LevelSequence/Public/LevelSequencePlayer.h"
#include "LevelSequenceActor.h"
#include "Math/UnitConversion.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"


DEFINE_LOG_CATEGORY_CLASS(UGameplayExtensions, GameplayExtensionsLog);




void UGameplayExtensions::LauncherGroupUpdate(UObject* WorldContextObject,
    float DeltaSeconds,
    FTransform VirtualTransform,
    FVector TargetLocation,
    float MinYaw,
    float MaxYaw,
    float FollowingAngleSpeed,
    float LocalYaw,
    float MaxTargetingAngleDiff,
    float& OutLocalYaw,
    float& LeftYawDiff,
    bool& TargetingSucceeded)
{
    float diff = UExtendBlueprintFunctions::GetYawFromVector(VirtualTransform.InverseTransformPosition(TargetLocation));
    float change = UExtendBlueprintFunctions::CalcFollowingNumberCPP(
        WorldContextObject, diff, 0, DeltaSeconds, FollowingAngleSpeed, MinYaw - LocalYaw, MaxYaw - LocalYaw);

    OutLocalYaw = change + LocalYaw;
    LeftYawDiff = diff - change;
    TargetingSucceeded = FMath::Abs(LeftYawDiff) <= MaxTargetingAngleDiff;
}



void UGameplayExtensions::FindActorsInSector(const TArray<AActor*> &actors, const FVector &sectorCenter, const FVector &sectorForward,
    const float &sectorAngle, const float &radius, TArray<AActor*> &outActors)
{
    for (AActor* actor : actors)
    {
        FVector VecCenterToActor = actor->GetActorLocation() - sectorCenter;
        if (VecCenterToActor.SizeSquared2D() < radius * radius &&
            FVector::DotProduct(VecCenterToActor.GetSafeNormal2D(), sectorForward) > FMath::Cos(sectorAngle / 2.0f))
        {
            outActors.Add(actor);
        }
    }
}
