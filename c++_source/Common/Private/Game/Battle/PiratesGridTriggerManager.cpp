 // Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Battle/PiratesGridTriggerManager.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"

DEFINE_LOG_CATEGORY_STATIC(LogPiratesGridTriggerManager, Log, All);

// 刷新间隔
#define UPDATE_INTERVAL 0.5f
#define FILE_EXT ".data"
#define PGTM_RECT_POINT_COUNT 4

struct FGridTriggerManagerHelper
{
    // Size : (rectLength / 2 ,  rectWidth / 2)
    // OutVertices : 4 vertices in clockwise
    static void GetRectVertices(FVector2D Center, FVector2D Size, float Yaw, TArray<FVector2D>& OutVertices)
    {
        int Count = OutVertices.Num();
        int CountAdded = PGTM_RECT_POINT_COUNT - Count;
        if (CountAdded > 0)
        {
            OutVertices.AddDefaulted(CountAdded);
        }
        Size.X = FMath::Abs(Size.X);
        Size.Y = FMath::Abs(Size.Y);
        OutVertices[0].X = -Size.X;
        OutVertices[0].Y = -Size.Y;
        OutVertices[1].X = Size.X;
        OutVertices[1].Y = -Size.Y;
        OutVertices[2].X = Size.X;
        OutVertices[2].Y = Size.Y;
        OutVertices[3].X = -Size.X;
        OutVertices[3].Y = Size.Y;
        for (int ii = 0; ii < PGTM_RECT_POINT_COUNT; ii++)
        {
            OutVertices[ii] = OutVertices[ii].GetRotated(Yaw);
            OutVertices[ii] = OutVertices[ii] + Center;
        }
    }

    static void GetCenterPointOfGrid(int GridX, int GridY, UPiratesGridTriggerManager::MapBasicInfo* InfoPtr, FVector2D& OutPoint)
    {
        check(GridX >= 0 && GridY >= 0);
        float LeftTopX = InfoPtr->MapCenterX - InfoPtr->MapSizeX / 2;
        float LeftTopY = InfoPtr->MapCenterY - InfoPtr->MapSizeY / 2;
        OutPoint.X = (GridX + 0.5) * InfoPtr->GridSizeX + LeftTopX;
        OutPoint.Y = (GridY + 0.5) * InfoPtr->GridSizeX + LeftTopY;
    }

    static bool IsPointInAlignAxisRect(const FVector2D& Point, const FVector2D& RectMin, const FVector2D& RectMax)
    {
        bool bInX = (Point.X - RectMin.X) * (Point.X - RectMax.X) <= 0;
        bool bInY = (Point.Y - RectMin.Y) * (Point.Y - RectMax.Y) <= 0;
        return bInX && bInY;
    }

    static void CoordinateToGridXY(FVector2D Coord, UPiratesGridTriggerManager::MapBasicInfo* InfoPtr, int& OutGridX, int& OutGridY)
    {
        float LeftTopX = InfoPtr->MapCenterX - InfoPtr->MapSizeX / 2;
        float LeftTopY = InfoPtr->MapCenterY - InfoPtr->MapSizeY / 2;
        float LocationX = FMath::Max(FMath::Min(LeftTopX + InfoPtr->MapSizeX, Coord.X), LeftTopX);
        float LocationY = FMath::Max(FMath::Min(LeftTopY + InfoPtr->MapSizeY, Coord.Y), LeftTopY);
        float DeltaX = FMath::Abs(LocationX - LeftTopX);
        float DeltaY = FMath::Abs(LocationY - LeftTopY);
        OutGridX = FMath::Min(FMath::FloorToInt(DeltaX / InfoPtr->GridSizeX), InfoPtr->TotalCountX);
        OutGridY = FMath::Min(FMath::FloorToInt(DeltaY / InfoPtr->GridSizeY), InfoPtr->TotalCountY);
    }

    static uint64 MakeIndex(const int& GridX, const int& GridY, const int& TotalCountX)
    {
        uint64 Result = GridX + (uint64)GridY * TotalCountX + 1;  // grid index start from 1, because 0 is set to default value
        return Result;
    }

