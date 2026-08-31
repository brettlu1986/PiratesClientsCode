// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/ShipMovementComponent.h"
#include "Common.h"
#include "Net/UnrealNetwork.h"
#include "AI/Navigation/AvoidanceManager.h"
#include "Pawns/PiratesShipPawn.h"
#include "MapNavGridLayout.h"
#include "Game/GameCommon.h"
#include "OceanNavGridManager.h"
#include "PiratesGameState.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "Game/Delegates/PiratesMovementDelegate.h"
#include "Shell/CommonShell.h"
#include "Game/Delegates/GameDelegateManager.h"

DEFINE_LOG_CATEGORY_STATIC(LogShipMovement, Log, All);

int32 CVar_ShipMovementDrawServerLoction = 0;
static FAutoConsoleVariableRef CVarShipMovementDrawServerLoction(TEXT("ShipMovement.DrawServerLocation"), CVar_ShipMovementDrawServerLoction, TEXT(""), ECVF_Default);

int32 CVar_ShipMovementMaxSmoothTime = 0;
static FAutoConsoleVariableRef CVarShipMovementMaxSmoothTime(TEXT("ShipMovement.MaxSmoothTime"), CVar_ShipMovementMaxSmoothTime, TEXT(""), ECVF_Default);

int32 CVar_ShipMovementLerpTime = 2;
static FAutoConsoleVariableRef CVarShipMovementLerpTime(TEXT("ShipMovement.LerpTime"), CVar_ShipMovementLerpTime, TEXT(""), ECVF_Default);

UShipMovementComponent::UShipMovementComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    PrimaryComponentTick.bCanEverTick = true;
    PrimaryComponentTick.bStartWithTickEnabled = false;
    PrimaryComponentTick.TickGroup = TG_PrePhysics;
    bAutoActivate = 0;
    SetIsReplicatedByDefault(true);
    bUseAccelerationForPaths = false;
    bUpdateNavAgentWithOwnersCollision = true;

    MaxBasicGear = MaxGear = 0;

    ShipPawn = nullptr;
    GridLayout = nullptr;

    ImmediateStopEnabled = true;
    bMoveEnable = 1;

    //RVO
    bUseRVOAvoidance = false;
    AvoidanceVelocity = FVector::ZeroVector;
    AvoidanceLockVelocity = FVector::ZeroVector;
    AvoidanceLockTimer = 0.0f;
    AvoidanceGroup.bGroup0 = true;
    GroupsToAvoid.Packed = 0xFFFFFFFF;
    GroupsToIgnore.Packed = 0;
    RVOAvoidanceRadius = 400.0f;
    RVOAvoidanceHeight = 200.0f;
    AvoidanceConsiderationRadius = 2000.0f;
    bInAvoidancePhase = false;
    MaxAvoidanceVelocity2D = 800.0f;

    MaxSimulationTimeStep = 0.016667f;
    MaxSimulationIterations = 8;

}

void UShipMovementComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(UShipMovementComponent, SyncServerData);
    DOREPLIFETIME(UShipMovementComponent, BasicGearBuff);
    DOREPLIFETIME_CONDITION(UShipMovementComponent, ViewersNum, COND_AutonomousOnly);
    DOREPLIFETIME_CONDITION(UShipMovementComponent, bMoveEnable, COND_AutonomousOnly);
}

void UShipMovementComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
    //DeltaTime = AvoidLongTickInterval ? FMath::Clamp(DeltaTime, 0.0f, MaxTickInterval) : DeltaTime;
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    if (ShipPawn == nullptr)
    {
        UE_LOG(LogShipMovement, Warning, TEXT("Maybe Ship InitData error!"));
        return;
    }

    {
        FScopedMovementUpdate ScopedMovementUpdate(UpdatedPrimitive, EScopedUpdate::DeferredUpdates);

        if (!IsValid())
        {
            return;
        }

        // 不能移动，但是需要有浮力的效果
        if (!bMoveEnable)
        {
            MoveShip(0.f, 0.f, DeltaTime);
            //观战需要，镜头也需要更新
            if (PawnOwner->GetLocalRole() == ROLE_AutonomousProxy)
            {
                if (GetNetMode() == NM_Client)
                {
                    APlayerController* PC = Cast<APlayerController>(PawnOwner->GetController());
                    APlayerCameraManager* PlayerCameraManager = (PC ? PC->PlayerCameraManager : NULL);
                    if (PlayerCameraManager != NULL && PlayerCameraManager->bUseClientSideCameraUpdates)
                    {
                        PlayerCameraManager->bShouldSendClientSideCameraUpdate = true;
                    }
                }
            }
            return;
        }

        if (AvoidanceLockTimer > 0.0f)
        {
            AvoidanceLockTimer -= DeltaTime;
        }

        if (bUseRVOAvoidance)
        {
            bInAvoidancePhase = CalculateAvoidanceVelocity(DeltaTime);
            UpdateAvoidance(DeltaTime);
            SteerRight(RVOCalcSteering());
            SpeedUp(RVOCalcThrottle());
        }

        if (!bInAvoidancePhase)
        {
            ProcessPathMoveRequest(DeltaTime);
        }

        bInAvoidancePhase = false;

        if (PawnOwner->GetLocalRole() == ROLE_AutonomousProxy)
        {
            ProcessAutonomousRole(DeltaTime);

            if (GetNetMode() == NM_Client)
            {
                APlayerController* PC = Cast<APlayerController>(PawnOwner->GetController());
                APlayerCameraManager* PlayerCameraManager = (PC ? PC->PlayerCameraManager : NULL);
                if (PlayerCameraManager != NULL && PlayerCameraManager->bUseClientSideCameraUpdates)
                {
                    PlayerCameraManager->bShouldSendClientSideCameraUpdate = true;
                }
            }
        }
        else if (PawnOwner->GetLocalRole() == ROLE_Authority)
        {
            ProcessAuthorityRole(DeltaTime);
        }
        else if (PawnOwner->GetLocalRole() == ROLE_SimulatedProxy)
        {
            ProcessSimulatedRole(DeltaTime);
        }
    }

    if (PawnOwner->GetLocalRole() == ROLE_Authority && !bRequestPathMove && PawnOwner->IsPlayerControlled())
    {
        CheckMovementIllegal(DeltaTime);
    }
}

void UShipMovementComponent::StopActiveMovement()
{
    Super::StopActiveMovement();

    SteerRight(0.f);
    Brake();
}

void UShipMovementComponent::StopMovementImmediately()
{
    AbortShipPathMove(EMapNavGridPathFollowingResult::Aborted);

    if (ImmediateStopEnabled)
    {
        auto OldGear = InputData.GearValue;
        CurrentLinearSpeed = 0.f;
        CurrentAngularSpeed = 0.f;
        InputData.ResetGear();
        InputData.bChanged = true;
        OnGearValueChanged.Broadcast(EShipGear::Stopped, OldGear);

        this->Velocity = FVector::ZeroVector;

        if (PawnOwner->GetLocalRole() == ROLE_Authority)
        {
            ClientSendInput(InputData);
        }
        else if (PawnOwner->GetLocalRole() == ROLE_AutonomousProxy)
        {
            ServerStopMove();
        }
    }
}

void UShipMovementComponent::StopMove()
{
    auto OldGear = InputData.GearValue;
    InputData.ResetGear();
    InputData.bChanged = true;
    OnGearValueChanged.Broadcast(EShipGear::Stopped, OldGear);

    AbortShipPathMove(EMapNavGridPathFollowingResult::Aborted);

    if (PawnOwner->GetLocalRole() == ROLE_Authority)
    {
        ClientSendInput(InputData);
    }
}

float UShipMovementComponent::GetMaxSpeed() const
{
    return GetMaxLinearSpeed(Gears.Num() - 1);
}

void UShipMovementComponent::Activate(bool bReset)
{
    UActorComponent::Activate(bReset);
}

void UShipMovementComponent::Deactivate()
{
    UActorComponent::Deactivate();
}

void UShipMovementComponent::InitData(bool bInHubMode, const FShipMovementConfig& InConfig)
{
    ShipPawn = Cast<APiratesShipPawn>(PawnOwner);
    check(ShipPawn != nullptr);

    if (UpdatedPrimitive == nullptr)
    {
        UpdatedPrimitive = Cast<UPrimitiveComponent>(ShipPawn->GetRootComponent());
        check(UpdatedPrimitive != nullptr);
    }

    bUseClientMovementSync = 1;
    MaxSmoothMoveTime = 1.0f / 30.f;

    PathMoveSteerAngle = 0.f;

    Config = InConfig;
    bShipMoving = false;

    ViewersNum = 0;
    ViewerRotator = FRotator::ZeroRotator;

    SetGearData(InConfig.BasicGearConfigs);
    ResetMovement();

    bStartTotalDistance = false;
    TotalDistance = 0.f;

    if (AccquireGridLayout())
    {
        FVector Loc = GetShipLocation();
        GridLayout->BoundToMap(Loc);

        if (!GridLayout->IsReachable(Loc))
        {
            FVector SafeLoc;
            if (GridLayout->GetNearestReachableLocation(Loc, GridLayout->GetGridLength() * 2.f, SafeLoc))
            {
				check(UpdatedPrimitive->GetNumChildrenComponents() > 0);
                USceneComponent* FlotageRoot = Cast<USceneComponent>(UpdatedPrimitive->GetChildComponent(0));
				check(FlotageRoot != nullptr);

				FVector LocShipBox(SafeLoc.X, SafeLoc.Y, UpdatePrimitiveZ);
				UpdatedPrimitive->SetWorldLocation(LocShipBox, false, nullptr, ETeleportType::TeleportPhysics);

				FVector LocFloatage(0.0f, 0.0f, SafeLoc.Z);
				FlotageRoot->SetRelativeLocation(LocFloatage, false, nullptr, ETeleportType::TeleportPhysics);
            }
        }
    }

    CollisionChannel = UpdatedPrimitive->GetCollisionObjectType();
    CollisionShape = UpdatedPrimitive->GetCollisionShape();
//     if (CollisionShape.IsBox())
//     {
//         auto BoxExtent = CollisionShape.GetBox();
//         if (BoxExtent.Z > 500.f)
//         {
//             BoxExtent.Z = 500.f;
//         }
//         CollisionShape.SetBox(BoxExtent);
//     }

    FVector Extent = CollisionShape.GetExtent();
    NavAgentProps.AgentRadius = Extent.Size2D();
    NavAgentProps.AgentHeight = Extent.Z;

    if (UpdatedPrimitive->IsCollisionEnabled())
    {
        UpdatedPrimitive->SetCollisionResponseToChannel(CollisionChannel, ECR_Block);
    }

    ImpactAreaPartitionBound = FMath::Cos(FPiratesMovementUtil::DegreesToRadiansFactor * (90.f - Config.ImpactMiddleAreaAngle * 0.5f));

    MaxDelayTime = Config.ClientMaxLerpTime + Config.MaxSimTimeDiff;
    MinLocDiffThreshold = GetMaxLinearSpeed(MaxBasicGear) * MaxDelayTime;
    MinYawDiffThreshold = GetMaxAngularSpeed(MaxBasicGear) * MaxDelayTime;

    CollisionQueryParams = FComponentQueryParams(FName(TEXT("ShipMovementComponent")), PawnOwner);
    UpdatedPrimitive->InitSweepCollisionParams(CollisionQueryParams, CollisionResponseParams);

    if (HasBegunPlay())
    {
        Activate();
    }
    else
    {
        bAutoActivate = 1;
    }   
}

void UShipMovementComponent::RefreshShipBoxExtend(float BoxExtendZ)
{
    BoxExtendZ = 200.f;
    UBoxComponent* BoxCollision = Cast<UBoxComponent>(UpdatedPrimitive);
    if (BoxCollision)
    {
        FVector Extend = BoxCollision->GetUnscaledBoxExtent();
        BoxCollision->SetBoxExtent(FVector(Extend.X, Extend.Y, FMath::Abs(BoxExtendZ)));
    }

    CollisionChannel = UpdatedPrimitive->GetCollisionObjectType();
    CollisionShape = UpdatedPrimitive->GetCollisionShape();

    FVector Extent = CollisionShape.GetExtent();
    NavAgentProps.AgentRadius = Extent.Size2D();
    NavAgentProps.AgentHeight = Extent.Z;

    if (UpdatedPrimitive->IsCollisionEnabled())
    {
        UpdatedPrimitive->SetCollisionResponseToChannel(CollisionChannel, ECR_Block);
    }

    CollisionQueryParams = FComponentQueryParams(FName(TEXT("ShipMovementComponent")), PawnOwner);
    UpdatedPrimitive->InitSweepCollisionParams(CollisionQueryParams, CollisionResponseParams);
}

