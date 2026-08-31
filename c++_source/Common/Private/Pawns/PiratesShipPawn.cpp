#include "Pawns/PiratesShipPawn.h"
#include "Common.h"
#include "Components/ShipMovementComponent.h"
#include "ShipNavigationComponent.h"
#include "KMPlayerController.h"
#include "PiratesLocalPlayer.h"
#include "ReplicatedProtoPropertyComponent.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "EmitterActivateComponent.h"
#include "CustomReplicationComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetMathLibrary.h"
#include "FlotageComponent.h"
#include "Camera/PlayerCameraManager.h"
#include "Net/UnrealNetwork.h"

APiratesShipPawn::APiratesShipPawn(const FObjectInitializer& ObjectInitailizer)
	: Super(ObjectInitailizer)
	, ShipHeight(0.f)
	, bUsingAsyncPathFindingForAI(false)
	, bMastVisible(true)
	, ShipModelRelativeZ(0.0f)
{
	PrimaryActorTick.bCanEverTick = true;

//    static FName DefaultRPCPropertyCompName = FName("ReplicatedProtoPropertyComponent");
//	CreateOptionalDefaultSubobject<UReplicatedProtoPropertyComponent>(DefaultRPCPropertyCompName);

	ShipMovementComponent = CreateDefaultSubobject<UShipMovementComponent>(TEXT("ShipMovementComponent"));
	AddOwnedComponent(ShipMovementComponent);
    ShipMovementComponent->OnShipPathMoveFinished.AddDynamic(this, &APiratesShipPawn::OnNavMoveFinishedInternal);

    ShipNavigationComponent = CreateDefaultSubobject<UShipNavigationComponent>(TEXT("ShipNavigationComponent"));
    AddOwnedComponent(ShipNavigationComponent);

    if (!HasAnyFlags(RF_ClassDefaultObject))
    {
        EmitterActivateComponent = CreateDefaultSubobject<UEmitterActivateComponent>(TEXT("EmitterActivate"));
        AddOwnedComponent(EmitterActivateComponent);
    }
}

void APiratesShipPawn::BeginPlay()
{
	UChildActorComponent* ChildActorComponent = Cast<UChildActorComponent>(GetComponentByClass(UChildActorComponent::StaticClass()));
	if (ChildActorComponent != nullptr)
	{
		ShipModelRelativeZ = ChildActorComponent->GetRelativeLocation().Z;
		AActor* ModelActor = ChildActorComponent->GetChildActor();
		if (ModelActor != nullptr)
		{
			FlotageComponent = Cast<UFlotageComponent>(ModelActor->GetComponentByClass(UFlotageComponent::StaticClass()));
			if (FlotageComponent != nullptr)
			{
				FlotageComponent->ApplyTransform = false;
			}
		}
	}

    if (ShipMovementComponent)
    {
        ShipMovementComponent->RefreshShipBoxExtend(FlotageComponent->GetWaterLineOffset());
    }

	Super::BeginPlay();
}

void APiratesShipPawn::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
	UpdateSynchron();
	//UpdateMastVisible();
}

void APiratesShipPawn::SmoothTravelSwap_Implementation(AActor* Actor)
{
}

void APiratesShipPawn::SmoothTravelPreTravel_Implementation()
{
}

void APiratesShipPawn::SetRemoteViewYaw(float NewRemoteViewYaw)
{
	// Compress pitch to 1 byte
	NewRemoteViewYaw = FRotator::ClampAxis(NewRemoteViewYaw);
	RemoteViewYaw = (uint8)(NewRemoteViewYaw * 255.f / 360.f);
}
//
//bool APiratesShipPawn::IsNetRelevantFor(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const
//{
//    return Super::IsNetRelevantFor(RealViewer, ViewTarget, SrcLocation)
//        && IsNetRelevantForInBP(RealViewer, ViewTarget, SrcLocation);
//}
//
//bool APiratesShipPawn::IsNetRelevantForInBP_Implementation(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const
//{
//	return true;
//}

