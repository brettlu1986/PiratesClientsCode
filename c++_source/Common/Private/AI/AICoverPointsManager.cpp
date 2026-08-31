#include "AI/AICoverPointsManager.h"
#include "Shell/CommonShell.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "HAL/FileManager.h"
#if WITH_EDITOR
#include "DrawDebugHelpers.h"
#include "Kismet/GameplayStatics.h"
#include "Camera/PlayerCameraManager.h"
#include "GameFramework/PlayerController.h"
#endif

static const TCHAR* AI_COVER_POINTS_LOAD_PATH = TEXT("GameDataGenerated/common/ai/");

struct FVisitor : public IPlatformFile::FDirectoryVisitor
{
    UAICoverPointsManager*  AICoverPointsManager;

    FVisitor(UAICoverPointsManager* InAICoverPointsManager) :AICoverPointsManager(InAICoverPointsManager)
    {

    }

    virtual bool Visit(const TCHAR* FilenameOrDirectory, bool bIsDirectory)
    {
        if (!bIsDirectory)
        {
            IFileManager& FileManager = IFileManager::Get();
            FArchive* FileReader = FileManager.CreateFileReader(FilenameOrDirectory);
            if (FileReader)
            {
                AICoverPointsManager->ParseOneOctree(*FileReader);
                FileReader->Close();
                delete FileReader;

            }
        }
        return true;
    }
};



UAICoverPointsManager::UAICoverPointsManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{

}

bool UAICoverPointsManager::Init()
{
    OnPostLoadMapHandle = FCoreUObjectDelegates::PostLoadMapWithWorld.AddUObject(this, &UAICoverPointsManager::OnPostLoadMap);
    OnWorldCleanUpHandle = FWorldDelegates::OnWorldCleanup.AddUObject(this, &UAICoverPointsManager::OnWorldCleanUp);

    return true;
}

bool UAICoverPointsManager::Uninit()
{
    FCoreUObjectDelegates::PostLoadMapWithWorld.Remove(OnPostLoadMapHandle);
    FWorldDelegates::OnWorldCleanup.Remove(OnWorldCleanUpHandle);
    return true;
}


void UAICoverPointsManager::Load(const FString& WorldName)
{
    
    UnLoad();
    UE_LOG(LogTemp, Display, TEXT("%s: Start load"), *GetNameSafe(this));

    FString LoadDir = FPaths::ProjectContentDir() + AI_COVER_POINTS_LOAD_PATH + WorldName;
    
    FVisitor Visitor(this);
    IFileManager& FileManager = IFileManager::Get();
    IFileManager::Get().IterateDirectory(*LoadDir, Visitor);
}

void UAICoverPointsManager::ParseOneOctree(FArchive& Ar)
{
    FVector Extent;
    FVector Center;

    FCoverPointOctreeProxy::LoadCenterAndSize(Ar, Center, Extent);
    FCoverPointOctreeProxy* CoverPointOctree = new FCoverPointOctreeProxy(Center, Extent);

    uint32 NumCoverPoint = 0;
    Ar << NumCoverPoint;

    for (size_t i = 0; i < NumCoverPoint; i++)
    {
        UCoverPoint* CoverPoint = NewObject<UCoverPoint>();
        check(CoverPoint);
        CoverPoint->Serialize(Ar);
        CoverPointOctree->AddCoverPoint(CoverPoint);
        CoverPoints.Emplace(CoverPoint);
    }

    CoverPointOctree->ShrinkElements();


    UE_LOG(LogTemp, Log, TEXT("load cover at %f, %f with size %f, totol points %d"), Center.X, Center.Y, Extent.GetMax(), NumCoverPoint);

    AddCoverPointOctree(CoverPointOctree);
}

void UAICoverPointsManager::UnLoad()
{
    for (auto& CoverPointOctree : CoverPointOctrees)
    {
        delete CoverPointOctree;
    }
    CoverPointOctrees.Empty();
    CoverPoints.Empty();
}

void UAICoverPointsManager::BeginDestroy()
{
    UnLoad();
    Super::BeginDestroy();
}

TArray<UCoverPoint*> UAICoverPointsManager::GetCoverWithinBounds(const FBoxCenterAndExtent& BoundsIn)
{
    FVector Center = BoundsIn.Center;
    for (const auto& Octree : CoverPointOctrees)
    {
        if (Octree->IsPointInside(Center))
        {
            return Octree->GetCoverWithinBounds(BoundsIn);
        }
    }
    UE_LOG(LogTemp, Error, TEXT("%s: can not find octree in position, %f, %f!"), *GetNameSafe(this), Center.X, Center.Y);
    return  TArray<UCoverPoint*>();
}

void UAICoverPointsManager::AddCoverPointOctree(FCoverPointOctreeProxy* CoverPointOctree)
{
    check(CoverPointOctree);
    CoverPointOctrees.Emplace(CoverPointOctree);
}

void UAICoverPointsManager::OnPostLoadMap(UWorld* CurrentWorld)
{
    FString WorldName = CurrentWorld->GetName();

    Load(WorldName);
}

void UAICoverPointsManager::OnWorldCleanUp(UWorld* World, bool bSessionEnded, bool bCleanupResources)
{
    UnLoad();
}

void UAICoverPointsManager::PrintDebugInfo()
{
    uint32 MemorySize = CoverPoints.GetAllocatedSize();
    for (const auto& Octree : CoverPointOctrees)
    {
        MemorySize += Octree->GetAllocatedSize();
    }
    MemorySize += sizeof(UCoverPoint) * CoverPoints.Num();
    UE_LOG(LogTemp, Display, TEXT("====================================================================================================="));
    UE_LOG(LogTemp, Display, TEXT("MemorySize: %.2f kb, TotalCount: %d, Octree: %d"),
        MemorySize / 1024.0f, CoverPoints.Num(), CoverPointOctrees.Num());
    for (const auto& Octree : CoverPointOctrees)
    {
        Octree->DumpOctree();
    }
    UE_LOG(LogTemp, Display, TEXT("====================================================================================================="));
}

void UAICoverPointsManager::Update(float DeltaTime)
{
#if WITH_EDITOR
    const FVector CrouchHeight = FVector(0.f, 0.f, 50.f);
    const FVector StandingHeight = FVector(0.f, 0.f, 120.f);

    APlayerController* PlayerController = UGameplayStatics::GetPlayerController(GetWorld(), 0);
    if (!PlayerController)
    {
        return;
    }
    FVector CameraLocation = PlayerController->PlayerCameraManager->GetCameraLocation();

    for (const UCoverPoint* Cover : CoverPoints)
    {
        if (FVector::Distance(CameraLocation, Cover->Location) > 10000)
        {
            continue;
        }
        const FVector CoverDirection = 50 * Cover->DirectionToWall.GetSafeNormal();
        {
            FColor DrawColor = FColor::Blue;
            if (!Cover->IsCoverFree())
            {
                DrawColor = FColor::Red;
            }
            const FVector CrouchLocation = Cover->Location + CrouchHeight;
            DrawDebugSphere(GetWorld(), CrouchLocation, 30, 4, DrawColor);
            DrawDebugDirectionalArrow(GetWorld(), CrouchLocation, CrouchLocation + CoverDirection, 50, FColor::Red);
        }
        if (!Cover->bCanShotFromStanding)
        {
            const FVector StandingLocation = Cover->Location + StandingHeight;
            DrawDebugSphere(GetWorld(), StandingLocation, 30, 4, FColor::Orange);
            DrawDebugDirectionalArrow(GetWorld(), StandingLocation, StandingLocation + CoverDirection, 50, FColor::Red);
        }
    }
#endif
}