void UShipMovementComponent::ResetMovement()
{
    MovementSyncState = EMovementSyncState::None;
    AccumulatedSimTimeDiff = 0.f;
    CurrentSimTimestamp = 0.f;
    LastCheckTimestamp = 0.f;
    bForceSync = false;

    InputData.Reset();
    CurrentLinearSpeed = 0.f;
    CurrentAngularSpeed = 0.f;
    bUseAccelerationLinearSpeed = true;
    ShipDirection = UpdatedPrimitive->GetForwardVector();
    ShipDirection.Z = 0.f;
    ShipYaw = GetShipRotation().Yaw;
    ShipMoveFlags = 0;

    bRequestPathMove = false;
    PathMoveNextVector = FVector::ZeroVector;
    PathMoveCurrentVector = FVector::ZeroVector;
    PathMoveNextVector = FVector::ZeroVector;
    PathMoveNextMoveDistance = 0.f;
    PathMoveNextMoveDistanceSq = 0.f;
    bPathMoveSteerInSitu = false;
    bPathMoveLockGear = false;
    CurrentPathIndex = 0;
    MaxPathIndex = -1;
    CheckFinalRadiusIndex = -1;
    FinalAcceptanceRadius = 0.f;
    FinalAcceptanceRadiusSq = 0.f;
    IntermedialAcceptanceRadius = 0.f;
    bStopOnPathMoveFinished = false;

    LeftLerpTime = 0.f;
    LerpLinearSpeed = 0.f;
    LerpAngularSpeed = 0.f;
    LerpShipYaw = 0.f;
    LerpShipLocation = FVector::ZeroVector;

    LeftImpactResolveTime = 0.f;
    ImpactVelocitySize = 0.f;
    ImpactVelocityNormal = FVector::ZeroVector;

    SpeedHackTimeStamp = 0.f;
    DebugIllegalSpeed = 0.f;
}

void UShipMovementComponent::TeleportShip(const FVector& Location, float Yaw, bool bResetMovement)
{
    if (ShipPawn->GetLocalRole() != ROLE_Authority)
    {
        return;
    }

    SetShipTransform(Location, Yaw);
    //FillSyncData(SyncServerData);
    SetShipMoveFlag(EMoveFlag::Teleported, true);

    if (bResetMovement)
    {
        OnGearValueChanged.Broadcast(EShipGear::Stopped, InputData.GearValue);
        ResetMovement();
        ClientSendInput(InputData);
    }

    bForceSync = true;
}

void UShipMovementComponent::TeleportToSafeLocation()
{
    FVector OldLocation = GetShipLocation();
    FVector NewLocation = OldLocation;
    UPiratesGridTypeManager* GridTypeManager = UCommonShell::GetCommon(GWorld)->GetGridTypeManager();
    EPiratesGridRegionType RegionType = GridTypeManager->GetRegionType(OldLocation.X, OldLocation.Y);
    FVector2D OutPosition;
    if (RegionType != EPiratesGridRegionType::Ocean && GridTypeManager->GetClosestPositionOfRegionType(OldLocation.X, OldLocation.Y, EPiratesGridRegionType::Ocean, OutPosition))
    {
        NewLocation.X = OutPosition.X;
        NewLocation.Y = OutPosition.Y;
        TeleportShip(NewLocation, GetShipRotation().Yaw, false);
        UE_LOG(LogShipMovement, Log, TEXT("UShipMovementComponent::TeleportToSafeLocation not ocean, old=%s, new=%s, loc=%s"), *OldLocation.ToString(), *NewLocation.ToString(), *GetShipLocation().ToString());
    }
    else
    {
        NewLocation.X += FMath::RandRange(-Config.SafeTeleportDistance, Config.SafeTeleportDistance);
        NewLocation.Y += FMath::RandRange(-Config.SafeTeleportDistance, Config.SafeTeleportDistance);
        if (ShipPawn->GetNearestReachableLocation(NewLocation, Config.SafeTeleportDistance*2.f, NewLocation))
        {
            TeleportShip(NewLocation, GetShipRotation().Yaw, false);
            UE_LOG(LogShipMovement, Log, TEXT("UShipMovementComponent::TeleportToSafeLocation in ocean 1, old=%s, new=%s, loc=%s"), *OldLocation.ToString(), *NewLocation.ToString(), *GetShipLocation().ToString());
        }
        else
        {
            NewLocation.X += FMath::RandRange(-Config.SafeTeleportDistance, Config.SafeTeleportDistance);
            NewLocation.Y += FMath::RandRange(-Config.SafeTeleportDistance, Config.SafeTeleportDistance);
            if (ShipPawn->GetNearestReachableLocation(NewLocation, Config.SafeTeleportDistance*2.f, NewLocation))
            {
                TeleportShip(NewLocation, GetShipRotation().Yaw, false);
                UE_LOG(LogShipMovement, Log, TEXT("UShipMovementComponent::TeleportToSafeLocation in ocean 2, old=%s, new=%s, loc=%s"), *OldLocation.ToString(), *NewLocation.ToString(), *GetShipLocation().ToString());
            }
            else
            {
                UE_LOG(LogShipMovement, Log, TEXT("UShipMovementComponent::TeleportToSafeLocation error, not find safe loc"));
            }
        }
    }
}

void UShipMovementComponent::MoveShipToSafeLocation()
{
    if (ROLE_Authority != ShipPawn->GetLocalRole())
    {
        return;
    }
    FHitResult OutHitResult;
    FVector StartLoc = GetShipLocation();
    ShipDirection = UpdatedPrimitive->GetForwardVector();
    ShipDirection.Z = 0.f;
    ShipYaw = GetShipRotation().Yaw;
    FVector OutEndLoc = StartLoc + UpdatedPrimitive->GetRightVector() * NavAgentProps.AgentRadius;
    OutEndLoc.Z = StartLoc.Z = TransformNonManagedValue.Z;    
    FQuat EndQuat = GetShipQuaternion();
    //UE_LOG(LogShipMovement, Log, TEXT("MoveShipToSafeLocation %s, %s"), *StartLoc.ToString(), *GetShipRotation().ToString());
    if (GetWorld()->SweepSingleByChannel(OutHitResult, StartLoc, OutEndLoc, EndQuat,
        CollisionChannel, CollisionShape, CollisionQueryParams, CollisionResponseParams))
    {
        if (OutHitResult.bStartPenetrating)
        {
            FVector Extent = CollisionShape.GetExtent();
            OutEndLoc = StartLoc + UpdatedPrimitive->GetRightVector() * Extent.Y * 4.f;
            TeleportShip(OutEndLoc, GetShipRotation().Yaw, false);
        }
    }
}

void UShipMovementComponent::SetGearData(const TArray<FShipGearData>& InGears)
{
    int32 BasicGearNum = InGears.Num();
    check(BasicGearNum > 0);

    Gears.Empty();
    for (auto& i : InGears)
    {
        int index = Gears.Emplace(i);
        Gears[index].Buff = BasicGearBuff;
    }

    MaxBasicGear = (int32)EShipGear::FullSpeed;
    MaxGear = BasicGearNum - 1;

    int32 PathMoveGearNum = Config.PathMoveGearConfigs.Num();
    int32 Num = BasicGearNum < PathMoveGearNum ? BasicGearNum : PathMoveGearNum;
    auto& PathMoveGearConfigs = Config.PathMoveGearConfigs;
    for (int32 i = 0; i < Num; ++i)
    {
        PathMoveGears.Emplace(i, &Gears[i], PathMoveGearConfigs[i].MaxSteerAngle, PathMoveGearConfigs[i].MinDistance);
        Gears[i].Buff = BasicGearBuff;
    }

    MaxGear = Gears.Num() - 1;

    bForceSync = true;
    SetShipMoveFlag(EMoveFlag::GearUpdated, true);
}


void UShipMovementComponent::Brake()
{
    SetGear(0);
    SpeedUp(-1.f);
    SteerRight(0.f);
    SetGearAndPosture(EShipGear::Stopped, EShipPosture::FullSail);
}

bool UShipMovementComponent::SetGearAndPosture(EShipGear Gear, EShipPosture Posture)
{
    if (Gear < EShipGear::FullSpeed || Gear > EShipGear::Reverse || Posture < EShipPosture::FullSail || Posture > EShipPosture::Sinking)
    {
        return false;
    }
    if (Gear != EShipGear::Stopped)
    {
        SpeedUp(1.f);
    }

    auto OldGear = InputData.GearValue;
    InputData.SetGearValue(Gear);
    InputData.SetPosture(Posture);

    int32 maxGear = static_cast<int32>(EShipGear::Reverse) + 1;
    int32 GearIndex = static_cast<int32>(Posture) * maxGear + static_cast<int32>(Gear);
    SetGear(GearIndex);
    OnGearValueChanged.Broadcast(Gear, OldGear);
    InputDataChangedSync();
    return true;
}

bool UShipMovementComponent::SetBasicGear(EShipGear Gear)
{
    if (Gear == InputData.GearValue)
    {
        return false;
    }

    if (Gear != EShipGear::Stopped)
    {
        SpeedUp(1.f);
    }
    auto OldGear = InputData.GearValue;
    InputData.SetGearValue(Gear);

    int32 maxGear = static_cast<int32>(EShipGear::Reverse) + 1;
    int32 GearIndex = static_cast<int32>(InputData.Posture) * maxGear + static_cast<int32>(Gear);
    SetGear(GearIndex);
    OnGearValueChanged.Broadcast(Gear, OldGear);
    InputDataChangedSync();
    return true;
}

bool UShipMovementComponent::SetPosture(EShipPosture Posture)
{
    if (Posture == InputData.Posture)
    {
            return false;
    }

    InputData.SetPosture(Posture);

    int32 maxGear = static_cast<int32>(EShipGear::Reverse) + 1;
    int32 GearIndex = static_cast<int32>(Posture) * maxGear + static_cast<int32>(InputData.GearValue);
    SetGear(GearIndex);
    if (InputData.GearValue != EShipGear::Stopped)
    {
        SpeedUp(1.f);
    }
    InputDataChangedSync();
    return true;
}

bool UShipMovementComponent::SetGear(int Gear)
{
    if (Gear > MaxGear || Gear < 0)
        return false;

    InputData.SetGear(Gear);
    return true;
}

void UShipMovementComponent::StartShipPathMove(const TArray<FVector>& InPath, float AcceptanceRadius, bool bStopOnFinish)
{
    if (InPath.Num() == 0)
    {
        return;
    }

    NavPath.Empty(InPath.Num());
    NavPath.Append(InPath);
    int32 N = NavPath.Num();

    CurrentPathIndex = 0;
    MaxPathIndex = N - 1;

    PathMoveCurrentVector = NavPath[0] - GetShipLocation();
    if (MaxPathIndex > 0)
    {
        PathMoveNextVector = NavPath[1] - NavPath[0];
        PathMoveNextMoveDistanceSq = PathMoveNextVector.SizeSquared2D();
        PathMoveNextMoveDistance = FMath::Sqrt(PathMoveNextMoveDistanceSq);
    }
    else
    {
        PathMoveNextVector = FVector::ZeroVector;
        PathMoveNextMoveDistanceSq = 0.f;
        PathMoveNextMoveDistance = 0.f;
    }

    if (AccquireGridLayout())
    {
        IntermedialAcceptanceRadius = GridLayout->GetGridLength() * 0.5f;
    }
    else
    {
        IntermedialAcceptanceRadius = NavAgentProps.AgentHeight;
    }

    FinalAcceptanceRadius = AcceptanceRadius;
    if (FinalAcceptanceRadius < IntermedialAcceptanceRadius)
    {
        FinalAcceptanceRadius = IntermedialAcceptanceRadius;
    }
    FinalAcceptanceRadiusSq = FMath::Square(FinalAcceptanceRadius);

    CheckFinalRadiusIndex = N;
    const FVector& Dest = NavPath[MaxPathIndex];
    for (int32 i = MaxPathIndex - 1; i > -1; --i)
    {
        if ((Dest - NavPath[i]).SizeSquared2D() > FinalAcceptanceRadiusSq)
        {
            CheckFinalRadiusIndex = i;
            break;
        }
    }
    if (CheckFinalRadiusIndex > MaxPathIndex)
    {
        CheckFinalRadiusIndex = -1;
    }
    else if (CheckFinalRadiusIndex > MaxPathIndex - 2)
    {
        CheckFinalRadiusIndex = N;
    }

    bStopOnPathMoveFinished = bStopOnFinish;
    bPathMoveSteerInSitu = false;
    bPathMoveLockGear = false;
    bRequestPathMove = true;
    PathMoveSteerAngle = 0.f;
}

void UShipMovementComponent::AbortShipPathMove(EMapNavGridPathFollowingResult Result)
{
    if (IsShipPathMove())
    {
        OnPathMoveFinished(Result);
    }
}

float UShipMovementComponent::GetMaxBasicSpeed()
{
    return GetMaxLinearSpeed(MaxBasicGear);
}

void UShipMovementComponent::UpdateShipTransformRestrictly(float LocationZ, float Pitch, float Roll)
{
    TransformNonManagedValue.Z = LocationZ;
    TransformNonManagedValue.Pitch = Pitch;
    TransformNonManagedValue.Roll = Roll;
    TransformNonManagedValue.bChanged = true;
}

void UShipMovementComponent::AddShipMoveGearBuff(bool bBasic, EShipMoveGearBuffType Type, float Value)
{
    AddShipMoveGearBuffInternal(bBasic, Type, Value);
}

float UShipMovementComponent::GetShipMoveGearBuffValue(bool bBasic, EShipMoveGearBuffType Type)
{
    check(Type < EShipMoveGearBuffType::NUM);

    return BasicGearBuff[(int)Type].GetPercent();
}

void UShipMovementComponent::SetShipMoveGearBuff(bool bBasic, int MaxLinearSpeed, int LinearAcceleration, int LinearDeceleration,
    int MaxAngularSpeed, int AngularAcceleration, int AngularDeceleration)
{
    SetShipMoveGearBuffInternal(bBasic, EShipMoveGearBuffType::MAX_LINEAR_SPEED, MaxLinearSpeed);
    SetShipMoveGearBuffInternal(bBasic, EShipMoveGearBuffType::LINEAR_ACCELERATION, LinearAcceleration);
    SetShipMoveGearBuffInternal(bBasic, EShipMoveGearBuffType::LINEAR_DECELERATION, LinearDeceleration);
    SetShipMoveGearBuffInternal(bBasic, EShipMoveGearBuffType::MAX_ANGULAR_SPEED, MaxAngularSpeed);
    SetShipMoveGearBuffInternal(bBasic, EShipMoveGearBuffType::ANGULAR_ACCELERATION, AngularAcceleration);
    SetShipMoveGearBuffInternal(bBasic, EShipMoveGearBuffType::ANGULAR_DECELERATION, AngularDeceleration);
}

