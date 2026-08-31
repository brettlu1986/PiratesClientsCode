// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

//#include "GameFramework/CharacterMovementComponent.h"
#include "PiratesMovementUtil.h"
#include "EngineExt/Public/Components/KMCharacterMovementComponent.h"
#include "Navigation/PathFollowingComponent.h"
#include "HumanMovementComponent.generated.h"


USTRUCT(Blueprintable)
struct FHumanMovementConfig
{
    GENERATED_USTRUCT_BODY()

    FHumanMovementConfig()
        : SafeTeleportMinDistance(0.f), SafeTeleportMaxDistance(0.f)
    {}

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float SafeTeleportMinDistance;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float SafeTeleportMaxDistance;
};

USTRUCT(Blueprintable)
struct FHumanFallConfig
{
    GENERATED_USTRUCT_BODY()

    FHumanFallConfig()
        : AirDragCoefficient(0.f), LateralAcceleration(0.f), DefaultOriginSpeed(0.f), LandStunTime(0.f), LandStunSpeedPreservation(0.f), JumpLateralSpeedRatio(0.f), JumpZVelocity(0.f), CustomGravityScale(0.f)
    {}

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float AirDragCoefficient;           // Ratio of deceleration / current speed.

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float LateralAcceleration;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float DefaultOriginSpeed;           // Default origin speed with input

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float LandStunTime;                 // Stun time when landing

    /*Ratio of the speed on land stunning to the speed on falling. A float between 0 and 1. */
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float LandStunSpeedPreservation;

    /*Ratio of the speed on jumping/falling to the speed on walking.*/
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float JumpLateralSpeedRatio;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float JumpZVelocity;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float CustomGravityScale;
};


UCLASS()
class COMMON_API UHumanMovementComponent : public UKMCharacterMovementComponent
{
    GENERATED_UCLASS_BODY()

public:
    
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

    virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;

    // 计算跳/下落等特殊速度
    virtual void CalcVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration) override;

    virtual FVector NewFallVelocity(const FVector& InitialVelocity, const FVector& Gravity, float DeltaTime) const override;

    // 下面几个函数的重载，全部都是因为移动平滑的处理
    virtual void MoveSmooth(const FVector& InVelocity, const float DeltaSeconds, FStepDownResult* OutStepDownResult = NULL) override;

    virtual void SmoothCorrection(const FVector& OldLocation, const FQuat& OldRotation, const FVector& NewLocation, const FQuat& NewRotation) override;
    
    virtual void ClientAdjustPosition_Implementation(float TimeStamp, FVector NewLoc, FVector NewVel, UPrimitiveComponent* NewBase, FName NewBaseBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode);

    /**
     * Check position error within ServerCheckClientError(). Set bNetworkLargeClientCorrection to true if the correction should be prioritized (delayed less in SendClientAdjustment).
     */
    virtual bool ServerExceedsAllowablePositionError(float ClientTimeStamp, float DeltaTime, const FVector& Accel, const FVector& ClientWorldLocation, const FVector& RelativeClientLocation, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode);
      
    // 当没有移动时（包括location和rotation），采用ClientNetSendMoveDeltaTimeStationary的同步间隔的修改
    /** Determine minimum delay between sending client updates to the server. If updates occur more frequently this than this time, moves may be combined delayed. */
    virtual float GetClientNetSendDeltaTime(const APlayerController* PC, const FNetworkPredictionData_Client_Character* ClientData, const FSavedMovePtr& NewMove) const;

protected:
    virtual float SlideAlongSurface(const FVector& Delta, float Time, const FVector& Normal, FHitResult& Hit, bool bHandleImpact) override;

public:
    // human movement delegates
    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FHumanPathMoveFinishedDelegate, EPathFollowingResult::Type, Result);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnHumanPathMoveFinished"))
    FHumanPathMoveFinishedDelegate OnHumanPathMoveFinished;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FHumanMoveStateChangedDelegate, bool, IsMoving);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnHumanMoveStateChanged"))
    FHumanMoveStateChangedDelegate OnHumanMoveStateChanged;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE(FHumanStopMovementImmediatelyDelegate);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnHumanStopMovementImmediately"))
    FHumanStopMovementImmediatelyDelegate OnHumanStopMovementImmediately;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FHumanMoveAngleChangedDelegate, bool, bLessThan);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnHumanMoveAngleChanged"))
    FHumanMoveAngleChangedDelegate OnHumanMoveAngleChanged;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FHumanMoveFindSwimFloorDelegate, bool, bFindFloor);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnHumanFindSwimFloor"))
    FHumanMoveFindSwimFloorDelegate OnHumanFindSwimFloor;

