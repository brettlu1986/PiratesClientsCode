#include "AI/DestructibleObject/AIDoorManager.h"
#include "Shell/CommonShell.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "HAL/FileManager.h"
#include "AI/DestructibleObject/AIDoorExporter.h"

const FString AIDoorManager::FileExtension = ".data";

FString AIDoorManager::GetConfigPath(const FString& WorldName) const
{
    FString FilePath = FPaths::ProjectContentDir() + TEXT("GameDataGenerated/common/ai/door/") + WorldName;
    FilePath = FPaths::SetExtension(FilePath, FileExtension);
    return FilePath;
}

void AIDoorManager::OnElementAdded(TSharedPtr<FAIDoor>& Door)
{
    if (Door && Door.IsValid())
    {
        int32 TranaformId = Door->TransformId;
        MapOfTransformIdToDoor.Emplace(TranaformId, Door);
        UE_LOG(LogTemp, Log, TEXT("on element added %d"), TranaformId);
    }
}

void AIDoorManager::OnRegionAdded(TSharedPtr<FAIDoorOctreeSpacePartition>& SPC)
{
    if (SPC)
    {
        SPC->ShrinkElements();
    }
}

void AIDoorManager::SetInstanceId(int32 TransformId, int32 InstanceId)
{
    auto Door = MapOfTransformIdToDoor.Find(TransformId);
    if (Door && (*Door).IsValid())
    {
        //check((*Door)->InstanceId <= 0);
        (*Door)->InstanceId = InstanceId;
        UE_LOG(LogTemp, Log, TEXT("set element %d instanceid %d"), TransformId, InstanceId);
    }
    else
    {
        UE_LOG(LogTemp, Log, TEXT("element %d not found"), TransformId);
    }
}


bool AIDoorManager::UnLoad()
{
    if (bLoaded)
    {
        UE_LOG(LogTemp, Log, TEXT("unload door manager"));
    }
    bool bUnLoaded = AIDoorManagerBase::UnLoad();
    MapOfTransformIdToDoor.Empty();
    return bUnLoaded;
}

