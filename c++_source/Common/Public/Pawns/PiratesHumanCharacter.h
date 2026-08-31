#pragma once

#include "AIController.h"
#include "EngineExt/Public/KMCharacter.h"
#include "Components/HumanMovementComponent.h"
#include "Components/RelativePathFollowingComponent.h"
#include "Perception/AISightTargetInterface.h"
#include "PiratesHumanCharacter.generated.h"

class FMapNavGridLayout;
class FMapNavGridPathFinding;
class UFlotageComponent;

UCLASS()
class COMMON_API APiratesHumanCharacter : public AKMCharacter, public IAISightTargetInterface
{
    GENERATED_UCLASS_BODY()

public:

    virtual void Destroyed() override;

    virtual void Tick(float DeltaSeconds) override;

    virtual void BeginPlay() override;

public:

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FNavMoveFinishedDelegate, EPathFollowingResult::Type, Result);
    UPROPERTY(BlueprintAssignable, Category = "HumanNavMove")
    FNavMoveFinishedDelegate OnNavMoveFinished;

public:

//     UFUNCTION(BlueprintCallable, Category = "HumanNavMove")
//     EPathFollowingRequestResult::Type NavMoveToLocation(const FVector& DestLocation, float AcceptanceRadius, TArray<FVector>& OutNavPath);
// 
//     UFUNCTION(BlueprintCallable, Category = "HumanNavMove")
//     EPathFollowingRequestResult::Type NavMoveToActor(AActor* Target, float AcceptanceRadius);

    UFUNCTION(BlueprintCallable, Category = "HumanNavMove")
    EPathFollowingRequestResult::Type SwimNavMove(const FVector& DestLocation, float AcceptanceRadius);

    UFUNCTION(BlueprintCallable, Category = "HumanNavMove")
    void AbortNavMove();

    UFUNCTION(BlueprintCallable, Category = "HumanNavMove")
    void AbortRelativeMove();

    UFUNCTION(BlueprintCallable, Category = "HumanNavMove")
    bool FindPathSync(const FVector& DestLocation, TArray<FVector>& OutNavPath, bool bOptimizePath = false);

    UFUNCTION(BlueprintCallable, Category = "HumanNavMove")
    EPathFollowingRequestResult::Type DirectNavMove(const TArray<FVector>& NavPath, float AcceptanceRadius);

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    UHumanMovementComponent* GetHumanMovementComponent();

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    FVector GetHumanLocation();

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    void TeleportHuman(const FVector& Location, float Yaw, bool bResetMovement);

 	UFUNCTION(Category = "HumanMovement", BlueprintCallable)
	void SetIsRelativePath(bool Value);

	UFUNCTION(Category = "HumanMovement", BlueprintCallable)
	bool GetIsRelativePath();

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    bool IsLocationReachable(const FVector& Location);

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    bool GetNearestSafeLocation(const FVector& InLocation, float Radius, FVector& OutLocation);

    UFUNCTION(Category = "NetRelevant", BlueprintCallable)
    void SetActorIsReplicates(bool bInReplicates);
    
    //yangjingzhao for 4.20
	//UFUNCTION(BlueprintCallable, Category = "Rendering", meta = (DisplayName = "Set Actor Hidden In Game", Keywords = "Visible Hidden Show Hide"))
	virtual void SetActorHiddenInGame(bool bNewHidden) override;


    // used for ai to determine if current player is visible, use player head position instend defualt positioon
    virtual bool CanBeSeenFrom(const FVector& ObserverLocation, FVector& OutSeenLocation, int32& NumberOfLoSChecksPerformed, float& OutSightStrength, const AActor* IgnoreActor = NULL) const override;

    virtual void GetActorEyesViewPoint( FVector& Location, FRotator& Rotation ) const override;

    UFUNCTION(BlueprintNativeEvent, Category = "AI")
    FVector GetEyePosition() const;

    virtual void OnRep_ReplicatedBasedMovement() override;

private:

    bool EnsureNavMovePreCondition();

    void BuildAIMoveRequest(FAIMoveRequest& AIMoveRequest, const FVector& Dest, float AcceptanceRadius);

    bool FindNearestNavLocation(FVector& Location);

    bool FindSwimPathSync(const FVector& DestLocation, TArray<FVector>& OutNavPath);

    bool AcquireOceanNavData();

    void UpdateSynchron();

private:

    UPROPERTY()
    AAIController* NavMoveAIController;

    UPROPERTY()
    UHumanMovementComponent* MovementComponent;

    UPROPERTY()
    UFlotageComponent* FlotageComponent;

	UPROPERTY()
	bool IsRelativePath;

	UPROPERTY()
	URelativePathFollowingComponent* PathFollowingComponent;

	UPROPERTY()
	class UEmitterActivateComponent* EmitterActivateComponent;

    bool bOceanNavDataAcquired;    
    FMapNavGridPathFinding* PathFinding;
    FMapNavGridLayout* GridLayout;

protected:
    UPROPERTY()
    class UCustomReplicationComponent* CustomReplicationComponent;
};