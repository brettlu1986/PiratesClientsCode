#include "Pawns/PiratesHumanCharacter.h"
#include "Common.h"
//#include "GameFramework/Character.h"
#include "NavMesh/RecastNavMesh.h"
#include "EmitterActivateComponent.h"
#include "NavigationData.h"
#include "NavigationSystem.h"
#include "Game/GameCommon.h"
#include "Network/CustomReplicationComponent.h"
#include "MapNavGridLayout.h"
#include "MapNavGridPathFinding.h"
#include "FlotageComponent.h"
#include "OceanNavGridManager.h"

DEFINE_LOG_CATEGORY_STATIC(LogPiratesHuman, Log, All);

APiratesHumanCharacter::APiratesHumanCharacter(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer.SetDefaultSubobjectClass<UHumanMovementComponent>(ACharacter::CharacterMovementComponentName))
{
    NavMoveAIController = nullptr;
    MovementComponent = nullptr;

	IsRelativePath = false;

    if (!HasAnyFlags(RF_ClassDefaultObject))
    {
        EmitterActivateComponent = CreateDefaultSubobject<UEmitterActivateComponent>(TEXT("EmitterActivate"));
        AddOwnedComponent(EmitterActivateComponent);
    }
}

void APiratesHumanCharacter::Destroyed()
{
    if (IsPlayerControlled() && NavMoveAIController != nullptr)
    {
        NavMoveAIController->Destroy(false, false);
    }

    Super::Destroyed();
}

void APiratesHumanCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    UpdateSynchron();
}

void APiratesHumanCharacter::BeginPlay()
{
	FlotageComponent = Cast<UFlotageComponent>(GetComponentByClass(UFlotageComponent::StaticClass()));

	if (FlotageComponent != nullptr)
	{
		FlotageComponent->ApplyTransform = false;
		FlotageComponent->bForShip = false;
		FlotageComponent->SetWaterLineOffset(20.0f);
		FlotageComponent->SetWaterPositionOffset(30.0f);
	}

	Super::BeginPlay();
}


EPathFollowingRequestResult::Type APiratesHumanCharacter::SwimNavMove(const FVector& DestLocation, float AcceptanceRadius)
{
    if (GetHumanMovementComponent() == nullptr)
    {
        return EPathFollowingRequestResult::Type::Failed;
    }

    if ((GetHumanLocation() - DestLocation).SizeSquared2D() < FMath::Square(AcceptanceRadius))
    {
        return EPathFollowingRequestResult::Type::AlreadyAtGoal;
    }

    TArray<FVector> OutNavPath;
    if (!FindSwimPathSync(DestLocation, OutNavPath))
    {
        return EPathFollowingRequestResult::Type::Failed;
    }

    if (OutNavPath.Num() == 0)
    {
        return EPathFollowingRequestResult::Type::AlreadyAtGoal;
    }

    MovementComponent->StartHumanPathMove(OutNavPath, AcceptanceRadius);

    return EPathFollowingRequestResult::RequestSuccessful;
}

void APiratesHumanCharacter::AbortNavMove()
{
    if (EnsureNavMovePreCondition())
    {
        //NavMoveAIController->StopMovement();
        MovementComponent->AbortHumanPathMove();
    }
}

void APiratesHumanCharacter::AbortRelativeMove()
{
    if (PathFollowingComponent != nullptr)
    {
        PathFollowingComponent->AbortMove();
    }
}

bool APiratesHumanCharacter::FindPathSync(const FVector& DestLocation, TArray<FVector>& OutNavPath, bool bOptimizePath)
{
    if (!EnsureNavMovePreCondition())
    {
        return false;
    }

    FVector ProjectedLocation = DestLocation;
    if (!FindNearestNavLocation(ProjectedLocation))
    {
        return false;
    }

    FAIMoveRequest MoveRequest;
    BuildAIMoveRequest(MoveRequest, ProjectedLocation, 200.f);

    FPathFindingQuery PFQuery;
    if (NavMoveAIController->BuildPathfindingQuery(MoveRequest, PFQuery))
    {
        //PFQuery.NavDataFlags |= ERecastPathFlags::SkipStringPulling | ERecastPathFlags::GenerateCorridor;

        FNavPathSharedPtr PathPtr;
        NavMoveAIController->FindPathForMoveRequest(MoveRequest, PFQuery, PathPtr);

        if (PathPtr.IsValid() && PathPtr->IsValid())
        {
            /*FNavMeshPath* NavMeshPath = PathPtr->CastPath<FNavMeshPath>();
            if (NavMeshPath == nullptr)
            {
                return false;
            }

            for (auto& i : NavMeshPath->GetPathCorridorEdges())
            {
                OutNavPath.Emplace(i.GetMiddlePoint());
            }

            OutNavPath.Emplace(ProjectedLocation);*/

            for (auto& point : PathPtr->GetPathPoints())
            {
                OutNavPath.Emplace(point);
            }

//             if (bOptimizePath)
//             {
//                 MovementComponent->OptimizeNavMeshPath(OutNavPath);
//             }

            return true;
        }
    }

    return false;
}

