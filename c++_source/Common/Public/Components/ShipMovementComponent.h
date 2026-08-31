// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "PiratesMovementUtil.h"
#include "GameFramework/PawnMovementComponent.h"
#include "MapNavGridPathFollowingComponent.h"
#include "AI/RVOAvoidanceInterface.h"
#include "ShipMovementComponent.generated.h"


class APiratesShipPawn;
class FMapNavGridLayout;

UENUM(BlueprintType)
enum class EShipMoveGearBuffType : uint8
{
    MAX_LINEAR_SPEED,
    LINEAR_ACCELERATION,
    LINEAR_DECELERATION,
    MAX_ANGULAR_SPEED,
    ANGULAR_ACCELERATION,
    ANGULAR_DECELERATION,

    NUM
};

USTRUCT()
struct FShipMoveGearBuff
{
    GENERATED_USTRUCT_BODY()

    FShipMoveGearBuff()
        : Percent(0.f), Multiplier(1.f)
    {}

    void Set(float Value)
    {
        Percent = Value;
        Update();
    }

    void AddPercent(float Value)
    {
        Value += Percent;
        Set(Value);
    }

    void Empty()
    {
        Percent = 0.f;
        Multiplier = 1.f;
    }

    void Update()
    {
        Multiplier = 1.f + Percent * 0.01f;
        if (Multiplier < 0.f)
        {
            Multiplier = 0.f;
        }
    }

    float GetMultiplier() const { return Multiplier; }

    float GetPercent() const { return Percent; }

protected:

    UPROPERTY(Transient)
    float Percent;

    float Multiplier;
};

USTRUCT(BlueprintType)
struct FShipGearData
{
    GENERATED_USTRUCT_BODY()

    friend class UShipMovementComponent;

    FShipGearData()
        : LinearAcceleration(0.f), LinearDeceleration(0.f), MaxLinearSpeed(0.f)
        , AngularAcceleration(0.f), AngularDeceleration(0.f), MaxAngularSpeed(0.f)
        , Buff(nullptr)
    {}

    float GetMaxLinearSpeed() const
    {
        return MaxLinearSpeed * Buff[(int)EShipMoveGearBuffType::MAX_LINEAR_SPEED].GetMultiplier();
    }

    float GetLinearAcceleration() const
    {
        return LinearAcceleration * Buff[(int)EShipMoveGearBuffType::LINEAR_ACCELERATION].GetMultiplier();
    }

    float GetLinearDeceleration() const
    {
        return LinearDeceleration * Buff[(int)EShipMoveGearBuffType::LINEAR_DECELERATION].GetMultiplier();
    }

    float GetMaxAngularSpeed() const
    {
        return MaxAngularSpeed * Buff[(int)EShipMoveGearBuffType::MAX_ANGULAR_SPEED].GetMultiplier();
    }

    float GetAngularAcceleration() const
    {
        return AngularAcceleration * Buff[(int)EShipMoveGearBuffType::ANGULAR_ACCELERATION].GetMultiplier();
    }

    float GetAngularDeceleration() const
    {
        return AngularDeceleration * Buff[(int)EShipMoveGearBuffType::ANGULAR_DECELERATION].GetMultiplier();
    }

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float LinearAcceleration;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float LinearDeceleration;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float MaxLinearSpeed;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float AngularAcceleration;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float AngularDeceleration;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float MaxAngularSpeed;

private:

    FShipMoveGearBuff* Buff;

};

USTRUCT(BlueprintType)
struct FShipPathMoveGearConfig
{
    GENERATED_USTRUCT_BODY()

    FShipPathMoveGearConfig()
        : MaxSteerAngle(0.f), MinDistance(0.f)
    {}


    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    FShipGearData GearData;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float MaxSteerAngle;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float MinDistance;
};

USTRUCT(BlueprintType)
struct FShipPathMoveConfig
{
    GENERATED_USTRUCT_BODY()

    FShipPathMoveConfig()
        : FinalAcceptanceRadius(0.f), IntermedialAcceptanceRadius(0.f), bStopOnFinish(false)
    {}

    float FinalAcceptanceRadius;
    float IntermedialAcceptanceRadius;
    bool bStopOnFinish;
};

struct FShipPathMoveGearData
{
    FShipPathMoveGearData()
        : Gear(-1), GearData(nullptr), CosAngleSq(1.f), MinDistanceSq(0.f)
    {}

    FShipPathMoveGearData(int32 InGear, FShipGearData* InGearData, float MaxAngle, float MinDistance)
        : Gear(InGear), GearData(InGearData)
    {
        CosAngleSq = FMath::Cos(MaxAngle * FPiratesMovementUtil::DegreesToRadiansFactor);
        bool bNegative = (CosAngleSq < 0.f);

        CosAngleSq = FMath::Square(CosAngleSq);
        if (bNegative)
        {
            CosAngleSq = -CosAngleSq;
        }

        MinDistanceSq = FMath::Square(MinDistance);
    }

    int32 Gear;
    FShipGearData* GearData;
    float CosAngleSq;
    float MinDistanceSq;
};

UENUM(BlueprintType)
enum class EShipPosture : uint8
{
	// 满帆姿势
    FullSail        = 0,
	// 半帆姿势
    HalfSail        = 1,
	// 收帆姿势
    Reef            = 2,
	// 沉没状态
    Sinking         = 3,
};