FRotator APiratesShipPawn::GetBaseAimRotation() const
{
	FVector POVLoc;
	FRotator POVRot;
	if (Controller != nullptr && !InFreeCam())
	{
		Controller->GetPlayerViewPoint(POVLoc, POVRot);
		return POVRot;
	}

	POVRot = GetActorRotation();
	POVRot.Pitch = RemoteViewPitch;
	POVRot.Pitch = POVRot.Pitch * 360.0f / 255.0f;
	POVRot.Yaw = RemoteViewYaw;
	POVRot.Yaw = POVRot.Yaw * 360.0f / 255.0f;

	return POVRot;
}

void APiratesShipPawn::GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	DOREPLIFETIME_CONDITION(APiratesShipPawn, RemoteViewYaw, COND_SkipOwner);
}

void APiratesShipPawn::PreReplication(IRepChangedPropertyTracker & ChangedPropertyTracker)
{
	Super::PreReplication(ChangedPropertyTracker);

	if (GetLocalRole() == ROLE_Authority && GetController())
	{
		SetRemoteViewYaw(GetController()->GetControlRotation().Yaw);
	}
}

void APiratesShipPawn::OnRep_Controller()
{
    //In the case APawn::Controller is repped before AController::Pawn, when OnRep_Controller comes, it calls Controller->SetPawnFromRep(this) to
    //ensure APawn::OnRep_Pawn is called. But we "SetPawn(SwapFrom->GetPawn())" in APiratesPlayerController::SmoothTravelSwap_Implementation, which
    //prevents Controller->SetPawnFromRep(this) from calling. So here we need to SetPawn to null to activate SetPawnFromRep.

    APlayerController* PlayerController = Cast<APlayerController>(Controller);
    if (PlayerController != NULL)
    {
        auto localPlayer = Cast<UPiratesLocalPlayer>(PlayerController->GetLocalPlayer());
        auto bInSmoothTravel = localPlayer != NULL && localPlayer->InSmoothTravel();
        if (bInSmoothTravel && PlayerController->GetPawn() != this)
        {
            PlayerController->SetPawn(NULL);
        }
    }

    Super::OnRep_Controller();
}

bool APiratesShipPawn::NavMove(const FVector& DestLocation, float AcceptanceRadius, bool bStopOnFinish, TArray<FVector>& OutPath)
{
    if (IsPendingKill() || ShipMovementComponent == nullptr || ShipNavigationComponent == nullptr)
    {
        return false;
    }

    if (ShipNavigationComponent->FindPathSync(DestLocation, OutPath))
    {
        ShipMovementComponent->StartShipPathMove(OutPath, AcceptanceRadius, bStopOnFinish);
        return true;
    }

    return false;
}

bool APiratesShipPawn::DirectNavMove(const TArray<FVector>& InPath, float AcceptanceRadius, bool bStopOnFinish)
{
    if (IsPendingKill() || ShipMovementComponent == nullptr)
    {
        return false;
    }

    ShipMovementComponent->StartShipPathMove(InPath, AcceptanceRadius, bStopOnFinish);
    return true;
}

void APiratesShipPawn::AbortNavMove(EMapNavGridPathFollowingResult Result)
{
    if (IsPendingKill() || ShipMovementComponent == nullptr)
    {
        return;
    }

    ShipMovementComponent->AbortShipPathMove(Result);
}

bool APiratesShipPawn::FindPathSync(const FVector& DestLocation, TArray<FVector>& OutPath)
{
    if (IsPendingKill() || ShipNavigationComponent == nullptr)
    {
        return false;
    }

    return ShipNavigationComponent->FindPathSync(DestLocation, OutPath);
}

void APiratesShipPawn::FindPathAsync(const FVector& DestLocation)
{
    if (IsPendingKill() || ShipNavigationComponent == nullptr)
    {
        return;
    }

    ShipNavigationComponent->FindPathAsync(DestLocation);
}

int32 APiratesShipPawn::GetNavMoveNextPathPointIndex()
{
    if (ShipMovementComponent != nullptr && ShipMovementComponent->IsShipPathMove())
    {
        return ShipMovementComponent->GetShipPathMoveCurrentIndex();
    }

    return -1;
}

bool APiratesShipPawn::DrawDebugNavMovePath(float ExitTime)
{
    if (ShipMovementComponent == nullptr)
    {
        return false;
    }

    int32 StartIndex = GetNavMoveNextPathPointIndex();
    if (StartIndex < 0)
    {
        return false;
    }

    const auto& NavPath = ShipMovementComponent->GetShipPathMoveNavPath();
    for (int i = StartIndex; i < NavPath.Num(); ++i)
    {
        ShipMovementComponent->DrawDebugGrids(NavPath[i], false, ExitTime);
    }

    return true;
}

