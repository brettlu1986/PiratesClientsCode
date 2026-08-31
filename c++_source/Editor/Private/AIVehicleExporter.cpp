#include "AIVehicleExporter.h"
#include "Battle/PiratesGridTypeManager.h"

static const FString VehicleFileName = TEXT("Transforms.json");

enum class EAIVehicleFileVerison : uint16
{
    VERSION_INIT = 1,
};

class AIVehicleExporterImp
{
public:
    AIVehicleExporterImp() :CellSize(0), GridTypeManager(nullptr) { }

    bool Export(const FString& LevelName, const FString& SaveDir, bool bVerbose = false);
    bool Parse(const TSharedPtr<FJsonObject>& JsonObject, bool bVerbose = false);

    void SetCellSize(int32 InCellSize)
    {
        check(InCellSize > 0);
        CellSize = (uint32)InCellSize;
    }
protected:

    struct FIsland
    {
        FBox Bounds;
    };

    typedef TMap<int32, FIsland> IslandMap;

    uint32 CellSize;
    IslandMap Islands;
    UPiratesGridTypeManager* GridTypeManager;
};

struct FAIVehicleVisitor : public IPlatformFile::FDirectoryVisitor
{
    AIVehicleExporterImp*  VehicleExpoter;
    bool bVerbose;

    FAIVehicleVisitor(AIVehicleExporterImp* InVehicleExpoter, bool bInVerbose = false) :VehicleExpoter(InVehicleExpoter),
        bVerbose(bInVerbose)
    {

    }

    virtual bool Visit(const TCHAR* FilenameOrDirectory, bool bIsDirectory)
    {
        if (!bIsDirectory && FPaths::GetCleanFilename(FilenameOrDirectory) == VehicleFileName)
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
            VehicleExpoter->Parse(Object, bVerbose);
        }
        return true;
    }
};


bool AIVehicleExporterImp::Export(const FString& LevelName, const FString& SaveDir, bool bVerbose /* = false */)
{
    Islands.Empty();
    check(!GridTypeManager);
    GridTypeManager = NewObject<UPiratesGridTypeManager>();
    GridTypeManager->Init();
    GridTypeManager->Load(LevelName);
    FString DirPath = FPaths::ProjectContentDir() + TEXT("GameData/common/scene/descriptors/") + LevelName;
    UE_LOG(LogTemp, Log, TEXT("start export map: %s"), *DirPath);
    FAIVehicleVisitor Visitor(this, bVerbose);
    IFileManager& FileManager = IFileManager::Get();
    IFileManager::Get().IterateDirectoryRecursively(*DirPath, Visitor);

    FString SavePath = FPaths::ProjectContentDir() + SaveDir + LevelName;
    SavePath = FPaths::SetExtension(SavePath, UAIVehicleManager::FileExtension);

    FileManager.MakeDirectory(*FPaths::GetPath(*SavePath));
    UE_LOG(LogTemp, Log, TEXT("dump file to: %s"), *SavePath);
    FArchive* FileWriter = FileManager.CreateFileWriter(*SavePath);
    if (FileWriter)
    {
        uint16 Version = static_cast<uint16>(EAIVehicleFileVerison::VERSION_INIT);
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
            (*FileWriter) << CellSize;
            FIsland& IsLand = Iter.Value();
            FBox Bounds = IsLand.Bounds.ExpandBy(5000);
            check(Bounds.IsValid > 0);
            (*FileWriter) << Bounds;
            UE_LOG(LogTemp, Log, TEXT("island id: %d, cell size: %d, bounds: %s"), int32(nLandId), int32(CellSize), *Bounds.ToString());

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

struct FTransformInfo
{
    FVector Location;
    int32 Id;

    FTransformInfo(int32 InId = 0, const FVector& InLocation = FVector::ZeroVector) :
        Location(InLocation), Id(InId)
    {

    }
};

bool AIVehicleExporterImp::Parse(const TSharedPtr<FJsonObject>& JsonObject, bool bVerbose /* = false */)
{
    if (JsonObject.IsValid() && JsonObject->HasField("Vehicles"))
    {
        TMap<int32, FTransformInfo> VehiclesMap;
        auto& JsonTransforms = JsonObject->GetArrayField("Transforms");
        for (const auto& TransformsItem : JsonTransforms)
        {
            const TSharedPtr<FJsonObject>& JsonTransformsObject = TransformsItem->AsObject();
            const TSharedPtr<FJsonObject>& JsonLocation = JsonTransformsObject->GetObjectField("Transform");
            FTransformInfo TransformInfo;
            TransformInfo.Location.X = JsonLocation->GetNumberField("X");
            TransformInfo.Location.Y = JsonLocation->GetNumberField("Y");
            TransformInfo.Location.Z = JsonLocation->GetNumberField("Z");
            TransformInfo.Id = JsonTransformsObject->GetNumberField("TransformId");

            VehiclesMap.Emplace(TransformInfo.Id, TransformInfo);
        }

        auto& JsonVehicles = JsonObject->GetArrayField("Vehicles");
        for (const auto& VehicleItem : JsonVehicles)
        {
            const TSharedPtr<FJsonObject>& JsonVehicleObject = VehicleItem->AsObject();
            auto& JsonVehicleGroups = JsonVehicleObject->GetArrayField("Group");
            for (const auto& GroupItem : JsonVehicleGroups)
            {
                int32 Id = GroupItem->AsNumber();
                FTransformInfo* Info = VehiclesMap.Find(Id);
                if (Info)
                {
                    uint8 nLandId = GridTypeManager->GetLandID(Info->Location.X, Info->Location.Y);
                    if (nLandId > 0)
                    {
                        FIsland& IsLand = Islands.FindOrAdd(nLandId);
                        IsLand.Bounds += Info->Location;
                        if (bVerbose)
                        {
                            UE_LOG(LogTemp, Log, TEXT("add vehicle object in island %d [%s] %d"), (int32)nLandId, *Info->Location.ToString(), Info->Id);
                        }
                    }
                    else
                    {
                        UE_LOG(LogTemp, Error, TEXT("vehicle object not in island %d [%s] %d"), (int32)nLandId, *Info->Location.ToString(), Info->Id);
                    }
                }
            }
        }
    }
    else if (bVerbose)
    {
        UE_LOG(LogTemp, Log, TEXT("do not found key [vehicleObjects]"));
    }
    return true;
}

UAIVehicleExporter::UAIVehicleExporter(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}


bool UAIVehicleExporter::Export(const FString& LevelName, int32 CellSize, const FString& SaveDir, bool bVerbose /* = false */)
{
    AIVehicleExporterImp Exporter;
    Exporter.SetCellSize(CellSize);
    Exporter.Export(LevelName, SaveDir, bVerbose);
    return true;
}