UENUM(BlueprintType)
enum class EShipGear : uint8
{
	// 行驶档位
    FullSpeed       = 0,
	// 低速档位
    LowSpeed        = 1,
	// 停船档位
    Stopped         = 2,
	// 倒船档位
    Reverse         = 3, 
};

USTRUCT(BlueprintType)
struct FShipInputData
{
    GENERATED_USTRUCT_BODY()

    friend class UShipMovementComponent;

    FShipInputData()
        : ThrustScale(0.f), SteerScale(0.f), Gear(static_cast<int32>(EShipGear::Stopped)), GearValue(EShipGear::Stopped), Posture(EShipPosture::FullSail), bChanged(false) {}


    FShipInputData& operator=(const FShipInputData& Other)
    {
        if (this == &Other) return *this;

        SetThrustScale(Other.ThrustScale);
        SetSteerScale(Other.SteerScale);
        SetGear(Other.Gear);
        if (Other.Gear != static_cast<int32>(EShipGear::Stopped) && Other.GearValue == EShipGear::Stopped && Other.Posture == EShipPosture::FullSail)
        {
            SetGearValue(static_cast<EShipGear>(Other.Gear % 4));
            SetPosture(static_cast<EShipPosture>(Other.Gear / 4));
        }
        else
        {
            SetGearValue(Other.GearValue);
            SetPosture(Other.Posture);
        }

        return *this;
    }

    FORCEINLINE bool operator==(const FShipInputData& Other) const
    {
        return FPiratesMovementUtil::CheckFloatEqual(ThrustScale, Other.ThrustScale, ThrustScalePrecision)
            && FPiratesMovementUtil::CheckFloatEqual(SteerScale, Other.SteerScale, SteerScalePrecision)
            && Gear == Other.Gear
            && GearValue == Other.GearValue
            && Posture == Other.Posture;
    }

    FORCEINLINE bool operator!=(const FShipInputData& Other) const
    {
        return !(*this == Other);
    }

    FORCEINLINE void Reset()
    {
        ThrustScale = 0.f;
        SteerScale = 0.f;
        GearValue = EShipGear::Stopped;
        Posture = EShipPosture::FullSail;
        int gear = static_cast<int32>(Posture) * 4 + static_cast<int32>(GearValue);
        SetGear(gear);
        bChanged = false;
    }

    FORCEINLINE void ResetGear()
    {
        ThrustScale = 0.f;
        SteerScale = 0.f;
        GearValue = EShipGear::Stopped;
        int gear = static_cast<int32>(Posture) * 4 + static_cast<int32>(GearValue);
        SetGear(gear);
        bChanged = false;
    }

    FORCEINLINE bool IsZero()
    {
        return FMath::Abs(ThrustScale) < ThrustScalePrecision
            && FMath::Abs(SteerScale) < SteerScalePrecision
            && Gear == 0;
    }

    FORCEINLINE void SetThrustScale(float ScaleValue)
    {
        if (FPiratesMovementUtil::CheckFloatEqual(ScaleValue, ThrustScale, ThrustScalePrecision))
            return;

        ThrustScale = ScaleValue;
        bChanged = true;
    }

    FORCEINLINE void SetSteerScale(float ScaleValue)
    {
        if (FPiratesMovementUtil::CheckFloatEqual(ScaleValue, SteerScale, SteerScalePrecision))
            return;

        SteerScale = ScaleValue;
        bChanged = true;
    }

    FORCEINLINE void SetGear(int32 InGear)
    {
        if (InGear == Gear)
            return;

        Gear = InGear;
        bChanged = true;
    }

    FORCEINLINE void SetGearValue(EShipGear InGear)
    {
        if (InGear == GearValue)
            return;

        GearValue = InGear;
        bChanged = true;
    }

    FORCEINLINE void SetPosture(EShipPosture InPosture)
    {
        if (InPosture == Posture)
            return;

        Posture = InPosture;
        bChanged = true;
    }

    FORCEINLINE float GetThrustScale() const { return ThrustScale; }
    FORCEINLINE float GetSteerScale() const { return SteerScale; }
    FORCEINLINE int32 GetGear() const { return Gear; }
    FORCEINLINE EShipGear GetGearValue() const { return GearValue; }
    FORCEINLINE EShipPosture GetPosture() const { return Posture; }

    bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess)
    {
        Ar << ThrustScale;
        Ar << SteerScale;
        Ar << Gear;

        return bOutSuccess;
    }


protected:

    UPROPERTY(Transient, BlueprintReadOnly)
    float ThrustScale;

    UPROPERTY(Transient, BlueprintReadOnly)
    float SteerScale;

    UPROPERTY(Transient, BlueprintReadOnly)
    int32 Gear;

    UPROPERTY(Transient, BlueprintReadOnly)
    EShipGear GearValue;

    UPROPERTY(Transient, BlueprintReadOnly)
    EShipPosture Posture;


private:

    static CONSTEXPR float ThrustScalePrecision = 0.01f;
    static CONSTEXPR float SteerScalePrecision = 0.01f;

    bool bChanged;
};
template<>
struct TStructOpsTypeTraits<FShipInputData> : public TStructOpsTypeTraitsBase2<FShipInputData>
{
    enum
    {
        WithNetSerializer = true
    };
};

UENUM(BlueprintType)
enum class EShipSailState : uint8
{
    Stopped,
    Accelerating,
    Decelerating,
    FullSpeed
};

