#include "AI/Vehicle/AIVehicleManager.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "Shell/CommonShell.h"
#include "Engine/World.h"
#include "Game/GameCommon.h"


const FString UAIVehicleManager::FileExtension = ".data";

bool AIVehiclePerIsland::SetVehicleLocation(FAIVehicle* Vehicle, const FVector& Location)
{
    int32 CellIndex = GetCellIndex(Location);
    if (CellIndex != INDEX_NONE && Vehicle)
    {
        Vehicle->Location = Location;
        FAIVehicleCell& Cell = GetCellAtIndexUnsafe(CellIndex);
        Cell.Add(Vehicle);
        return true;
    }
    return false;
}




/////////////////////////////////////////////////////////////////////////////

UAIVehicleManager::UAIVehicleManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer), VehicleClass(nullptr), bLoaded(false)
{

}



FAIVehicle* UAIVehicleManager::GetVehicle(int32 InstanceId)
{
    auto Vehicle = Vehicles.Find(InstanceId);
    if (Vehicle && (*Vehicle).IsValid())
    {
        return (*Vehicle).Get();
    }
    return nullptr;
}



bool UAIVehicleManager::SetVehicleLocation(int32 InstanceId, const FVector& Location)
{
    UPiratesGridTypeManager* GridTypeManager = UGameCommon::Get(this)->GetGridTypeManager();
    uint8 nLandId = GridTypeManager->GetLandID(Location.X, Location.Y);

    TSharedPtr<AIVehiclePerIsland>* Island = Islands.Find(nLandId);
    if (Island)
    {
        TSharedPtr<FAIVehicle>  Vehicle;
        TSharedPtr<FAIVehicle>* VehiclePtr = Vehicles.Find(InstanceId);
        if (!VehiclePtr)
        {
            Vehicle = MakeShared<FAIVehicle>(InstanceId, Location);
            Vehicles.Emplace(InstanceId, Vehicle);
        }
        else
        {
            Vehicle = (*VehiclePtr);
        }
        if (Vehicle.IsValid())
        {
            (*Island)->SetVehicleLocation(Vehicle.Get(), Location);
            UE_LOG(LogTemp, Log, TEXT("set vehicle location %d, %d, %s"), InstanceId, int32(nLandId), *Location.ToString());
            return true;
        }
    }
    return false;
}


bool UAIVehicleManager::RemoveVehicle(int32 InstanceId)
{
    FAIVehicle* Vehicle = GetVehicle(InstanceId);
    if (Vehicle)
    {
        UE_LOG(LogTemp, Log, TEXT("removed vehicle %d"), InstanceId);
        Vehicle->Unlink();
        Vehicles.Remove(InstanceId);
        return true;
    }
    return false;
}

FString GetConfigPath(const FString& WorldName)
{
    FString FilePath = FPaths::ProjectContentDir() + TEXT("GameDataGenerated/common/ai/vehicle/") + WorldName;
    FilePath = FPaths::SetExtension(FilePath, UAIVehicleManager::FileExtension);
    return FilePath;
}

bool UAIVehicleManager::Load(const FString& FilePath)
{
    Unload();
    FString FullFilePath = GetConfigPath(FilePath);
    UE_LOG(LogTemp, Log, TEXT("ai vehicle:load data in path: %s"), *FullFilePath);
    IFileManager& FileManager = IFileManager::Get();
    FArchive* FileReader = FileManager.CreateFileReader(*FullFilePath);
    if (FileReader)
    {
        uint16 Version = 0;
        uint8 NumIsland = 0;
        (*FileReader) << Version;
        (*FileReader) << NumIsland;
        UE_LOG(LogTemp, Log, TEXT("ai vehicle: version %d, num island %d"), int32(Version), int32(NumIsland));
        for (uint8 i = 0; i < NumIsland; i++)
        {
            uint32 nLandId = 0;
            (*FileReader) << nLandId;
            UE_LOG(LogTemp, Log, TEXT("ai vehicle: parse land %d"), int32(nLandId));
            TSharedPtr<AIVehiclePerIsland> Island = MakeShared<AIVehiclePerIsland>();
            uint32 CellSize = 0;
            FBox Bound;
            (*FileReader) << CellSize;
            (*FileReader) << Bound;
            Island->Init((float)CellSize, Bound);
            Islands.Emplace(nLandId, Island);
        }
        delete FileReader;
        bLoaded = true;
        InitVehicleClass();
        return true;
    }
    UE_LOG(LogTemp, Log, TEXT("ai vehicle:file bot found: %s"), *FilePath);
    return false;
}

void UAIVehicleManager::Unload()
{
    if (bLoaded)
    {
        UE_LOG(LogTemp, Log, TEXT("Vehicle Manager Unload"));
        for (auto& IslandPair : Islands)
        {
            TSharedPtr<AIVehiclePerIsland>& Island = IslandPair.Value;
            Island->CleanUp();
        }
        Islands.Empty();
        Vehicles.Empty();
        bLoaded = false;
    }
}

