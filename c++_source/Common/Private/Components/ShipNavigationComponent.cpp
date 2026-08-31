#include "Components/ShipNavigationComponent.h"
#include "Common.h"
#include "Pawns/PiratesShipPawn.h"
#include "Components/ShipMovementComponent.h"
#include "Game/GameCommon.h"
#include "OceanNavGridManager.h"
#include "MapNavGridLayout.h"
#include "MapNavGridPathFinding.h"
#include "MapNavGridAsyncPathFindingManager.h"


//#include <sys/time.h>
//#include <time.h>
//#include <stdio.h>
//#include "WindowsPlatformTime.h"

DEFINE_LOG_CATEGORY_STATIC(LogShipNavigation, Log, All);

int32 CVar_ShipNavLog = 0;
static FAutoConsoleVariableRef CVarShipNavLog(TEXT("ShipNavLog"), CVar_ShipNavLog, TEXT(""), ECVF_Default);

UShipNavigationComponent::UShipNavigationComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
    PrimaryComponentTick.bCanEverTick = true;
    PrimaryComponentTick.bStartWithTickEnabled = true;
    PrimaryComponentTick.TickGroup = TG_PrePhysics;

    SetIsReplicatedByDefault(false);

    ShipPawn = nullptr;
    MovementComponent = nullptr;

    bNavDataAcquired = false;
    PathFinding = nullptr;
    GridLayout = nullptr;
    GridCost = nullptr;
    AsyncPathFindingManager = nullptr;
    AsyncPathFindingFuture = nullptr;

    bNeedRetryAsyncPathFinding = false;
    AsyncPathFindingRetryLocation = FVector::ZeroVector;
}

void UShipNavigationComponent::BeginPlay()
{
    Super::BeginPlay();

    ShipPawn = Cast<APiratesShipPawn>(GetOwner());
    check(ShipPawn != nullptr);

    MovementComponent = ShipPawn->GetShipMovementComponent();
}

void UShipNavigationComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    Super::EndPlay(EndPlayReason);

    CancelAsyncPathFinding();
}

void UShipNavigationComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
    Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

    if (AsyncPathFindingFuture != nullptr && AsyncPathFindingFuture->IsReady())
    {
        ShipPawn->OnAsyncPathFindingFinished.Broadcast(AsyncPathFindingFuture->GetResult(), AsyncPathFindingFuture->GetNavPath());
        AsyncPathFindingManager->Release(AsyncPathFindingFuture);
        AsyncPathFindingFuture = nullptr;
    }

    if (bNeedRetryAsyncPathFinding)
    {
        FindPathAsync(AsyncPathFindingRetryLocation);
    }
}

bool UShipNavigationComponent::FindPathSync(const FVector& DestLocation, TArray<FVector>& OutPath)
{
    if (AcquireNavData())
    {
        FVector CurrentLocation = ShipPawn->GetShipLocation();
        double NowTime = FPlatformTime::Cycles64();
        FMapNavGridPathFinding::EResult Result = PathFinding->FindPathSync(CurrentLocation, nullptr, DestLocation, OutPath);
        if (FMapNavGridPathFinding::EResult::Successful == Result)
        {
           double EndTime = FPlatformTime::Cycles64();
           double MSec = FPlatformTime::ToMilliseconds64((EndTime - NowTime));
           if (MSec > 10.f || CVar_ShipNavLog)
           {
               UE_LOG(LogShipNavigation, Log, TEXT("%s finging path success, mtime=%lf, curLoc=%s, desLoc=%s"),
                   *(ShipPawn->GetName()), MSec, *CurrentLocation.ToString(), *DestLocation.ToString());
           }           
            return true;
        }
       double EndTime = FPlatformTime::Cycles64();
       double MSec = FPlatformTime::ToMilliseconds64((EndTime - NowTime));
       if (MSec > 10.f || CVar_ShipNavLog)
       {
           UE_LOG(LogShipNavigation, Log, TEXT("%s finging path fail, mtime=%lf, curLoc=%s, desLoc=%s"),
               *(ShipPawn->GetName()), MSec, *CurrentLocation.ToString(), *DestLocation.ToString());
       }      

#if UE_EDITOR
        UE_LOG(LogShipNavigation, Log, TEXT("[%s] Fail to FindPathSync, result = %i, start = %s, dest = %s"),
            *(GetName()), (int)Result, *(CurrentLocation.ToString()), *(DestLocation.ToString()));
#endif
    }
    else
    {
        UE_LOG(LogShipNavigation, Error, TEXT("Fail to FindPathSync because no navigation data"));
    }

    return false;
}

