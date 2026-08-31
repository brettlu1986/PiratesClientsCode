// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "AIController.h"
#include "KMPlayerController.h"
#include "KMSmartPlayerController.generated.h"


/**
 * The extension for PlayerController that support client side navigation move.
 */
UCLASS()
class ENGINEEXT_API AKMSmartPlayerController : public AKMPlayerController
{
    GENERATED_UCLASS_BODY()

public:

    virtual void BeginDestroy() override;
    virtual void SetPawn(APawn* InPawn) override;

public:

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FPlayerNavMoveFinishedSignature, EPathFollowingResult::Type, Result);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnNavMoveFinished"))
    FPlayerNavMoveFinishedSignature OnNavMoveFinished;

public:

    UFUNCTION(BlueprintCallable, Category = "SmartPlayerController: Navigation Move")
    virtual EPathFollowingRequestResult::Type StartNavMoveToLocation(
        const FVector& DestLocation, float AcceptanceRadius = -1.0f, bool bStopOnOverlap = true,
        bool bUsePathfinding = true, bool bProjectDestinationToNavigation = false, bool bCanStrafe = true,
        TSubclassOf<UNavigationQueryFilter> FilterClass = NULL, bool bAllowPartialPaths = true);

    UFUNCTION(BlueprintCallable, Category = "SmartPlayerController: Navigation Move")
    virtual EPathFollowingRequestResult::Type StartNavMoveToActor(
        AActor* Target, float AcceptanceRadius = -1.0f, bool bStopOnOverlap = true,
        bool bUsePathfinding = true, bool bCanStrafe = true,
        TSubclassOf<UNavigationQueryFilter> FilterClass = NULL, bool bAllowPartialPaths = true);

    UFUNCTION(BlueprintCallable, Category = "SmartPlayerController: Navigation Move")
    virtual void StopNavMove();

    UFUNCTION(BlueprintCallable, Category = "SmartPlayerController: Navigation Move")
    virtual bool IsNavMoving();


protected:

    UPROPERTY(Category = "SmartPlayerController: Navigation Controller", BlueprintReadOnly)
    AAIController* AIController;

protected:

    virtual void EnsureNavMovePreCondition();

    UFUNCTION()
    virtual void HandleAIControllerReceiveMoveCompleted(FAIRequestID RequestID, EPathFollowingResult::Type Result);

private:

    bool bIsNavMoving;
};