EPathFollowingRequestResult::Type APiratesHumanCharacter::DirectNavMove(const TArray<FVector>& NavPath, float AcceptanceRadius)
{
    if (!EnsureNavMovePreCondition())
    {
        UE_LOG(LogPiratesHuman, Log, TEXT("DirectNavMove EnsureNavMovePreCondition Error."));
        return EPathFollowingRequestResult::Type::Failed;
    }

    if (NavPath.Num() == 0)
    {
        UE_LOG(LogPiratesHuman, Log, TEXT("DirectNavMove Error, NavPath is null."));
        return EPathFollowingRequestResult::Type::AlreadyAtGoal;
    }

    MovementComponent->StartHumanPathMove(NavPath, AcceptanceRadius);
    return EPathFollowingRequestResult::RequestSuccessful;

    /*FAIMoveRequest MoveRequest;
    BuildAIMoveRequest(MoveRequest, NavPath[NavPath.Num() - 1], AcceptanceRadius);

    FNavPathSharedPtr PathPtr = MakeShareable(new FNavigationPath);
    PathPtr->MarkReady();
    TArray<FNavPathPoint>& PathPoints = PathPtr->GetPathPoints();
    for (const auto& i : NavPath)
    {
        PathPoints.Emplace(i);
    }

    FAIRequestID RequestID = NavMoveAIController->RequestMove(MoveRequest, PathPtr);
    if (RequestID.IsValid())
    {
        return EPathFollowingRequestResult::RequestSuccessful;
    }

    return EPathFollowingRequestResult::Type::Failed;*/
}

UHumanMovementComponent* APiratesHumanCharacter::GetHumanMovementComponent()
{
    if (MovementComponent == nullptr)
    {
        MovementComponent = Cast<UHumanMovementComponent>(GetCharacterMovement());
        //MovementComponent->OnHumanPathMoveFinished.AddDynamic(this, &APiratesHumanCharacter::OnReceiveMoveCompleted);
    }

    return MovementComponent;
}

FVector APiratesHumanCharacter::GetHumanLocation()
{
    check(MovementComponent != nullptr);
    return MovementComponent->UpdatedComponent->GetComponentLocation();
}

void APiratesHumanCharacter::TeleportHuman(const FVector& Location, float Yaw, bool bResetMovement)
{
    check(MovementComponent != nullptr);
    MovementComponent->TeleportHuman(Location, Yaw, bResetMovement);
}

void APiratesHumanCharacter::SetIsRelativePath(bool Value) { IsRelativePath = Value; }

bool APiratesHumanCharacter::GetIsRelativePath()
{
	return IsRelativePath;
}

bool APiratesHumanCharacter::IsLocationReachable(const FVector& Location)
{
    TArray<FVector> OutNavPath;
    if (FindPathSync(Location, OutNavPath, false))
    {
        return true;
    }

    return false;
}

bool APiratesHumanCharacter::GetNearestSafeLocation(const FVector& InLocation, float Radius, FVector& OutLocation)
{
    UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(GetWorld());
    if (NavSys)
    {
        FNavLocation ResultLocation;
        if (NavSys->GetRandomReachablePointInRadius(InLocation, Radius, ResultLocation))
        {
            OutLocation = ResultLocation.Location;
            return true;
        }        
    }

    return false;
}

void APiratesHumanCharacter::SetActorIsReplicates(bool bInReplicates)
{
    if (GetLocalRole() == ROLE_Authority)
    {
        const bool bAddNetworkActor = (bReplicates == false && bInReplicates == true);
        const bool bRemoveNetworkActor = (bReplicates == true && bInReplicates == false);

        // Update our settings before calling into net driver
        //RemoteRole = (bInReplicates ? ROLE_SimulatedProxy : ROLE_None);
        bReplicates = bInReplicates;

        // Only call into net driver if we actually changed
        if (bAddNetworkActor)
        {
            if (UWorld* MyWorld = GetWorld())
            {
                MyWorld->AddNetworkActor(this);
            }
        }
        else if (bRemoveNetworkActor)
        {
            if (UWorld* MyWorld = GetWorld())
            {
                MyWorld->RemoveNetworkActor(this);
            }
        }
    }
}
//
//bool APiratesHumanCharacter::IsNetRelevantFor(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const
//{
//    return Super::IsNetRelevantFor(RealViewer, ViewTarget, SrcLocation)
//        && IsNetRelevantForInBP(RealViewer, ViewTarget, SrcLocation);
//}
//
//bool APiratesHumanCharacter::IsNetRelevantForInBP_Implementation(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const
//{
//	return true;
//}