void UAIVehicleManager::FindVisibleVehicle(APawn* Pawn, int32 IslandId, float SightDist, float SightFOV, UWorld* World, TArray<int32>& OutInstanceIds)
{
    if (!Pawn || Pawn->IsPendingKill() || !World)
    {
        return;
    }
/*    double StartTime = FPlatformTime::Seconds();*/
    FVector Location = Pawn->GetActorLocation();
    if (IslandId <= 0)
    {
        UPiratesGridTypeManager* GridTypeManager = UGameCommon::Get(this)->GetGridTypeManager();
        IslandId = GridTypeManager->GetLandID(Location.X, Location.Y);
    }

    TSharedPtr<AIVehiclePerIsland>* IslandPtr = Islands.Find(IslandId);
    if (IslandPtr)
    {
        TSharedPtr<AIVehiclePerIsland>& Island = (*IslandPtr);
        FIntVector CellCoords = Island->GetCellCoordsUnsafe(Location);
        TArray<FIntVector> CellCoordsList;
        CellCoordsList.Emplace(CellCoords);
        CellCoordsList.Emplace(CellCoords + FIntVector( 1, -1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector( 1,  0, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector( 1,  1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector( 0, -1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector( 0,  1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(-1, -1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(-1,  0, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(-1,  1, 0));

        FCollisionQueryParams TraceParams;
        TraceParams.bFindInitialOverlaps = false;
        TraceParams.AddIgnoredActor(Pawn);

        float LimitDistanceSquared = SightDist * SightDist;

        FVector  EyePosition;
        FRotator EyeRotator;
        Pawn->GetActorEyesViewPoint(EyePosition, EyeRotator);
        const FVector OwnerFowardDir = EyeRotator.Vector().GetSafeNormal2D();
        const float LimitDot = FMath::Cos(SightFOV * 0.5f * PI / (180.f));

        for (const FIntVector& Coords : CellCoordsList)
        {
            int32 CellIndex = Island->GetCellIndex(Coords.X, Coords.Y);
            if (CellIndex != INDEX_NONE)
            {
                FAIVehicleCell& Cell = Island->GetCellAtIndexUnsafe(CellIndex);
        
                for (FAIVehicle::TConstIterator It(Cell.GetHead().GetNextLink()); It; It.Next())
                {
                    const FAIVehicle& Vehicle = (*It);

                    FVector TraceEnd = Vehicle.Location;
                    FVector TraceStart = EyePosition;

                    float SquaredDistance = FVector::DistSquaredXY(TraceStart, TraceEnd);
                    float Dot = FVector::DotProduct(OwnerFowardDir, (TraceEnd - TraceStart).GetSafeNormal2D());
                    if (SquaredDistance <= LimitDistanceSquared && Dot >= LimitDot)
                    {
                        FHitResult OutHit;

                        const bool bHit = World->LineTraceSingleByChannel(OutHit, TraceStart, TraceEnd, ECollisionChannel::ECC_WorldStatic, TraceParams);
                        if (bHit && OutHit.Actor.IsValid() && !OutHit.Actor->IsPendingKill()
                            && VehicleClass && OutHit.Actor->GetClass() && OutHit.Actor->GetClass()->IsChildOf(VehicleClass))
                        {
                            OutInstanceIds.Emplace(Vehicle.InstanceId);
                        }
                    }
                }
            }
        }

    }
//     double EndTime = FPlatformTime::Seconds();
//     float fTime = (float)(EndTime - StartTime)*1000.0f;
//     UE_LOG(LogTemp, Log, TEXT("time: %f ms"), fTime);
}


void UAIVehicleManager::InitVehicleClass(void)
{
    if (VehicleClass == NULL && VehicleClassName != TEXT(""))
    {
        VehicleClass = LoadClass<ACharacter>(NULL, *VehicleClassName, NULL, LOAD_None, NULL);
        if (VehicleClass == NULL)
        {
            UE_LOG(LogTemp, Error, TEXT("Failed to load vehicle class '%s'"), *VehicleClassName);
        }
        else
        {
            UE_LOG(LogTemp, Log, TEXT("Load vehicle class '%s'"), *VehicleClassName);
        }
    }
}


bool UAIVehicleManager::Init()
{
    OnPostLoadMapHandle = FCoreUObjectDelegates::PostLoadMapWithWorld.AddUObject(this, &UAIVehicleManager::OnPostLoadMap);
    OnWorldCleanUpHandle = FWorldDelegates::OnWorldCleanup.AddUObject(this, &UAIVehicleManager::OnWorldCleanUp);
    return true;
}

bool UAIVehicleManager::Uninit()
{
    FCoreUObjectDelegates::PostLoadMapWithWorld.Remove(OnPostLoadMapHandle);
    FWorldDelegates::OnWorldCleanup.Remove(OnWorldCleanUpHandle);
    Unload();
    return true;
}

void UAIVehicleManager::Dump()
{
    int32 CellCount = 0;
    int32 MemorySize = Islands.GetAllocatedSize();
    for (auto& ItemPair : Islands)
    {
        TSharedPtr<AIVehiclePerIsland>& Island = ItemPair.Value;
        MemorySize += Island->GetAllocatedSize();
        CellCount += Island->GetCellsCount();
    }

    MemorySize += Vehicles.Num() * sizeof(FAIVehicle);
    MemorySize += Vehicles.GetAllocatedSize();

    UE_LOG(LogTemp, Display, TEXT("AIVehicleManager: MemorySize: %.2f kb, CellCount: %d, Num Vehicle: %d"), MemorySize / 1024.0f, CellCount, Vehicles.Num());
}