void UShipMovementComponent::EmptyShipMoveGearBuff(bool bBasic, EShipMoveGearBuffType Type)
{
    EmptyShipMoveGearBuffInternal(bBasic, Type);
}

void UShipMovementComponent::EmptyAllShipMoveGearBuff(bool bBasic)
{
	EmptyAllShipMoveGearBuffInternal(bBasic);
}

int32 UShipMovementComponent::IncreaseViewers()
{
    return ViewersNum++;
}

int32 UShipMovementComponent::DecreaseViewers()
{
    ViewersNum = ViewersNum > 0 ? ViewersNum - 1 : 0;
    return ViewersNum;
}

void UShipMovementComponent::ProcessPathMoveRequest(float DeltaTime)
{
    if (!bRequestPathMove)
    {
        return;
    }

    if (NavPath.Num() <= 0)
    {
        return;
    }

    if (MaxPathIndex == -1)
    {
        MaxPathIndex = NavPath.Num() - 1;
    }

    FVector CurrentLocation = GetShipLocation();

    if (CurrentPathIndex > CheckFinalRadiusIndex)
    {
        if ((CurrentLocation - NavPath[MaxPathIndex]).SizeSquared2D() < FinalAcceptanceRadiusSq)
        {
            OnPathMoveFinished(EMapNavGridPathFollowingResult::Completed);
            return;
        }
    }

    FVector TargetLocation = NavPath[CurrentPathIndex];
    FVector CurrentMoveVector = TargetLocation - CurrentLocation;

    bool bIsLast = (CurrentPathIndex == MaxPathIndex);
    float CurrentAcceptanceRadius = bIsLast ? FinalAcceptanceRadius : IntermedialAcceptanceRadius;

    bool bHasReached = false;
    if (CurrentMoveVector.SizeSquared2D() < FMath::Square(CurrentAcceptanceRadius))
    {
        bHasReached = true;
    }
    else if (!bIsLast)
    {
        bHasReached = (PathMoveCurrentVector | CurrentMoveVector) < 0.f;
    }

    if (bHasReached)
    {
        if (bIsLast)
        {
            OnPathMoveFinished(EMapNavGridPathFollowingResult::Completed);
            return;
        }

        TargetLocation = NavPath[++CurrentPathIndex];
        PathMoveCurrentVector = TargetLocation - NavPath[CurrentPathIndex - 1];
        CurrentMoveVector = TargetLocation - CurrentLocation;

        if (CurrentPathIndex < MaxPathIndex)
        {
            PathMoveNextVector = NavPath[CurrentPathIndex + 1] - TargetLocation;
            PathMoveNextMoveDistanceSq = PathMoveNextVector.SizeSquared2D();
            PathMoveNextMoveDistance = FMath::Sqrt(PathMoveNextMoveDistanceSq);
        }
        else
        {
            PathMoveNextVector = FVector::ZeroVector;
            PathMoveNextMoveDistanceSq = 0.f;
            PathMoveNextMoveDistance = 0.f;
        }

        bPathMoveLockGear = false;
    }

    EMapNavGridType CurrentGridType = EMapNavGridType::NonBlock;
    EMapNavGridType TargetGridType = EMapNavGridType::NonBlock;

    if (AccquireGridLayout())
    {
        CurrentAcceptanceRadius = IntermedialAcceptanceRadius;

        CurrentGridType = GridLayout->GetGrid(CurrentLocation);
        TargetGridType = GridLayout->GetGrid(TargetLocation);

        if (CurrentGridType > EMapNavGridType::NonBlock || TargetGridType > EMapNavGridType::NonBlock)
        {
            CurrentAcceptanceRadius *= 0.5f;
        }
    }

#if UE_EDITOR
    if (bDrawDebugInEditor && AccquireGridLayout() && ShipPawn->IsPlayerControlled())
    {
        FVector Loc = NavPath[CurrentPathIndex];
        Loc.Z = 0.f;
        DrawDebugCapsule(this->GetWorld(), Loc, 0.f, CurrentAcceptanceRadius, FQuat::Identity, FColor::Cyan, false, 30.f, 0, 30.f);
        DrawDebugGrids(Loc, false, 30.f);
    }
#endif

    float CurrentDistanceSquared = CurrentMoveVector.SizeSquared2D();
    float ProjectionDistance = CurrentMoveVector | ShipDirection;
    float ProjectionDistanceSquared = FMath::Square(ProjectionDistance);

    bool bNeedSteer = false;
    bool bNeedDecleration = false;

    if (ProjectionDistance > 0.f)
    {
        if (CurrentDistanceSquared - ProjectionDistanceSquared > FMath::Square(CurrentAcceptanceRadius))
        {
            bNeedSteer = true;
        }
    }
    else
    {
        bNeedSteer = true;
    }

    if (GetShipMoveFlag(EMoveFlag::Impacted))
    {
        if (bNeedSteer)
        {
            bPathMoveSteerInSitu = true;
        }
        else
        {
            OnPathMoveFinished(EMapNavGridPathFollowingResult::Blocked);
            return;
        }
    }

    if (bNeedSteer)
    {
        float DotP = FVector(-(ShipDirection.Y), ShipDirection.X, 0.f) | CurrentMoveVector;
        SteerRight(DotP < 0.f ? -1.f : 1.f);
        float CosAngle = FMath::Sqrt(ProjectionDistanceSquared / CurrentDistanceSquared);
        if (ProjectionDistance < 0.f)
        {
            CosAngle = -CosAngle;
        }
        PathMoveSteerAngle = FMath::RadiansToDegrees(FMath::Acos(CosAngle));
        if (bPathMoveSteerInSitu)
        {
            bNeedDecleration = true;
        }
    }
    else
    {
        bPathMoveSteerInSitu = false;
        SteerRight(0.f);
    }

    int32 TargetGear = 0;
    if (bPathMoveLockGear)
    {
        TargetGear = InputData.Gear;
    }
    else
    {
        int32 PathMoveGearIndex = PathMoveGears.Num() - 1;

        if (bNeedSteer)
        {
            if (CurrentGridType > EMapNavGridType::NonBlock)
            {
                PathMoveGearIndex = GetPathMoveBrakeGearIndex();
            }
            else
            {
                float CosAngleSq = ProjectionDistanceSquared / CurrentDistanceSquared;
                if (ProjectionDistance < 0.f)
                {
                    CosAngleSq = -CosAngleSq;
                }

                PathMoveGearIndex = GetPathMoveGearIndex(PathMoveGearIndex, CosAngleSq, CurrentDistanceSquared);
            }
        }

        if (CurrentPathIndex > MaxPathIndex - 2)
        {
            int32 BrakeGearIndex = GetPathMoveBrakeGearIndex();
            float BrakeDistance = GetPathMoveBrakeDistance(PathMoveGears[BrakeGearIndex].Gear);

            float DistThreshold = BrakeDistance + FinalAcceptanceRadius - PathMoveNextMoveDistance;
            if (DistThreshold > 0.f && CurrentDistanceSquared < FMath::Square(DistThreshold))
            {
                if (bStopOnPathMoveFinished)
                {
                    PathMoveGearIndex = BrakeGearIndex;
                }
                else
                {
                    if (PathMoveNextMoveDistance > 0.f)
                    {
                        PathMoveGearIndex = GetPathMoveGearIndexByNextNavPoint(PathMoveGearIndex);
                    }
                }

                bPathMoveLockGear = true;
            }
        }
        else
        {
            if (PathMoveNextMoveDistance > 0.f && CurrentDistanceSquared < PathMoveGears[PathMoveGearIndex].MinDistanceSq)
            {
                PathMoveGearIndex = GetPathMoveGearIndexByNextNavPoint(PathMoveGearIndex);
                bPathMoveLockGear = true;
            }
        }

        TargetGear = PathMoveGears[PathMoveGearIndex].Gear;
    }

    SetGearAndPosture(EShipGear::FullSpeed, InputData.GetPosture());

#if UE_EDITOR
    if (bDrawDebugInEditor && ShipPawn->IsPlayerControlled() && InputData.bChanged)
    {
        FString SteerStr = "None";
        if (InputData.SteerScale > 0.f)
        {
            SteerStr = "Right";
        }
        else if (InputData.SteerScale < 0.f)
        {
            SteerStr = "Left";
        }

        FString SpeedStr = "None";
        if (InputData.ThrustScale < 0.f)
        {
            SpeedStr = "Down";
        }
        else if (InputData.ThrustScale > 0.f)
        {
            SpeedStr = "Up";
        }

        float CosAngle = FMath::Sqrt(ProjectionDistanceSquared / CurrentDistanceSquared);
        if (ProjectionDistance < 0.f)
        {
            CosAngle = -CosAngle;
        }

        UE_LOG(LogShipMovement, Error, TEXT("[NavMoveDebug] Timestamp = %f; Gear [%i]; Steer = %s; Thrust = %s; Angle = %f; AS = %f; ADe = %f"),
            CurrentSimTimestamp, InputData.Gear, *SteerStr, *SpeedStr,
            FMath::RadiansToDegrees(FMath::Acos(CosAngle)), CurrentAngularSpeed, GetAngularDeceleration(InputData.Gear));
    }
#endif

}

void UShipMovementComponent::OnPathMoveFinished(EMapNavGridPathFollowingResult Result)
{
    bRequestPathMove = false;
    bPathMoveSteerInSitu = false;
    bPathMoveLockGear = false;

    NavPath.Empty(0);
    CurrentPathIndex = 0;
    PathMoveSteerAngle = 0.f;
//     CurrentLinearSpeed = 0.f;
//     CurrentAngularSpeed = 0.f;
    EShipPosture CurrentPosture = InputData.GetPosture();
    switch (Result)
    {
        case EMapNavGridPathFollowingResult::Completed:
            if (bStopOnPathMoveFinished)
            {
                SetGearAndPosture(EShipGear::Stopped, CurrentPosture);
            }
            else
            {
                SetGearAndPosture(EShipGear::Stopped, CurrentPosture);
            }
            break;
        case EMapNavGridPathFollowingResult::Aborted:
        {
            SetGearAndPosture(EShipGear::Stopped, CurrentPosture);
        }
            break;
        default:
            break;
    }

    SteerRight(0.f);

    OnShipPathMoveFinished.Broadcast(Result);
}


int32 UShipMovementComponent::GetPathMoveGearIndex(int32 StartIndex, float CosAngleSq, float MinDistanceSq)
{
    while (StartIndex > 0 && CosAngleSq < PathMoveGears[StartIndex].CosAngleSq)
    {
        --StartIndex;
    }

    while (StartIndex > 0 && MinDistanceSq < PathMoveGears[StartIndex].MinDistanceSq)
    {
        --StartIndex;
    }

    return StartIndex;
}

void UShipMovementComponent::SetSailState(EShipSailState InNewState, int32 InGear)
{
    if (SailState == InNewState)
        return;

    OnShipSailStateChanged.Broadcast(SailState, InNewState, InGear);
    SailState = InNewState;
}

void UShipMovementComponent::SetShipMoveState(float Distance)
{
    bool bMove = !(Distance == 0.f && CurrentLinearSpeed == 0.f);
    if (bShipMoving == bMove)
        return;

	bShipMoving = bMove;
    OnShipMoveStateChanged.Broadcast(bShipMoving);
}

bool UShipMovementComponent::CheckMovementIllegal(float DeltaSeconds)
{
    if (InputData.GearValue == EShipGear::Stopped)
    {
        return false;
    }

    float BuffValue = GetShipMoveGearBuffValue(true, EShipMoveGearBuffType::MAX_LINEAR_SPEED);
    if (BuffValue > 200.f)
    {
        return false;
    }

    SpeedHackTimeStamp += DeltaSeconds;
    if (SpeedHackTimeStamp < 1.f)
    {
        return false;
    }

    const int32 IllegalDecetionCount = 5;
    const float CheckMaxLinearSpeed = 4500.f;
    float TempMaxSpeed = FMath::Max(GetMaxBasicSpeed(), GetMaxLinearSpeed());
    float MaxLinearSpeed = FMath::Min(TempMaxSpeed, CheckMaxLinearSpeed);
    FVector CurrentLoction = GetShipLocation();
    FVector MoveVector = CurrentLoction - SpeedHackLocation;
    MoveVector.Z = 0.f;
    float LocDiff = MoveVector.Size2D();
    float SpeedHackMaxLocDiff = MaxLinearSpeed * SpeedHackTimeStamp * 1.5f;
    SpeedHackLocation = CurrentLoction;
    SpeedHackTimeStamp = 0.f;
    if (LocDiff > SpeedHackMaxLocDiff)
    {
        LocationIllegalCount++;
        UE_LOG(LogShipMovement, Log, TEXT("CheckSpeedHack true %s loc diff=%f, maxDiff=%f, count=%i, buffV=%f"), *(ShipPawn->GetName()), LocDiff, SpeedHackMaxLocDiff, LocationIllegalCount, BuffValue);
        if (LocationIllegalCount >= IllegalDecetionCount && bUseClientMovementSync == 1)
        {
            bUseClientMovementSync = 0;
            SetShipMoveFlag(EMoveFlag::Correcting, true);
            auto DelegateManger = UCommonShell::GetCommon(GWorld)->GetGameDelegateManager();
            DelegateManger->Movement->OnMovementIllegalDetection.Broadcast(ShipPawn);
            return true;
        }
    }
    else if (bUseClientMovementSync == 0)
    {
        // 为避免误报，隔30s再检测一次
        LocationIllegalCount--;
        const int32 ResetMovementCount = -30;
        if (LocationIllegalCount < ResetMovementCount)
        {
            LocationIllegalCount = IllegalDecetionCount - 1;
            bUseClientMovementSync = 1;
            SetShipMoveFlag(EMoveFlag::Correcting, false);
        }
    }
    else
    {
        LocationIllegalCount = 0;
    }
    return false;
}