public:

    /* 标记移动时是否使用SlideAlongSurface，主要用在手持武器做不同操作的时候 */
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    bool bEnableSlideAlongSurface = true;

    /*init movement */
	UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    void InitData(const FHumanMovementConfig& InConfig, const FHumanFallConfig& InFallConfig);

    /*teleport */
    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    void TeleportHuman(const FVector& Location, float Yaw, bool bResetMovement, bool bAdjustZ = true, bool bSynClient = false);

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    void TeleportToSafeLocation();

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    void TeleportBot();

    /*for Vehicle, update human base movement */
    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    void SetActorLocationAndUpdateBasedMovement(FVector NewLocation);

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    void SetActorRotationAndUpdateBasedMovement(FRotator NewRotation);

    /* 返回当前human是否正在移动中 */
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    bool IsHumanMoving() const { return bHumanMoving; }

    /* 返回当前脚下的地面材质，用来给脚步配音效 */
    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    EPhysicalSurface GetFootPhysicalSurfaceType() const { return AlongSurfaceType; };
        
    /* 统计人移动的距离 */
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetStartTotalDistance(bool bStart) { bStartTotalDistance = bStart; }

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    float GetTotalDistance() { return TotalDistance; }

    /* 人立即停止移动 */
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void StopHumanMovementImmediately();
    
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void PlayRootMotion(const TArray<FVector>& RootMotionSouce, float ScaleZ = 1.0f, const FVector& StartPos = FVector::ZeroVector, const FRotator& StartRotator = FRotator::ZeroRotator, bool ResetReplicateMovement = true, float PlayRate = 1.0f);

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void StopRootMotion();

    /*带有Delta矫正的RootMotion*/
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void PlayRootMotionWithDeltaCorrection(const TArray<FVector>& RootMotionSouce, const FTransform& ExpectStartPos, float fStartCorrectTime, const FVector2D& FinalCorrectTimeRange, const FTransform& FinalTargetPos, float fPlayRate = 1.0, bool bSafeMoveLocation = true);
private:
   
    /* Pirates Special Move Mode: Jump, Crawl */
    void SetHumanMoveState();

    /* Other Utils */
    bool UsePiratesSmoothMode();

    void ProcessHumanMovementState();

    void SetAlongSurfaceType();

    void SetTotalDistance(FVector OldLocation);

    void CheckConsumeInputVector();

private:    
    UFUNCTION(Reliable, Client)
    void ClientSendStopMovement();

    UFUNCTION(unreliable, Client)
    void ClientTeleportHuman(FVector Location, float Yaw);

private:
    class APiratesHumanCharacter* HumanCharacter;
    FHumanMovementConfig Config;
    FHumanFallConfig HumanFallConfig;

    // 辅助计算location Z
    float HumanHalfHeight;
    float CorrectionAdjustZ;

    // 返回地表材质，用于音效
    EPhysicalSurface AlongSurfaceType;

    // Simulate客户端，平滑的处理
    float SmoothCorrectionTimestamp;
    float SmoothCorrectionDeltaZ;
    FVector SmoothCorrectionDirection;
    float SmoothMoveMaxDeltaTime;
    float SmoothMoveCorrection;
    
    // 用于数据统计
    bool bStartTotalDistance;
    float TotalDistance;

    // 是否正在移动
    bool bHumanMoving;


    //=============================================================================
    /**
    *  处理跳伞过程的移动
    *  在下落的过程中可能会有几种不同的状态
    */
public:
    /* 处理跳伞下落的逻辑，用来区分跳伞下落还是普通下落 */
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    bool bUseHumanFallingTerminalVelocity = false;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetFallingTerminalVelocity(const float TerminalVelocity);

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    const float GetFallingTerminalVelocity() const;

private:
    float FallingTerminalVelocity;
    mutable bool bFallingDeceleration;


    //=============================================================================
    /**
    *  处理爬行状态
    *  包括卧倒锁定的判定，爬行时根据地形修改Rotation等
    */
public:
    //override
#if WITH_EDITOR
    virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
#endif // WITH_EDITOR
    virtual void OnRegister() override;

    /* 标记是否用地面坡度调整人的Rotation */
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    bool bEnableAdjustRotationMatchSlope = true;

    /* 可以趴下的地面坡度值 */
    UPROPERTY(Category = "HumanMovement", EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "90.0", UIMin = "0.0", UIMax = "90.0"))
    float CrawlMoveAlongFloorAngle = 30.f;

    UPROPERTY(Category = "HumanMovement", VisibleAnywhere)
    float CrawlMoveAlongFloorZ;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetCrawlMoveAlongFloorAngle(float MoveAngle);

    /* 标记爬行状态 */
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetCrawlState(bool bCrawl);

