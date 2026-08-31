#pragma once

#include "KMPawn.h"
#include "Components/ShipMovementComponent.h"
#include "SmoothTravel.h"
#include "PiratesShipPawn.generated.h"


class UShipNavigationComponent;
class UFlotageComponent;
class UEmitterActivateComponent;
class UCustomReplicationComponent;


UCLASS()
class COMMON_API APiratesShipPawn : public AKMPawn, public ISmoothTravel
{
    GENERATED_BODY()

public:

    APiratesShipPawn(const FObjectInitializer& ObjectInitailizer);

    virtual void BeginPlay() override;

    virtual void Tick(float DeltaSeconds) override;

    virtual void OnRep_Controller() override;

    virtual void GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const override;

	virtual void PreReplication(IRepChangedPropertyTracker & ChangedPropertyTracker) override;

    virtual void SmoothTravelSwap_Implementation(AActor* Actor) override;

    virtual void SmoothTravelPreTravel_Implementation() override;

	//virtual bool IsNetRelevantFor(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const override;

	virtual void SetActorHiddenInGame(bool bNewHidden) override;

	bool UsingAsyncPathFindingForAI() const { return bUsingAsyncPathFindingForAI; }

	UShipMovementComponent* GetShipMovementComponent();

	void SetRemoteViewYaw(float NewRemoteViewYaw);
public:

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    bool NavMove(const FVector& DestLocation, float AcceptanceRadius, bool bStopOnFinish, TArray<FVector>& OutPath);

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    bool DirectNavMove(const TArray<FVector>& InPath, float AcceptanceRadius, bool bStopOnFinish);

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    void AbortNavMove(EMapNavGridPathFollowingResult Result = EMapNavGridPathFollowingResult::Aborted);

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    bool FindPathSync(const FVector& DestLocation, TArray<FVector>& OutPath);

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    void FindPathAsync(const FVector& DestLocation);

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    int32 GetNavMoveNextPathPointIndex();

    UFUNCTION(BlueprintCallable, Category = "ShipNavMove")
    bool DrawDebugNavMovePath(float ExitTime);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    bool IsLocationReachable(const FVector& Location);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    bool IsLocationSafe(const FVector& Location);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    bool GetNearestReachableLocation(const FVector& InLocation, float Radius, FVector& OutLocation);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    bool GetNearestSafeLocation(const FVector& InLocation, float Radius, FVector& OutLocation);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    FVector GetShipLocation();

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
    void TeleportShip(const FVector& Location, float Yaw, bool bResetMovement);

    UFUNCTION(BlueprintImplementableEvent, Category = "Mast")
    float GetCameraArmLength();

	UFUNCTION(BlueprintImplementableEvent, Category = "Mast")
	void OnMastVisibleChanged(bool bVisible);

	UFUNCTION(BlueprintCallable, Category = "NetRelevant")
	void SetMastVisible(bool Visible);

    UFUNCTION(BlueprintCallable, Category = "ShipPawnComponent")
	void TriggerMastVisibleChangedEvent();

	//UFUNCTION(BlueprintNativeEvent, Category = "NetRelevant")
	//bool IsNetRelevantForInBP(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const;

	virtual FRotator GetBaseAimRotation() const override;
protected:

	UFUNCTION()
	virtual void OnNavMoveFinishedInternal(EMapNavGridPathFollowingResult Result);

private:

    // 这个接口只用来给美术跑地图用的BP_ArtShip使用
    UFUNCTION(BlueprintCallable, Category = "ShipPawn")
    void RefindShipMovementComponent() { ShipMovementComponent = FindComponentByClass<UShipMovementComponent>(); }

	// void UpdateMastVisible();

	void UpdateSynchron();

public:

	DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FAsyncPathFindingFinishedDelegate, bool, bSuccess, const TArray<FVector>&, NavPath);
	UPROPERTY(BlueprintAssignable, Category = "ShipNavMove")
	FAsyncPathFindingFinishedDelegate OnAsyncPathFindingFinished;

	DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FNavMoveFinishedDelegate, EMapNavGridPathFollowingResult, Result);
	UPROPERTY(BlueprintAssignable, Category = "ShipNavMove")
	FNavMoveFinishedDelegate OnNavMoveFinished;

	DECLARE_DYNAMIC_MULTICAST_DELEGATE(FPlayerTeleportFinishedDelegate);
	UPROPERTY(BlueprintAssignable, Category = "PlayerTeleport")
	FPlayerTeleportFinishedDelegate OnPlayerTeleportFinished;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, meta = (AllowPrivateAccess = "true"))
    UShipNavigationComponent* ShipNavigationComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, meta = (AllowPrivateAccess = "true"))
	UFlotageComponent* FlotageComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Config", meta = (AllowPrivateAccess = "true"))
	float ShipHeight;

	/** Replicated so we can see where remote clients are looking. */
	UPROPERTY(replicated)
    uint8 RemoteViewYaw;

private:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, meta = (AllowPrivateAccess = "true"))
    UShipMovementComponent* ShipMovementComponent;

protected:

    UPROPERTY()
    UEmitterActivateComponent* EmitterActivateComponent;

    UPROPERTY()
	UCustomReplicationComponent* CustomReplicationComponent;

	UPROPERTY(EditAnywhere, Category = "ShipNavMove")
	bool bUsingAsyncPathFindingForAI;

private:

    bool bMastVisible;

	float ShipModelRelativeZ;

};