    static bool IsGridInRect(TArray<FVector2D> & RectPoints, int GridX, int GridY, UPiratesGridTriggerManager::MapBasicInfo* InfoPtr)
    {
        FVector2D PointToBeChecked;
        FGridTriggerManagerHelper::GetCenterPointOfGrid(GridX, GridY, InfoPtr, PointToBeChecked);

        FVector2D P0P3 = RectPoints[3] - RectPoints[0];
        FVector2D P0P = PointToBeChecked - RectPoints[0];

        FVector2D P2P1 = (RectPoints[1] - RectPoints[2]);
        FVector2D P2P = PointToBeChecked - RectPoints[2];

        FVector2D P1P0 = RectPoints[0] - RectPoints[1];
        FVector2D P1P = PointToBeChecked - RectPoints[0];

        FVector2D P3P2 = (RectPoints[2] - RectPoints[3]);
        FVector2D P3P = PointToBeChecked - RectPoints[3];

        bool bRet = FVector2D::CrossProduct(P0P3, P0P) *
            FVector2D::CrossProduct(P2P1, P2P) >= 0;
        bRet = bRet && ( FVector2D::CrossProduct(P1P0, P1P) *
            FVector2D::CrossProduct(P3P2, P3P) >= 0);

        return bRet;
    }

    static bool IsGridInAlignRect(UPiratesGridTriggerManager::MapBasicInfo* InfoPtr, int GridX, int GridY, float Yaw,
            const FVector2D& AlignRectMax, const FVector2D& AlignRectMin)
    {
        FVector2D PointToBeChecked;
        FGridTriggerManagerHelper::GetCenterPointOfGrid(GridX, GridY, InfoPtr, PointToBeChecked);
        FVector2D AfterRotate = PointToBeChecked.GetRotated(-Yaw);
        bool bCheckResult = FGridTriggerManagerHelper::IsPointInAlignAxisRect(AfterRotate, AlignRectMin, AlignRectMax);
        return bCheckResult;
    }

    static void RotateWithPivot(const FVector2D& Point, const FVector2D& Pivot, float Yaw, FVector2D& OutPoint)
    {
        OutPoint = Point - Pivot;
        OutPoint = OutPoint.GetRotated(Yaw);
        OutPoint = OutPoint + Pivot;

    }

    static void DeserializeVector2D(FArchive* Ar, FVector2D& Value)
    {
        *Ar << Value.X;
        *Ar << Value.Y;
    }

    static void SerializeVector2D(FArchive* Ar, const FVector2D& Value)
    {
        float X = Value.X;
        float Y = Value.Y;
        *Ar << X;
        *Ar << Y;
    }
};


UPiratesGridTriggerManager::UPiratesGridTriggerManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , CurrentTime(0.0f)
    , HasInited(false)
{
}