void APiratesHumanCharacter::SetActorHiddenInGame(bool bNewHidden)
{
	Super::SetActorHiddenInGame(bNewHidden);
	if (EmitterActivateComponent)
	{
		EmitterActivateComponent->ActivateEmitter();
	}
}

bool APiratesHumanCharacter::EnsureNavMovePreCondition()
{
    if (GetHumanMovementComponent() == nullptr)
    {
        return false;
    }

    //if (IsLocallyControlled())
    if (IsPlayerControlled())
    {
        if (AIControllerClass == nullptr)
        {
            return false;
        }

        if (NavMoveAIController == nullptr)
        {
            NavMoveAIController = GetWorld()->SpawnActor<AAIController>(AIControllerClass);
            if (NavMoveAIController == nullptr)
            {
                return false;
            }
        }

        APiratesHumanCharacter* ThePawn = Cast<APiratesHumanCharacter>(NavMoveAIController->GetPawn());
        if (ThePawn != this)
        {
            NavMoveAIController->SetPawn(this);
        }

        return true;
    }
    else
    {
        NavMoveAIController = Cast<AAIController>(GetController());
        if (NavMoveAIController == nullptr)
        {
            return false;
        }
    }

    return true;
}

void APiratesHumanCharacter::BuildAIMoveRequest(FAIMoveRequest& AIMoveRequest, const FVector& Dest, float AcceptanceRadius)
{
    AIMoveRequest.SetGoalLocation(Dest);
    AIMoveRequest.SetUsePathfinding(true);
    AIMoveRequest.SetAllowPartialPath(false);
    AIMoveRequest.SetProjectGoalLocation(false);
    AIMoveRequest.SetNavigationFilter(nullptr);
    AIMoveRequest.SetAcceptanceRadius(AcceptanceRadius);
    AIMoveRequest.SetReachTestIncludesAgentRadius(false);
    AIMoveRequest.SetCanStrafe(true);
}

bool APiratesHumanCharacter::FindNearestNavLocation(FVector& Location)
{
    UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(GetWorld());
    if (NavSys == nullptr)
    {
        return false;
    }

    const FNavDataConfig& NavDataConfig = NavSys->GetDefaultSupportedAgentConfig();
    const FVector& QueryExtent = NavDataConfig.DefaultQueryExtent;
    //Location.Z = QueryExtent.Z * 0.5f;

    const FNavAgentProperties& AgentProps = GetNavAgentPropertiesRef();
	const ANavigationData* NavData = NavSys->GetNavDataForProps(AgentProps);
    FNavLocation ProjectedLocation;
    if (NavSys->ProjectPointToNavigation(Location, ProjectedLocation, QueryExtent, NavData))
    {
        Location = ProjectedLocation.Location;
        return true;
    }

    return false;
}

bool APiratesHumanCharacter::FindSwimPathSync(const FVector& DestLocation, TArray<FVector>& OutNavPath)
{
    if (!AcquireOceanNavData())
    {
        return false;
    }

    auto StartLocation = GetHumanLocation();
    FMapNavGridPathFinding::EResult Result = PathFinding->FindSwimPathSync(StartLocation, nullptr, DestLocation, OutNavPath);
    if (Result == FMapNavGridPathFinding::EResult::Successful)
    {
        return true;
    }
    else
    {
        OutNavPath.Emplace(DestLocation);
        return true;
    }

    return false;
}

bool APiratesHumanCharacter::AcquireOceanNavData()
{
    if (bOceanNavDataAcquired)
    {
        return true;
    }

    auto OceanNavGridManager = UGameCommon::Get(this)->GetOceanNavGridManager();
    if (OceanNavGridManager == nullptr)
    {
        return false;
    }

    float NavAgentRadius = 10.f;
    GridLayout = OceanNavGridManager->GetGridLayout(NavAgentRadius);
    if (GridLayout == nullptr)
    {
        return false;
    }

    PathFinding = OceanNavGridManager->GetPathFinding(NavAgentRadius);
    if (PathFinding == nullptr)
    {
        return false;
    }

    bOceanNavDataAcquired = true;
    return true;
}

void APiratesHumanCharacter::UpdateSynchron()
{
    if (GetHumanMovementComponent() == nullptr)
    {
        return;
    }

    ReturnIfNullptr(FlotageComponent);
    MovementComponent->UpdateFlotage(FlotageComponent->LocationZ);
}