private:
    void ProcessCrawlMove();
    void AdjustRotationMatchSlope();
    void ComputeHumanMoveAngle();
    void HandleCrawlHit();

private:
    bool bCrawlState;
    bool bCrawlStateChanged;
    bool bMoveAngleLessThan;
    FVector LastAdjustLoction;
    FRotator LastAdjustRotator;
    FVector CollisionCheckBox;

    //=============================================================================
    /**
    *  载具相关的处理
    */
public:
    /** 丢弃全部SavedMoves */
    UFUNCTION()
    void ClearAllSavedMoves();

    /** 强制更新BasedMovement*/
    UFUNCTION()
    void ForceUpdateBasedMovement();

    /** 将bNetWorkSmoothingComplete设为false*/
    UFUNCTION()
    void ResetNetworkSmoothingComplete();

    UFUNCTION()
    void ResetNetworkMovementModeChanged();

    /** 客户端根据是否有Controller校验人的LocalRole*/
    UFUNCTION()
    void VerifyLocalRole();

    /** 下马后设置胶囊体前根据当前位置和胶囊体高度设置位置*/
    UFUNCTION()
    void AdjustHeightAccordingToCapsuleHalfHeight(float TargetCapsuleHalfHeight);

    //=============================================================================
    /**
    *  跳跃逻辑的处理
    *  todo: @chenyixin 添加说明文字
    */
public:
    //override
    virtual bool DoJump(bool bReplayingMoves);
    
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "0", UIMin = "0"))
    float CheckRunJumpSpeed;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    bool bUseNewJump = true;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    float CurrentMaxWalkSpeed;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    float GetFallLandingStunTime() { return FallLandingStunTime; }

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetHumanFallConfig(const FHumanFallConfig& InFallConfig);

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    FHumanFallConfig GetHumanFallConfig();

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetMaxWalkSpeed(float InSpeed);

    UFUNCTION(Category = "HumanMovement", BlueprintCallable)
    void OnLanded(const FHitResult& Hit);

private:
    bool IsHumanRunJump();
    void CalcFallingVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration);

private:
    float CurrentFallingLateralAcceleration;    
    float FallLandingStunTime;
    
    /*单独用来给simulated客户端同步跳的状态，避免有可能会出现看别人跳的时候，还未跳到最高点就被拉回的现象。*/
    UPROPERTY(Transient, ReplicatedUsing = OnRep_JumpMode)
    uint8 HumanJumpMode;
    
    UFUNCTION()
    void OnRep_JumpMode();


    //=============================================================================
    /**
    * RootMotion攀爬的处理
    * todo:@lihui 可以根据rootmotion的逻辑统一处理，看是否需要保留这些修改
    */
public:
    //override
    virtual FVector ConstrainAnimRootMotionVelocity(const FVector& RootMotionVelocity, const FVector& CurrentVelocity) const override;

    /* 标记是否修正RootMotion的Z轴 */
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    bool bCorrectiveRootMotion = false;

    /* RootMotion过程中，客户端是否根据服务器端位置纠正自己，处理自己可能会被拉回的问题 */
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    bool bEnableClientAdjustPosition = true;

private:
    float SaveDeltaTime;


    //=============================================================================
    /**
    * 非法移动检测
    * 主要针对使用内存修改器强制修改速度的行为
    */
public:
    /* 非法检测的测试 */
    virtual float GetMaxSpeed() const override;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    float DebugIllegalSpeed = 0.f;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    float CheckMaxSpeed = 650.f;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    float InitWalkSpeed = 450.f;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    int32 ResetMovementCount = -10;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    int32 CheckIllegalCount = 5;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    float MovementIllegalRate = 1.5f;

private:
    bool CheckMovementIllegal(float DeltaTime);
    
    /* 上一次检测时的位置 */
    FVector LastCheckLocation;
    /* 检测时间间隔 */
    float MovementIllegalTime;
    /* 判定非法的次数 */
    int32 MovementIllegalCount;
    /* 标记是否非法移动 */
    uint8 bMovementIllegal;
    /* 辅助处理移动误差计算 */
    float MovementIllegalDiff;


    //=============================================================================
    /**
    * Swim Part
    * 人的游泳我们没有用引擎的PhysicsVolume，而是根据判断当前的地形（海滩，港口等）和当前z轴的位置来更新MovementMode，游泳的位移和碰撞也都是单独处理的
    */