void UShipMovementComponent::ClientSetCurrentGearDataForDebug_Implementation(EShipMoveGearBuffType Type, float Value)
{
    Debug_SetCurrentGearDataInternal(Type, Value);
}

void UShipMovementComponent::Debug_SetCurrentGearData(EShipMoveGearBuffType Type, float Value)
{
    if (PawnOwner->GetLocalRole() == ROLE_Authority)
    {
        Debug_SetCurrentGearDataInternal(Type, Value);
        ClientSetCurrentGearDataForDebug(Type, Value);
    }
}

void UShipMovementComponent::Debug_SetCurrentGearDataInternal(EShipMoveGearBuffType Type, float Value)
{
    auto& GearData = Gears[InputData.Gear];
    switch (Type)
    {
    case EShipMoveGearBuffType::MAX_LINEAR_SPEED:
        GearData.MaxLinearSpeed = Value;
        if (Value > GetMaxLinearSpeed(MaxBasicGear))
        {
            MinLocDiffThreshold = Value * MaxDelayTime;
        }
        break;
    case EShipMoveGearBuffType::LINEAR_ACCELERATION:
        GearData.LinearAcceleration = Value;
        break;
    case EShipMoveGearBuffType::LINEAR_DECELERATION:
        GearData.LinearDeceleration = Value;
        break;
    case EShipMoveGearBuffType::MAX_ANGULAR_SPEED:
        GearData.MaxAngularSpeed = Value;
        if (Value > GetMaxAngularSpeed(MaxBasicGear))
        {
            MinYawDiffThreshold = Value * MaxDelayTime;
        }
        break;
    case EShipMoveGearBuffType::ANGULAR_ACCELERATION:
        GearData.AngularAcceleration = Value;
        break;
    case EShipMoveGearBuffType::ANGULAR_DECELERATION:
        GearData.AngularDeceleration = Value;
        break;
    case EShipMoveGearBuffType::NUM:
        break;
    default:
        break;
    }
}

void UShipMovementComponent::DrawDebugGrids(const FVector& Location, bool bDrawNeighbors, float ExitTime)
{
    if (GridLayout == nullptr)
    {
        return;
    }

    auto DrawFunc = [this](const FMapNavGridCoordinate& Coord, const FVector& Extent, float InExitTime)
    {
        EMapNavGridType Grid = GridLayout->GetGrid(Coord);
        FVector GridLocation = GridLayout->GetLocation(Coord);
        FColor Color;
        switch (Grid)
        {
            case EMapNavGridType::Priority:
                Color = FColor::White;
                break;
            case EMapNavGridType::NonBlock:
                Color = FColor::Blue;
                break;
            case EMapNavGridType::BlockEdge:
                Color = FColor::Green;
                break;
            case EMapNavGridType::PartialBlock:
                Color = FColor::Yellow;
                break;
            case EMapNavGridType::Block:
                Color = FColor::Red;
                break;
            case EMapNavGridType::Unknown:
                Color = FColor::Black;
                break;
            default:
                break;
        }

        DrawDebugBox(this->GetWorld(), GridLocation, Extent, Color, false, InExitTime, 0, 100.0f);
    };

    FMapNavGridCoordinate Coord = GridLayout->GetCoordinate(Location);
    float HalfGridLength = GridLayout->GetGridLength() * 0.5f;
    FVector Extent(HalfGridLength, HalfGridLength, HalfGridLength);

    DrawFunc(Coord, Extent, ExitTime);

    if (bDrawNeighbors)
    {
        TArray<FMapNavGridNeighbor> Neighbors;
        GridLayout->GetReachableNeighbors(Coord, Neighbors);

        for (auto& Neighbor : Neighbors)
        {
            DrawFunc(Neighbor.Coord, Extent, ExitTime);
        }
    }
}

bool UShipMovementComponent::AccquireGridLayout()
{
    if (GridLayout == nullptr)
    {
        UOceanNavGridManager* GridManager = UGameCommon::Get(this)->GetOceanNavGridManager();
        if (GridManager != nullptr)
        {
            GridLayout = GridManager->GetGridLayout(NavAgentProps.AgentRadius);
        }

        if (GridLayout == nullptr)
        {
            return false;
        }
    }

    return true;
}

bool UShipMovementComponent::MoveShipSweepTest(const FQuat& TestQuat, float SteerScale, const FVector& VelocityNormal, FVector& OutStartLoc, FVector& OutEndLoc, FHitResult& OutHitResult)
{
    if (!UpdatedPrimitive->IsQueryCollisionEnabled())
    {
        return false;
    }

    bool bHasPenetration = false;
    OutEndLoc.Z = OutStartLoc.Z = UpdatePrimitiveZ;
    if (GetWorld()->SweepSingleByChannel(OutHitResult, OutStartLoc, OutEndLoc, TestQuat,
        CollisionChannel, CollisionShape, CollisionQueryParams, CollisionResponseParams))
    {
        bHasPenetration = OutHitResult.bStartPenetrating;
        if (bHasPenetration)
        {
            ResolvePenetration(TestQuat, SteerScale, OutStartLoc, OutEndLoc, OutHitResult);
            if (OutHitResult.bStartPenetrating)
            {
                auto NormalTemp = FVector(-(OutHitResult.ImpactNormal.Y), OutHitResult.ImpactNormal.X, 0.f);
                if (InputData.GetGearValue() == EShipGear::Reverse)
                {
                    NormalTemp = FVector(OutHitResult.ImpactNormal.Y, OutHitResult.ImpactNormal.X, 0.f);
                }
                float DotPTemp = ShipDirection | NormalTemp;
                auto MoveAngle = FMath::RadiansToDegrees(FMath::Acos(ShipDirection.CosineAngle2D(NormalTemp)));
                auto Impact = GetShipImpactArea(OutHitResult, *(ShipPawn->GetShipMovementComponent()));
                if (ROLE_AutonomousProxy <= ShipPawn->GetLocalRole())
                {
                    if (((Impact == EShipImpactArea::Front || Impact == EShipImpactArea::Middle) && InputData.SteerScale == 0.f && ((MoveAngle < 1.f || MoveAngle > 179.f)))
                        || (Impact == EShipImpactArea::Back && InputData.GetGearValue() < EShipGear::Stopped && (MoveAngle < 5.f || MoveAngle > 175.f)))
                    {
                        //UE_LOG(LogShipMovement, Log, TEXT("MoveShipSweepTest 1, angle=%f, dotp=%f, impact=%i"), MoveAngle, DotPTemp, (int)impact);
                        OutEndLoc = OutStartLoc + ShipDirection * CurrentLinearSpeed * 0.017f;
                        return false;
                    }
                    else
                    {
                        OutEndLoc = OutStartLoc;
                        return true;
                    }
                }
            }
        }

        if (OutHitResult.bBlockingHit)
        {
            auto NormalTemp = FVector(-(OutHitResult.ImpactNormal.Y), OutHitResult.ImpactNormal.X, 0.f);
            if (InputData.GetGearValue() == EShipGear::Reverse)
            {
                NormalTemp = FVector(OutHitResult.ImpactNormal.Y, OutHitResult.ImpactNormal.X, 0.f);
            }
            float DotPTemp = ShipDirection | NormalTemp;
            auto MoveAngle = FMath::RadiansToDegrees(FMath::Acos(ShipDirection.CosineAngle2D(NormalTemp)));
            auto Impact = GetShipImpactArea(OutHitResult, *(ShipPawn->GetShipMovementComponent()));
            if (ROLE_AutonomousProxy == ShipPawn->GetLocalRole())
            {
                if (((Impact == EShipImpactArea::Front || Impact == EShipImpactArea::Middle) && InputData.SteerScale == 0.f && ((MoveAngle < 1.f || MoveAngle > 179.f)))
                    || (Impact == EShipImpactArea::Back && InputData.GetGearValue() < EShipGear::Stopped && (MoveAngle < 5.f || MoveAngle > 175.f)))
                {
                    //UE_LOG(LogShipMovement, Log, TEXT("MoveShipSweepTest 2, angle=%f, dotp=%f, dotPP=%f, impact=%i, dis=%f"), MoveAngle, DotPTemp, dotPP, (int)impact, OutHitResult.Distance);
                    OutEndLoc = OutStartLoc + ShipDirection * CurrentLinearSpeed * 0.017f;
                    return false;
                }
            }
            if (OutHitResult.Distance > Config.SweepPullBackDistance)
            {
                //UE_LOG(LogShipMovement, Log, TEXT("MoveShipSweepTest 3, angle=%f, dotp=%f, dotPP=%f, impact=%i, dis=%f"), MoveAngle, DotPTemp, dotPP, (int)impact, OutHitResult.Distance);
                OutEndLoc = OutHitResult.Location - VelocityNormal * Config.SweepPullBackDistance;
            }
            else
            {
                //UE_LOG(LogShipMovement, Log, TEXT("MoveShipSweepTest 4, angle=%f, dotp=%f, impact=%i, dis=%f"), MoveAngle, DotPTemp, (int)impact, OutHitResult.Distance);
                OutHitResult.Time = 0.f;
                OutEndLoc = OutStartLoc;
            }
        }
    }

    return bHasPenetration;
}

void UShipMovementComponent::ResolvePenetration(const FQuat& TestQuat, float SteerScale, FVector& OutStartLoc, FVector& OutEndLoc, FHitResult& OutHitResult)
{
    if (!OutHitResult.bStartPenetrating || OutHitResult.PenetrationDepth < 0.f)
    {
        return;
    }

    FVector SteerDirection = FVector(-(ShipDirection.Y), ShipDirection.X, 0.f);
    if (SteerScale < 0.f)
    {
        SteerDirection = FVector(ShipDirection.Y, -(ShipDirection.X), 0.f);
    }
    if (InputData.GearValue == EShipGear::Reverse)
    {
        SteerDirection = -SteerDirection;
    }
    float DotP = SteerDirection | OutHitResult.Normal;
//     DrawDebugLine(GetWorld(), OutHitResult.Location, OutHitResult.Location + OutHitResult.Normal * 3000.f, FColor::Red);
//     DrawDebugLine(GetWorld(), GetShipLocation(), GetShipLocation() + ShipDirection * 3000.f, FColor::Green);
    if (SteerScale != 0.f)
    {
        if (-1.f + KINDA_SMALL_NUMBER < DotP && DotP < -KINDA_SMALL_NUMBER)
        {
            //UE_LOG(LogShipMovement, Log, TEXT("Can't steer to this direction"));
            return;
        }
    }

    FVector DelMove = OutStartLoc - OutEndLoc;
    FVector OldNormal = OutHitResult.Normal;
    for (int32 i = 0; i < Config.MaxAdjustStepsForPenetration; ++i)
    {
        float AdjustDistance = OutHitResult.PenetrationDepth < Config.MinAdjustDistanceForPenetration
            ? Config.MinAdjustDistanceForPenetration : OutHitResult.PenetrationDepth;

        FVector AdjustVector = OutHitResult.Normal * (AdjustDistance + Config.SweepPullBackDistance);

        OutStartLoc += AdjustVector;
        OutEndLoc += AdjustVector;
        OutStartLoc.Z = OutEndLoc.Z = UpdatePrimitiveZ;

        OutHitResult = FHitResult();
        if (GetWorld()->SweepSingleByChannel(OutHitResult, OutStartLoc, OutEndLoc, TestQuat,
            CollisionChannel, CollisionShape, CollisionQueryParams, CollisionResponseParams))
        {
            if (!OutHitResult.bStartPenetrating || (OldNormal | OutHitResult.Normal) < 0.f || (OutHitResult.PenetrationDepth < Config.MinAdjustDistanceForPenetration))
            {
                break;
            }

            OldNormal = OutHitResult.Normal;
        }
        else
        {
            break;
        }
    }
}

void UShipMovementComponent::OnFailToResolvePenetration()
{
    //UE_LOG(LogShipMovement, Log, TEXT("Fail to resolve penetration"));
    //StopMovementImmediately();
    StopMove();
}

