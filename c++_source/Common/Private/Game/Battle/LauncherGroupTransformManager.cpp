// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Battle/LauncherGroupTransformManager.h"
#include "Common.h"
#include "Kismet/KismetMathLibrary.h"
#include "ExtendBlueprintFunctions.h"
#include "GameplayExtensions.h"

bool ULauncherGroupTransformManager::IsTickable() const
{
    return Super::IsTickable();

    //UObject* outer = this->GetOuter();
    //return outer && outer->IsValidLowLevel();
}

void ULauncherGroupTransformManager::Init(USceneComponent* aVirtualParent, FTransform aOriginalRelativeTransform, float minYaw, float maxYaw, float followingAngleSpeed, float maxTargetingAngleDiff)
{
    VirtualParent = aVirtualParent;
    OriginalRelativeTransform = aOriginalRelativeTransform;

    this->MinYaw = minYaw;
    this->MaxYaw = maxYaw;
    this->FollowingAngleSpeed = followingAngleSpeed;
    this->MaxTargetingAngleDiff = maxTargetingAngleDiff;

    LocalYaw = 0;
}

void ULauncherGroupTransformManager::OnTick(float DeltaSeconds)
{
    if (!GetTargetLocation.IsBound())
    {
        return;
    }

    FVector TargetLocation = GetTargetLocation.Execute();

    // Update virtual transform.
    FTransform LocalTransform = UKismetMathLibrary::MakeTransform(FVector::ZeroVector, FRotator(0, LocalYaw, 0), FVector::OneVector);

    FTransform VirtualTransform = VirtualParent ? UKismetMathLibrary::ComposeTransforms(LocalTransform,
        UKismetMathLibrary::ComposeTransforms(OriginalRelativeTransform, VirtualParent->GetComponentTransform())) :
        UKismetMathLibrary::ComposeTransforms(LocalTransform, OriginalRelativeTransform);


    float YawDiff = UExtendBlueprintFunctions::GetYawFromVector(VirtualTransform.InverseTransformPosition(TargetLocation));

    bool Succeeded;
    UGameplayExtensions::LauncherGroupUpdate(this, DeltaSeconds, VirtualTransform, TargetLocation, MinYaw, MaxYaw, FollowingAngleSpeed,
        LocalYaw, MaxTargetingAngleDiff, LocalYaw, LeftYawDiff, Succeeded);

    if (Succeeded != TargetingSucceeded && OnTargetingStateChanged.IsBound())
    {
        TargetingSucceeded = Succeeded;
        OnTargetingStateChanged.Broadcast(Succeeded);
    }
    else
    {
        TargetingSucceeded = Succeeded;
    }

}

void ULauncherGroupTransformManager::BindGetTargetLocationDelegate(UObject* Object, FString FunctionName)
{
    FName const FunctionFName(*FunctionName);
    if (Object)
    {
        UFunction* const Func = Object->FindFunction(FunctionFName);
        if (Func)
        {
            GetTargetLocation.BindUFunction(Object, FunctionFName);
        }
    }
}

FTransform ULauncherGroupTransformManager::GetVirtualTransform()
{
    if (!GetTargetLocation.IsBound())
    {
        return FTransform::Identity;
    }

    FVector TargetLocation = GetTargetLocation.Execute();

    // Update virtual transform.
    FTransform LocalTransform = UKismetMathLibrary::MakeTransform(FVector::ZeroVector, FRotator(0, LocalYaw, 0), FVector::OneVector);

    return VirtualParent ? UKismetMathLibrary::ComposeTransforms(LocalTransform,
        UKismetMathLibrary::ComposeTransforms(OriginalRelativeTransform, VirtualParent->GetComponentTransform())) :
        UKismetMathLibrary::ComposeTransforms(LocalTransform, OriginalRelativeTransform);
}