// void APiratesHumanCharacter::OnReceiveMoveCompleted(EPathFollowingResult::Type Result)
// {
//     OnNavMoveFinished.Broadcast(Result);
// }

bool APiratesHumanCharacter::CanBeSeenFrom(const FVector& ObserverLocation, FVector& OutSeenLocation, int32& NumberOfLoSChecksPerformed, float& OutSightStrength, const AActor* IgnoreActor /* = NULL */) const
{
    NumberOfLoSChecksPerformed = 0;
    TArray<FVector, TInlineAllocator<4>> CheckPointList;
    CheckPointList.Emplace(GetActorLocation());
    CheckPointList.Emplace(GetEyePosition());
    static const FName QueryName = TEXT("AI Visibly Check");
    for (auto& CheckPoint : CheckPointList)
    {
        FHitResult HitResult;
        NumberOfLoSChecksPerformed++;
        bool bHit = GetWorld()->LineTraceSingleByChannel(HitResult, ObserverLocation, CheckPoint, ECC_Visibility, FCollisionQueryParams(QueryName, true, IgnoreActor));
        if (bHit == false || (HitResult.Actor.IsValid() && HitResult.Actor->IsOwnedBy(this)))
        {
            OutSightStrength = 1;
            OutSeenLocation = CheckPoint;
            return true;
        }
    }
    return false;
}

void APiratesHumanCharacter::GetActorEyesViewPoint(FVector& Location, FRotator& Rotation) const
{
    Super::GetActorEyesViewPoint(Location, Rotation);
    Location = GetEyePosition();
}


FVector APiratesHumanCharacter::GetEyePosition_Implementation() const
{
    return GetPawnViewLocation();
}

void APiratesHumanCharacter::OnRep_ReplicatedBasedMovement()
{
    if (!IsReplicatingMovement())
    {
        return;
    }

    if (GetLocalRole() != ROLE_SimulatedProxy)
    {
        return;
    }
    UHumanMovementComponent* HumanMovementComponent = GetHumanMovementComponent();

    //// Skip base updates while playing root motion, it is handled inside of OnRep_RootMotion
    //if (IsPlayingNetworkedRootMotionMontage())
    //{
    //    return;
    //}
    HumanMovementComponent->bNetworkUpdateReceived = true;
    TGuardValue<bool> bInBaseReplicationGuard(bInBaseReplication, true);

    const bool bBaseChanged = (BasedMovement.MovementBase != ReplicatedBasedMovement.MovementBase || BasedMovement.BoneName != ReplicatedBasedMovement.BoneName);
    if (bBaseChanged)
    {
        // Even though we will copy the replicated based movement info, we need to use SetBase() to set up tick dependencies and trigger notifications.
        SetBase(ReplicatedBasedMovement.MovementBase, ReplicatedBasedMovement.BoneName);
    }

    // Make sure to use the values of relative location/rotation etc from the server.
    BasedMovement = ReplicatedBasedMovement;

    if (ReplicatedBasedMovement.HasRelativeLocation())
    {
        // Update transform relative to movement base
        const FVector OldLocation = GetActorLocation();
        const FQuat OldRotation = GetActorQuat();
        MovementBaseUtility::GetMovementBaseTransform(ReplicatedBasedMovement.MovementBase, ReplicatedBasedMovement.BoneName, HumanMovementComponent->OldBaseLocation, HumanMovementComponent->OldBaseQuat);
        const FVector NewLocation = HumanMovementComponent->OldBaseLocation + ReplicatedBasedMovement.Location;
        FRotator NewRotation;

        if (ReplicatedBasedMovement.HasRelativeRotation())
        {
            // Relative location, relative rotation
            NewRotation = (FRotationMatrix(ReplicatedBasedMovement.Rotation) * FQuatRotationMatrix(HumanMovementComponent->OldBaseQuat)).Rotator();

            if (HumanMovementComponent->ShouldRemainVertical())
            {
                NewRotation.Pitch = 0.f;
                NewRotation.Roll = 0.f;
            }
        }
        else
        {
            // Relative location, absolute rotation
            NewRotation = ReplicatedBasedMovement.Rotation;
        }

        // When position or base changes, movement mode will need to be updated. This assumes rotation changes don't affect that.
        HumanMovementComponent->bJustTeleported |= (bBaseChanged || NewLocation != OldLocation);
        HumanMovementComponent->bNetworkSmoothingComplete = false;
        HumanMovementComponent->SmoothCorrection(OldLocation, OldRotation, NewLocation, NewRotation.Quaternion());
        OnUpdateSimulatedPosition(OldLocation, OldRotation);
    }
}