void UShipMovementComponent::ResolveShipImpact(const FHitResult& HitResult, const UShipMovementComponent& OtherMovementComp)
{
    ImpactVelocityNormal.Set(-(HitResult.ImpactNormal.Y), HitResult.ImpactNormal.X, 0.f);
    ImpactVelocitySize = 0.f;
    this->Velocity = FVector::ZeroVector;

    float DotP = ShipDirection | ImpactVelocityNormal;
    float MinImpactSpeed = CurrentLinearSpeed * Config.MinSlideSpeedFactor;

    if (FPiratesMovementUtil::CheckFloatEqual(DotP, 0.f, KINDA_SMALL_NUMBER))
    {
        ImpactVelocityNormal.Set(-(ShipDirection.Y), ShipDirection.X, 0.f);
        ImpactVelocitySize = MinImpactSpeed;

        DotP = ImpactVelocityNormal | OtherMovementComp.GetShipDirection();
        float DotP2 = (OtherMovementComp.GetShipLocation() - GetShipLocation()) | ImpactVelocityNormal;

        if (FPiratesMovementUtil::CheckFloatEqual(DotP, 0.f, KINDA_SMALL_NUMBER))
        {
            if (DotP2 > 0.f)
            {
                ImpactVelocityNormal = -ImpactVelocityNormal;
            }
        }
        else if (DotP > 1.f - KINDA_SMALL_NUMBER)
        {
            if (DotP2 > 0.f || ImpactVelocitySize < OtherMovementComp.GetCurrentLinearSpeed())
            {
                ImpactVelocityNormal = -ImpactVelocityNormal;
            }
        }
        else if (DotP < KINDA_SMALL_NUMBER - 1.f)
        {
            if (DotP2 > 0.f && ImpactVelocitySize > OtherMovementComp.GetCurrentLinearSpeed())
            {
                ImpactVelocityNormal = -ImpactVelocityNormal;
            }
        }
        else if (DotP > 0.f)
        {
            ImpactVelocityNormal = -ImpactVelocityNormal;
        }
    }
    else
    {
        ImpactVelocitySize = CurrentLinearSpeed * DotP;
        if (ImpactVelocitySize < 0.f)
        {
            ImpactVelocitySize = -ImpactVelocitySize;
            ImpactVelocityNormal = -ImpactVelocityNormal;
        }
        if (ImpactVelocitySize < MinImpactSpeed)
        {
            ImpactVelocitySize = MinImpactSpeed;
        }

        if (ImpactVelocitySize /** 0.5f*/ < (OtherMovementComp.Velocity | ImpactVelocityNormal))
        {
            ImpactVelocitySize = 0.f;
            return;
        }
    }

    this->Velocity = ImpactVelocitySize * ImpactVelocityNormal;
}

EShipImpactArea UShipMovementComponent::GetShipImpactArea(const FHitResult& HitResult, const UShipMovementComponent& OtherMovementComp)
{
    FVector OtherImpactVector = HitResult.ImpactPoint - OtherMovementComp.GetShipLocation();
    float CosAngle = OtherMovementComp.GetShipDirection() | OtherImpactVector.GetSafeNormal2D();

    if (CosAngle > ImpactAreaPartitionBound)
    {
        return EShipImpactArea::Front;
    }
    else if (CosAngle > -ImpactAreaPartitionBound)
    {
        return EShipImpactArea::Middle;
    }
    else
    {
        return EShipImpactArea::Back;
    }
}

float UShipMovementComponent::ResolveBorderImpact(const FHitResult& HitResult)
{
    ImpactVelocityNormal = FVector(-(HitResult.ImpactNormal.Y), HitResult.ImpactNormal.X, 0.f);
    if (InputData.GetGearValue() == EShipGear::Reverse)
    {
        ImpactVelocityNormal = FVector(HitResult.ImpactNormal.Y, HitResult.ImpactNormal.X, 0.f);
    }
    float DotP = ShipDirection | ImpactVelocityNormal;
    auto MoveAngle = FMath::RadiansToDegrees(FMath::Acos(ShipDirection.CosineAngle2D(ImpactVelocityNormal)));
    auto impact = GetShipImpactArea(HitResult, *(ShipPawn->GetShipMovementComponent()));
    ImpactVelocitySize = CurrentLinearSpeed * DotP;
    if (ImpactVelocitySize < 0.f)
    {
        ImpactVelocitySize = -ImpactVelocitySize;
        ImpactVelocityNormal = -ImpactVelocityNormal;
    }

    float MinImpactSpeed = CurrentLinearSpeed * Config.MinSlideSpeedFactor;
    if (ImpactVelocitySize < MinImpactSpeed)
    {
        ImpactVelocitySize = MinImpactSpeed;
    }

    this->Velocity = ImpactVelocitySize * ImpactVelocityNormal;
    if (this->Velocity.IsNearlyZero(KINDA_SMALL_NUMBER))
    {
        ImpactVelocityNormal.Set(-(ShipDirection.Y), ShipDirection.X, 0.f);
        if (CurrentAngularSpeed < 0.f)
        {
            ImpactVelocityNormal = -ImpactVelocityNormal;
        }

        ImpactVelocitySize = MinImpactSpeed;
        this->Velocity = ImpactVelocitySize * ImpactVelocityNormal;
    }

    float MoveDegree = 0.f;
    if (ROLE_AutonomousProxy == ShipPawn->GetLocalRole() && (impact == EShipImpactArea::Front || impact == EShipImpactArea::Middle))
    {
        UE_LOG(LogShipMovement, Verbose, TEXT("ResolveBorderImpact dotP = %f, an = %f, impact=%i, rad=%f"), DotP, MoveAngle, (int)impact);
        if (DotP > 0.f && MoveAngle > 0.f && MoveAngle < 90.f && InputData.SteerScale != 1.f)
        {
            MoveDegree = -1.f;
        }
        else if (DotP < 0.f && MoveAngle >= 90.f && MoveAngle < 180.f && InputData.SteerScale != -1.f)
        {
            MoveDegree = 1.f;
        }
    }

    return MoveDegree;
}

void UShipMovementComponent::ResolveLandImpact(const FHitResult& HitResult)
{
    ImpactVelocityNormal = FVector::ZeroVector;
    ImpactVelocitySize = 0.f;
    this->Velocity = FVector::ZeroVector;
}

bool UShipMovementComponent::ComputeAngularSpeedNew(const FShipInputData& InInputData, float& AngularSpeed, float& LeftSeconds)
{
    float AbsAngularSpeed = FMath::Abs(AngularSpeed);
    float AngularAcceleration = GetAngularAcceleration(InInputData.Gear);
    float MaxSpeed = GetMaxAngularSpeed(InInputData.Gear);
    float MinSpeed = 0;
    float DotP = InInputData.SteerScale / AngularSpeed;
    if (AbsAngularSpeed == MaxSpeed && InInputData.SteerScale != 0.f && DotP > 0 && FPiratesMovementUtil::CheckFloatEqual(CurrentLinearSpeed,GetMaxLinearSpeed(InInputData.Gear)))
    {
        return false;
    }

    float SteerDirection = (InInputData.SteerScale < 0.f) ? -1.f : 1.f;
    if (InInputData.GearValue == EShipGear::Reverse)
    {
        SteerDirection = (InInputData.SteerScale > 0.f) ? -1.f : 1.f;
    }

    bool bDecreaseGear = ((AbsAngularSpeed > MaxSpeed));
    if (bDecreaseGear || (InInputData.SteerScale == 0.f) || !FPiratesMovementUtil::CheckFloatSameSign(AngularSpeed, SteerDirection))
    {
        AngularAcceleration = GetAngularDeceleration(InInputData.Gear);

        if (InInputData.SteerScale == 0.f && AngularSpeed < 0.f)
        {
            SteerDirection = -SteerDirection;
        }
    }

    if (FPiratesMovementUtil::CheckFloatEqual(AngularAcceleration, 0.f) || bRequestPathMove)
    {
        if (FMath::Abs(InInputData.SteerScale) > 0)
        {
            AbsAngularSpeed = MaxSpeed * FMath::Abs(InInputData.SteerScale);
        }
        else
        {
            AbsAngularSpeed = 0.f;
        }
    }

    float NewAbsAngularSpeed = AbsAngularSpeed + AngularAcceleration * LeftSeconds;
    if (NewAbsAngularSpeed > MaxSpeed)
    {
        NewAbsAngularSpeed = MaxSpeed;
    }
    else if (NewAbsAngularSpeed < MinSpeed)
    {
        NewAbsAngularSpeed = MinSpeed;
    }

    float NewAngularSpeed = SteerDirection * NewAbsAngularSpeed;
    AngularSpeed = NewAngularSpeed;
    return true;
}

bool UShipMovementComponent::IsSameNavDestLocation(const FVector& DestLocation)
{
    auto LastPathIndex = NavPath.Num() - 1;
    if (LastPathIndex >= 0 && NavPath[LastPathIndex] == DestLocation)
    {
        return true;
    }
    return false;
}

void UShipMovementComponent::FillSyncData(FShipMovementSyncData& OutData)
{
    OutData.SerializeFlag = FShipMovementSyncData::STANDARD_SERIALIZE_FLAG;

    OutData.InputData = InputData;

    FShipMoveData& MoveData = OutData.MoveData;
    MoveData.Location = GetShipLocation();
    MoveData.Yaw = GetShipRotation().Yaw;
    MoveData.LinearSpeed = CurrentLinearSpeed;
    MoveData.AngularSpeed = CurrentAngularSpeed;

    OutData.MoveFlags = ShipMoveFlags;
    OutData.Timestamp = CurrentSimTimestamp;
}

void UShipMovementComponent::InputDataChangedSync()
{
    if (InputData.bChanged)
    {
        if (PawnOwner->GetLocalRole() == ROLE_AutonomousProxy)
        {
            ServerSendInput(InputData);
        }
        else
        {
            ClientSendInput(InputData);
        }
        OnShipInputDataChanged.Broadcast(InputData);
        InputData.bChanged = false;
    }
}

void UShipMovementComponent::SetShipTransform(const FVector& Location, float Yaw)
{
    FVector Loc = Location;
    Loc.Z = TransformNonManagedValue.Z;

	check(UpdatedPrimitive->GetNumChildrenComponents() > 0);
	USceneComponent* FlotageRoot = Cast<USceneComponent>(UpdatedPrimitive->GetChildComponent(0));
	check(FlotageRoot != nullptr);

    if (FPiratesMovementUtil::CheckYawAreEqual(ShipYaw, Yaw) && !TransformNonManagedValue.bChanged)
    {
        //UpdatedPrimitive->SetWorldLocation(Loc, false, nullptr, ETeleportType::TeleportPhysics)
		FVector LocShipBox(Loc.X, Loc.Y, UpdatePrimitiveZ);
        UpdatedPrimitive->SetWorldLocation(LocShipBox, false, nullptr, ETeleportType::TeleportPhysics);
		FVector LocFloatage(0.0f, 0.0f, Loc.Z);
        FlotageRoot->SetRelativeLocation(LocFloatage, false, nullptr, ETeleportType::TeleportPhysics);
        }
    else
    {
        FRotator Rot = GetShipRotation();
        Rot.Yaw = Yaw;
        Rot.Pitch = TransformNonManagedValue.Pitch;
        Rot.Roll = TransformNonManagedValue.Roll;
		//UpdatedPrimitive->SetWorldLocationAndRotation(Loc, Rot, false, nullptr, ETeleportType::TeleportPhysics);

		FVector LocShipBox(Loc.X, Loc.Y, UpdatePrimitiveZ);
		FRotator RotShipBox(0.0f, Rot.Yaw, 0.0f);
		UpdatedPrimitive->SetWorldLocationAndRotation(LocShipBox, RotShipBox, false, nullptr, ETeleportType::TeleportPhysics);

		FVector LocFloatage(0.0f, 0.0f, Loc.Z);
		FRotator RotFloatage(Rot.Pitch, 0.0f, Rot.Roll);
		FlotageRoot->SetRelativeLocationAndRotation(LocFloatage, RotFloatage, false, nullptr, ETeleportType::TeleportPhysics);

        TransformNonManagedValue.bChanged = false;

        ShipYaw = Yaw;
        ShipDirection = UpdatedPrimitive->GetForwardVector();
        ShipDirection.Z = 0.f;
    }
}

void UShipMovementComponent::SetShipMoveGearBuffInternal(bool bBasic, EShipMoveGearBuffType Type, float Value)
{
    check(Type < EShipMoveGearBuffType::NUM);

    BasicGearBuff[(int)Type].Set(Value);
}

void UShipMovementComponent::AddShipMoveGearBuffInternal(bool bBasic, EShipMoveGearBuffType Type, float Value)
{
    check(Type < EShipMoveGearBuffType::NUM);

    BasicGearBuff[(int)Type].AddPercent(Value * 100);
}

void UShipMovementComponent::EmptyShipMoveGearBuffInternal(bool bBasic, EShipMoveGearBuffType Type)
{
	check(Type < EShipMoveGearBuffType::NUM);

    BasicGearBuff[(int)Type].Empty();
}

void UShipMovementComponent::EmptyAllShipMoveGearBuffInternal(bool bBasic)
{
    for (int i = 0; i < (int)EShipMoveGearBuffType::NUM; ++i)
    {
        BasicGearBuff[i].Empty();
    }
}

void UShipMovementComponent::OnRep_SyncData()
{
    MovementSyncState = EMovementSyncState::Successful;
}

void UShipMovementComponent::OnRep_GearBuff()
{
    for (int i = 0; i < (int)EShipMoveGearBuffType::NUM; ++i)
    {
        BasicGearBuff[i].Update();
    }
}

void UShipMovementComponent::ClientSendInput_Implementation(const FShipInputData& Input)
{
    if (InputData.GearValue != Input.GearValue)
    {
        OnGearValueChanged.Broadcast(Input.GearValue, InputData.GearValue);
    }
    InputData = Input;
    if (InputData.bChanged)
    {
        OnShipInputDataChanged.Broadcast(InputData);
        InputData.bChanged = false;
    }
}

void UShipMovementComponent::ServerSendInput_Implementation(const FShipInputData& Input)
{
    if (InputData.GearValue != Input.GearValue)
    {
        OnGearValueChanged.Broadcast(Input.GearValue, InputData.GearValue);
    }
    SyncClientData.InputData = Input;
    InputData = Input;
    MovementSyncState = EMovementSyncState::Successful;

    if (InputData.GearValue != EShipGear::Stopped && LocationIllegalCount > 0)
    {
        LocationIllegalCount--;
    }
}

