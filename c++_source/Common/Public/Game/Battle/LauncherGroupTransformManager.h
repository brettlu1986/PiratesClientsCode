// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Game/Battle/CustomizedTickableObject.h"
#include "LauncherGroupTransformManager.generated.h"


// Delegate to notify targeting state change.
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnTargetingStateChanged, bool, TargetingSucceeded);

// Delegate used to get targeting location.
DECLARE_DYNAMIC_DELEGATE_RetVal(FVector, FGetTargetLocation);

/**
 * xuweihua: This class is used to implement launcher groups' virtual movement.
 */
UCLASS()
class COMMON_API ULauncherGroupTransformManager : public UCustomizedTickableObject
{
	GENERATED_BODY()
	

public:
    virtual bool IsTickable() const override;

//Delegates
    UPROPERTY(BlueprintAssignable, EditAnywhere, BlueprintReadWrite, Category = "Tick")
    FOnTargetingStateChanged OnTargetingStateChanged;

    // This delegate must be provided to let the launcher group transform manager know the aiming position.
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tick")
    FGetTargetLocation GetTargetLocation;


// Public Properties
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tick")
    float LeftYawDiff;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tick")
    bool TargetingSucceeded;

// Utilities
    UFUNCTION(BlueprintCallable, Category = "Tick")
    void Init(USceneComponent* aVirtualParent, FTransform aOriginalRelativeTransform, float minYaw, float maxYaw, float followingAngleSpeed, float maxTargetingAngleDiff);

    // We have to use this utility method to bind GetTargetLocation delegate, since it seems BP cannot do this.
    UFUNCTION(BlueprintCallable, Category = "Tick")
    void BindGetTargetLocationDelegate(UObject* Object, FString FunctionName);

    UFUNCTION(BlueprintPure, BlueprintCallable, Category = "Tick")
    FTransform GetVirtualTransform();

private:
// Internal
    float LocalYaw;
    FTransform OriginalRelativeTransform;
    USceneComponent* VirtualParent;


// Config.
    float MinYaw;
    float MaxYaw;
    float FollowingAngleSpeed;
    float MaxTargetingAngleDiff;


    // CPP customized tick.
    virtual void OnTick(float DeltaSeconds) override;
};