UENUM(BlueprintType)
enum class EShipImpactArea : uint8
{
    Front,
    Middle,
    Back,
};

UENUM(BlueprintType)
enum class EShipImpactType : uint8
{
    Ship,
    Land,
    Border,
    Human,
};

USTRUCT(BlueprintType)
struct FShipMoveData
{
    GENERATED_USTRUCT_BODY()

    FShipMoveData()
        : Location(FVector::ZeroVector), Yaw(0.f)
        , LinearSpeed(0.f), AngularSpeed(0.f)
    {}


    bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess)
    {
        Ar << Location.X;
        Ar << Location.Y;
        Ar << Yaw;
        Ar << LinearSpeed;
        Ar << AngularSpeed;

        Location.Z = 0.f;
        return bOutSuccess;
    }


    UPROPERTY(Transient)
    FVector Location;

    UPROPERTY(Transient)
    float Yaw;

    UPROPERTY(Transient)
    float LinearSpeed;

    UPROPERTY(Transient)
    float AngularSpeed;
};
template<>
struct TStructOpsTypeTraits<FShipMoveData> : public TStructOpsTypeTraitsBase2<FShipMoveData>
{
    enum
    {
        WithNetSerializer = true
    };
};

USTRUCT(BlueprintType)
struct FShipMovementSyncData
{
    GENERATED_USTRUCT_BODY()

    FShipMovementSyncData()
        : SerializeFlag(STANDARD_SERIALIZE_FLAG), MoveFlags(0), Timestamp(0.f)/*, Velocity(FVector::ZeroVector)*/
    {}

    FShipMovementSyncData& SyncCopy(const FShipMovementSyncData& Other)
    {
        if (this != &Other)
        {
//             SerializeFlag = Other.SerializeFlag;
            if (HasSerializeFlag(ESerializeFlag::HasInputData))
            {
                this->InputData = Other.InputData;
            }
//             if (HasSerializeFlag(ESerializeFlag::HasMoveData))
//             {
                this->MoveData = Other.MoveData;
//             }
//             if (HasSerializeFlag(ESerializeFlag::HasMoveFlags))
//             {
                this->MoveFlags = Other.MoveFlags;
//             }
//             if (HasSerializeFlag(ESerializeFlag::HasTimestamp))
//             {
//                 this->Timestamp = Other.Timestamp;
//             }
        }

        return *this;
    }


    enum class ESerializeFlag : uint8
    {
        None = 0,
        HasInputData = 1,
        HasMoveData = 2,
        HasMoveFlags = 4,
//         HasTimestamp = 8,
    };

    bool HasSerializeFlag(ESerializeFlag Flag) const
    {
        uint8 f = (uint8)Flag;
        return (SerializeFlag & f) == f;
    }

    void SetSerializeFlag(ESerializeFlag Flag, bool bSet)
    {
        uint8 f = (uint8)Flag;
        if (bSet)
        {
            SerializeFlag |= f;
        }
        else
        {
            SerializeFlag &= ~f;
        }
    }

    void SetSerializeFlag(uint8 Flag) { SerializeFlag = Flag; }

    bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess)
    {
        bOutSuccess = true;
//         Ar << SerializeFlag;

        if (HasSerializeFlag(ESerializeFlag::HasInputData))
        {
            bOutSuccess = InputData.NetSerialize(Ar, Map, bOutSuccess);
        }
//         if (HasSerializeFlag(ESerializeFlag::HasMoveData))
//         {
            bOutSuccess = MoveData.NetSerialize(Ar, Map, bOutSuccess);
//         }
//         if (HasSerializeFlag(ESerializeFlag::HasMoveFlags))
//         {
            Ar << MoveFlags;
//         }
//         if (HasSerializeFlag(ESerializeFlag::HasTimestamp))
//         {
//             Ar << Timestamp;
//         }
//        UE_LOG(LogShipMovement, Error, TEXT("Ship NetSerialize"));
        return bOutSuccess;
    }

    FString ToDebugString() const
    {
        return FString::Printf(TEXT(
            "{{ThrustScale = %f, SteerScale = %f, Gear = %i}, {Yaw = %f, LinearSpeed = %f, AngularSpeed = %f}, MoveFlags = %i}"),
            InputData.GetThrustScale(), InputData.GetSteerScale(), InputData.GetGear(),
            MoveData.Yaw, MoveData.LinearSpeed, MoveData.AngularSpeed, MoveFlags
        );
    }


    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    uint8 SerializeFlag;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    FShipInputData InputData;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    FShipMoveData MoveData;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    uint8 MoveFlags;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float Timestamp;

    //Standard flag is (HasInputData | HasMoveData | HasMoveFlags | HasTimestamp) == 15
    //Standard flag is (HasMoveData | HasMoveFlags) == 6
    //Standard flag is (HasInputData | HasMoveData | HasMoveFlags) == 7
    static CONSTEXPR uint8 STANDARD_SERIALIZE_FLAG = 7;
};
template<>
struct TStructOpsTypeTraits<FShipMovementSyncData> : public TStructOpsTypeTraitsBase2<FShipMovementSyncData>
{
    enum
    {
        WithNetSerializer = true
    };
};



USTRUCT(BlueprintType)
struct FShipMovementConfig
{
    GENERATED_USTRUCT_BODY()