void UPiratesGridTriggerManager::Update(float DeltaTime)
{
    bool bExecute = false;
    CurrentTime += DeltaTime;
    while (CurrentTime >= UPDATE_INTERVAL)
    {
        bExecute = true;
        CurrentTime -= UPDATE_INTERVAL;
    }
    if (bExecute)
    {
        for (FActorInfo& ActorInfo : ActorInfos)
        {
            auto Actor = ActorInfo.Actor;
            FVector2D ActorLocation(Actor->GetActorLocation());
            uint64 NewGridIndex = LocationVectorToGridIndex(ActorLocation);
            uint64 OldGridIndex = ActorInfo.GridIndex;

            if (NewGridIndex != OldGridIndex)
            {
                //UE_LOG(LogPiratesGridTriggerManager, Display,
                //    TEXT("UPiratesGridTriggerManager Update, NewGridIndex: %d, coord x: %f, coord y : %f"), NewGridIndex, ActorLocation.X, ActorLocation.Y);
                auto OldGridInfoPtr = CurrentGridInfos.Find(OldGridIndex);

                auto NewGridInfoPtr = CurrentGridInfos.Find(NewGridIndex);
                if (OldGridInfoPtr == nullptr && NewGridInfoPtr != nullptr)
                {
                    EnterGrid(Actor, NewGridInfoPtr->VolumnIds);
                }
                else if (OldGridInfoPtr != nullptr && NewGridInfoPtr == nullptr)
                {
                    LeaveGrid(Actor, OldGridInfoPtr->VolumnIds);
                }
                else if (OldGridInfoPtr == nullptr && NewGridInfoPtr == nullptr)
                {
                    // do nothing
                }
                else
                {
                    // find difference between old and new
                    TMap<int, char> OldVolumeMap;
                    TArray<int> EnterVolumeIds;
                    TArray<int> LeaveVolumeIds;
                    for (int Id : OldGridInfoPtr->VolumnIds)
                    {
                        OldVolumeMap.Add(Id);
                    }
                    for (int Id : NewGridInfoPtr->VolumnIds)
                    {
                        if (OldVolumeMap.Contains(Id))
                        {
                            OldVolumeMap.Remove(Id);
                        }
                        else
                        {
                            EnterVolumeIds.Add(Id);
                        }
                    }
                    OldVolumeMap.GenerateKeyArray(LeaveVolumeIds);
                    if (LeaveVolumeIds.Num() != 0)
                    {
                        LeaveGrid(Actor, LeaveVolumeIds);
                    }
                    if (EnterVolumeIds.Num() != 0)
                    {
                        EnterGrid(Actor, EnterVolumeIds);
                    }
                }
                ActorInfo.GridIndex = NewGridIndex;
            }
        }
    }
}

uint64 UPiratesGridTriggerManager::LocationVectorToGridIndex(const FVector2D& Location)
{
    int GridX;
    int GridY;
    FGridTriggerManagerHelper::CoordinateToGridXY(Location, &BasicInfo, GridX, GridY);
    //UE_LOG(LogPiratesGridTriggerManager, Display, TEXT("UPiratesGridTriggerManager LocationVectorToGridIndex, grid index: %d, grid X: %d, grid Y: %d"), Result, GridIndexX, GridIndexY);
    return FGridTriggerManagerHelper::MakeIndex(GridX, GridY, BasicInfo.TotalCountX);
}



void UPiratesGridTriggerManager::EnterGrid(TWeakObjectPtr<AActor> Actor, const TArray<int>& VolumeIds)
{
    auto GameMisc = GetGameMiscDelegate();
    if (GameMisc)
    {
        GameMisc->OnActorEnterVolume.ExecuteIfBound(Actor->GetUniqueID(), VolumeIds);
    }
}

void UPiratesGridTriggerManager::LeaveGrid(TWeakObjectPtr<AActor> Actor, const TArray<int>& VolumeIds)
{
    auto GameMisc = GetGameMiscDelegate();
    if (GameMisc)
    {
        GameMisc->OnActorLeaveVolume.ExecuteIfBound(Actor->GetUniqueID(), VolumeIds);
    }
}

UPiratesGameMiscDelegate* UPiratesGridTriggerManager::GetGameMiscDelegate()
{
    auto GameDelegateManager = Cast<UGameCommon>(GetOuter())->GetGameDelegateManager();
    if (GameDelegateManager)
    {
        auto GameMisc = GameDelegateManager->GameMisc;
        return GameMisc;
    }
    else
    {
        return nullptr;
    }
}

bool UPiratesGridTriggerManager::Init()
{
    OnPostLoadMapHandle = FCoreUObjectDelegates::PostLoadMapWithWorld.AddUObject(this, &UPiratesGridTriggerManager::OnPostLoadMap);
    OnWorldCleanUpHandle = FWorldDelegates::OnWorldCleanup.AddUObject(this, &UPiratesGridTriggerManager::OnWorldCleanUp);
    return true;
}

bool UPiratesGridTriggerManager::Uninit()
{
    FCoreUObjectDelegates::PostLoadMapWithWorld.Remove(OnPostLoadMapHandle);
    FWorldDelegates::OnWorldCleanup.Remove(OnWorldCleanUpHandle);
    return true;
}


void UPiratesGridTriggerManager::OnPostLoadMap(UWorld* CurrentWorld)
{
    FString WorldName = CurrentWorld->GetName();
    LoadInfo(WorldName);
}

