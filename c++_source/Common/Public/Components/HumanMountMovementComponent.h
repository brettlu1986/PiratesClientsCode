// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

//#include "GameFramework/CharacterMovementComponent.h"

#include "PiratesMovementUtil.h"
#include "MapNavMeshCache.h"
#include "EngineExt/Public/Components/KMCharacterMovementComponent.h"
#include "Navigation/PathFollowingComponent.h"
#include "HumanMountMovementComponent.generated.h"

USTRUCT(Blueprintable)
struct FHumanMountMovementConfig
{
    GENERATED_USTRUCT_BODY()

    FHumanMountMovementConfig()
        : ForwardAccelerateCoefficient(0.f), BackwardAccelerateCoefficient(0.f), ForwardBrakeDecelerateCoefficient(0.f), BackwardBrakeDecelerateCoefficient(0.f), ForwardNaturalDecelerateCoefficient(0.f), BackwardNaturalDecelerateCoefficient(0.f), ImmediateStopReadySpeed(0.f), TriggerImmediateStopSpeed(0.f), ForwardMaxWalkSpeed(0.f)
    {}

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ForwardAccelerateCoefficient;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float BackwardAccelerateCoefficient;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ForwardBrakeDecelerateCoefficient;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float BackwardBrakeDecelerateCoefficient;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ForwardNaturalDecelerateCoefficient;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float BackwardNaturalDecelerateCoefficient;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ImmediateStopReadySpeed;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float TriggerImmediateStopSpeed;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ForwardMaxWalkSpeed;
};

// Custom jump/fall config
USTRUCT(Blueprintable)
struct FHumanMountFallConfig
{
    GENERATED_USTRUCT_BODY()

    FHumanMountFallConfig()
        : AirDragCoefficient(0.f), LateralAcceleration(0.f), LandStunTime(0.f), LandStunSpeedPreservation(0.f), JumpLateralSpeedRatio(0.f), JumpZVelocity(0.f), CustomGravityScale(0.f)
    {}

    /*空气阻力系数*/
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float AirDragCoefficient;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float LateralAcceleration;

    /*落地硬直时间*/
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float LandStunTime;

    /*落地硬直时间内，速度相对落地前速度保留系数*/
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float LandStunSpeedPreservation;

    /*起跳后速度相对起跳前速度系数*/
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float JumpLateralSpeedRatio;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float JumpZVelocity;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float CustomGravityScale;
};

UCLASS()
class COMMON_API UHumanMountMovementComponent : public UKMCharacterMovementComponent
{
    GENERATED_UCLASS_BODY()

public:

    virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;
    virtual void SimulateMovement(float DeltaTime);
    virtual void CalcVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration) override;
    virtual void SmoothCorrection(const FVector& OldLocation, const FQuat& OldRotation, const FVector& NewLocation, const FQuat& NewRotation) override;
    virtual void MoveSmooth(const FVector& InVelocity, const float DeltaSeconds, FStepDownResult* OutStepDownResult = NULL) override;
    virtual void MoveAlongFloor(const FVector& InVelocity, float DeltaSeconds, FStepDownResult* OutStepDownResult = NULL) override;
    virtual void PerformMovement(float DeltaTime) override;

public:
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    float GetTotalDistance() { return TotalDistance; }

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void ClearTotalDistance() { TotalDistance = 0; }

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetActorLocationAndUpdateBasedMovement(FVector NewLocation);

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetHumanMountMovementConfig(const FHumanMountMovementConfig &InHumanMountMovementConfig);

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void ResetNetworkSmoothingComplete();

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void ResetLastVelocity();

    /*下马时清除Driver的MovementBase，防止踢下马时位置出错*/
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void ClearDriverBase(ACharacter* InDriver);

public:

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    float MaxAccelerationSlowDown;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    bool bIsDead;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    bool bDeadMoveEnd;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    bool bIsFrightened;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    ACharacter* Driver;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    FVector CollisionCheckBox;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    float CollisionRadios;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    float CollisionOffset;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    float CollisionZOffset;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    float ForwardCollisionOffset;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    bool bBlocked;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    bool bInOcean;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    TArray<TEnumAsByte<EObjectTypeQuery> >  CollisionObjectTypes;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    FRotator LastRotation;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    FVector CollisionCheckBoxSlide;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    float AdjustPitchForwardCheck;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    float AdjustPitchBackCheck;

    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    float AdjustRotationRate;

    // 以下用于检测Driver碰撞
    UPROPERTY(Category = "Mount|Driver", EditAnywhere, BlueprintReadWrite)
    float DriverCollisionRadius;

    UPROPERTY(Category = "Mount|Driver", EditAnywhere, BlueprintReadWrite)
    FVector DriverCollisionOffset;

    UPROPERTY(Category = "Mount|Driver", EditAnywhere, BlueprintReadWrite)
    float DriverCollisionHalfHeight;

    // 以上用于检测Driver碰撞

private:
    void AdjustRotationMatchSlope(float DeltaTime); // Use CurrentFloor.HitResult
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void AdjustRotationMatchSlope(float DeltaTime, const FHitResult HitResult);

    bool HandleHit(const FVector& Dir, FHitResult& OutHit);
    bool HandleDriverHit(const FVector& Dir, FHitResult& OutHit);
    bool CheckCanSlide(const FVector& Dir);
    
private:
    float SmoothMoveLerpRate;
    FVector SmoothCorrectionDirection;
    FVector LastVelocity;
    float TotalDistance;
	float LastPawnYaw;
	float MinOffsetYaw;


// For custom jump.
public:
    UPROPERTY(Category = "Mount|Falling", EditAnywhere, BlueprintReadWrite)
    FHumanMountMovementConfig HumanMountMovementConfig;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetHumanMountFallConfig(const FHumanMountFallConfig& InConfig);

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    FHumanMountFallConfig GetHumanMountFallConfig();

private:
    FHumanMountFallConfig HumanMountFallConfig;
    float CurrentFallingLateralAcceleration;    // lateral acceleration in air

    void CalcFallingVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration);
    bool CheckJumpCanMoveForward(const FVector& Dir);

public:
    UPROPERTY(Category = "Mount|Falling", EditAnywhere, BlueprintReadWrite)
    FVector JumpCollisionCheckBox;

// For custom jump end.


// 以下用于计算MovementInput
private:
    bool CheckNeedStop(float InAxisValue, float CurrentSpeed);
    float CalcAxisValueInterpolation(float InAxisValue);

public:
    UPROPERTY(Category = "Mount", BlueprintReadWrite)
    bool bImmediateStopReady;

    UPROPERTY(Category = "Mount", BlueprintReadWrite)
    bool bImmediateStopTriggered;

    UPROPERTY(Category = "Mount", BlueprintReadWrite)
    float CurrentAxisValue;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    float LerpAxisValue(float InAxisValue, float DeltaTime);
// 以上用于计算MovementInput


// For debug
public:
    UPROPERTY(Category = "Mount", EditAnywhere, BlueprintReadWrite)
    TEnumAsByte<EDrawDebugTrace::Type> DrawCollisionDebug;

};