bool UShipMovementComponent::ServerSendInput_Validate(const FShipInputData& Input)
{
    if (Input.Gear < 0 || Input.Gear > MaxGear)
        return false;

    if (Input.SteerScale > 1.f || Input.SteerScale < -1.f)
        return false;

    if (Input.ThrustScale > 1.f || Input.ThrustScale < -1.f)
        return false;

    return true;
}

void UShipMovementComponent::ServerRequestChangeGear_Implementation(const FShipInputData& Input)
{
    SetGearAndPosture(Input.GearValue, Input.Posture);
}


bool UShipMovementComponent::ServerRequestChangeGear_Validate(const FShipInputData& Input)
{
    return true;
}

void UShipMovementComponent::ServerStopMove_Implementation()
{
    AbortShipPathMove(EMapNavGridPathFollowingResult::Aborted);

    if (ImmediateStopEnabled)
    {
        auto OldGear = InputData.GearValue;
        CurrentLinearSpeed = 0.f;
        CurrentAngularSpeed = 0.f;
        InputData.ResetGear();
        InputData.bChanged = true;
        OnGearValueChanged.Broadcast(EShipGear::Stopped, OldGear);

        this->Velocity = FVector::ZeroVector;
    }
}

bool UShipMovementComponent::ServerStopMove_Validate()
{
    return true;
}

bool UShipMovementComponent::ServerSendViewerRotator_Validate(FRotator NewRotator)
{
    return true;
}

void UShipMovementComponent::ServerSendViewerRotator_Implementation(FRotator NewRotator)
{
    APlayerController* PC = Cast<APlayerController>(PawnOwner->GetController());
    if (PC)
    {
        PC->SetControlRotation(NewRotator);
    }
}

bool UShipMovementComponent::MoveShip(float Degree, float Distance, float DeltaTime)
{
    auto EndImpactFunc = [&]()
    {
        SetShipMoveFlag(EMoveFlag::Impacted, false);

        ImpactVelocitySize = 0.f;
        ImpactVelocityNormal = FVector::ZeroVector;

        OnShipEndImpact.Broadcast();
        bForceSync = true;
    };

    this->Velocity = FVector::ZeroVector;
    if (PawnOwner->GetLocalRole() >= ROLE_AutonomousProxy)
    {
        SetShipMoveState(Distance);
    }
    if (Distance == 0.f && Degree == 0.f)
    {
        if (TransformNonManagedValue.bChanged)
        {
            FVector Loc = GetShipLocation();
            Loc.Z = TransformNonManagedValue.Z;

            FRotator Rot = GetShipRotation();
            Rot.Pitch = TransformNonManagedValue.Pitch;
            Rot.Roll = TransformNonManagedValue.Roll;

            TransformNonManagedValue.bChanged = false;

// 			UpdatedPrimitive->SetWorldLocationAndRotation(
// 			                Loc, Rot, false, nullptr, ETeleportType::TeleportPhysics);

			check(UpdatedPrimitive->GetNumChildrenComponents() > 0);
			USceneComponent* FlotageRoot = Cast<USceneComponent>(UpdatedPrimitive->GetChildComponent(0));
			check(FlotageRoot != nullptr);

			FVector LocShipBox(Loc.X, Loc.Y, UpdatePrimitiveZ);
			FRotator RotShipBox(0.0f, Rot.Yaw, 0.0f);
			UpdatedPrimitive->SetWorldLocationAndRotation(LocShipBox, RotShipBox, false, nullptr, ETeleportType::TeleportPhysics);

			FVector LocFloatage(0.0f, 0.0f, Loc.Z);
			FRotator RotFloatage(Rot.Pitch, 0.0f, Rot.Roll);
			FlotageRoot->SetRelativeLocationAndRotation(LocFloatage, RotFloatage, false, nullptr, ETeleportType::TeleportPhysics);
        }

        if (GetShipMoveFlag(EMoveFlag::Impacted))
        {
            EndImpactFunc();
        }

        return false;
    }

    FQuat EndQuat = GetShipQuaternion();
    FVector EndDirection = ShipDirection;
    float EndYaw = ShipYaw;
    bool bSteered = (Degree != 0.f);
    FRotator EndRot = GetShipRotation();
    if (bSteered || TransformNonManagedValue.bChanged)
    {
        EndRot.Yaw += Degree;
        EndRot.Pitch = 0.f;
        EndRot.Roll = 0.f;

		check(UpdatedPrimitive->GetNumChildrenComponents() > 0);
		USceneComponent* FlotageRoot = Cast<USceneComponent>(UpdatedPrimitive->GetChildComponent(0));
		check(FlotageRoot != nullptr);

		FVector LocFloatage(0.0f, 0.0f, TransformNonManagedValue.Z);
		FRotator RotFloatage(TransformNonManagedValue.Pitch, 0.0f, TransformNonManagedValue.Roll);
		FlotageRoot->SetRelativeLocationAndRotation(LocFloatage, RotFloatage, false, nullptr, ETeleportType::TeleportPhysics);

        TransformNonManagedValue.bChanged = false;

        if (bSteered)
        {
            EndYaw = FPiratesMovementUtil::BoundYaw(EndRot.Yaw);
            EndDirection = FPiratesMovementUtil::ComputeMoveVector(EndYaw, 1.f);
        }

        EndQuat = EndRot.Quaternion();
    }

    FVector StartLoc = GetShipLocation();
    FVector TestEndLoc = StartLoc + EndDirection * Distance;
    TestEndLoc.Z = UpdatePrimitiveZ;

    FVector TestStartLoc = StartLoc;

    if (ShipPawn->GetLocalRole() != ROLE_SimulatedProxy)
    {
        FHitResult HitResult;
        MoveShipSweepTest(EndQuat, InputData.SteerScale, EndDirection, TestStartLoc, TestEndLoc, HitResult);

        if (HitResult.bBlockingHit)
        {
            bForceSync = true;

            APiratesShipPawn* OtherShipPawn = Cast<APiratesShipPawn>(HitResult.GetActor());
            EShipImpactType ImpactType = EShipImpactType::Ship;
            if (OtherShipPawn == nullptr)
            {
                auto HitType = HitResult.GetComponent()->GetCollisionObjectType();
                if (HitType == ECC_WorldStatic)
                {
                    ImpactType = EShipImpactType::Land;
                }
                else if (HitType == ECC_Pawn)
                {
                    ImpactType = EShipImpactType::Human;
                    TestEndLoc = StartLoc + EndDirection * Distance;
                    TestEndLoc.Z = UpdatePrimitiveZ;
                }
                else
                {
                    ImpactType = EShipImpactType::Border;
                }
            }

            if (!GetShipMoveFlag(EMoveFlag::Impacted))
            {
                if (ImpactType != EShipImpactType::Human)
                {
                    SetShipMoveFlag(EMoveFlag::Impacted, true);
                    LeftImpactResolveTime = Config.MaxImpactResolveTime;
                }

                if (OtherShipPawn != nullptr && ::IsValid(OtherShipPawn))
                {
                    OnShipStartImpact.Broadcast(EShipImpactType::Ship, OtherShipPawn, GetShipImpactArea(HitResult, *(OtherShipPawn->GetShipMovementComponent())), HitResult.ImpactPoint);
                }
                else
                {
                    OnShipStartImpact.Broadcast(ImpactType, HitResult.GetActor(), EShipImpactArea::Middle, HitResult.ImpactPoint);
                }
                //UE_LOG(LogShipMovement, Error, TEXT("[%s] StartImpact -------------> LinearSpeed = %f"), *(ShipPawn->GetName()),CurrentLinearSpeed);
            }

            if (HitResult.bStartPenetrating && HitResult.PenetrationDepth >= Config.MinAdjustDistanceForPenetration
                && bSteered && FMath::Abs(Distance) > 0.f && ImpactType != EShipImpactType::Human)
            {
                EndDirection = ShipDirection;
                EndQuat = GetShipQuaternion();
                bSteered = false;
                TestEndLoc = TestStartLoc + EndDirection * Distance;

                HitResult.Reset(1.f, false);
                MoveShipSweepTest(EndQuat, 0.f, EndDirection, TestStartLoc, TestEndLoc, HitResult);
            }

            this->Velocity = EndDirection * CurrentLinearSpeed;

            if (HitResult.bBlockingHit && ImpactType != EShipImpactType::Human)
            {
                float MoveDegree = 0.f;
                if (OtherShipPawn != nullptr)
                {
                    ResolveShipImpact(HitResult, *(OtherShipPawn->GetShipMovementComponent()));
                }
                else
                {
                    MoveDegree = ResolveBorderImpact(HitResult);
                }

                if (MoveDegree != 0.f && ShipPawn->GetLocalRole() == ROLE_AutonomousProxy)
                {
                    EndRot = EndQuat.Rotator();
                    EndRot.Yaw += MoveDegree;
                    EndRot.Pitch = 0.f;
                    EndRot.Roll = 0.f;

                    EndQuat = EndRot.Quaternion();
                    bSteered = true;
                }

                float LeftTime = DeltaTime * (1.f - HitResult.Time);
                if (LeftTime < FPiratesMovementUtil::SMALL_MOVEMENT_TIME)
                {
                    LeftTime = 0.f;
                }

                float ImpactDistance = ImpactVelocitySize * LeftTime;
                if (ImpactDistance > FPiratesMovementUtil::SMALL_LINEAR_DISTANCE)
                {
                    TestStartLoc = TestEndLoc;
                    TestEndLoc = TestStartLoc + ImpactVelocityNormal * ImpactDistance;

                    HitResult.Reset(1.f, false);
                    bool bPentrat = MoveShipSweepTest(EndQuat, false, ImpactVelocityNormal, TestStartLoc, TestEndLoc, HitResult);

                    if ((bPentrat && HitResult.bStartPenetrating && HitResult.PenetrationDepth >= Config.MinAdjustDistanceForPenetration)
                        || (HitResult.GetComponent() && HitResult.GetComponent()->GetCollisionObjectType() == ECC_GameTraceChannel3))
                    {
                        bool bInPathMove = bRequestPathMove;
                        OnFailToResolvePenetration();
                        if (bInPathMove)
                        {
                            OnShipPathMoveImpactStop.Broadcast(HitResult.ImpactPoint);
                        }
                        return false;
                    }

                    if (!HitResult.bBlockingHit)
                    {
                        LeftTime = 0.f;
                        LeftImpactResolveTime = Config.MaxImpactResolveTime;
                    }
                }
                //UE_LOG(LogShipMovement, Error, TEXT("[%s] *** ResolvingImpact, LinearSpeed = %f"), *(ShipPawn->GetName()), CurrentLinearSpeed);

                LeftImpactResolveTime -= LeftTime;
                if (LeftImpactResolveTime < 0.f)
                {
                    bool bInPathMove = bRequestPathMove;
                    StopMovementImmediately();
                    EndImpactFunc();
                    if (bInPathMove)
                    {
                        OnShipPathMoveImpactStop.Broadcast(HitResult.ImpactPoint);
                    }
                }
            }
        }
        else
        {
            this->Velocity = EndDirection * CurrentLinearSpeed;

            if (GetShipMoveFlag(EMoveFlag::Impacted))
            {
                EndImpactFunc();
            }
        }
    }
    else
    {
        this->Velocity = EndDirection * CurrentLinearSpeed;
    }

    if (bSteered)
    {
        TransformNonManagedValue.bChanged = false;
        EndYaw = FPiratesMovementUtil::BoundYaw(EndRot.Yaw);
        EndDirection = FPiratesMovementUtil::ComputeMoveVector(EndYaw, 1.f);

        ShipDirection = EndDirection;
        ShipYaw = EndYaw;
    }

    return UpdatedPrimitive->MoveComponent(
        TestEndLoc - StartLoc, EndQuat,
        false, nullptr,
        MoveComponentFlags, ETeleportType::TeleportPhysics);

}

