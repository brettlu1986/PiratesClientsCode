#include "AI/DestructibleObject/AIDoorExporter.h"
#include "Battle/PiratesGridTypeManager.h"
#include "AI/DestructibleObject/AIDoorManager.h"

static const FString DestructibleObjectFileName = TEXT("Transforms.json");

enum class EAIDoorFileVerison : uint16
{
    VERSION_INIT = 1,
};

class AIDoorExporterImp
{
public:
    AIDoorExporterImp() :GridTypeManager(nullptr) { }

    bool Export(const FString& LevelName, const FString& SaveDir, bool bVerbose = false);
    bool ParseIsland(const TSharedPtr<FJsonObject>& JsonObject, bool bVerbose = false);
    void SetDoorId(const TArray<int32>& DoorIds) {
        ValidDoorIds = DoorIds;
    }
protected:

    struct FIsland
    {
        TArray<FAIDoor>  Doors;
        FBox Bounds;
    };


    typedef TMap<int32, FIsland> IslandMap;

    IslandMap Islands;
    TArray<int32> ValidDoorIds;
    UPiratesGridTypeManager* GridTypeManager;
};

struct FAIDoorVisitor : public IPlatformFile::FDirectoryVisitor
{
    AIDoorExporterImp*  DoorExpoter;
    bool bVerbose;

    FAIDoorVisitor(AIDoorExporterImp* InDoorExpoter, bool bInVerbose = false) :DoorExpoter(InDoorExpoter),
        bVerbose(bInVerbose)
    {

    }

    virtual bool Visit(const TCHAR* FilenameOrDirectory, bool bIsDirectory)
    {
        if (!bIsDirectory && FPaths::GetCleanFilename(FilenameOrDirectory) == DestructibleObjectFileName)
        {
            if (bVerbose)
            {
                UE_LOG(LogTemp, Log, TEXT("start export file: %s"), FilenameOrDirectory);
            }
            FString FileContents;
            if (!FFileHelper::LoadFileToString(FileContents, FilenameOrDirectory))
            {
                return true;
            }
            TSharedPtr<FJsonObject> Object;
            TSharedRef<TJsonReader<> > Reader = TJsonReaderFactory<>::Create(FileContents);
            if (!FJsonSerializer::Deserialize(Reader, Object) || !Object.IsValid())
            {
                return true;
            }
            DoorExpoter->ParseIsland(Object, bVerbose);
        }
        return true;
    }
};


bool AIDoorExporterImp::Export(const FString& LevelName, const FString& SaveDir, bool bVerbose /* = false */)
{
    Islands.Empty();
    check(!GridTypeManager);
    GridTypeManager = NewObject<UPiratesGridTypeManager>();
    GridTypeManager->Init();
    GridTypeManager->Load(LevelName);
    FString DirPath = FPaths::ProjectContentDir() + TEXT("GameData/common/scene/descriptors/") + LevelName;
    UE_LOG(LogTemp, Log, TEXT("start export map: %s"), *DirPath);
    FAIDoorVisitor Visitor(this, bVerbose);
    IFileManager& FileManager = IFileManager::Get();
    IFileManager::Get().IterateDirectoryRecursively(*DirPath, Visitor);

    FString SavePath = FPaths::ProjectContentDir() + SaveDir + LevelName;
    SavePath = FPaths::SetExtension(SavePath, AIDoorManager::FileExtension);

    FileManager.MakeDirectory(*FPaths::GetPath(*SavePath));
    UE_LOG(LogTemp, Log, TEXT("dump file to: %s"), *SavePath);
    FArchive* FileWriter = FileManager.CreateFileWriter(*SavePath);
    if (FileWriter)
    {
        uint16 Version = static_cast<uint16>(EAIDoorFileVerison::VERSION_INIT);
        uint8 NumIsland = Islands.Num();
        (*FileWriter) << Version;
        (*FileWriter) << NumIsland;
        UE_LOG(LogTemp, Log, TEXT("version: %d"), int32(Version));
        UE_LOG(LogTemp, Log, TEXT("island num: %d"), int32(NumIsland));
        for (auto Iter = Islands.CreateIterator(); Iter; ++Iter)
        {
            UE_LOG(LogTemp, Log, TEXT("--------------------"));
            uint32 nLandId = Iter.Key();
            (*FileWriter) << nLandId;
            UE_LOG(LogTemp, Log, TEXT("island id: %d"), int32(nLandId));
            FIsland& IsLand = Iter.Value();
            FBox Bounds = IsLand.Bounds.ExpandBy(5000);
            FVector Extent = Bounds.GetExtent();
            FVector Center = Bounds.GetCenter();
            (*FileWriter) << Center;
            (*FileWriter) << Extent;
            UE_LOG(LogTemp, Log, TEXT("island bounds: %s"), *Bounds.ToString());
            uint32 NumElement = IsLand.Doors.Num();
            (*FileWriter) << NumElement;
            UE_LOG(LogTemp, Log, TEXT("island doors: %d"), int32(NumElement));
            for (auto& Door : IsLand.Doors)
            {
                Door.Serialize((*FileWriter));
            }
        }
        UE_LOG(LogTemp, Log, TEXT("total file size: %.2f K"), (FileWriter->TotalSize()) / 1024.0f );
        FileWriter->Close();
        delete FileWriter;
        GridTypeManager->Uninit();
        GridTypeManager = nullptr;
        return true;
    }
    GridTypeManager->Uninit();
    GridTypeManager = nullptr;
    return false;
}


