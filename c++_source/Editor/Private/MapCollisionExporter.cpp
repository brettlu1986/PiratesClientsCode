// Fill out your copyright notice in the Description page of Project Settings.

#include "MapCollisionExporter.h"
#include "PiratesEditor.h"
#include "FileHelpers.h"

#include "Engine/LevelStreaming.h"
#include "Engine/LevelBounds.h"
#include "Misc/ConfigCacheIni.h"

#include "Game/GameEngineExt.h"
#include "LevelEditorActions.h"
#include "Engine/WorldComposition.h"
#include "EditorLevelUtils.h"
#include "Exporters/Exporter.h"
#include "Exporters/FbxExportOption.h"
#include "Editor/UnrealEd/Private/FbxExporter.h"
#include "LandscapeProxy.h"
#include "Foliage/Public/InstancedFoliageActor.h"


static const FString FbxExtension = TEXT(".fbx");
static const FString DoorFileName = TEXT("Transforms.json");
static const FString WCConfigFile = TEXT("Blueprint'/Game/Maps/WCData/WCData_FFA_Arts.WCData_FFA_Arts_C'");

enum class EDoorState : uint8
{
    DOOR_STATE_CLOSED = 0,
    DOOR_STATE_OPEN1,
    DOOR_STATE_OPEN2,
    MAX,
};

struct DoorContext
{
    TMap<int32, FString>  DoorActorMeshMap;
    FString DoorClassPath;
    void AddDoorRes(int32 ID, const FString& DoorMeshPath)
    {
        DoorActorMeshMap.Emplace(ID, DoorMeshPath);
    }
    const FString* FindDoorMeshPath(int32 ID) const
    {
        return DoorActorMeshMap.Find(ID);
    }
};

struct SubLevelContext
{
    FString SubLevelName;
    int32 ExportLOD;
    FString DoorConfigPath;
};

struct ExportContext
{
    TArray<SubLevelContext> SubLevelContexts;
    FString SavePath;
    DoorContext Door;
    bool bLandscapeOnly;
};

bool ParseConfigFile(const FString& ConfigFilePath, ExportContext& Context)
{
    FString FileContents;
    if (!FFileHelper::LoadFileToString(FileContents, *ConfigFilePath))
    {
        return false;
    }

    TSharedPtr<FJsonObject> JsonObject;
    TSharedRef<TJsonReader<> > Reader = TJsonReaderFactory<>::Create(FileContents);
    if (!FJsonSerializer::Deserialize(Reader, JsonObject) || !JsonObject.IsValid())
    {
        return false;
    }
    Context.bLandscapeOnly = false;
    JsonObject->TryGetBoolField("LandscapeOnly", Context.bLandscapeOnly);
    if (JsonObject->HasField("Door"))
    {
        Context.Door.DoorClassPath = JsonObject->GetStringField("DoorClass");
        auto& JsonDoorContextArray = JsonObject->GetArrayField("Door");
        for (const auto& Item : JsonDoorContextArray)
        {
            const TSharedPtr<FJsonObject>& JsonDoorContextObject = Item->AsObject();
            int32 Id = JsonDoorContextObject->GetNumberField("Id");
            FString DoorMeshPath = JsonDoorContextObject->GetStringField("Res");
            Context.Door.AddDoorRes(Id, DoorMeshPath);
        }
    }
    if (JsonObject->HasField("SubLevel"))
    {
        auto& JsonSubLevelArray = JsonObject->GetArrayField("SubLevel");
        for (const auto& Item : JsonSubLevelArray)
        {
            SubLevelContext ContextOfSubLevel;
            const TSharedPtr<FJsonObject>& JsonSubLevelObject = Item->AsObject();
            ContextOfSubLevel.DoorConfigPath = JsonSubLevelObject->GetStringField("DoorPath");
            ContextOfSubLevel.ExportLOD = JsonSubLevelObject->GetNumberField("ExportLOD");
            ContextOfSubLevel.SubLevelName = JsonSubLevelObject->GetStringField("Name");
            Context.SubLevelContexts.Emplace(ContextOfSubLevel);
        }
    }
    return true;
}