void UShipMovementComponent::SmoothMove(float DeltaTime)
{
    FVector LerpLocation = FVector::ZeroVector;
    float LerpYaw = 0.f;
    FVector MoveVector = FVector::ZeroVector;
    if (MovementSyncState == EMovementSyncState::Successful)
    {
        ShipMoveFlags = SyncServerData.MoveFlags;
        const FShipMoveData& SyncMoveData = SyncServerData.MoveData;
        CurrentSimTimestamp = 0.f;

        LerpLinearSpeed = (CurrentLinearSpeed + SyncMoveData.LinearSpeed) * 0.5f;
        if (LerpLinearSpeed > SyncMoveData.LinearSpeed)
        {
            LerpLinearSpeed = SyncMoveData.LinearSpeed;
        }

        LerpAngularSpeed = (CurrentAngularSpeed + SyncMoveData.AngularSpeed) * 0.5f;
        if (FMath::Abs(LerpAngularSpeed) > FMath::Abs(SyncMoveData.AngularSpeed))
        {
            LerpAngularSpeed = SyncMoveData.AngularSpeed;
        }

        CurrentLinearSpeed = SyncMoveData.LinearSpeed;
        CurrentAngularSpeed = SyncMoveData.AngularSpeed;

        if (GetShipMoveFlag(EMoveFlag::Teleported))
        {
            SetShipTransform(SyncMoveData.Location, SyncMoveData.Yaw);
            return;
        }

        if (bNeedAdjustPostion)
        {
            float MaxSmoothTime = CVar_ShipMovementMaxSmoothTime > 0 ? CVar_ShipMovementMaxSmoothTime : 1.f;
            float YawDiff = FPiratesMovementUtil::BoundYaw(SyncMoveData.Yaw - ShipYaw);
            float AbsDiffYaw = FMath::Abs(YawDiff);
            float YawDiffMax = MinYawDiffThreshold * DeltaTime * MaxSmoothTime;
            float AbsYawDiffMax = FMath::Abs(YawDiffMax);

            MoveVector = SyncMoveData.Location - GetShipLocation();
            MoveVector.Z = 0.f;
            float LocDiff = MoveVector.Size2D();
            float LocDiffMax = MinLocDiffThreshold * DeltaTime * MaxSmoothTime;
            LerpLocation = GetShipLocation();
            LerpLocation.Z = TransformNonManagedValue.Z;
            LerpYaw = SyncMoveData.Yaw;
            if (AbsDiffYaw > AbsYawDiffMax || LocDiff > LocDiffMax)
            {
                LerpYaw = FPiratesMovementUtil::LerpYaw(ShipYaw, SyncMoveData.Yaw, 0.05);
                LerpLocation = FPiratesMovementUtil::Lerp(GetShipLocation(), SyncMoveData.Location, 0.02);
            }
            SetShipTransform(LerpLocation, LerpYaw);
        }

        if (CVar_ShipMovementDrawServerLoction)
        {
            DrawDebugBox(GetWorld(), SyncMoveData.Location, CollisionShape.GetExtent(), GetShipQuaternion(), FColor::Red, true, 3.f);
        }
    }

    if (!GetShipMoveFlag(EMoveFlag::Impacted))
    {
        if (CurrentLinearSpeed != 0.f)
        {
            MaxSmoothMoveTime = 1.f / GEngine->GetMaxFPS();

            if (DeltaTime - MaxSmoothMoveTime > FPiratesMovementUtil::SMALL_MOVEMENT_TIME)
            {
                LeftLerpTime += (DeltaTime - MaxSmoothMoveTime);

                if (LeftLerpTime > FPiratesMovementUtil::SMALL_MOVEMENT_LERP_TIME)
                {
                    LeftLerpTime -= FPiratesMovementUtil::SMALL_MOVEMENT_LERP_TIME;
                    DeltaTime = MaxSmoothMoveTime + FPiratesMovementUtil::SMALL_MOVEMENT_LERP_TIME;
                }
            }
        }
        else
        {
            LeftLerpTime = 0.f;
        }

        float Distance = CurrentLinearSpeed * DeltaTime;
        float Degree = CurrentAngularSpeed * DeltaTime;

//          UE_LOG(LogShipMovement, Error, TEXT("%s SmoothMove, cl=%f, ca=%f, t=%f, dis=%f, degree=%f"), *GetOwner()->GetName(),
//              LerpLinearSpeed, LerpAngularSpeed, DeltaTime, Distance, Degree);

        MoveShip(Degree, Distance, DeltaTime);
        SetShipMoveState(Distance);
        CurrentSimTimestamp += DeltaTime;
    }
}

float UShipMovementComponent::ComputeMovementDegreeNew(const FShipInputData& InInputData, float InDeltaSeconds, float& AngularSpeed)
{
    if ((InInputData.SteerScale == 0.f && AngularSpeed == 0.f) || InDeltaSeconds < FPiratesMovementUtil::SMALL_MOVEMENT_TIME)
    {
        return 0.f;
    }

    float StartSpeed = AngularSpeed;
    float EndSpeed = StartSpeed;
    float StartLeftSeconds = InDeltaSeconds;
    float EndLeftSeconds = StartLeftSeconds;
    float Degree = 0.f;
    ComputeAngularSpeedNew(InInputData, EndSpeed, EndLeftSeconds);
    Degree = EndSpeed * EndLeftSeconds;
    AngularSpeed = EndSpeed;

    if (bRequestPathMove)
    {
        if (Degree > PathMoveSteerAngle)
        {
            Degree = PathMoveSteerAngle;
        }
//        UE_LOG(LogShipMovement, Error, TEXT("PathMoveAngular[%s] degree=%f, speed=%f, steer=%f, sa=%f"), *(ShipPawn->GetName()), Degree, AngularSpeed, InInputData.SteerScale, SteerAngle);
    }
    return Degree;
}

float UShipMovementComponent::ComputeMovementDistanceNew(const FShipInputData& InInputData, float InDeltaSeconds, float& LinearSpeed)
{
    if (InDeltaSeconds < FPiratesMovementUtil::SMALL_MOVEMENT_TIME || (InInputData.GearValue == EShipGear::Stopped && LinearSpeed == 0.f))
    {
        CurrentLinearAcceleration = 0.f;
        return 0.f;
    }

    float StartSpeed = LinearSpeed;
    float EndSpeed = StartSpeed;
    float StartLeftSeconds = InDeltaSeconds;
    float EndLeftSeconds = StartLeftSeconds;
    float Distance = 0.f;
    ComputeLinearSpeedNew2(InInputData, EndSpeed, EndLeftSeconds);
    LinearSpeed = EndSpeed;
    Distance = EndSpeed * EndLeftSeconds;
    if (DebugIllegalSpeed > 0.f)
    {
        LinearSpeed = DebugIllegalSpeed;
        Distance = DebugIllegalSpeed * InDeltaSeconds;
    }

    return Distance;
}

bool UShipMovementComponent::ComputeLinearSpeedNew2(const FShipInputData& InInputData, float& LinearSpeed, float& LeftSeconds)
{
    float LinearAcceleration = 0.f;
    float MaxSpeed = GetMaxLinearSpeed(InInputData.Gear);
    float MinSpeed = 0.f;
    float AbsLinearSpeed = FMath::Abs(LinearSpeed);
    float AbsMaxSpeed = FMath::Abs(MaxSpeed);
    if (AbsLinearSpeed == AbsMaxSpeed && InInputData.GearValue != EShipGear::Stopped)
    {
        CurrentLinearAcceleration = 0.f;
        return false;
    }

    bool bDecreaseGear = (LinearSpeed > MaxSpeed);
    if (bDecreaseGear)
    {
        LinearAcceleration = GetLinearDeceleration(InInputData.Gear);
        MinSpeed = MaxSpeed;
    }
    else
    {
        if (InInputData.ThrustScale < 0.f)
        {
            LinearAcceleration = GetLinearDeceleration(InInputData.Gear);
        }
        else if (InInputData.ThrustScale > 0.f)
        {
            LinearAcceleration = GetLinearAcceleration(InInputData.Gear);
        }
        else if (InInputData.ThrustScale == 0.f && LinearSpeed < 0.f)
        {
            LinearAcceleration = GetLinearAcceleration(InInputData.Gear);
        }
    }
    CurrentLinearAcceleration = LinearAcceleration;

    if (FPiratesMovementUtil::CheckFloatEqual(LinearAcceleration, 0.f))
    {
        return false;
    }

    float NewLinearSpeed = LinearSpeed + LinearAcceleration * LeftSeconds;
    if (FPiratesMovementUtil::CheckFloatEqual(NewLinearSpeed, 0.f))
    {
        NewLinearSpeed = 0.f;
    }
    if (NewLinearSpeed > 0.f)
    {
        if (NewLinearSpeed > MaxSpeed && !bDecreaseGear)
        {
            NewLinearSpeed = MaxSpeed;
            CurrentLinearAcceleration = 0.f;
        }
        else if (NewLinearSpeed < MinSpeed)
        {
            NewLinearSpeed = MinSpeed;
            CurrentLinearAcceleration = 0.f;
        }
    }
    else
    {
         if (AbsMaxSpeed > 0 && FMath::Abs(NewLinearSpeed) > AbsMaxSpeed && InInputData.GearValue != EShipGear::Reverse)
         {
             NewLinearSpeed = MaxSpeed;
             CurrentLinearAcceleration = 0.f;
         }
         else if (NewLinearSpeed > MinSpeed && (InInputData.GearValue != EShipGear::Reverse && InInputData.GearValue != EShipGear::Stopped))
         {
             NewLinearSpeed = MinSpeed;
             CurrentLinearAcceleration = 0.f;
         }
    }

    LinearSpeed = NewLinearSpeed;
    return true;
}

void UShipMovementComponent::ProcessAuthorityRole(float DeltaTime)
{
    if (MovementSyncState == EMovementSyncState::Successful)
    {
        InputData = SyncClientData.InputData;
        MovementSyncState = EMovementSyncState::None;
    }

    if (bMoveEnable)
    {
        float Distance = 0.f;
        float Degree = ComputeMovementDegreeNew(InputData, DeltaTime, CurrentAngularSpeed);;
        if (bUseAccelerationLinearSpeed)
        {
            Distance = ComputeMovementDistanceNew(InputData, DeltaTime, CurrentLinearSpeed);
        }
        else
        {
            Distance = CurrentLinearSpeed * DeltaTime;
        }

        MoveShip(Degree, Distance, DeltaTime);
        if (bStartTotalDistance)
        {
            TotalDistance += FMath::Abs(Distance);
        }
    }
    else
    {
        MoveShip(0.f, 0.f, DeltaTime);
    }

    CurrentSimTimestamp += DeltaTime;

    if (bForceSync || InputData.bChanged || CurrentSimTimestamp > Config.ServerMaxSyncInterval)
    {
        FillSyncData(SyncServerData);
        if (InputData.bChanged)
        {
            OnShipInputDataChanged.Broadcast(InputData);
            InputData.bChanged = false;
        }

        CurrentSimTimestamp = 0.f;
        bForceSync = false;
        if (GetShipMoveFlag(EMoveFlag::Teleported))
        {
            SetShipMoveFlag(EMoveFlag::Teleported, false);
        }
    }
}

bool UShipMovementComponent::ServerMove_Validate(FVector Location, float Yaw)
{
    return true;
}

void UShipMovementComponent::ServerMove_Implementation(FVector Location, float Yaw)
{
    if (GetWorld() && GetWorld()->GetWorldSettings()->TimeDilation != 1.f)
    {
        return;
    }
    if (bUseClientMovementSync == 0)
    {
        return;
    }
    FVector OldLocation = GetShipLocation();
    FVector MoveVector = Location - OldLocation;
    MoveVector.Z = 0.f;
    float LocDiff = MoveVector.Size2D();
    if (LocDiff > 0.f && LocDiff <= 10000.f && !GetShipMoveFlag(EMoveFlag::Teleported) /*&& InputData.GetGearValue() != EShipGear::Stopped*/)
    {
        Location.Z = TransformNonManagedValue.Z;
        SetShipTransform(Location, Yaw);
    }
}

void UShipMovementComponent::CheckInputData(const FShipInputData& ServerInput)
{
    auto ThisTime = GetWorld()->GetTimeSeconds();
    if (FMath::Abs(ThisTime - LastCheckTimestamp) > 2.f)
    {
        LastCheckTimestamp = ThisTime;
        if (InputData.Gear != ServerInput.Gear || InputData.SteerScale != ServerInput.SteerScale)
        {
            ServerSendInput(InputData);
//             UE_LOG(LogShipMovement, Error, TEXT("client input g(%i) s(%f), server g(%i) s(%f)"),
//                 (int)InputData.Gear,InputData.SteerScale, (int)ServerInput.Gear, ServerInput.SteerScale);
        }
    }
}