void UShipNavigationComponent::FindPathAsync(const FVector& DestLocation)
{
    if (AcquireNavData())
    {
        CancelAsyncPathFinding();

        AsyncPathFindingFuture = AsyncPathFindingManager->FindPathAsync(ShipPawn, GridLayout, GridCost, DestLocation);
        if (AsyncPathFindingFuture == nullptr)
        {
#if UE_EDITOR
            UE_LOG(LogShipNavigation, Warning, TEXT("Fail to FindPathAsync because request pool is full. UserNum=%i, ZombieNum=%i"),
                AsyncPathFindingManager->GetUserNum(), AsyncPathFindingManager->GetZombieNum());
#endif
            
            bNeedRetryAsyncPathFinding = true;
            AsyncPathFindingRetryLocation = DestLocation;
        }
        else
        {
            bNeedRetryAsyncPathFinding = false;
        }
    }
    else
    {
        UE_LOG(LogShipNavigation, Error, TEXT("Fail to FindPathAsync because no navigation data"));
    }
}

void UShipNavigationComponent::CancelAsyncPathFinding()
{
    if (AsyncPathFindingFuture != nullptr)
    {
        const APiratesShipPawn* User = Cast<APiratesShipPawn>(AsyncPathFindingFuture->GetUser());
        if (User == ShipPawn)
        {
            check(AsyncPathFindingManager != nullptr);
            AsyncPathFindingManager->Release(AsyncPathFindingFuture);

            AsyncPathFindingFuture = nullptr;
            bNeedRetryAsyncPathFinding = false;
        }
    }
}

bool UShipNavigationComponent::IsLocationReachable(const FVector& Location)
{
    if (AcquireNavData())
    {
        if (!GridLayout->IsValidLocation(Location, 0.f))
        {
            return false;
        }

        return GridLayout->IsReachable(Location);
    }

    return false;
}

bool UShipNavigationComponent::IsLocationSafe(const FVector & Location)
{
    if (AcquireNavData())
    {
        if (!GridLayout->IsValidLocation(Location, 0.f))
        {
            return false;
        }

        return GridLayout->GetGrid(Location) < EMapNavGridType::BlockEdge;
    }

    return false;
}

bool UShipNavigationComponent::GetNearestReachableLocation(const FVector& InLocation, float Radius, FVector & OutLocation)
{
    if (AcquireNavData())
    {
        return GridLayout->GetNearestLocation(InLocation, Radius, EMapNavGridType::PartialBlock, OutLocation);
    }

    return false;
}

bool UShipNavigationComponent::GetNearestSafeLocation(const FVector& InLocation, float Radius, FVector& OutLocation)
{
    if (AcquireNavData())
    {
        return GridLayout->GetNearestLocation(InLocation, Radius, EMapNavGridType::BlockEdge, OutLocation);
    }

    return false;
}

bool UShipNavigationComponent::AcquireNavData()
{
    if (bNavDataAcquired)
    {
        return true;
    }

    auto OceanNavGridManager = UGameCommon::Get(this)->GetOceanNavGridManager();
    if (OceanNavGridManager == nullptr)
    {
        return false;
    }

    float NavAgentRadius = 0.f;
    if (MovementComponent != nullptr)
    {
        NavAgentRadius = MovementComponent->GetNavAgentPropertiesRef().AgentRadius;
    }

    GridLayout = OceanNavGridManager->GetGridLayout(NavAgentRadius);
    if (GridLayout == nullptr)
    {
        return false;
    }

    GridCost = OceanNavGridManager->GetGridCost();
    if (GridCost == nullptr)
    {
        return false;
    }

    PathFinding = OceanNavGridManager->GetPathFinding(NavAgentRadius);
    if (PathFinding == nullptr)
    {
        return false;
    }

    AsyncPathFindingManager = OceanNavGridManager->GetAsyncPathFindingManager();
    if (AsyncPathFindingManager == nullptr)
    {
        return false;
    }

    bNavDataAcquired = true;
    return true;
}