void UPiratesGridTriggerManager::OnWorldCleanUp(UWorld* World, bool bSessionEnded, bool bCleanupResources)
{
    UnloadInfo();
}



bool UPiratesGridTriggerManager::LoadInfo(const FString& WorldName)
{
    UE_LOG(LogPiratesGridTriggerManager, Display, TEXT("UPiratesGridTriggerManager::Load"));
    UnloadInfo();
    FString LoadDir = FPaths::ProjectContentDir() + "GameDataGenerated/common/gridinfo/";
    FString InfoPath = LoadDir + WorldName + FILE_EXT;

    IFileManager& FileManager = IFileManager::Get();
    if (!FileManager.FileExists(*InfoPath))
    {
        return false;
    }

    FArchive* Reader = FileManager.CreateFileReader(*InfoPath);
    if (Reader == nullptr)
    {
        return false;
    }

    // parse map basic info
    *Reader << BasicInfo.MapSizeX;
    *Reader << BasicInfo.MapSizeY;
    *Reader << BasicInfo.TotalCountX;
    *Reader << BasicInfo.TotalCountY;

    UE_LOG(LogPiratesGridTriggerManager, Display, TEXT("Load Grid Info, MapSize : (%f, %f), Total Count : (%d, %d)"), 
        BasicInfo.MapSizeX, BasicInfo.MapSizeY, BasicInfo.TotalCountX, BasicInfo.TotalCountY);
    // parse grid info
    while (Reader->Tell() < Reader->TotalSize())
    {
        int VolumeId;
        *Reader << VolumeId;
        TArray<FVector2D> Points;
        Points.Reserve(PGTM_RECT_POINT_COUNT);
        Points.AddDefaulted(PGTM_RECT_POINT_COUNT);
        for (int tempI = 0; tempI < PGTM_RECT_POINT_COUNT; tempI++)
        {
            FGridTriggerManagerHelper::DeserializeVector2D(Reader, Points[tempI]);
        }
        float Yaw;
        *Reader << Yaw;
        int MaxGridX, MaxGridY, MinGridX, MinGridY;
        *Reader << MaxGridX;
        *Reader << MaxGridY;
        *Reader << MinGridX;
        *Reader << MinGridY;
        int ApproximateGridCount;
        *Reader << ApproximateGridCount;

        UE_LOG(LogPiratesGridTriggerManager, Display,
            TEXT("Load Grid Info, VolumeId : %d, P0 : (%f, %f), P1 : (%f, %f),P2 : (%f, %f), P3 : (%f, %f), Yaw: %f, MinX : %d, MaxX : %d, MinY : %d, MaxY : %d, ReserveGridCount : %d"),
            VolumeId, Points[0].X, Points[0].Y, Points[1].X, Points[1].Y, Points[2].X, Points[2].Y, Points[3].X, Points[3].Y, Yaw, MinGridX, MaxGridX, MinGridY, MaxGridY, ApproximateGridCount);

        CurrentGridInfos.Reserve(CurrentGridInfos.Num() + ApproximateGridCount);
        for (int yy = MinGridY; yy <= MaxGridY; yy++)
        {
            for (int xx = MinGridX; xx <= MaxGridX; xx++)
            {
                //FVector2D PointToBeChecked;
                bool bCheckResult = FGridTriggerManagerHelper::IsGridInRect(Points, xx, yy, &BasicInfo);

                if (bCheckResult)
                {
                    uint64 Idx = FGridTriggerManagerHelper::MakeIndex(xx, yy, BasicInfo.TotalCountX);
                    FGridInfo& Info = CurrentGridInfos.FindOrAdd(Idx);
                    Info.VolumnIds.Add(VolumeId);
                }
            }
        }
    }

    delete Reader;
    UE_LOG(LogPiratesGridTriggerManager, Display, TEXT("UPiratesGridTriggerManager After load, grid info count: %d"), CurrentGridInfos.Num());
    return true;
}

bool UPiratesGridTriggerManager::UnloadInfo()
{
    CurrentGridInfos.Empty();
    ActorInfos.Empty();
    return true;
}