    FShipMovementConfig()
        : ClientMinSyncInterval(0.f), ClientMaxSyncInterval(0.f), ServerMaxSyncInterval(0.f), MaxSimTimeDiff(0.f), ClientMaxLerpTime(0.f)
        , SweepPullBackDistance(0.f), MinAdjustDistanceForPenetration(0.f), MaxAdjustStepsForPenetration(0)
        , MinSlideSpeedFactor(0.f), MaxImpactResolveTime(0.f), ImpactMiddleAreaAngle(0.f)
        , ReturnToBasicGearLinearDecelerationMultiplier(1.f), ReturnToBasicGearAngularDecelerationMultiplier(1.f)
        , SafeTeleportDistance(0.f)
    {}


    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ClientMinSyncInterval;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ClientMaxSyncInterval;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ServerMaxSyncInterval;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float MaxSimTimeDiff;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ClientMaxLerpTime;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float SweepPullBackDistance;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float MinAdjustDistanceForPenetration;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    int32 MaxAdjustStepsForPenetration;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float MinSlideSpeedFactor;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float MaxImpactResolveTime;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ImpactMiddleAreaAngle;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    TArray<FShipGearData> BasicGearConfigs;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    FShipGearData CruiseGearConfig;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    TArray<FShipPathMoveGearConfig> PathMoveGearConfigs;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ReturnToBasicGearLinearDecelerationMultiplier;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float ReturnToBasicGearAngularDecelerationMultiplier;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
    float SafeTeleportDistance;
};


UCLASS(ClassGroup = Ship, meta = (BlueprintSpawnableComponent), Blueprintable)
class COMMON_API UShipMovementComponent : public UPawnMovementComponent, public IRVOAvoidanceInterface
{
    GENERATED_UCLASS_BODY()

public:

    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

    virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;

    virtual void StopActiveMovement() override;

    virtual void StopMovementImmediately() override;

    virtual float GetMaxSpeed() const override;

    virtual void Activate(bool bReset = false) override;

	virtual void Deactivate() override;


public:

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FShipInputDataChangedDelegate, const FShipInputData&, NewValue);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnShipInputDataChanged"))
    FShipInputDataChangedDelegate OnShipInputDataChanged;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FShipGearValueChangedDelegate, EShipGear, NewGear, EShipGear, OldGear);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnGearValueChanged"))
    FShipGearValueChangedDelegate OnGearValueChanged;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FShipSailStateChangedDelegate, EShipSailState, OldState, EShipSailState, NewState, int32, Gear);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnShipSailStateChanged"))
    FShipSailStateChangedDelegate OnShipSailStateChanged;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_FourParams(FShipStartImpactDelegate, EShipImpactType, Type, AActor*, Target, EShipImpactArea, Area, const FVector&, Location);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnShipStartImpact"))
    FShipStartImpactDelegate OnShipStartImpact;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE(FShipEndImpactDelegate);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnShipEndImpact"))
    FShipEndImpactDelegate OnShipEndImpact;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FShipPathMoveFinishedDelegate, EMapNavGridPathFollowingResult, Result);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnShipPathMoveFinished"))
    FShipPathMoveFinishedDelegate OnShipPathMoveFinished;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FShipMoveStateChangedDelegate, bool, IsMoving);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnShipMoveStateChanged"))
    FShipMoveStateChangedDelegate OnShipMoveStateChanged;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FShipPathMoveImpactStopDelegate, FVector, ImpactPoint);
    UPROPERTY(BlueprintAssignable, meta = (DisplayName = "OnShipPathMoveImpactStop"))
    FShipPathMoveImpactStopDelegate OnShipPathMoveImpactStop;

public:
    /** Immediate stop switch. */
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    bool ImmediateStopEnabled;

    /* 作弊测试 */
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float DebugIllegalSpeed;