bool APiratesShipPawn::IsLocationReachable(const FVector& Location)
{
    if (ShipNavigationComponent == nullptr)
    {
        return false;
    }

    return ShipNavigationComponent->IsLocationReachable(Location);
}

bool APiratesShipPawn::IsLocationSafe(const FVector& Location)
{
    if (ShipNavigationComponent == nullptr)
    {
        return false;
    }

    return ShipNavigationComponent->IsLocationSafe(Location);
}

bool APiratesShipPawn::GetNearestReachableLocation(const FVector& InLocation, float Radius, FVector& OutLocation)
{
    if (ShipNavigationComponent == nullptr)
    {
        return false;
    }

    return ShipNavigationComponent->GetNearestReachableLocation(InLocation, Radius, OutLocation);
}

bool APiratesShipPawn::GetNearestSafeLocation(const FVector& InLocation, float Radius, FVector& OutLocation)
{
    if (ShipNavigationComponent == nullptr)
    {
        return false;
    }

    return ShipNavigationComponent->GetNearestSafeLocation(InLocation, Radius, OutLocation);
}

FVector APiratesShipPawn::GetShipLocation()
{
    check(ShipMovementComponent != nullptr);
    return ShipMovementComponent->GetShipLocation();
}

void APiratesShipPawn::TeleportShip(const FVector& Location, float Yaw, bool bResetMovement)
{
    check(ShipMovementComponent != nullptr);
    ShipMovementComponent->TeleportShip(Location, Yaw, bResetMovement);
}

UShipMovementComponent* APiratesShipPawn::GetShipMovementComponent()
{
    return ShipMovementComponent;
}

void APiratesShipPawn::SetActorHiddenInGame(bool bNewHidden)
{
	Super::SetActorHiddenInGame(bNewHidden);
	ReturnIfNullptr(EmitterActivateComponent);
	EmitterActivateComponent->ActivateEmitter();
}

void APiratesShipPawn::OnNavMoveFinishedInternal(EMapNavGridPathFollowingResult Result)
{
    OnNavMoveFinished.Broadcast(Result);
}

// void APiratesShipPawn::UpdateMastVisible()
// {
// 	ReturnIfFalse(GIsClient);

// 	auto PlayerPawn = UGameplayStatics::GetPlayerPawn(this, 0);
// 	ReturnIfFalse(PlayerPawn == this);

//     auto CameraArmLength = GetCameraArmLength();
// 	ReturnIfFalse(CameraArmLength > 0);

// 	auto PlayerCameraManager = UGameplayStatics::GetPlayerCameraManager(this, 0);
// 	ReturnIfNullptr(PlayerCameraManager);

// 	auto CameraRotation = PlayerCameraManager->GetCameraRotation();
// 	bool bNewVisible = CameraRotation.Pitch > UKismetMathLibrary::DegAtan(ShipHeight / CameraArmLength);
// 	ReturnIfFalse(bNewVisible != bMastVisible);

// 	bMastVisible = bNewVisible;
// 	OnMastVisibleChanged(bMastVisible);
// }

void APiratesShipPawn::SetMastVisible(bool Visible)
{
	bMastVisible = Visible;
	OnMastVisibleChanged(bMastVisible);
}

void APiratesShipPawn::TriggerMastVisibleChangedEvent()
{
	OnMastVisibleChanged(bMastVisible);
}

void APiratesShipPawn::UpdateSynchron()
{
	ReturnIfNullptr(FlotageComponent);
    if (ShipMovementComponent == nullptr)
    {
        return;
    }
    ShipMovementComponent->UpdateShipTransformRestrictly(FlotageComponent->LocationZ - ShipModelRelativeZ, FlotageComponent->Pitch, FlotageComponent->Roll);
    FlotageComponent->SetShipLinearSpeed(ShipMovementComponent->GetCurrentLinearSpeed());
    FlotageComponent->SetShipAngularSpeed(ShipMovementComponent->GetCurrentAngularSpeed());
}
