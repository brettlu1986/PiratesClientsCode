#include "LandNavMeshDataManager.h"
#include "Common.h"
#include "NavMesh/RecastNavMesh.h"

DEFINE_LOG_CATEGORY_STATIC(LogLandNavMeshData, Log, All);

//FString ULandNavMeshDataManager::RootDirectory = FPaths::ProjectContentDir() + "GameDataGenerated/client/navigation/";
FString ULandNavMeshDataManager::FileName = "cache.data";

void ULandNavMeshDataManager::Init()
{
    CurrentMapName = "";
    bIsValid = false;

    FCoreUObjectDelegates::PreLoadMap.AddUObject(this, &ULandNavMeshDataManager::OnPreLoadMap);
    //FCoreUObjectDelegates::PostLoadMapWithWorld.AddUObject(this, &ULandNavMeshDataManager::OnPostLoadMapWithWorld);
}

void ULandNavMeshDataManager::Clear()
{
    //FCoreUObjectDelegates::PostLoadMapWithWorld.RemoveAll(this);
}

const FMapNavMeshCache* ULandNavMeshDataManager::GetNavMeshCache() const
{
    /*FString MapName = GetWorld()->GetMapName();
#ifdef UE_EDITOR
    MapName = UWorld::RemovePIEPrefix(MapName);
#endif*/

    if (bIsValid)
    {
        return &CurrentNavMeshCache;
    }

    return nullptr;
}

void ULandNavMeshDataManager::LoadNavMeshData(const FString& MapName)
{
    UE_LOG(LogLandNavMeshData, Log, TEXT("ULandNavMeshDataManager::LoadNavMeshData"));

    if (MapName == CurrentMapName)
    {
        bIsValid = true;
        return;
    }
    
    FString RootDirectory = FPaths::ProjectContentDir() + "GameDataGenerated/client/navigation/";
    FString DataFilePath = RootDirectory + MapName + "/" + FileName;
    
    if (!IFileManager::Get().FileExists(*DataFilePath))
    {
        UE_LOG(LogLandNavMeshData, Warning, TEXT("ULandNavMeshDataManager::LoadNavMeshData File is not exist."));
        bIsValid = false;
        return;
    }
    
    if (CurrentNavMeshCache.Init(DataFilePath))
    {
        CurrentMapName = MapName;
        bIsValid = true;
    }
    else
    {
        UE_LOG(LogLandNavMeshData, Warning, TEXT("ULandNavMeshDataManager::LoadNavMeshData Init Error."));
        CurrentMapName = "";
        bIsValid = false;
    }
}

void ULandNavMeshDataManager::OnPreLoadMap(const FString& InMapName)
{
   FString MapName = InMapName;
   int32 LastSlashIndex = MapName.Find("/", ESearchCase::CaseSensitive, ESearchDir::FromEnd);
   if (LastSlashIndex > -1)
   {
       MapName = InMapName.Right(InMapName.Len() - LastSlashIndex - 1);
   }

#ifdef UE_EDITOR
   MapName = UWorld::RemovePIEPrefix(MapName);
#endif

   //LoadNavMeshData(MapName);
}