public:

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void InitData(bool bInHubMode, const FShipMovementConfig& InConfig);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void ResetMovement();

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void TeleportShip(const FVector& Location, float Yaw, bool bResetMovement);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void TeleportToSafeLocation();

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void MoveShipToSafeLocation();

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void SetGearData(const TArray<FShipGearData>& InGears);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void SpeedUp(float ScaleValue)
    {
        InputData.SetThrustScale(ScaleValue);
    }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void SteerRight(float ScaleValue)
    {
        InputData.SetSteerScale(ScaleValue);
        InputDataChangedSync();
    }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void StopMove();

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void Brake();

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void SetMoveEnable(bool bEnable) { bMoveEnable = bEnable; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    bool SetGearAndPosture(EShipGear Gear, EShipPosture Posture);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    bool SetBasicGear(EShipGear Gear);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    bool SetPosture(EShipPosture Posture);

    UFUNCTION(Category = "ShipMovement", BlueprintPure)
	EShipPosture GetPosture() { return InputData.Posture; }

    UFUNCTION(Category = "ShipMovement", BlueprintPure)
    EShipGear GetBasicGear() { return InputData.GearValue; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	bool SetGear(int Gear);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	int GetGear() { return InputData.Gear; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	bool IsBraking() const { return InputData.GearValue == EShipGear::Stopped; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	int GetGearNum() const { return Gears.Num(); }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void SetUseAccelerationLinearSpeed(bool bUse) { bUseAccelerationLinearSpeed = bUse; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void SetCurrentLinearSpeed(float LinearSpeed) { CurrentLinearSpeed = LinearSpeed; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    float GetCurrentLinearAcceleration() const { return CurrentLinearAcceleration; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	float GetCurrentLinearSpeed() const { return CurrentLinearSpeed; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	float GetCurrentAngularSpeed() const { return CurrentAngularSpeed; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	float GetCurrentMaxLinearSpeed() const { return GetMaxLinearSpeed(); }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	float GetCurrentMaxAngularSpeed() const { return GetMaxAngularSpeed(); }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	float GetAngluarSpeedRatio() const
    {
        float MaxSpeed = GetMaxAngularSpeed();
        return (MaxSpeed > 0.f) ? CurrentAngularSpeed / MaxSpeed : 0.f;
    }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    FVector GetShipLocation() const { return UpdatedPrimitive->GetComponentLocation(); }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    FRotator GetShipRotation() const { return UpdatedPrimitive->GetComponentRotation(); }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    FQuat GetShipQuaternion() const { return UpdatedPrimitive->GetComponentQuat(); }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    FVector GetShipDirection() const { return ShipDirection; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    uint8 GetShipMoveFlags() const { return ShipMoveFlags; }

    UFUNCTION(Category = "ShipMovement|PathMove", BlueprintCallable)
    void StartShipPathMove(const TArray<FVector>& InPath, float AcceptanceRadius, bool bStopOnFinish);

    UFUNCTION(Category = "ShipMovement|PathMove", BlueprintCallable)
    void AbortShipPathMove(EMapNavGridPathFollowingResult Result = EMapNavGridPathFollowingResult::Aborted);

    UFUNCTION(Category = "ShipMovement|PathMove", BlueprintCallable)
    bool IsShipPathMove() const { return (bRequestPathMove == true || NavPath.Num() > 0); }

    UFUNCTION(Category = "ShipMovement|PathMove", BlueprintCallable)
    int32 GetShipPathMoveCurrentIndex() const { return CurrentPathIndex; }

    UFUNCTION(Category = "ShipMovement|PathMove", BlueprintCallable)
    const TArray<FVector>& GetShipPathMoveNavPath() const { return NavPath; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    bool IsValid() const { return PawnOwner && !PawnOwner->IsPendingKill(); }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    float GetMaxBasicSpeed();

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void UpdateShipTransformRestrictly(float LocationZ, float Pitch, float Roll);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void AddShipMoveGearBuff(bool bBasic, EShipMoveGearBuffType Type, float Value);

    //TODO:@liujifang 等lua清理完，将此接口删掉！
    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void AddShipMoveGearValueBuff(bool bBasic, EShipMoveGearBuffType Type, float Value) {}

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void SetShipMoveGearBuff(bool bBasic, int MaxLinearSpeed, int LinearAcceleration, int LinearDeceleration,
        int MaxAngularSpeed, int AngularAcceleration, int AngularDeceleration);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    float GetShipMoveGearBuffValue(bool bBasic, EShipMoveGearBuffType Type);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void EmptyShipMoveGearBuff(bool bBasic, EShipMoveGearBuffType Type);

	UFUNCTION(Category = "ShipMovement", BlueprintCallable)
	void EmptyAllShipMoveGearBuff(bool bBasic);

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    bool IsShipMoving() { return bShipMoving; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    int32 IncreaseViewers();

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    int32 DecreaseViewers();

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    FRotator GetViewerRotator() { return ViewerRotator; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void SetStartTotalDistance(bool bStart) { bStartTotalDistance = bStart; }

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    float GetTotalDistance() { return TotalDistance; }

public:

    // xwh: If true tick DeltaTime will be clamped due to a long tick.
    UPROPERTY(Category = "ShipMovement", EditAnywhere, BlueprintReadWrite, meta = (DefaultValue = "false"))
    bool AvoidLongTickInterval = false;

    // xwh: How we define a long tick.
    UPROPERTY(Category = "ShipMovement", EditAnywhere, BlueprintReadWrite, meta = (DefaultValue = 0.036f))
    float MaxTickInterval = 0.036f;

    UPROPERTY(Category = "ShipMovement", EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "0.0166", ClampMax = "0.50", UIMin = "0.0166", UIMax = "0.50"))
    float MaxSimulationTimeStep;

    UPROPERTY(Category = "ShipMovement", EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "1", ClampMax = "25", UIMin = "1", UIMax = "25"))
    int32 MaxSimulationIterations;

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void Debug_SetCurrentGearData(EShipMoveGearBuffType Type, float Value);

    UFUNCTION(Reliable, Client)
    void ClientSetCurrentGearDataForDebug(EShipMoveGearBuffType Type, float Value);

    void Debug_SetCurrentGearDataInternal(EShipMoveGearBuffType Type, float Value);


    UPROPERTY(Category = "ShipMovement", EditAnywhere, BlueprintReadWrite, meta = (DefaultValue = "true"))
    bool UpdatedPrimitiveMoveEnabled = true;

    UPROPERTY(Category = "ShipMovement", EditAnywhere, BlueprintReadWrite, meta = (DefaultValue = "false"))
    bool bDrawDebugInEditor = false;

    UPROPERTY(Category = "ShipMovement", EditAnywhere, BlueprintReadWrite, meta = (DefaultValue = "true"))
    bool bNeedAdjustPostion = true;

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void Debug_CloseCollision(bool bClose) {}

    UFUNCTION(Category = "ShipMovement", BlueprintCallable)
    void DrawDebugGrids(const FVector& Location, bool bDrawNeighbors, float ExitTime);



protected:

    UPROPERTY(Category = "ShipMovement", VisibleAnywhere)
    FShipMovementConfig Config;

    UPROPERTY(Category = "ShipMovement", VisibleAnywhere)
    TArray<FShipGearData> Gears;

    UPROPERTY(Category = "ShipMovement", EditAnywhere, BlueprintReadWrite)
    float UpdatePrimitiveZ = 0.f;

private:

    struct FTransformNonManagedValue
    {
        FTransformNonManagedValue()
            : Z(0.f), Pitch(0.f), Roll(0.f), bChanged(false)
        {}

        float Z;
        float Pitch;
        float Roll;

        bool bChanged;
    };

    FTransformNonManagedValue TransformNonManagedValue;

    APiratesShipPawn* ShipPawn;
    const FMapNavGridLayout* GridLayout;

    EShipSailState SailState;
    bool bShipMoving;

    FShipInputData InputData;
    float CurrentLinearSpeed;
    float CurrentAngularSpeed;
    float CurrentLinearAcceleration;
    FVector ShipDirection;
    float ShipYaw;
    uint8 ShipMoveFlags;
    bool bUseAccelerationLinearSpeed;

    int32 MaxGear;
    int32 MaxBasicGear;
    int32 CruiseGear;

    bool bStartTotalDistance;
    float TotalDistance;

    float ImpactVelocitySize;
    FVector ImpactVelocityNormal;
    float LeftImpactResolveTime;
    float ImpactAreaPartitionBound;

    FCollisionShape CollisionShape;
    FCollisionQueryParams CollisionQueryParams;
    FCollisionResponseParams CollisionResponseParams;
    ECollisionChannel CollisionChannel;

    FVector SpeedHackLocation;
    float SpeedHackTimeStamp;
    int32 SpeedIllegalCount;
    int32 LocationIllegalCount;
    uint8 bUseClientMovementSync;

    FRotator ViewerRotator;

private:

    enum class EMoveFlag : uint8
    {
        None = 0,
        Correcting = 1,
        Impacted = 2,
        Teleported = 4,
        GearUpdated = 8,
        InputChanging = 16,
    };

    FORCEINLINE bool GetShipMoveFlag(uint8 Flags, EMoveFlag Flag)
    {
        uint8 f = (uint8)Flag;
        return (Flags & f) == f;
    }

    FORCEINLINE void SetShipMoveFlag(uint8& OutFlags, EMoveFlag Flag, bool bSet)
    {
        uint8 f = (uint8)Flag;
        if (bSet)
        {
            OutFlags |= f;
        }
        else
        {
            OutFlags &= ~f;
        }
    }

    FORCEINLINE bool GetShipMoveFlag(EMoveFlag Flag)
    {
        return GetShipMoveFlag(ShipMoveFlags, Flag);
    }

    FORCEINLINE void SetShipMoveFlag(EMoveFlag Flag, bool bSet)
    {
        SetShipMoveFlag(ShipMoveFlags, Flag, bSet);
    }

private:

    bool AccquireGridLayout();
    bool MoveShipSweepTest(const FQuat& TestQuat, float SteerScale, const FVector& VelocityNormal, FVector& OutStartLoc, FVector& OutEndLoc, FHitResult& OutHitResult);

    void ResolvePenetration(const FQuat& TestQuat, float SteerScale, FVector& OutStartLoc, FVector& OutEndLoc, FHitResult& OutHitResult);
    void OnFailToResolvePenetration();
    void ResolveShipImpact(const FHitResult& HitResult, const UShipMovementComponent& OtherMovementComp);
    EShipImpactArea GetShipImpactArea(const FHitResult& HitResult, const UShipMovementComponent& OtherMovementComp);
    float ResolveBorderImpact(const FHitResult& HitResult);
    void ResolveLandImpact(const FHitResult& HitResult);

    void SetSailState(EShipSailState InNewState, int32 InGear);
    void SetShipMoveState(float Distance);

    bool CheckMovementIllegal(float DeltaSeconds);

private:

    float ComputeMovementDistanceNew(const FShipInputData& InInputData, float InDeltaSeconds, float& LinearSpeed);
    float ComputeMovementDegreeNew(const FShipInputData& InInputData, float InDeltaSeconds, float& AngularSpeed);
    bool ComputeLinearSpeedNew2(const FShipInputData& InInputData, float& LinearSpeed, float& LeftSeconds);
    bool ComputeAngularSpeedNew(const FShipInputData& InInputData, float& AngularSpeed, float& LeftSeconds);

private:

    FORCEINLINE float GetLinearAcceleration(int32 Gear) const 
    { 
        if (Gear < 0 || Gear >= Gears.Num())
        {
            return 0.f;
        }
        return Gears[Gear].GetLinearAcceleration(); 
    }
    FORCEINLINE float GetLinearAcceleration() const { return GetLinearAcceleration(InputData.Gear); }

    FORCEINLINE float GetLinearDeceleration(int32 Gear) const 
    {
        if (Gear < 0 || Gear >= Gears.Num())
        {
            return 0.f;
        }
        return Gears[Gear].GetLinearDeceleration(); 
    }
    FORCEINLINE float GetLinearDeceleration() const { return GetLinearDeceleration(InputData.Gear); }

    FORCEINLINE float GetMaxLinearSpeed(int32 Gear) const 
    { 
        if (Gear < 0 || Gear >= Gears.Num())
        {
            return 0.f;
        }
        return Gears[Gear].GetMaxLinearSpeed(); 
    }

    FORCEINLINE float GetMaxLinearSpeed() const { return GetMaxLinearSpeed(InputData.Gear); }

    FORCEINLINE float GetAngularAcceleration(int32 Gear) const 
    { 
        if (Gear < 0 || Gear >= Gears.Num())
        {
            return 0.f;
        }
        return Gears[Gear].GetAngularAcceleration();
    }
    FORCEINLINE float GetAngularAcceleration() const { return GetAngularAcceleration(InputData.Gear); }

    FORCEINLINE float GetMaxAngularSpeed(int32 Gear) const 
    {
        if (Gear < 0 || Gear >= Gears.Num())
        {
            return 0.f;
        }
        return Gears[Gear].GetMaxAngularSpeed(); 
    }
    FORCEINLINE float GetMaxAngularSpeed() const { return GetMaxAngularSpeed(InputData.Gear); }

    FORCEINLINE float GetAngularDeceleration(int32 Gear) const 
    { 
        if (Gear < 0 || Gear >= Gears.Num())
        {
            return 0.f;
        }
        return Gears[Gear].GetAngularDeceleration(); 
    }
    FORCEINLINE float GetAngularDeceleration() const { return GetAngularDeceleration(InputData.Gear); }

private:

    enum class EMovementSyncState : uint8
    {
        None,
        Successful,
        Failed,
        Interpolating
    };

    EMovementSyncState MovementSyncState;
    float LastCheckTimestamp;
    float CurrentSimTimestamp;
    float AccumulatedSimTimeDiff;
    FShipMovementSyncData SyncClientData;

    bool bForceSync;

    float LeftLerpTime;
    float LerpLinearSpeed;
    float LerpAngularSpeed;
    float LerpShipYaw;
    FVector LerpShipLocation;
    float MaxDelayTime;
    float MinLocDiffThreshold;
    float MinYawDiffThreshold;
    float MaxSmoothMoveTime;

private:

    UPROPERTY(Category = "ShipMovement", EditDefaultsOnly, Replicated)
    int32 ViewersNum;

    UPROPERTY(Category = "ShipMovement", EditDefaultsOnly, Replicated)
    uint8 bMoveEnable;

    UPROPERTY(Category = "ShipMovement", EditDefaultsOnly, ReplicatedUsing = OnRep_SyncData)
    FShipMovementSyncData SyncServerData;

    UFUNCTION()
    void OnRep_SyncData();

    UPROPERTY(Category = "ShipMovement", EditDefaultsOnly, ReplicatedUsing = OnRep_GearBuff)
    FShipMoveGearBuff BasicGearBuff[(int)EShipMoveGearBuffType::NUM];

    UFUNCTION()
    void OnRep_GearBuff();


private:

    UFUNCTION(Reliable, Client)
    void ClientSendInput(const FShipInputData& Input);

    UFUNCTION(Reliable, Server, WithValidation)
    void ServerSendInput(const FShipInputData& Input);

    UFUNCTION(Reliable, Server, WithValidation)
    void ServerStopMove();

    UFUNCTION(Reliable, Server, WithValidation)
    void ServerRequestChangeGear(const FShipInputData& Input);

    UFUNCTION(unreliable, Server, WithValidation)
    void ServerSendViewerRotator(FRotator NewRotator);

    UFUNCTION(unreliable, server, WithValidation)
    void ServerMove(FVector Location, float Yaw);

private:

    bool MoveShip(float Degree, float Distance, float DeltaTime);
    void SmoothMove(float DeltaTime);
    void ProcessAuthorityRole(float DeltaTime);
    void ProcessAutonomousRole(float DeltaTime);
    void ProcessSimulatedRole(float DeltaTime);

    float GetSimulationTimeStep(float RemainingTime, int32 Iterations) const;

    void FillSyncData(FShipMovementSyncData& OutData);
    void SetShipTransform(const FVector& Location, float Yaw);

    void SetShipMoveGearBuffInternal(bool bBasic, EShipMoveGearBuffType Type, float Value);
	void AddShipMoveGearBuffInternal(bool bBasic, EShipMoveGearBuffType Type, float Value);
	void EmptyShipMoveGearBuffInternal(bool bBasic, EShipMoveGearBuffType Type);
	void EmptyAllShipMoveGearBuffInternal(bool bBasic);

    void InputDataChangedSync();
    void CheckInputData(const FShipInputData& ServerInput);

public:

    bool IsSameNavDestLocation(const FVector& DestLocation);

    void RefreshShipBoxExtend(float BoxExtendZ);
    
private:

    TArray<FShipPathMoveGearData> PathMoveGears;
    bool bRequestPathMove;
    TArray<FVector> NavPath;
    int32 CurrentPathIndex;
    int32 MaxPathIndex;
    int32 CheckFinalRadiusIndex;
    FVector PathMoveCurrentVector;
    FVector PathMoveNextVector;
    float PathMoveSteerAngle;
    float PathMoveNextMoveDistance;
    float PathMoveNextMoveDistanceSq;
    float FinalAcceptanceRadius;
    float FinalAcceptanceRadiusSq;
    float IntermedialAcceptanceRadius;
    bool bStopOnPathMoveFinished;
    bool bPathMoveSteerInSitu;
    bool bPathMoveLockGear;
    

private:

    void ProcessPathMoveRequest(float DeltaTime);

    void OnPathMoveFinished(EMapNavGridPathFollowingResult Result);

    int32 GetPathMoveGearIndex(int32 StartIndex, float CosAngleSq, float MinDistanceSq);

    FORCEINLINE int32 GetPathMoveGearIndexByNextNavPoint(int32 StartIndex)
    {
        float NextProjectionDistance = PathMoveNextVector | ShipDirection;
        float CosAngleSq = FMath::Square(NextProjectionDistance) / PathMoveNextMoveDistanceSq;
        if (NextProjectionDistance < 0.f)
        {
            CosAngleSq = -CosAngleSq;
        }

        return GetPathMoveGearIndex(StartIndex, CosAngleSq, PathMoveNextMoveDistanceSq);
    }

    FORCEINLINE float GetPathMoveBrakeDistance(int32 Gear)
    {
        return -FMath::Square(CurrentLinearSpeed) / (2.f * GetLinearDeceleration(Gear));
    }

    FORCEINLINE int32 GetPathMoveBrakeGearIndex()
    {
        for (int32 i = 0; i < PathMoveGears.Num(); ++i)
        {
            if (GetMaxLinearSpeed(PathMoveGears[i].Gear) > 0.f)
            {
                return i;
            }
        }

        return 0;
    }


public:
    /** Change avoidance state and register with RVO manager if necessary */
    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|ShipMovement")
    void SetAvoidanceEnabled(bool bEnable);

    virtual void SetUpdatedComponent(USceneComponent* NewUpdatedComponent) override;

protected:
    // RVO Avoidance

    /** If set, component will use RVO avoidance */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadWrite)
    uint32 bUseRVOAvoidance : 1;

    /** Vehicle Radius to use for RVO avoidance (usually half of vehicle width) */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadWrite)
    float RVOAvoidanceRadius;

    /** Vehicle Height to use for RVO avoidance (usually vehicle height) */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadWrite)
    float RVOAvoidanceHeight;

    /** Area Radius to consider for RVO avoidance */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadWrite)
    float AvoidanceConsiderationRadius;

    /** calculate RVO avoidance and apply it to current velocity, return if enter avoidance phase */
    virtual bool CalculateAvoidanceVelocity(float DeltaTime);

    /** No default value, for now it's assumed to be valid if GetAvoidanceManager() returns non-NULL. */
    UPROPERTY(Category = "Avoidance", VisibleAnywhere, BlueprintReadOnly, AdvancedDisplay)
    int32 AvoidanceUID;

    /** Moving actor's group mask */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadOnly, AdvancedDisplay)
    FNavAvoidanceMask AvoidanceGroup;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|ShipMovement")
    void SetAvoidanceGroup(int32 GroupFlags);

    /** Will avoid other agents if they are in one of specified groups */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadOnly, AdvancedDisplay)
    FNavAvoidanceMask GroupsToAvoid;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|ShipMovement")
    void SetGroupsToAvoid(int32 GroupFlags);

    /** Will NOT avoid other agents if they are in one of specified groups, higher priority than GroupsToAvoid */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadOnly, AdvancedDisplay)
    FNavAvoidanceMask GroupsToIgnore;

    UFUNCTION(BlueprintCallable, Category = "Pawn|Components|ShipMovement")
    void SetGroupsToIgnore(int32 GroupFlags);

    /** De facto default value 0.5 (due to that being the default in the avoidance registration function), indicates RVO behavior. */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadOnly)
    float AvoidanceWeight;

    /** 2D max velocity in avoidance. */
    UPROPERTY(Category = "Avoidance", EditAnywhere, BlueprintReadWrite)
    float MaxAvoidanceVelocity2D;



protected:
    /** Update RVO Avoidance for simulation */
    void UpdateAvoidance(float DeltaTime);

    /** called in Tick to update data in RVO avoidance manager */
    void UpdateDefaultAvoidance();

    /** lock avoidance velocity */
    void SetAvoidanceVelocityLock(class UAvoidanceManager* Avoidance, float Duration);

    /** Was avoidance updated in this frame? */
    UPROPERTY(Transient)
    uint32 bWasAvoidanceUpdated : 1;

    /** Calculated avoidance velocity used to adjust steering and throttle */
    FVector AvoidanceVelocity;

    /** forced avoidance velocity, used when AvoidanceLockTimer is > 0 */
    FVector AvoidanceLockVelocity;

    /** remaining time of avoidance velocity lock */
    float AvoidanceLockTimer;

    bool bInAvoidancePhase;

    float RVOCalcSteering();

    virtual float RVOCalcThrottle();

    /** BEGIN IRVOAvoidanceInterface */
    virtual void SetRVOAvoidanceUID(int32 UID) override;
    virtual int32 GetRVOAvoidanceUID() override;
    virtual void SetRVOAvoidanceWeight(float Weight) override;
    virtual float GetRVOAvoidanceWeight() override;
    virtual FVector GetRVOAvoidanceOrigin() override;
    virtual float GetRVOAvoidanceRadius() override;
    virtual float GetRVOAvoidanceHeight() override;
    virtual float GetRVOAvoidanceConsiderationRadius() override;
    virtual FVector GetVelocityForRVOConsideration() override;
    virtual int32 GetAvoidanceGroupMask() override;
    virtual int32 GetGroupsToAvoidMask() override;
    virtual int32 GetGroupsToIgnoreMask() override;
    /** END IRVOAvoidanceInterface */
};