void UShipMovementComponent::ProcessAutonomousRole(float DeltaTime)
{
    InputDataChangedSync();

    if (MovementSyncState == EMovementSyncState::Successful)
    {
        ShipMoveFlags = SyncServerData.MoveFlags;
        const FShipMoveData& SyncMoveData = SyncServerData.MoveData;
        LerpLinearSpeed = (SyncMoveData.LinearSpeed + CurrentLinearSpeed) * 0.5f;
        if (LerpLinearSpeed > SyncMoveData.LinearSpeed)
        {
            LerpLinearSpeed = SyncMoveData.LinearSpeed;
        }
        LerpAngularSpeed = SyncMoveData.AngularSpeed;
        CurrentLinearSpeed = SyncMoveData.LinearSpeed;
        CurrentAngularSpeed = LerpAngularSpeed;
        CheckInputData(SyncServerData.InputData);

        if (GetShipMoveFlag(EMoveFlag::Teleported))
        {
            SetShipTransform(SyncMoveData.Location, SyncMoveData.Yaw);
            SetShipMoveFlag(EMoveFlag::Teleported, false);
            return;
        }

        FVector MoveVector = SyncMoveData.Location - GetShipLocation();
        MoveVector.Z = 0.f;
        float MaxSmoothTime = CVar_ShipMovementMaxSmoothTime > 0 ? CVar_ShipMovementMaxSmoothTime : 1.f;
        float LocDiff = MoveVector.Size2D();
        float LocDiffMax = MinLocDiffThreshold * DeltaTime * 2;
        if (LocDiff > 10000.f || GetShipMoveFlag(EMoveFlag::Correcting))
        {
            UE_LOG(LogShipMovement, Verbose, TEXT("SmoothTrans LocDiffMax=%f, LocDiff=%f"), LocDiffMax, LocDiff);
            SetShipTransform(SyncMoveData.Location, SyncMoveData.Yaw);
            SetShipMoveFlag(EMoveFlag::Correcting, false);
        }
        else if (GetWorld() && GetWorld()->GetWorldSettings()->TimeDilation != 1.f)
        {
            float YawDiff = FPiratesMovementUtil::BoundYaw(SyncMoveData.Yaw - ShipYaw);
            float AbsDiffYaw = FMath::Abs(YawDiff);
            float YawDiffMax = MinYawDiffThreshold * DeltaTime * MaxSmoothTime;
            float AbsYawDiffMax = FMath::Abs(YawDiffMax);

            MoveVector = SyncMoveData.Location - GetShipLocation();
            MoveVector.Z = 0.f;
            FVector LerpLocation = GetShipLocation();
            LerpLocation.Z = TransformNonManagedValue.Z;
            float LerpYaw = SyncMoveData.Yaw;
            if (AbsDiffYaw > AbsYawDiffMax || LocDiff > LocDiffMax)
            {
                LerpYaw = FPiratesMovementUtil::LerpYaw(ShipYaw, SyncMoveData.Yaw, 0.05);
                LerpLocation = FPiratesMovementUtil::Lerp(GetShipLocation(), SyncMoveData.Location, 0.02);
            }
            SetShipTransform(LerpLocation, LerpYaw);
        }

        if (CVar_ShipMovementDrawServerLoction)
        {
            DrawDebugBox(GetWorld(), SyncMoveData.Location, CollisionShape.GetExtent(), GetShipQuaternion(), FColor::Red, true, 3.f);
        }
    }

    float FPSTime = GEngine->GetMaxFPS();
    MaxSmoothMoveTime = 1.f / FPSTime;

    if (CurrentLinearSpeed != 0.f && GetWorld() && GetWorld()->GetWorldSettings()->TimeDilation == 1.f)
    {
        auto lerpTime = FPiratesMovementUtil::SMALL_MOVEMENT_TIME * CVar_ShipMovementLerpTime;
        if (DeltaTime - MaxSmoothMoveTime > lerpTime || LeftLerpTime > lerpTime)
        {
            LeftLerpTime += (DeltaTime - MaxSmoothMoveTime);
            if (LeftLerpTime > 0.5f)
            {
                LeftLerpTime -= (lerpTime * 2.f);
                DeltaTime = MaxSmoothMoveTime + (lerpTime * 2.f);
            }
            else if (LeftLerpTime > lerpTime)
            {
                LeftLerpTime -= lerpTime;
                DeltaTime = MaxSmoothMoveTime + lerpTime;
            }
        }
    }
    else
    {
        LeftLerpTime = 0.f;
    }


    if (bMoveEnable)
    {
        float Distance = ComputeMovementDistanceNew(InputData, DeltaTime, CurrentLinearSpeed);
        float Degree = ComputeMovementDegreeNew(InputData, DeltaTime, CurrentAngularSpeed);
        if (Degree != 0.f)
        {
            UE_LOG(LogShipMovement, Verbose, TEXT("ProcessAutonomousRole Speed=%f, dis=%f, degree=%f, gear=%i, time=%f, leftTime=%f, fpsTime=%f"),
                CurrentLinearSpeed, Distance, Degree, (int)InputData.GetGearValue(), DeltaTime, LeftLerpTime, FPSTime);
        }
        MoveShip(Degree, Distance, DeltaTime);
        SetShipMoveState(Distance);
    }
    else
    {
        MoveShip(0.f, 0.f, DeltaTime); //这么处理是因为要求不能移动和转向，但是浮力的作用还在
    }

    if (bForceSync || InputData.bChanged || CurrentSimTimestamp > Config.ClientMaxSyncInterval)
    {
        ServerMove(GetShipLocation(), GetShipRotation().Yaw);
        CurrentSimTimestamp = 0.f;
        bForceSync = false;
    }
    else
    {
        CurrentSimTimestamp += DeltaTime;
    }

    if (ViewersNum > 0)
    {
        APlayerController* PC = Cast<APlayerController>(PawnOwner->GetController());
        if (PC)
        {
            FRotator ControllerRotator = PC->GetControlRotation();
            if (ControllerRotator != ViewerRotator)
            {
                ViewerRotator = ControllerRotator;
                ServerSendViewerRotator(ViewerRotator);
            }
        }
    }
}

void UShipMovementComponent::ProcessSimulatedRole(float DeltaTime)
{
    InputData = SyncServerData.InputData;
    if (InputData.bChanged)
    {
        OnShipInputDataChanged.Broadcast(InputData);
        InputData.bChanged = false;
    }

    SmoothMove(DeltaTime);
}


float UShipMovementComponent::GetSimulationTimeStep(float RemainingTime, int32 Iterations) const
{
    if (RemainingTime > MaxSmoothMoveTime)
    {
        if (Iterations < MaxSimulationIterations)
        {
            if (InputData.GearValue == EShipGear::Stopped)
            {
                RemainingTime = FMath::Min(MaxSmoothMoveTime, RemainingTime);
            }
            else
            {
                RemainingTime = MaxSmoothMoveTime;
            }
        }
        return RemainingTime;
    }
    return 0.f;
}

void UShipMovementComponent::UpdateAvoidance(float DeltaTime)
{
    UpdateDefaultAvoidance();
}

void UShipMovementComponent::UpdateDefaultAvoidance()
{
    if (!bUseRVOAvoidance)
    {
        return;
    }

    //SCOPE_CYCLE_COUNTER(STAT_AI_ObstacleAvoidance);

    UAvoidanceManager* AvoidanceManager = GetWorld()->GetAvoidanceManager();
    if (AvoidanceManager && !bWasAvoidanceUpdated)
    {
        AvoidanceManager->UpdateRVO(this);

        //Consider this a clean move because we didn't even try to avoid.
        SetAvoidanceVelocityLock(AvoidanceManager, AvoidanceManager->LockTimeAfterClean);
    }

    bWasAvoidanceUpdated = false;		//Reset for next frame
}

void UShipMovementComponent::SetAvoidanceVelocityLock(class UAvoidanceManager* Avoidance, float Duration)
{
    Avoidance->OverrideToMaxWeight(AvoidanceUID, Duration);
    AvoidanceLockVelocity = AvoidanceVelocity;
    AvoidanceLockTimer = Duration;
}

float UShipMovementComponent::RVOCalcSteering()
{
    if (bUseRVOAvoidance)
    {
        const float AngleDiff = AvoidanceVelocity.HeadingAngle() - GetVelocityForRVOConsideration().HeadingAngle();
        if (AngleDiff > 0.0f)
        {
            return 1.0f;
        }
        else if (AngleDiff < 0.0f)
        {
            return -1.0f;
        }
    }
    return 0;
}

float UShipMovementComponent::RVOCalcThrottle()
{
    if (bUseRVOAvoidance)
    {
        const float AvoidanceSpeedSq = AvoidanceVelocity.SizeSquared();
        const float DesiredSpeedSq = GetVelocityForRVOConsideration().SizeSquared();
        if (bInAvoidancePhase &&
            (DesiredSpeedSq > FMath::Square(MaxAvoidanceVelocity2D) || DesiredSpeedSq > AvoidanceSpeedSq))
        {
            return -1.0f;
        }
        else if (bInAvoidancePhase)
        {
            return 1.0f;
        }
    }
    return 0;
}

void UShipMovementComponent::SetAvoidanceEnabled(bool bEnable)
{
    if (bUseRVOAvoidance != bEnable)
    {
        bUseRVOAvoidance = bEnable;

        UAvoidanceManager* AvoidanceManager = GetWorld()->GetAvoidanceManager();
        if (AvoidanceManager && bEnable && AvoidanceUID == 0)
        {
            AvoidanceManager->RegisterMovementComponent(this, AvoidanceWeight);
        }
    }
}

void UShipMovementComponent::SetUpdatedComponent(USceneComponent* NewUpdatedComponent)
{
    Super::SetUpdatedComponent(NewUpdatedComponent);
    if (bUseRVOAvoidance && ::IsValid(NewUpdatedComponent))
    {
        UAvoidanceManager* AvoidanceManager = GetWorld()->GetAvoidanceManager();
        if (AvoidanceManager)
        {
            AvoidanceManager->RegisterMovementComponent(this, AvoidanceWeight);
        }
    }
}

void UShipMovementComponent::SetRVOAvoidanceUID(int32 UID)
{
    AvoidanceUID = UID;
}

int32 UShipMovementComponent::GetRVOAvoidanceUID()
{
    return AvoidanceUID;
}

void UShipMovementComponent::SetRVOAvoidanceWeight(float Weight)
{
    AvoidanceWeight = Weight;
}

float UShipMovementComponent::GetRVOAvoidanceWeight()
{
    return AvoidanceWeight;
}

FVector UShipMovementComponent::GetRVOAvoidanceOrigin()
{
    return UpdatedComponent->GetComponentLocation();
}

float UShipMovementComponent::GetRVOAvoidanceRadius()
{
    return RVOAvoidanceRadius;
}

float UShipMovementComponent::GetRVOAvoidanceHeight()
{
    return RVOAvoidanceHeight;
}

float UShipMovementComponent::GetRVOAvoidanceConsiderationRadius()
{
    return AvoidanceConsiderationRadius;
}

FVector UShipMovementComponent::GetVelocityForRVOConsideration()
{
    FVector V = UpdatedComponent->GetComponentVelocity();
    V.Z = 0.f;
    return V;
}

int32 UShipMovementComponent::GetAvoidanceGroupMask()
{
    return AvoidanceGroup.Packed;
}

int32 UShipMovementComponent::GetGroupsToAvoidMask()
{
    return GroupsToAvoid.Packed;
}

int32 UShipMovementComponent::GetGroupsToIgnoreMask()
{
    return GroupsToIgnore.Packed;
}

bool UShipMovementComponent::CalculateAvoidanceVelocity(float DeltaTime)
{
    if (!bUseRVOAvoidance)
    {
        return false;
    }

    UAvoidanceManager* AvoidanceManager = GetWorld()->GetAvoidanceManager();
    APawn* MyOwner = UpdatedComponent ? Cast<APawn>(UpdatedComponent->GetOwner()) : NULL;

    // since we don't assign the avoidance velocity but instead use it to adjust steering and throttle,
    // always reset the avoidance velocity to the current velocity
    AvoidanceVelocity = GetVelocityForRVOConsideration();

    if (AvoidanceWeight >= 1.0f || AvoidanceManager == NULL || MyOwner == NULL)
    {
        return false;
    }

    if (MyOwner->GetLocalRole() != ROLE_Authority)
    {
        return false;
    }

#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
    const bool bShowDebug = AvoidanceManager->IsDebugEnabled(AvoidanceUID);
#endif

    bool ret = false;
    if (!AvoidanceVelocity.IsZero())
    {
        //See if we're doing a locked avoidance move already, and if so, skip the testing and just do the move.
        if (AvoidanceLockTimer > 0.0f)
        {
            AvoidanceVelocity = AvoidanceLockVelocity;
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
            if (bShowDebug)
            {
                DrawDebugLine(GetWorld(), GetRVOAvoidanceOrigin(), GetRVOAvoidanceOrigin() + AvoidanceVelocity, FColor::Blue, true, 0.5f, SDPG_MAX);
            }
#endif
            ret = true;
        }
        else
        {
            FVector NewVelocity = AvoidanceManager->GetAvoidanceVelocityForComponent(this);
            if (!NewVelocity.Equals(AvoidanceVelocity))		//Really want to branch hint that this will probably not pass
            {
                if (AvoidanceVelocity.Size2D() > MaxAvoidanceVelocity2D)
                {
                    AvoidanceVelocity = AvoidanceVelocity.GetSafeNormal2D() * MaxAvoidanceVelocity2D;
                    SetAvoidanceVelocityLock(AvoidanceManager, AvoidanceManager->LockTimeAfterClean);
                }
                else
                {
                    //Had to divert course, lock this avoidance move in for a short time. This will make us a VO, so unlocked others will know to avoid us.
                    AvoidanceVelocity = NewVelocity;
                    SetAvoidanceVelocityLock(AvoidanceManager, AvoidanceManager->LockTimeAfterAvoid);
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
                    if (bShowDebug)
                    {
                        DrawDebugLine(GetWorld(), GetRVOAvoidanceOrigin(), GetRVOAvoidanceOrigin() + AvoidanceVelocity, FColor::Red, true, 20.0f, SDPG_MAX, 10.0f);
                    }
#endif
                }

                ret = true;
            }
            else
            {
                //Although we didn't divert course, our velocity for this frame is decided. We will not reciprocate anything further, so treat as a VO for the remainder of this frame.
                SetAvoidanceVelocityLock(AvoidanceManager, AvoidanceManager->LockTimeAfterClean);	//10 ms of lock time should be adequate.
            }
        }

        AvoidanceManager->UpdateRVO(this);
        bWasAvoidanceUpdated = true;
    }
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
    else if (bShowDebug)
    {
        DrawDebugLine(GetWorld(), GetRVOAvoidanceOrigin(), GetRVOAvoidanceOrigin() + GetVelocityForRVOConsideration(), FColor::Yellow, true, 0.05f, SDPG_MAX);
    }

    if (bShowDebug)
    {
        FVector UpLine(0, 0, 500);
        DrawDebugLine(GetWorld(), GetRVOAvoidanceOrigin(), GetRVOAvoidanceOrigin() + UpLine, (AvoidanceLockTimer > 0.01f) ? FColor::Red : FColor::Blue, true, 0.05f, SDPG_MAX, 5.0f);
    }
#endif
    if (ret)
    {
        //UE_LOG(LogShipMovement, Log, TEXT("%s true avoidance"), *GetOwner()->GetName());
    }
    return ret;
}

void UShipMovementComponent::SetAvoidanceGroup(int32 GroupFlags)
{
    AvoidanceGroup.SetFlagsDirectly(GroupFlags);
}

void UShipMovementComponent::SetGroupsToAvoid(int32 GroupFlags)
{
    GroupsToAvoid.SetFlagsDirectly(GroupFlags);
}

void UShipMovementComponent::SetGroupsToIgnore(int32 GroupFlags)
{
    GroupsToIgnore.SetFlagsDirectly(GroupFlags);
}