void UPiratesGridTriggerManager::AddActor(AActor* Actor)
{
    if (!Actor)
    {
        return;
    }
    bool bExisted = false;
    for (int i = 0; i < ActorInfos.Num();)
    {
        auto& Info = ActorInfos[i];

        if (!Info.Actor.IsValid())
        {
            ActorInfos.RemoveAt(i, 1, false);
            continue;
        }

        if (Info.Actor == Actor)
        {
            bExisted = true;
            break; 
        }
        i++;
    }
    if (!bExisted)
    {
        int idx = ActorInfos.AddDefaulted(1);
        auto& AddedInfo = ActorInfos[idx];
        AddedInfo.Actor = Actor;
        Actor->OnDestroyed.AddDynamic(this, &UPiratesGridTriggerManager::OnActorDestroyed);
    }
}

void UPiratesGridTriggerManager::RemoveActor(AActor* Actor)
{
    if (!Actor)
    {
        return;
    }
    for (int i = 0; i < ActorInfos.Num();)
    {
        FActorInfo& Info = ActorInfos[i];
        if (!Info.Actor.IsValid())
        {
            ActorInfos.RemoveAt(i, 1, false);
            continue;
        }
        if (Info.Actor == Actor)
        {
            auto GridIndex = Info.GridIndex;
            Actor->OnDestroyed.RemoveDynamic(this, &UPiratesGridTriggerManager::OnActorDestroyed);            
            ActorInfos.RemoveAt(i);

            auto GridInfoPtr = CurrentGridInfos.Find(GridIndex);
            if (GridInfoPtr != nullptr)
            {
                LeaveGrid(Actor, GridInfoPtr->VolumnIds);
            }
            break;
        }
        i++;
    }
}

bool UPiratesGridTriggerManager::CheckActor(AActor* Actor, int VolumeId)
{
    FVector2D ActorLocation(Actor->GetActorLocation());
    uint64 GridIndex = LocationVectorToGridIndex(ActorLocation);
    FGridInfo* InfoPtr = CurrentGridInfos.Find(GridIndex);
    bool Result = false;
    if (InfoPtr != nullptr)
    {
        Result = (InfoPtr->VolumnIds.Find(VolumeId) != INDEX_NONE);
    }
    return Result;
}

int32 UPiratesGridTriggerManager::GetActorVolume(AActor* Actor)
{
    FVector2D ActorLocation(Actor->GetActorLocation());
    uint64 GridIndex = LocationVectorToGridIndex(ActorLocation);
    FGridInfo* InfoPtr = CurrentGridInfos.Find(GridIndex);
    if (InfoPtr != nullptr && InfoPtr->VolumnIds.Num() > 0)
    {
        return InfoPtr->VolumnIds[0];
    }
    return 0;
}

void UPiratesGridTriggerManager::OnActorDestroyed(AActor* Actor)
{
    RemoveActor(Actor);
}

/////////////////////////////////////// For Editor /////////////////////////////////////// 

struct ExportGridInfo
{
    ExportGridInfo()
        : Actor(nullptr)
        , VolumeId(0) 
        , Yaw(0.f) {}
    AActor* Actor;
    int VolumeId;
    FVector2D Center;
    FVector2D Size;
    float Yaw; // degree
};

#if WITH_EDITOR
class FEditorExporter
{
public:
    static FEditorExporter& Get()
    {
        static FEditorExporter Instance;
        return Instance;
    }

    void Begin()
    {
        ExportInfos.Empty();
    }

    void End()
    {
        if (ExportInfos.Num() <= 0)
            return;
        FString MapDir;
        GetMapDir(MapDir);
        ExportHeader(MapDir);
        ExportContent(MapDir);
    }

    void RecordExportInfo(AActor* Actor, int VolumeId, const FVector2D& Center, FVector2D Size, float Yaw)
    {
        int idx = ExportInfos.AddDefaulted(1);
        ExportGridInfo& Info = ExportInfos[idx];
        Info.Actor = Actor;
        Info.VolumeId = VolumeId;
        Info.Center = Center;
        Info.Size = Size;
        Info.Yaw = Yaw;
    }
    