bool AIDoorExporterImp::ParseIsland(const TSharedPtr<FJsonObject>& JsonObject, bool bVerbose /* = false */)
{
    if (JsonObject.IsValid() && JsonObject->HasField("DestructibleObjects"))
    {
        auto& JsonDestructibleObjectArray = JsonObject->GetArrayField("DestructibleObjects");
        for (const auto& Item : JsonDestructibleObjectArray)
        {
            const TSharedPtr<FJsonObject>& JsonDestructibleObject = Item->AsObject();
            const TSharedPtr<FJsonObject>& JsonTransfom = JsonDestructibleObject->GetObjectField("Transform");
            const TSharedPtr<FJsonObject>& JsonScale = JsonDestructibleObject->GetObjectField("Scale");
            FVector Location, Scale;
            Location.X = JsonTransfom->GetNumberField("X");
            Location.Y = JsonTransfom->GetNumberField("Y");
            Location.Z = JsonTransfom->GetNumberField("Z");
            Scale.X = JsonScale->GetNumberField("X");
            Scale.Y = JsonScale->GetNumberField("Y");
            Scale.Z = JsonScale->GetNumberField("Z");
            int32 TransformId = JsonDestructibleObject->GetNumberField("TransformId");
            int32 TemplateId = JsonDestructibleObject->GetNumberField("Id");
            if (ValidDoorIds.Find(TemplateId) != INDEX_NONE)
            {
                uint8 nLandId = GridTypeManager->GetLandID(Location.X, Location.Y);
                if (nLandId > 0)
                {
                    FIsland& IsLand = Islands.FindOrAdd(nLandId);
                    IsLand.Doors.Emplace(FAIDoor(TransformId, Location, Scale));
                    IsLand.Bounds += Location;
                    if (bVerbose)
                    {
                        UE_LOG(LogTemp, Log, TEXT("add destructible object in island %d [%s] [%s] %d"), (int32)nLandId, *Location.ToString(), *Scale.ToString(), TransformId);
                    }
                }
                else
                {
                    UE_LOG(LogTemp, Error, TEXT("destructible object not in island %d [%s] [%s] %d"), (int32)nLandId, *Location.ToString(), *Scale.ToString(), TransformId);
                }
            }
        }
    }
    else if (bVerbose)
    {
        UE_LOG(LogTemp, Log, TEXT("do not found key [DestructibleObjects]"));
    }
    return true;
}

UAIDoorExporter::UAIDoorExporter(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}


bool UAIDoorExporter::Export(const FString& LevelName, const TArray<int32>& DoorIds, const FString& SaveDir, bool bVerbose /* = false */)
{
#if WITH_EDITOR
    AIDoorExporterImp Exporter;
    Exporter.SetDoorId(DoorIds);
    Exporter.Export(LevelName, SaveDir, bVerbose);
#endif
    return true;
}