UMapCollisionExporter::UMapCollisionExporter(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

void OnWorldCompositionCollecting(const FString& PersistentName, TArray<FString>& WorldRoots)
{

    const UWorldCompositionConfig* DefaultWCConfig = GetDefault<UWorldCompositionConfig>();

    UClass* WCDataClass = StaticLoadClass(UWorldCompositionData::StaticClass(), nullptr, *WCConfigFile, nullptr, LOAD_None);

    if (!WCDataClass)
    {
        UE_LOG(LogTemp, Error, TEXT("Can not find World Composition Config !!!"));
        return;
    }

    UWorldCompositionData* TempWCData = WCDataClass->GetDefaultObject<UWorldCompositionData>();
    for (auto WCIt = TempWCData->WorldCompositions.CreateConstIterator(); WCIt; ++WCIt)
    {
        const FWorldCompositionPair& Persistentdata = *WCIt;
        if (Persistentdata.PersistentName.Equals(PersistentName))
        {
            for (auto SubLevelIt = Persistentdata.Roots.CreateConstIterator(); SubLevelIt; ++SubLevelIt)
            {
                const FWorldCompositionSubLevel& SublevelItemData = *SubLevelIt;

                //don't add server only path
                if (SublevelItemData.IsServerOnly)
                {
                    continue;
                }

                //if is used , add path to roots
                if (SublevelItemData.IsUsed)
                {
                    WorldRoots.AddUnique(FPaths::ProjectContentDir() + SublevelItemData.DirectoryPath);
                }
            }

            break;
        }
    }
}

void ExportLevel(ULevel* InLevel, INodeNameAdapter& NodeNameAdapter, bool bOnlyLandScape)
{
	UnFbx::FFbxExporter* Exporter = UnFbx::FFbxExporter::GetInstance();
	TArray<AActor*> ActorToExport;
	int32 ActorCount = InLevel->Actors.Num();
	for (int32 ActorIndex = 0; ActorIndex < ActorCount; ++ActorIndex)
	{
		AActor* Actor = InLevel->Actors[ActorIndex];
		if (Actor != NULL)
        {
            if (!bOnlyLandScape || Actor->IsA(ALandscapeProxy::StaticClass()))
            {
                ActorToExport.Add(Actor);
            }
		}
	}
    Exporter->ExportLevelMesh(InLevel, true, ActorToExport, NodeNameAdapter);
}

void ExportFBX(UWorld* World, const FString& FilePath, int32 LandScapeLODLevel, bool bOnlyLandScape)
{
    UnFbx::FFbxExporter* Exporter = UnFbx::FFbxExporter::GetInstance();

    UFbxExportOption* AutomatedExportOptions = NewObject<UFbxExportOption>();

    AutomatedExportOptions->LoadOptions();

    AutomatedExportOptions->bASCII = false;
    AutomatedExportOptions->FbxExportCompatibility = EFbxExportCompatibility::FBX_2013;
    AutomatedExportOptions->bForceFrontXAxis = false;
    AutomatedExportOptions->VertexColor = false;
    AutomatedExportOptions->LevelOfDetail = false;
    AutomatedExportOptions->Collision = true;
    AutomatedExportOptions->MapSkeletalMotionToRoot = false;
    AutomatedExportOptions->bCollisionOnly = true;

    Exporter->SetExportOptionsOverride(AutomatedExportOptions);
    {
        Exporter->CreateDocument();
        int32 OldExportLOD = 0;
        for (TActorIterator<ALandscapeProxy> It(World); It; ++It)
        {
            ALandscapeProxy* Landscape = *It;
            if (Landscape)
            {
                OldExportLOD = Landscape->ExportLOD;
                Landscape->ExportLOD = LandScapeLODLevel;
                UE_LOG(LogTemp, Log, TEXT("landscape old export lod %d"), OldExportLOD);
            }
        }

        {
            ULevel* Level = World->PersistentLevel;

            INodeNameAdapter NodeNameAdapter;

			ExportLevel(Level, NodeNameAdapter, bOnlyLandScape);

			// Export streaming levels and actors
			for (int32 CurLevelIndex = 0; CurLevelIndex < World->GetNumLevels(); ++CurLevelIndex)
			{
				ULevel* CurLevel = World->GetLevel(CurLevelIndex);
				if (CurLevel != NULL && CurLevel != Level)
				{
					ExportLevel(CurLevel, NodeNameAdapter, bOnlyLandScape);
				}
			}
            
        }
        Exporter->WriteToFile(*FilePath);

        for (TActorIterator<ALandscapeProxy> It(World, ALandscapeProxy::StaticClass()); It; ++It)
        {
            ALandscapeProxy* Landscape = *It;
            if (Landscape)
            {
                Landscape->ExportLOD = OldExportLOD;
            }
        }
    }

    Exporter->SetExportOptionsOverride(nullptr);
}


void SetDoorState(AActor* Door, int32 nState)
{
    if (nState > 0)
    {
        UFunction* Function = Door->FindFunction(TEXT("SetStateInEditor"));
        if (Function)
        {
            FProperty* Link = Function->PropertyLink;
            FIntProperty* DoorStateProperty = CastField<FIntProperty>(Link);
            if (DoorStateProperty)
            {
                uint8* Parms = (uint8*)FMemory_Alloca(Function->ParmsSize);
                FMemory::Memzero(Parms, Function->ParmsSize);

                DoorStateProperty->SetPropertyValue_InContainer(Parms, nState);
                Door->ProcessEvent(Function, Parms);
                DoorStateProperty->DestroyValue_InContainer(Parms);
            }
        }
    }

}


void SetDoorMesh(AActor* Door, const FString& MeshPath)
{
    if (!MeshPath.IsEmpty())
    {
        UFunction* Function = Door->FindFunction(TEXT("SetMeshInEditor"));
        if (Function)
        {
            FProperty* Link = Function->PropertyLink;
            FStrProperty* MeshProperty = CastField<FStrProperty>(Link);
            if (MeshProperty)
            {
                uint8* Parms = (uint8*)FMemory_Alloca(Function->ParmsSize);
                FMemory::Memzero(Parms, Function->ParmsSize);

                MeshProperty->SetPropertyValue_InContainer(Parms, MeshPath);
                Door->ProcessEvent(Function, Parms);
                MeshProperty->DestroyValue_InContainer(Parms);
            }
        }
    }

}


void CreateDoors(UWorld* World, const FString &DoorFilePath,  const DoorContext& Context, TArray<AActor*>& Doors)
{
    FString DoorFile = DoorFilePath + "/" + DoorFileName;
    FString FileContents;
    if (!FFileHelper::LoadFileToString(FileContents, *DoorFile))
    {
        return;
    }
    TSharedPtr<FJsonObject> JsonObject;
    TSharedRef<TJsonReader<> > Reader = TJsonReaderFactory<>::Create(FileContents);
    if (!FJsonSerializer::Deserialize(Reader, JsonObject) || !JsonObject.IsValid())
    {
        return;
    }
    if (JsonObject->HasField("DestructibleObjects"))
    {
        auto& JsonDestructibleObjectArray = JsonObject->GetArrayField("DestructibleObjects");
        for (const auto& Item : JsonDestructibleObjectArray)
        {
            const TSharedPtr<FJsonObject>& JsonDestructibleObject = Item->AsObject();
            int32 TemplateId = JsonDestructibleObject->GetNumberField("Id");
            const TSharedPtr<FJsonObject>& JsonTransfom = JsonDestructibleObject->GetObjectField("Transform");
            const TSharedPtr<FJsonObject>& JsonScale = JsonDestructibleObject->GetObjectField("Scale");
            FVector Location, Scale;
            FRotator Rotation = FRotator::ZeroRotator;
            Location.X = JsonTransfom->GetNumberField("X");
            Location.Y = JsonTransfom->GetNumberField("Y");
            Location.Z = JsonTransfom->GetNumberField("Z");
            Rotation.Yaw = JsonTransfom->GetNumberField("Yaw");

            Scale.X = JsonScale->GetNumberField("X");
            Scale.Y = JsonScale->GetNumberField("Y");
            Scale.Z = JsonScale->GetNumberField("Z");

            const FString* DoorMeshPath = Context.FindDoorMeshPath(TemplateId);
            if (DoorMeshPath)
            {
                UClass* DoorClass  = Cast<UClass>(StaticLoadObject(UObject::StaticClass(), nullptr, *Context.DoorClassPath));
                if (DoorClass)
                {
                    FActorSpawnParameters SpawnParam;
                    SpawnParam.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
                    int32 StartStart = int32(EDoorState::DOOR_STATE_OPEN1);
                    int32 EndStart = int32(EDoorState::DOOR_STATE_OPEN2);
                    for (int32 DoorState = StartStart; DoorState <= EndStart; DoorState++)
                    {
                        AActor* Door = World->SpawnActor(DoorClass, &Location, &Rotation, SpawnParam);
                        if (Door)
                        {
                            SetDoorMesh(Door, *DoorMeshPath);
                            Door->SetActorScale3D(Scale);
                            Doors.Emplace(Door);
                            UE_LOG(LogTemp, Log, TEXT("add door at %s %d"), *Location.ToString(), DoorState);
                            SetDoorState(Door, DoorState);
                        }
                        else
                        {
                            UE_LOG(LogTemp, Error, TEXT("spawn door fail at %s."), *Location.ToString());
                        }
                    }
                }
                else
                {
                    UE_LOG(LogTemp, Error, TEXT("load door class [%s] fail."), *Context.DoorClassPath);
                }
            }
        }
    }

}

bool ExportSubLevel(UWorld* World, SubLevelContext& ContextOfSubLevel, ExportContext&  ContextOfExport)
{
    FString SubLevelName = ContextOfSubLevel.SubLevelName;
    int32 ExportLOD = ContextOfSubLevel.ExportLOD;

    TArray<FWorldCompositionTile>& Tiles = World->WorldComposition->GetTilesList();

    bool bHasStreamLevel = false;
    //load all _L_ level streamings
    for (int32 TIndex = 0; TIndex < Tiles.Num(); TIndex++)
    {
        FString TempPackageName = Tiles[TIndex].PackageName.ToString();
        if (!TempPackageName.Contains(SubLevelName))
        {
            continue;
        }

        //search level streaming
        ULevelStreaming* LevelStreaming = nullptr;
        TWeakObjectPtr<ULevel> LoadedLevel = nullptr;
        for (int32 LevelIndex = 0; LevelIndex < World->WorldComposition->TilesStreaming.Num(); ++LevelIndex)
        {
            if (Tiles[TIndex].PackageName == World->WorldComposition->TilesStreaming[LevelIndex]->GetWorldAssetPackageFName())
            {
                LevelStreaming = World->WorldComposition->TilesStreaming[LevelIndex];
                break;
            }
        }
        if (!LevelStreaming)
        {
            UE_LOG(LogTemp, Warning, TEXT("tile %d : %s not found in worldcomposition"), TIndex, *Tiles[TIndex].PackageName.ToString());
            continue;
        }

        bHasStreamLevel = true;
        World->AddStreamingLevel(LevelStreaming);

        check(LevelStreaming && LevelStreaming->GetLoadedLevel() == nullptr);

        // Load level package
        {
            FName LevelPackageName = LevelStreaming->GetWorldAssetPackageFName();
            UE_LOG(LogTemp, Log, TEXT("load stream level %s"), *LevelPackageName.ToString());

            ULevel::StreamedLevelsOwningWorld.Add(LevelPackageName, World);
            UWorld::WorldTypePreLoadMap.FindOrAdd(LevelPackageName) = World->WorldType;

            UPackage* LevelPackage = LoadPackage(nullptr, *LevelPackageName.ToString(), LOAD_None);

            ULevel::StreamedLevelsOwningWorld.Remove(LevelPackageName);
            UWorld::WorldTypePreLoadMap.Remove(LevelPackageName);

            // Find world object and use its PersistentLevel pointer.
            UWorld* LevelWorld = UWorld::FindWorldInPackage(LevelPackage);
            // Check for a redirector. Follow it, if found.
            if (LevelWorld == nullptr)
            {
                LevelWorld = UWorld::FollowWorldRedirectorInPackage(LevelPackage);
            }

            if (LevelWorld && LevelWorld->PersistentLevel)
            {
                // LevelStreaming is transient object so world composition stores color in ULevel object
                LevelStreaming->LevelColor = LevelWorld->PersistentLevel->LevelColor;
            }
        }



        // Our level package should be loaded at this point, so level streaming will find it in memory
        LevelStreaming->SetShouldBeLoaded(true);
        LevelStreaming->SetShouldBeVisible(false); // Should be always false in the Editor
        LevelStreaming->SetShouldBeVisibleInEditor(false);
        World->FlushLevelStreaming();

        LoadedLevel = LevelStreaming->GetLoadedLevel();

        // Bring level to world
        if (LoadedLevel.IsValid())
        {
            EditorLevelUtils::SetLevelVisibility(LoadedLevel.Get(), true, true);
        }
        // ~
    }

    if (!bHasStreamLevel)
    {
        UE_LOG(LogTemp, Error, TEXT("%s do not found any stream level"), *SubLevelName);
        return false;
    }

    FString SavePath = ContextOfExport.SavePath + SubLevelName + "_LOD" + FString::FromInt(ExportLOD);
    TArray<AActor*> Doors;
    if (!ContextOfSubLevel.DoorConfigPath.IsEmpty())
    {
        FString DoorFilePath = FPaths::ProjectContentDir() + ContextOfSubLevel.DoorConfigPath;
        CreateDoors(World, DoorFilePath, ContextOfExport.Door, Doors);
        UE_LOG(LogTemp, Log, TEXT("add %d doors in sub level %s"), Doors.Num(), *SubLevelName);
    }


    IFileManager& FileManager = IFileManager::Get();
    SavePath = FPaths::SetExtension(SavePath, FbxExtension);

    FileManager.MakeDirectory(*FPaths::GetPath(*SavePath));
    FileManager.Delete(*SavePath);

    ExportFBX(World, SavePath, ExportLOD, ContextOfExport.bLandscapeOnly);

    for (auto Door : Doors)
    {
        World->DestroyActor(Door);
    }
    Doors.Empty();

    //unload all level streamings
    {
        do
        {
            const TArray<ULevelStreaming*>& LevelStreamings = World->GetStreamingLevels();
            if (LevelStreamings.Num() > 0)
            {
                ULevelStreaming* SubLevelStreaming = LevelStreamings[0];
                ULevel* LoadedLevel = SubLevelStreaming->GetLoadedLevel();
                SubLevelStreaming->SetShouldBeLoaded(false);
                SubLevelStreaming->SetShouldBeVisible(false);
                SubLevelStreaming->bShouldBlockOnUnload = false;
                SubLevelStreaming->SetIsRequestingUnloadAndRemoval(true);
                //SubLevelStreaming->bShouldBlockOnUnload = true;
                World->FlushLevelStreaming();
                World->RemoveStreamingLevel(SubLevelStreaming);
                if (LoadedLevel)
                {
                    EditorLevelUtils::SetLevelVisibility(LoadedLevel, false, true);
                    World->RemoveLevel(LoadedLevel);
                }
            }

        } while (World->GetStreamingLevels().Num() > 0);
    }
    return true;
}


bool UMapCollisionExporter::ExportMapCollision(const FString& LevelName, const FString& ConfigFilePath, const FString& SaveDir)
{
    UE_LOG(LogTemp, Log, TEXT("export collision map : %s"), *LevelName);
    //world composition for editor
    FCoreUObjectDelegates::OnCollectingWorldComposition.BindStatic(&OnWorldCompositionCollecting);


    //set commandlet enviroment
    GIsRunningUnattendedScript = true;
    PRIVATE_GAllowCommandletRendering = true;
    //set editor featurelevel
    GEditor->SetPreviewPlatform(FPreviewPlatformInfo(ERHIFeatureLevel::SM5), false);


    FString LevelPath = FPaths::ProjectContentDir() + LevelName;

    if (!FEditorFileUtils::LoadMap(LevelPath))
    {
        UE_LOG(LogTemp, Error, TEXT("load %s persistent level fail!"), *LevelPath);
        return false;
    }
    UE_LOG(LogTemp, Log, TEXT("persistent level of %s is loaded!"), *LevelPath);

    FWorldContext& WorldContext = GEditor->GetEditorWorldContext();
    UWorld* World = WorldContext.World();

    if (!World || !World->WorldComposition)
    {
        UE_LOG(LogTemp, Error, TEXT("persistent level of %s has invalid worldcomposition!"), *LevelPath);
        return false;
    }

    ExportContext Context;
    if (!ParseConfigFile(FPaths::ProjectContentDir() + ConfigFilePath, Context))
    {
        UE_LOG(LogTemp, Error, TEXT("parse config file %s fail"), *ConfigFilePath);
        return false;
    }
    if (!SaveDir.IsEmpty())
    {
        FString NormalizedSaveDir = SaveDir;
        FPaths::NormalizeDirectoryName(NormalizedSaveDir);
        Context.SavePath = NormalizedSaveDir + TEXT("/");
    }
    else
    {
        Context.SavePath = FPaths::ProjectSavedDir() + TEXT("MapCollision/");
    }


    UE_LOG(LogTemp, Log, TEXT("export total sub level num: %d"), Context.SubLevelContexts.Num());
    for (SubLevelContext& SubLevel : Context.SubLevelContexts)
    {
        UE_LOG(LogTemp, Log, TEXT("start export sub level %s"), *SubLevel.SubLevelName);
        if (!ExportSubLevel(World, SubLevel, Context))
        {
            UE_LOG(LogTemp, Error, TEXT("export sub level %s fail"), *SubLevel.SubLevelName);
            return false;
        }
    }

    return true;
}