    void RecordMapSize(const FVector2D& MapSize)
    {
        BasicInfoForEditor.MapSizeX = MapSize.X;
        BasicInfoForEditor.MapSizeY = MapSize.Y;
    }
private:

    void GetMapDir(FString& OutMapDir)
    {
        FString AssetPathString = FSoftObjectPath(GWorld).GetAssetPathString();
        FString PathWithoutSuffix;
        FString Suffix;
        AssetPathString.Split(FString("."), &PathWithoutSuffix, &Suffix);
        FString PreString;
        FString RealName;
        PathWithoutSuffix.Split(FString("/"), &Suffix, &RealName, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
        OutMapDir = ExportDir + RealName + "/";
    }

    void ExportHeader(const FString& MapDir)
    {
        IFileManager& FileManager = IFileManager::Get();
        FString HeaderFile = MapDir + ExportHeaderFileName;
        if (FPaths::FileExists(*HeaderFile))
        {
            FileManager.Delete(*HeaderFile);
        }
        FArchive* HeaderFileWriter = FileManager.CreateFileWriter(*HeaderFile);
        if (HeaderFileWriter == nullptr)
        {
            return;
        }
        *HeaderFileWriter << BasicInfoForEditor.MapSizeX;
        *HeaderFileWriter << BasicInfoForEditor.MapSizeY;

        BasicInfoForEditor.TotalCountX = FMath::CeilToInt(BasicInfoForEditor.MapSizeX / BasicInfoForEditor.GridSizeX);
        BasicInfoForEditor.TotalCountY = FMath::CeilToInt(BasicInfoForEditor.MapSizeY / BasicInfoForEditor.GridSizeY);

        *HeaderFileWriter << BasicInfoForEditor.TotalCountX;
        *HeaderFileWriter << BasicInfoForEditor.TotalCountY;

        HeaderFileWriter->Close();
        delete HeaderFileWriter;
        UE_LOG(LogPiratesGridTriggerManager, Display,
            TEXT("Export Grid Info Header, MapSize : (%f, %f)"), BasicInfoForEditor.MapSizeX, BasicInfoForEditor.MapSizeY);
    }

    void ExportContent(const FString& MapDir)
    {
        IFileManager& FileManager = IFileManager::Get();
        // firstly, classify datas by logic level
        TMap<FString, TArray<int>> InfoMap;
        for (int ii = 0; ii < ExportInfos.Num(); ii++)
        {
            ExportGridInfo& Info = ExportInfos[ii];
            FString ParentLevelName = Info.Actor->GetOutermost()->GetName();

            TArray<int>& InfoIndices = InfoMap.FindOrAdd(ParentLevelName);
            InfoIndices.Add(ii);
        }

        TArray<FString> KeyArray;
        InfoMap.GenerateKeyArray(KeyArray);

        // then, export to data file named by logic level, the root path is the directory named by persistent level
        for (auto ParentLevelName : KeyArray)
        {
            TArray<int> InfoIndices = InfoMap[ParentLevelName];
            FString LString;
            FString LevelName;
            ParentLevelName.Split(FString("/"), &LString, &LevelName, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
            FString FilePath = MapDir + LevelName + FILE_EXT;

            if (FPaths::FileExists(*FilePath))
            {
                FileManager.Delete(*FilePath);
            }

            FArchive* Ar = FileManager.CreateFileWriter(*FilePath);
            if (Ar == nullptr)
            {
                return;
            }
            FVector2D Center(BasicInfoForEditor.MapCenterX, BasicInfoForEditor.MapCenterY);
            
            TArray<FVector2D> Points;  // upperLeft, upperRight, LowerRight, LowerLeft
            Points.Reserve(PGTM_RECT_POINT_COUNT);
            Points.AddDefaulted(PGTM_RECT_POINT_COUNT);
            for (int idx : InfoIndices)
            {
                ExportGridInfo& Info = ExportInfos[idx];
                FGridTriggerManagerHelper::GetRectVertices(Info.Center, Info.Size, Info.Yaw, Points);
                TArray<int> GridXs;
                GridXs.Reserve(PGTM_RECT_POINT_COUNT);
                GridXs.AddDefaulted(PGTM_RECT_POINT_COUNT);
                TArray<int> GridYs;
                GridYs.Reserve(PGTM_RECT_POINT_COUNT);
                GridYs.AddDefaulted(PGTM_RECT_POINT_COUNT);
                for (int tempI = 0; tempI < PGTM_RECT_POINT_COUNT; tempI++)
                {
                    FGridTriggerManagerHelper::CoordinateToGridXY(Points[tempI], &BasicInfoForEditor, GridXs[tempI], GridYs[tempI]);
                    //int tIdx = FGridTriggerManagerHelper::MakeIndex(GridXs[tempI], GridYs[tempI], BasicInfoForEditor.TotalCountX);
                    //UE_LOG(LogPiratesGridTriggerManager, Display,
                    //    TEXT("Export Grid Info, idx : %d , grid idx : %d"), tempI,
                    //    tIdx);
                    //UE_LOG(LogPiratesGridTriggerManager, Display,
                    //    TEXT("Export Grid Info, rotate, x : %f , y : %f"), Out.X,
                    //    Out.Y);
                }
                int MaxGridX = FMath::Max(GridXs);
                int MaxGridY = FMath::Max(GridYs);
                int MinGridX = FMath::Min(GridXs);
                int MinGridY = FMath::Min(GridYs);

                // calculate approximate grid count by align-axis rect
                int ApproximateGridCount = (MaxGridX - MinGridX + 1) * (MaxGridY - MinGridY + 1);

                // begin to export
                *Ar << Info.VolumeId;
                for (int tempI = 0; tempI < PGTM_RECT_POINT_COUNT; tempI++)
                {
                    FGridTriggerManagerHelper::SerializeVector2D(Ar, Points[tempI]);
                }
                *Ar << Info.Yaw;
                *Ar << MaxGridX;
                *Ar << MaxGridY;
                *Ar << MinGridX;
                *Ar << MinGridY;
                *Ar << ApproximateGridCount;

                UE_LOG(LogPiratesGridTriggerManager, Display,
                    TEXT("Export Grid Info, VolumeId : %d, UpperLeft : (%f, %f), UpperRight : (%f, %f), LowerRight : (%f, %f),  LowerLeft : (%f, %f), Yaw: %f, MinX : %d, MaxX : %d, MinY : %d, MaxY : %d, GridCount : %d"),
                    Info.VolumeId, Points[0].X, Points[0].Y, Points[1].X, Points[1].Y, Points[2].X, Points[2].Y, Points[3].X, Points[3].Y, Info.Yaw, MinGridX, MaxGridX, MinGridY, MaxGridY, ApproximateGridCount);
            }
            Ar->Close();
            delete Ar;
        }
        ExportInfos.Empty();
    }
private:
    UPiratesGridTriggerManager::MapBasicInfo BasicInfoForEditor;
    TArray<ExportGridInfo> ExportInfos;
    FString ExportDir = FPaths::ProjectContentDir() + "GameData/common/gridinfo/";
    FString ExportHeaderFileName = "data.header";
};
#endif

void UPiratesGridTriggerManager::BeginExport()
{
#if WITH_EDITOR
    FEditorExporter::Get().Begin();
#endif
}

void UPiratesGridTriggerManager::EndExport()
{
#if WITH_EDITOR
    FEditorExporter::Get().End();
#endif
}

// UpperLeft and LowerRight are both align-axis coordinates
void UPiratesGridTriggerManager::RecordExportInfo(AActor* Actor, int VolumeId, FVector2D Center, FVector2D Size, float Yaw)
{
//#if WITH_EDITOR
//    FEditorExporter::Get().RecordExportInfo(Actor, VolumeId, Center, Size, Yaw);
//#endif
}

void UPiratesGridTriggerManager::RecordMapSize(FVector2D MapSize)
{
//#if WITH_EDITOR
//    FEditorExporter::Get().RecordMapSize(MapSize);
//#endif
}