public:
    // override
    virtual void PhysSwimming(float deltaTime, int32 Iterations) override;

    /* 标记进入游泳状态的z轴高度 */
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    float SwimLocationZ;

    /* 区分游泳时是否使用浮力的效果 */
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    bool bFlotageLocationZEnable = false;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void SetHumanPreSwimState(bool bPerSwim) { bPerSwimState = bPerSwim; }

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|CharacterMovement")
    void InitHumanSwimState() { bFindSwimFloor = true; }

    /*Flotage effect for swim */
    void UpdateFlotage(float LocationZ);

private:
    void HandleSwimmingHit();
    void IsFindSwimFloor(bool bFind);
    bool CheckCanSwim();
    FVector GetHumanFeetLocation() const;

private:    
    /* 根据地形设置游泳判断的标记，当进入bPerSwimState时，判断是否可以游泳，类似于进入PhysicsVolume的判断 */
    bool bPerSwimState;

    /* 判断是否能踩到地面，是否更新动作 */
    bool bFindSwimFloor;

    /* 浮力影响的z轴，(ps:当前版本中游泳没有用浮力) */
    float FlotageLocationZ;


    //=============================================================================
    /**
    * 沿着路点的寻路移动（这里的寻路移动是在已知路点的情况下，人的移动状态计算。）
    * 人在陆地上的寻路采用recastnavmesh，接口调用在APiratesHumanCharacter中，这里并不涉及。
    * 人在海里游泳的寻路使用自定义的海洋2D格子寻路，这里仅处理游泳中移动的计算。
    */
public:

    void StartHumanPathMove(const TArray<FVector>& InPath, float AcceptanceRadius);
    void AbortHumanPathMove(EPathFollowingResult::Type Result = EPathFollowingResult::Aborted);

private:
    UFUNCTION(Reliable, Server, WithValidation)
    void ServerStartHumanPathMove(const TArray<FVector>& InPath, float AcceptanceRadius);

    UFUNCTION(Reliable, Server, WithValidation)
    void StopHumanPathMove(EPathFollowingResult::Type Result);

private:
    /* Path Move */
    void OnPathMoveFinished(EPathFollowingResult::Type Result);
    void ProcessPathMove();
    bool IsHumanPathMove() const { return bRequestPathMove == 1; }

    /* 标记当前是否在自动寻路 */
    uint8 bRequestPathMove;

    /* 当前的寻路方向 */
    FVector CurrentPathMoveVector;

    /* 路点的集合 */
    TArray<FVector> NavPath;

    /* 路点的索引 */
    int32 CurrentPathIndex;
    int32 MaxPathIndex;
    int32 CheckFinalRadiusIndex;

    /* 到达终点的半径 */
    float FinalAcceptanceRadiusSq;
    float IntermedialAcceptanceRadiusSq;

    //加速用
public:
    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    UCurveFloat* AnalogInputCurve;

    UPROPERTY(Category = "HumanMovement", EditAnywhere, BlueprintReadWrite)
    FName RootBoneName;
private:
    float AnalogInputCurrent;
    float AnalogInputAlpha;

    //RootMotion
    float RootMotionPlayRate;
    TArray<FVector> RootMotionPositions;
    bool IsRootMotionMovement;
    int RootMotionFrameIndex;
    float RootMotionDeltaTime;
    float RootMotionTotalDeltaTime;
    float RootMotionStartCorrectTime;
    FVector2D RootMotionCorrectTimeRange;
    FTransform RootMotionStartTransform;
    FTransform TargetRootMotionStartTransform;
    bool bUseTargetRootMotionStartTransform;
    bool bPlayingCorrectRootMotion;
    bool bSafeMove;
    bool IsLerpRotator;
    bool bResetReplicateMovement;
    //RootMotion Delta Correct
    FTransform RootMotionFinalTargetTransform;

private:
    void InitPlayRootMotion(const TArray<FVector>& RootMotionSouce, float fRate);
    void UnInitPlayRootMotion();
    void TickRootMotion(float DeltaTime);
    void TickCommonRootMotion(float DeltaTime);
    void TickCorrectRootMotion(float DeltaTime);
    bool GetRootMotionRelativeLocationByTime(float fTimeFromPlayRootMotion, FVector& fOutVector, bool& bLastFrame);
    void SafeMoveRootMotion(const FVector& DestPosition, const FQuat& NewQuat, float DeltaSeconds);
};

