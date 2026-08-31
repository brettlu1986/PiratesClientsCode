 // Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Battle/PiratesGridTypeManager.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Components/HierarchicalInstancedStaticMeshComponent.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "TabFile/LandIDNameTabFile.h"

DEFINE_LOG_CATEGORY_STATIC(LogPiratesGridTypeManager, Log, All);

#define GRIDTYPE_GAME_FILE_PATH "GameDataGenerated/common/gridtype/"
#define LANDIDNAME_GAME_FILE_PATH "common/scene/land_id_name/"

/*
* Show/Hide debug grid type from console command
*/
static bool bDebugGridType = true;
static FAutoConsoleCommandWithWorld CCmdDebugGridType = FAutoConsoleCommandWithWorld(
	TEXT("pir.DebugGridType"),
	TEXT("Enable/Disable DebugGridType"),
	FConsoleCommandWithWorldDelegate::CreateLambda([](UWorld* InWorld) {

	auto GameCommon = UGameCommon::Get(InWorld);
	if ((GameCommon != nullptr) && (GameCommon->GetGridTypeManager() != nullptr))
	{
		GameCommon->GetGridTypeManager()->ShowDebugGridType(bDebugGridType, InWorld);
		bDebugGridType = !bDebugGridType;
	}
})
);

UPiratesGridTypeManager::UPiratesGridTypeManager(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer),
	FileDataVersion(0),
	WorldSizeX(0.0f),
	WorldSizeY(0.0f), 
	GridSizeX(0.0f),
	GridSizeY(0.0f), 
	GridCountX(0),
	GridCountY(0),
	ShoreSearchPortUnitScale(1),
	PortSearchShoreUnitScale(1),
	RockSearchOceanUnitScale(1),
	OceanSearchShoreUnitScale(100),
	LandSearchOceanUnitScale(10),
	OceanSearchLandUnitScale(100),
	LakeSearchShoreUnitScale(100),
	bHasInited(false),
    CurrentTime(0.0f),
    UpdateInterval(0.5f)
{
}

#if WITH_EDITOR
static FString RemovePIEMapNamePrefix(const FString& MapName)
{
    FString Ret = MapName;
    if (Ret.StartsWith(PLAYWORLD_PACKAGE_PREFIX))
    {
        int FindexIndex = -1;
        Ret.RemoveAt(0, FCString::Strlen(PLAYWORLD_PACKAGE_PREFIX) + 2);
        if (Ret.FindChar('_', FindexIndex))
        {
            Ret.RemoveAt(0, FindexIndex + 1);
        }
    }
    return Ret;
}
#endif

bool UPiratesGridTypeManager::Init()
{
    //OnPostLoadMapHandle = FCoreUObjectDelegates::PostLoadMapWithWorld.AddUObject(this, &UPiratesGridTypeManager::OnPostLoadMap);
    //OnWorldCleanUpHandle = FWorldDelegates::OnWorldCleanup.AddUObject(this, &UPiratesGridTypeManager::OnWorldCleanUp);

#if WITH_EDITOR
    UWorld* World = GetWorld();
    if (GIsEditor && World && World->IsServer())
    {
        // 编辑器在起server时不会产生loadmap或者worldchange的消息，所以这里自己处理下
        Load(RemovePIEMapNamePrefix(World->GetMapName()));
    }
#endif

    return true;
}

bool UPiratesGridTypeManager::Uninit()
{
    //FCoreUObjectDelegates::PostLoadMapWithWorld.Remove(OnPostLoadMapHandle);
    //FWorldDelegates::OnWorldCleanup.Remove(OnWorldCleanUpHandle);

    ClearActorInfos();
    return true;
}

bool UPiratesGridTypeManager::Load(const FString& WorldName)
{   
	CleanData();

    UE_LOG(LogPiratesGridTypeManager, Display, TEXT("UPiratesGridTypeManager::Load %s"), *WorldName);

	const FString LoadDir = FPaths::ProjectContentDir() + GRIDTYPE_GAME_FILE_PATH;
	const FString InfoPath = LoadDir + WorldName + "/" + REGIONTYPE_FILE_NAME;

    IFileManager& FileManager = IFileManager::Get();
    if (!FileManager.FileExists(*InfoPath))
    {
        return false;
    }

    FArchive* FileReader = FileManager.CreateFileReader(*InfoPath);
    if (FileReader == nullptr)
    {
        return false;
    }

	// File Version first
	*FileReader << FileDataVersion;

	// Check file version
	if (FileDataVersion < CURRENT_FILE_VERSION)
	{
		UE_LOG(LogPiratesGridTypeManager, Error, TEXT("File version is not updated!"));

		FileReader->Close();
		delete FileReader;

		return false;
	}

	// Game data
	*FileReader << WorldSizeX;
	*FileReader << WorldSizeY;
	*FileReader << GridSizeX;
	*FileReader << GridSizeY;
	*FileReader << GridCountX;
	*FileReader << GridCountY;

	check(GridCountX < GRIDTYPE_MAX_GRID_INDEX);
	check(GridCountY < GRIDTYPE_MAX_GRID_INDEX);

	*FileReader << LineTypeDatas;
	*FileReader << LineIDDatas;
	*FileReader << LandIDGroupedShorePos;
	*FileReader << LandIDGroupedPortPos;
	*FileReader << RegionTypeMarkIDScale;
	*FileReader << LandMarkPosScale;

	*FileReader << LineShoreSearchPortDatas;
	*FileReader << LinePortSearchShoreDatas;
	*FileReader << LineRockSearchOceanDatas;
	*FileReader << LineOceanSearchShoreDatas;
	*FileReader << LineLandSearchOceanDatas;
	*FileReader << LineOceanSearchLandDatas;
	*FileReader << LineLakeSearchShoreDatas;

	*FileReader << ShoreSearchPortUnitScale;
	*FileReader << PortSearchShoreUnitScale;
	*FileReader << RockSearchOceanUnitScale;
	*FileReader << OceanSearchShoreUnitScale;
	*FileReader << LandSearchOceanUnitScale;
	*FileReader << OceanSearchLandUnitScale;
	*FileReader << LakeSearchShoreUnitScale;

	*FileReader << LandRandomDatas;
	*FileReader << OceanRandomDatas;
	*FileReader << LandIDGroupedRandomDatas;

	//*FileReader << LineRandomDatas;
	//*FileReader << LineRandomIndexes;

	FileReader->Close();

	delete FileReader;

    ClearActorInfos();

	// Load land id name info from table
	const FString TableFileDir = LANDIDNAME_GAME_FILE_PATH;
	const FString TableFilePath = TableFileDir + WorldName + "/" + LANDIDNAME_FILE_NAME;
    UE_LOG(LogPiratesGridTypeManager, Log, TEXT("[LANDIDNAME] TableFilePath=%s"), *TableFilePath);
	FLandIDNameTabFile::GetSingleton().SetPath(TableFilePath);
	FLandIDNameTabFile::GetSingleton().Load();
	TArray<const FTabFileDataBase*> LandIDNameDatas;
	FLandIDNameTabFile::GetSingleton().GetAllData(LandIDNameDatas);
	for (auto Data : LandIDNameDatas)
	{
		const FLandIDNameTabData* LandIDNameData = static_cast<const FLandIDNameTabData*>(Data);
		check(LandIDNameData != nullptr);
        LandIDNames.Add(LandIDNameData->LandID, LandIDNameData->LandName);
        UE_LOG(LogPiratesGridTypeManager, Log, TEXT("[LANDIDNAME] AddData id=%d name=%s"), LandIDNameData->LandID, *LandIDNameData->LandName);
	}
	FLandIDNameTabFile::GetSingleton().Unload();

	bHasInited = true;
   
	return true;
}

bool UPiratesGridTypeManager::Unload()
{
	UE_LOG(LogPiratesGridTypeManager, Display, TEXT("UPiratesGridTypeManager::Unload"));

	CleanData();

	return true;
}

bool UPiratesGridTypeManager::CleanData()
{
	WorldSizeX = 0.0f;
	WorldSizeY = 0.0f;
	GridSizeX = 0.0f;
	GridSizeY = 0.0f;
	GridCountX = 0;
	GridCountY = 0;

	LineTypeDatas.Empty();
	LineIDDatas.Empty();
	LineShoreSearchPortDatas.Empty();
	LinePortSearchShoreDatas.Empty();
	LineRockSearchOceanDatas.Empty();
	LineOceanSearchShoreDatas.Empty();
	LineLandSearchOceanDatas.Empty();
	LineOceanSearchLandDatas.Empty();
	LineLakeSearchShoreDatas.Empty();

	//LineRandomDatas.Empty();
	LandRandomDatas.Empty();
	OceanRandomDatas.Empty();
	LineRandomIndexes.Empty();
	LandIDGroupedRandomDatas.Empty();

	LandIDNames.Empty();

	bHasInited = false;

	ClearActorInfos();

	return true;
}

void UPiratesGridTypeManager::OnWorldChanged(UWorld* NewWorld)
{
    if (NewWorld)
    {
        FString MapName = NewWorld->GetMapName();
#if WITH_EDITOR
        MapName = RemovePIEMapNamePrefix(MapName);
#endif
        Load(MapName);
    }
    else
    {
        Unload();
    }
}

EPiratesGridRegionType UPiratesGridTypeManager::GetRegionType(float X, float Y)
{
	if (!bHasInited || !IsPositionValid(X, Y))
	{
		return EPiratesGridRegionType::Unknown;
	}

	uint16 GridPosX = FMath::FloorToInt((X + WorldSizeX * 0.5f) / GridSizeX);
	uint16 GridPosY = FMath::FloorToInt((Y + WorldSizeY * 0.5f) / GridSizeY);

	EPiratesGridRegionType RegionType = GetRegionType(GridPosX, GridPosY);

	return RegionType;
}

uint8 UPiratesGridTypeManager::GetLandID(float X, float Y)
{
	if (!bHasInited || !IsPositionValid(X, Y))
	{
		return GRIDTYPE_INVALID_LAND_ID;
	}

	if ((EPiratesGridRegionType::Land != GetRegionType(X, Y)) && (EPiratesGridRegionType::Shore != GetRegionType(X, Y)))
	{
		return GRIDTYPE_INVALID_LAND_ID;
	}

	check(RegionTypeMarkIDScale > 0);
	uint16 GridPosX = FMath::FloorToInt((X + WorldSizeX * 0.5f) / GridSizeX / RegionTypeMarkIDScale);
	uint16 GridPosY = FMath::FloorToInt((Y + WorldSizeY * 0.5f) / GridSizeY / RegionTypeMarkIDScale);
	uint8 RegionID = GetRegionID(GridPosX, GridPosY);

	return RegionID;
}

FString UPiratesGridTypeManager::GetRegionName(float PosX, float PosY)
{
	if (!bHasInited || !IsPositionValid(PosX, PosY))
	{
		return FString(UNKNOW_LANDNAME);
	}

	const uint8 LandID = GetLandID(PosX, PosY);
	const FString* LandName = LandIDNames.Find(LandID);
	if (LandName != nullptr)
	{
		return *LandName;
	}

	return FString(UNKNOW_LANDNAME);
}

bool UPiratesGridTypeManager::GetClosestPositionOfRegionType(float X, float Y, EPiratesGridRegionType RegionType, FVector2D& OutLocation)
{
	if (!bHasInited || !IsPositionValid(X, Y))
	{
		return false;
	}

	EPiratesGridRegionType SrcRegionType = GetRegionType(X, Y);

	// Shore region -> Ocean region (high way)
	if ((EPiratesGridRegionType::Shore == SrcRegionType) && (EPiratesGridRegionType::Port == RegionType))
	{
		uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
		uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
		if (GetShoreSearchPortData(X, Y, GridPosX, GridPosY))
		{
			check(GridPosX < GridCountX);
			check(GridPosY < GridCountY);

			OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
			OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

			return true;
		}
	}
	// Port region -> Land region(high way)
	else if ((EPiratesGridRegionType::Port == SrcRegionType) && (EPiratesGridRegionType::Shore == RegionType))
	{
		uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
		uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
		if (GetPortSearchShoreData(X, Y, GridPosX, GridPosY))
		{
			check(GridPosX < GridCountX);
			check(GridPosY < GridCountY);

			OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
			OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

			return true;
		}		
	}
	// Rock region -> non rock region(high way)
	else if ((EPiratesGridRegionType::Rock == SrcRegionType))
	{
		uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
		uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
		if (GetRockSearchOceanData(X, Y, GridPosX, GridPosY))
		{
			check(GridPosX < GridCountX);
			check(GridPosY < GridCountY);

			OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
			OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

			return true;
		}
	}
	// Ocean region -> shore region(high way)
	else if ((EPiratesGridRegionType::Ocean == SrcRegionType) && (EPiratesGridRegionType::Shore == RegionType))
	{
		uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
		uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
		if (GetOceanSearchShoreData(X, Y, GridPosX, GridPosY))
		{
			check(GridPosX < GridCountX);
			check(GridPosY < GridCountY);

			OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
			OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

			return true;
		}
	}
	// Ocean region -> land region(high way)
	else if (((EPiratesGridRegionType::Ocean == SrcRegionType) || (EPiratesGridRegionType::Port == SrcRegionType)) && (EPiratesGridRegionType::Land == RegionType))
	{
		uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
		uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
		if (GetOceanSearchLandData(X, Y, GridPosX, GridPosY))
		{
			check(GridPosX < GridCountX);
			check(GridPosY < GridCountY);

			OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
			OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

			return true;
		}
	}
	// Land region -> ocean region(high way)
	else if (((EPiratesGridRegionType::Land == SrcRegionType) || (EPiratesGridRegionType::Shore == SrcRegionType)) && (EPiratesGridRegionType::Ocean == RegionType))
	{
		uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
		uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
		if (GetLandSearchOceanData(X, Y, GridPosX, GridPosY))
		{
			check(GridPosX < GridCountX);
			check(GridPosY < GridCountY);

			OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
			OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

			return true;
		}
	}
	// Lake region -> shore region(high way)
	else if ((EPiratesGridRegionType::Lake == SrcRegionType) && (EPiratesGridRegionType::Shore == RegionType))
	{
		uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
		uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
		if (GetLakeSearchShoreData(X, Y, GridPosX, GridPosY))
		{
			check(GridPosX < GridCountX);
			check(GridPosY < GridCountY);

			OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
			OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

			return true;
		}
	}

	// Not support search type
	const UEnum* EnumRegionTypePtr = FindObject<UEnum>(ANY_PACKAGE, TEXT("EPiratesGridRegionType"), true);
	check(EnumRegionTypePtr != nullptr);
	FString SrcType = EnumRegionTypePtr->GetDisplayNameTextByIndex((int32) SrcRegionType).ToString();
	FString DestType = EnumRegionTypePtr->GetDisplayNameTextByIndex((int32) RegionType).ToString();
	UE_LOG(LogPiratesGridTypeManager, Warning, TEXT("UPiratesGridTypeManager::GetClosestPositionOfRegionType Unsupported search type. src position : (%f, %f), type : %s -> target type : %s"), X, Y, *SrcType, *DestType);

	return false;
}

EPiratesGridRegionType UPiratesGridTypeManager::GetRegionType(uint16 X, uint16 Y)
{
	check((X >= 0) && ((int32)X < GridCountX));
	check((Y >= 0) && ((int32)Y < LineTypeDatas.Num()));
	TArray<FSegmentTypeData>& SegmentDatas = LineTypeDatas[Y].SegmentDatas;

	// Binary search
	int32 MinIndex = 0;
	int32 MaxIndex = SegmentDatas.Num() - 1;
	int32 MidIndex = 0;

	while (MaxIndex >= MinIndex)
	{
		MidIndex = (MaxIndex + MinIndex) / 2;

		if ((X >= SegmentDatas[MidIndex].StartPos) && (X < (SegmentDatas[MidIndex].StartPos + SegmentDatas[MidIndex].Length)))
		{
			return SegmentDatas[MidIndex].Type;
		}

		if (SegmentDatas[MidIndex].StartPos > X)
		{
			MaxIndex = MidIndex - 1;
		}
		else
		{
			MinIndex = MidIndex + 1;
		}
	}

	return EPiratesGridRegionType::Ocean;
}

uint8 UPiratesGridTypeManager::GetRegionID(uint16 X, uint16 Y)
{
	check((X >= 0) && ((int32)X < GridCountX));
	check((Y >= 0) && ((int32)Y < LineIDDatas.Num()));
	TArray<FSegmentIDData>& SegmentDatas = LineIDDatas[Y].SegmentDatas;

	// Binary search
	int32 MinIndex = 0;
	int32 MaxIndex = SegmentDatas.Num() - 1;
	int32 MidIndex = 0;

	while (MaxIndex >= MinIndex)
	{
		MidIndex = (MaxIndex + MinIndex) / 2;

		if ((X >= SegmentDatas[MidIndex].StartPos) && (X < (SegmentDatas[MidIndex].StartPos + SegmentDatas[MidIndex].Length)))
		{
			return SegmentDatas[MidIndex].ID;
		}

		if (SegmentDatas[MidIndex].StartPos > X)
		{
			MaxIndex = MidIndex - 1;
		}
		else
		{
			MinIndex = MidIndex + 1;
		}
	}

	return 0;
}

bool UPiratesGridTypeManager::BinaryGetSearchData(TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas, uint16 X, uint16& GridPosX, uint16& GridPosY)
{
	// Binary search
	int32 MinIndex = 0;
	int32 MaxIndex = SegmentDatas.Num() - 1;
	int32 MidIndex = 0;

	while (MaxIndex >= MinIndex)
	{
		MidIndex = (MaxIndex + MinIndex) / 2;

		if ((X >= SegmentDatas[MidIndex].StartPos) && (X < (SegmentDatas[MidIndex].StartPos + SegmentDatas[MidIndex].Length)))
		{
			GridPosX = SegmentDatas[MidIndex].X;
			GridPosY = SegmentDatas[MidIndex].Y;

			return true;
		}

		if (SegmentDatas[MidIndex].StartPos > X)
		{
			MaxIndex = MidIndex - 1;
		}
		else
		{
			MinIndex = MidIndex + 1;
		}
	}

	return false;
}

bool UPiratesGridTypeManager::GetShoreSearchPortData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY)
{
	uint16 X = FMath::FloorToInt((WorldPosX + WorldSizeX * 0.5f) / GridSizeX / ShoreSearchPortUnitScale);
	uint16 Y = FMath::FloorToInt((WorldPosY + WorldSizeY * 0.5f) / GridSizeY / ShoreSearchPortUnitScale);

	check((X >= 0) && ((int32)X < GridCountX / ShoreSearchPortUnitScale));
	check((Y >= 0) && ((int32)Y < LineShoreSearchPortDatas.Num()));
	TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas = LineShoreSearchPortDatas[Y].SegmentDatas;

	return BinaryGetSearchData(SegmentDatas, X, GridPosX, GridPosY);
}

bool UPiratesGridTypeManager::GetPortSearchShoreData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY)
{
	uint16 X = FMath::FloorToInt((WorldPosX + WorldSizeX * 0.5f) / GridSizeX / PortSearchShoreUnitScale);
	uint16 Y = FMath::FloorToInt((WorldPosY + WorldSizeY * 0.5f) / GridSizeY / PortSearchShoreUnitScale);

	check((X >= 0) && ((int32)X < GridCountX / PortSearchShoreUnitScale));
	check((Y >= 0) && ((int32)Y < LinePortSearchShoreDatas.Num()));
	TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas = LinePortSearchShoreDatas[Y].SegmentDatas;

	return BinaryGetSearchData(SegmentDatas, X, GridPosX, GridPosY);
}

bool UPiratesGridTypeManager::GetRockSearchOceanData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY)
{
	uint16 X = FMath::FloorToInt((WorldPosX + WorldSizeX * 0.5f) / GridSizeX / RockSearchOceanUnitScale);
	uint16 Y = FMath::FloorToInt((WorldPosY + WorldSizeY * 0.5f) / GridSizeY / RockSearchOceanUnitScale);

	check((X >= 0) && ((int32)X < GridCountX / RockSearchOceanUnitScale));
	check((Y >= 0) && ((int32)Y < LineRockSearchOceanDatas.Num()));
	TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas = LineRockSearchOceanDatas[Y].SegmentDatas;

	return BinaryGetSearchData(SegmentDatas, X, GridPosX, GridPosY);
}

bool UPiratesGridTypeManager::GetOceanSearchShoreData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY)
{
	uint16 X = FMath::FloorToInt((WorldPosX + WorldSizeX * 0.5f) / GridSizeX / OceanSearchShoreUnitScale);
	uint16 Y = FMath::FloorToInt((WorldPosY + WorldSizeY * 0.5f) / GridSizeY / OceanSearchShoreUnitScale);

	check((X >= 0) && ((int32)X < GridCountX / OceanSearchShoreUnitScale));
	check((Y >= 0) && ((int32)Y < LineOceanSearchShoreDatas.Num()));
	TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas = LineOceanSearchShoreDatas[Y].SegmentDatas;

	return BinaryGetSearchData(SegmentDatas, X, GridPosX, GridPosY);
}

bool UPiratesGridTypeManager::GetLandSearchOceanData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY)
{
	uint16 X = FMath::FloorToInt((WorldPosX + WorldSizeX * 0.5f) / GridSizeX / LandSearchOceanUnitScale);
	uint16 Y = FMath::FloorToInt((WorldPosY + WorldSizeY * 0.5f) / GridSizeY / LandSearchOceanUnitScale);

	check((X >= 0) && ((int32)X < GridCountX / LandSearchOceanUnitScale));
	check((Y >= 0) && ((int32)Y < LineLandSearchOceanDatas.Num()));
	TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas = LineLandSearchOceanDatas[Y].SegmentDatas;

	return BinaryGetSearchData(SegmentDatas, X, GridPosX, GridPosY);
}

bool UPiratesGridTypeManager::GetOceanSearchLandData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY)
{
	uint16 X = FMath::FloorToInt((WorldPosX + WorldSizeX * 0.5f) / GridSizeX / OceanSearchLandUnitScale);
	uint16 Y = FMath::FloorToInt((WorldPosY + WorldSizeY * 0.5f) / GridSizeY / OceanSearchLandUnitScale);

	check((X >= 0) && ((int32)X < GridCountX / OceanSearchLandUnitScale));
	check((Y >= 0) && ((int32)Y < LineOceanSearchLandDatas.Num()));
	TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas = LineOceanSearchLandDatas[Y].SegmentDatas;

	return BinaryGetSearchData(SegmentDatas, X, GridPosX, GridPosY);
}

bool UPiratesGridTypeManager::GetLakeSearchShoreData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY)
{
	uint16 X = FMath::FloorToInt((WorldPosX + WorldSizeX * 0.5f) / GridSizeX / LakeSearchShoreUnitScale);
	uint16 Y = FMath::FloorToInt((WorldPosY + WorldSizeY * 0.5f) / GridSizeY / LakeSearchShoreUnitScale);

	check((X >= 0) && ((int32)X < GridCountX / LakeSearchShoreUnitScale));
	check((Y >= 0) && ((int32)Y < LineLakeSearchShoreDatas.Num()));
	TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas = LineLakeSearchShoreDatas[Y].SegmentDatas;

	return BinaryGetSearchData(SegmentDatas, X, GridPosX, GridPosY);
}

FVector2D UPiratesGridTypeManager::GetRandomPosition(float LandProb, bool LandIDEqual)
{
	if (!bHasInited || (LandRandomDatas.Num() < 1) || (OceanRandomDatas.Num() < 1))
	{
		UE_LOG(LogPiratesGridTypeManager, Error, TEXT("UPiratesGridTypeManager::GetRandomPosition Error not inited or no random data."));

		return FVector2D::ZeroVector;
	}

	float Prob = FMath::RandRange(0.0f, 1.0f);
	FGridPos GridPos;

	if (Prob <= LandProb)
	{
		if (LandIDEqual)
		{
			if (LandIDGroupedRandomDatas.Num() > 0)
			{
				// Random a land ID
				int32 LandIDProb = FMath::RandRange(0, (LandIDGroupedRandomDatas.Num() - 1));
				TMap<uint8, TArray<UPiratesGridTypeManager::FGridPos>>::TConstIterator ItLandPos(LandIDGroupedRandomDatas);
				for (int32 ItCount = 0; ItCount < LandIDProb; ItCount++)
				{
					++ItLandPos;
				}
				check(ItLandPos);

				// Random a pos in the pos list with the same ID
				const TArray<UPiratesGridTypeManager::FGridPos>& PosesWithSameID = ItLandPos.Value();
				check(PosesWithSameID.Num() > 0);
				int32 PosProb = FMath::RandRange(0, (PosesWithSameID.Num() - 1));

				GridPos = PosesWithSameID[PosProb];
			}
			else
			{
				UE_LOG(LogPiratesGridTypeManager, Warning, TEXT("UPiratesGridTypeManager::GetRandomPosition None Land ID Grouped Random Datas."));
			}
		}
		else
		{
			if (LandRandomDatas.Num() > 0)
			{
				GridPos = LandRandomDatas[FMath::RandRange(0, LandRandomDatas.Num() - 1)];
			}
			else
			{
				UE_LOG(LogPiratesGridTypeManager, Warning, TEXT("UPiratesGridTypeManager::GetRandomPosition None Land Random Datas."));
			}
		}
	}
	else
	{
		if (OceanRandomDatas.Num() > 0)
		{
			GridPos = OceanRandomDatas[FMath::RandRange(0, OceanRandomDatas.Num() - 1)];
		}
		else
		{
			UE_LOG(LogPiratesGridTypeManager, Warning, TEXT("UPiratesGridTypeManager::GetRandomPosition None Ocean Random Datas."));
		}
	}

	//check(LineRandomIndexes.Num() > 0);
	//check(LineRandomIndexes.Num() < LineRandomDatas.Num());
	//int32 RandomLineIndex = LineRandomIndexes[FMath::RandRange(0, LineRandomIndexes.Num() - 1)];
 //   check((RandomLineIndex >= 0) && (RandomLineIndex < LineRandomDatas.Num()));
	//int32 RandomSegIndex = FMath::RandRange(0, LineRandomDatas[RandomLineIndex].SegmentDatas.Num() - 1);
 //   check((RandomSegIndex >= 0) && (RandomSegIndex < LineRandomDatas[RandomLineIndex].SegmentDatas.Num()));
	//int32 RandomSegLength = FMath::RandRange(0, LineRandomDatas[RandomLineIndex].SegmentDatas[RandomSegIndex].Length - 1);

	FVector2D Pos;
	//check((LineRandomDatas[RandomLineIndex].SegmentDatas[RandomSegIndex].StartPos + RandomSegLength) >= 0);
	//check((LineRandomDatas[RandomLineIndex].SegmentDatas[RandomSegIndex].StartPos + RandomSegLength) < WorldSizeX);
	Pos.X = -WorldSizeX * 0.5f + GridPos.X * GridSizeX + GridSizeY * 0.5f;
	Pos.Y = -WorldSizeY * 0.5f + GridPos.Y * GridSizeY + GridSizeY * 0.5f;

	return Pos;
}

bool UPiratesGridTypeManager::GetMarkPositions(uint8 LandID, EPiratesGridRegionType RegionType, TArray<FVector2D>& PosList)
{
	if (!bHasInited || (LandID < 1) || (LandIDGroupedShorePos.Num() < LandID) || (LandIDGroupedPortPos.Num() < LandID))
	{
		UE_LOG(LogPiratesGridTypeManager, Error, TEXT("UPiratesGridTypeManager::GetMarkPositions Error not inited or no mark pos data. (bHasInited: %d, LandID: %d, LandIDGroupedShorePos Num: %d, LandIDGroupedPortPos Num: %d)"), bHasInited, LandID, LandIDGroupedShorePos.Num(), LandIDGroupedPortPos.Num());

		return false;
	}

	if ((EPiratesGridRegionType::Land == RegionType) || (EPiratesGridRegionType::Shore == RegionType))
	{
		for (int i = 0; i < LandIDGroupedShorePos[LandID - 1].Num(); i++)
		{
			FVector2D Pos;
			Pos.X = -WorldSizeX * 0.5f + LandIDGroupedShorePos[LandID - 1][i].X * GridSizeX + GridSizeY * 0.5f;
			Pos.Y = -WorldSizeY * 0.5f + LandIDGroupedShorePos[LandID - 1][i].Y * GridSizeY + GridSizeY * 0.5f;

			PosList.Add(Pos);
		}
	}
	else
	{
		for (int i = 0; i < LandIDGroupedPortPos[LandID - 1].Num(); i++)
		{
			FVector2D Pos;
			Pos.X = -WorldSizeX * 0.5f + LandIDGroupedPortPos[LandID - 1][i].X * GridSizeX + GridSizeY * 0.5f;
			Pos.Y = -WorldSizeY * 0.5f + LandIDGroupedPortPos[LandID - 1][i].Y * GridSizeY + GridSizeY * 0.5f;

			PosList.Add(Pos);
		}
	}

	return true;
}

void UPiratesGridTypeManager::OnPostLoadMap(UWorld* CurrentWorld)
{
	FString WorldName = CurrentWorld->GetName();

	Load(WorldName);
}

void UPiratesGridTypeManager::OnWorldCleanUp(UWorld* World, bool bSessionEnded, bool bCleanupResources)
{
	Unload();
}

void UPiratesGridTypeManager::GetRegionDataSaveDir(FString& OutDir, const FString AutoSuffix)
{
	FString ExportDir = FPaths::ProjectContentDir() + "GameData/common/gridtype/";
	FString AssetPathString = FSoftObjectPath(GWorld).GetAssetPathString();
	FString PathWithoutSuffix;
	FString Suffix;
	AssetPathString.Split(FString("."), &PathWithoutSuffix, &Suffix);
	FString PreString;
	FString RealName;
	PathWithoutSuffix.Split(FString("/"), &Suffix, &RealName, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
	OutDir = ExportDir + RealName + AutoSuffix + "/";
}

bool UPiratesGridTypeManager::IsPositionValid(float X, float Y)
{
	return ((X >= -WorldSizeX * 0.5f) &&(X < WorldSizeX * 0.5f) &&
		(Y >= -WorldSizeY * 0.5f) && (Y < WorldSizeY * 0.5f));
}

bool UPiratesGridTypeManager::ShowDebugGridType(bool Show, UWorld* World)
{
	if (nullptr == World)
	{
		return false;
	}

	if (bDebugGridType)
	{
		FVector PlayerLoc;
		APlayerController* PC = World->GetFirstPlayerController();
		if (PC->IsValidLowLevel() && PC->GetPawn()->IsValidLowLevel())
		{
			PlayerLoc = PC->GetPawn()->GetActorLocation();

			// Clamp to the center of the grid
			PlayerLoc.X = (FMath::FloorToInt(PlayerLoc.X / GridSizeX) + 0.5f) * GridSizeX;
			PlayerLoc.Y = (FMath::FloorToInt(PlayerLoc.Y / GridSizeY) + 0.5f) * GridSizeY;
		}
		else
		{
			return false;
		}

		// The shore and port region for rendering
		ActorRegionTypeData = World->SpawnActor(AActor::StaticClass());
		check(ActorRegionTypeData != nullptr);

		// Root component
		USceneComponent* RootComponent = NewObject<USceneComponent>(ActorRegionTypeData, USceneComponent::StaticClass());
		check(RootComponent != nullptr);
		RootComponent->RegisterComponent();
		ActorRegionTypeData->SetRootComponent(RootComponent);

		const float RegionTypeZ = 10.0f;
		ActorRegionTypeData->SetActorLocation(FVector(0.0f, 0.0f, RegionTypeZ));

		UMaterial* BaseTranslucentMaterial = LoadObject<UMaterial>(nullptr, TEXT("/Game/Game/Ocean/Materials/M_Debug"));
		check(BaseTranslucentMaterial != nullptr);

		FColor LandColor(127, 127, 127);
		FColor OceanColor(0, 0, 255);
		FColor ShoreColor(255, 255, 0);
		FColor PortColor(0, 255, 0);
		FColor RockColor(255, 0, 0);
		FColor LakeColor(50, 100, 100);
		FColor TransferColor(0, 0, 0);
		FColor ClosestLandColorFromPort(255, 105, 180);
		FColor ClosestOceanColorFromShore(255, 215, 0);
		FColor ClosestOceanColorFromRock(0, 191, 255);
		FColor ClosestOceanColorFromLand(30, 144, 255);
		FColor ClosestLandColorFromOcean(50, 50, 0);

		UMaterialInstanceDynamic* PortMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(PortMaterial != nullptr);
		PortMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(PortColor.R / 255.0f, PortColor.G / 255.0f, PortColor.B / 255.0f)));

		UMaterialInstanceDynamic* ShoreMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(ShoreMaterial != nullptr);
		ShoreMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(ShoreColor.R / 255.0f, ShoreColor.G / 255.0f, ShoreColor.B / 255.0f)));

		UMaterialInstanceDynamic* LandMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(LandMaterial != nullptr);
		LandMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(LandColor.R / 255.0f, LandColor.G / 255.0f, LandColor.B / 255.0f)));

		UMaterialInstanceDynamic* OceanMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(OceanMaterial != nullptr);
		OceanMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(OceanColor.R / 255.0f, OceanColor.G / 255.0f, OceanColor.B / 255.0f)));

		UMaterialInstanceDynamic* RockMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(RockMaterial != nullptr);
		RockMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(RockColor.R / 255.0f, RockColor.G / 255.0f, RockColor.B / 255.0f)));

		UMaterialInstanceDynamic* LakeMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(LakeMaterial != nullptr);
		LakeMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(LakeColor.R / 255.0f, LakeColor.G / 255.0f, LakeColor.B / 255.0f)));


		UMaterialInstanceDynamic* ShoreMarksFromPortMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(ShoreMarksFromPortMaterial != nullptr);
		ShoreMarksFromPortMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(ClosestLandColorFromPort.R / 255.0f, ClosestLandColorFromPort.G / 255.0f, ClosestLandColorFromPort.B / 255.0f)));

		UMaterialInstanceDynamic* PortMarksFromShoreMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(PortMarksFromShoreMaterial != nullptr);
		PortMarksFromShoreMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(ClosestOceanColorFromShore.R / 255.0f, ClosestOceanColorFromShore.G / 255.0f, ClosestOceanColorFromShore.B / 255.0f)));

		UMaterialInstanceDynamic* OceanMarksFromRockMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(OceanMarksFromRockMaterial != nullptr);
		OceanMarksFromRockMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(ClosestOceanColorFromRock.R / 255.0f, ClosestOceanColorFromRock.G / 255.0f, ClosestOceanColorFromRock.B / 255.0f)));

		UMaterialInstanceDynamic* OceanMarksFromLandMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(OceanMarksFromLandMaterial != nullptr);
		OceanMarksFromLandMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(ClosestOceanColorFromLand.R / 255.0f, ClosestOceanColorFromLand.G / 255.0f, ClosestOceanColorFromLand.B / 255.0f)));

		UMaterialInstanceDynamic* LandMarksFromOceanMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(LandMarksFromOceanMaterial != nullptr);
		LandMarksFromOceanMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(ClosestLandColorFromOcean.R / 255.0f, ClosestLandColorFromOcean.G / 255.0f, ClosestLandColorFromOcean.B / 255.0f)));

		UMaterialInstanceDynamic* TransferPosMaterial = UMaterialInstanceDynamic::Create(BaseTranslucentMaterial, ActorRegionTypeData);
		check(TransferPosMaterial != nullptr);
		TransferPosMaterial->SetVectorParameterValue("Color", FLinearColor(FVector(TransferColor.R / 255.0f, TransferColor.G / 255.0f, TransferColor.B / 255.0f)));


		UStaticMesh* MeshPlane = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Plane"));
		check(MeshPlane != nullptr);

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshPort = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshPort != nullptr);
		InstancedStaticMeshPort->RegisterComponent();
		InstancedStaticMeshPort->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshPort->SetStaticMesh(MeshPlane);
		InstancedStaticMeshPort->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshPort->bCastDynamicShadow = false;
		InstancedStaticMeshPort->TranslucencySortPriority = 1;
		for (int32 i = 0; i < InstancedStaticMeshPort->GetNumMaterials(); i++)
		{
			InstancedStaticMeshPort->SetMaterial(i, PortMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshShore = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshShore != nullptr);
		InstancedStaticMeshShore->RegisterComponent();
		InstancedStaticMeshShore->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshShore->SetStaticMesh(MeshPlane);
		InstancedStaticMeshShore->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshShore->bCastDynamicShadow = false;
		InstancedStaticMeshShore->TranslucencySortPriority = 1;
		for (int32 i = 0; i < InstancedStaticMeshShore->GetNumMaterials(); i++)
		{
			InstancedStaticMeshShore->SetMaterial(i, ShoreMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshLand = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshLand != nullptr);
		InstancedStaticMeshLand->RegisterComponent();
		InstancedStaticMeshLand->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshLand->SetStaticMesh(MeshPlane);
		InstancedStaticMeshLand->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshLand->bCastDynamicShadow = false;
		InstancedStaticMeshLand->TranslucencySortPriority = 1;
		for (int32 i = 0; i < InstancedStaticMeshShore->GetNumMaterials(); i++)
		{
			InstancedStaticMeshLand->SetMaterial(i, LandMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshOcean = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshOcean != nullptr);
		InstancedStaticMeshOcean->RegisterComponent();
		InstancedStaticMeshOcean->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshOcean->SetStaticMesh(MeshPlane);
		InstancedStaticMeshOcean->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshOcean->bCastDynamicShadow = false;
		InstancedStaticMeshOcean->TranslucencySortPriority = 1;
		for (int32 i = 0; i < InstancedStaticMeshOcean->GetNumMaterials(); i++)
		{
			InstancedStaticMeshOcean->SetMaterial(i, OceanMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshRock = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshRock != nullptr);
		InstancedStaticMeshRock->RegisterComponent();
		InstancedStaticMeshRock->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshRock->SetStaticMesh(MeshPlane);
		InstancedStaticMeshRock->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshRock->bCastDynamicShadow = false;
		InstancedStaticMeshRock->TranslucencySortPriority = 1;
		for (int32 i = 0; i < InstancedStaticMeshRock->GetNumMaterials(); i++)
		{
			InstancedStaticMeshRock->SetMaterial(i, RockMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshLake = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshLake != nullptr);
		InstancedStaticMeshLake->RegisterComponent();
		InstancedStaticMeshLake->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshLake->SetStaticMesh(MeshPlane);
		InstancedStaticMeshLake->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshLake->bCastDynamicShadow = false;
		InstancedStaticMeshLake->TranslucencySortPriority = 1;
		for (int32 i = 0; i < InstancedStaticMeshLake->GetNumMaterials(); i++)
		{
			InstancedStaticMeshLake->SetMaterial(i, LakeMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshShoreMarksFromPort = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshShoreMarksFromPort != nullptr);
		InstancedStaticMeshShoreMarksFromPort->RegisterComponent();
		InstancedStaticMeshShoreMarksFromPort->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshShoreMarksFromPort->SetStaticMesh(MeshPlane);
		InstancedStaticMeshShoreMarksFromPort->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshShoreMarksFromPort->bCastDynamicShadow = false;
		InstancedStaticMeshShoreMarksFromPort->TranslucencySortPriority = 2;
		for (int32 i = 0; i < InstancedStaticMeshShoreMarksFromPort->GetNumMaterials(); i++)
		{
			InstancedStaticMeshShoreMarksFromPort->SetMaterial(i, ShoreMarksFromPortMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshPortMarksFromShore = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshPortMarksFromShore != nullptr);
		InstancedStaticMeshPortMarksFromShore->RegisterComponent();
		InstancedStaticMeshPortMarksFromShore->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshPortMarksFromShore->SetStaticMesh(MeshPlane);
		InstancedStaticMeshPortMarksFromShore->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshPortMarksFromShore->bCastDynamicShadow = false;
		InstancedStaticMeshPortMarksFromShore->TranslucencySortPriority = 2;
		for (int32 i = 0; i < InstancedStaticMeshPortMarksFromShore->GetNumMaterials(); i++)
		{
			InstancedStaticMeshPortMarksFromShore->SetMaterial(i, PortMarksFromShoreMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshOceanMarksFromRock = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshOceanMarksFromRock != nullptr);
		InstancedStaticMeshOceanMarksFromRock->RegisterComponent();
		InstancedStaticMeshOceanMarksFromRock->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshOceanMarksFromRock->SetStaticMesh(MeshPlane);
		InstancedStaticMeshOceanMarksFromRock->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshOceanMarksFromRock->bCastDynamicShadow = false;
		InstancedStaticMeshOceanMarksFromRock->TranslucencySortPriority = 2;
		for (int32 i = 0; i < InstancedStaticMeshOceanMarksFromRock->GetNumMaterials(); i++)
		{
			InstancedStaticMeshOceanMarksFromRock->SetMaterial(i, OceanMarksFromRockMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshOceanMarksFromLand = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshOceanMarksFromLand != nullptr);
		InstancedStaticMeshOceanMarksFromLand->RegisterComponent();
		InstancedStaticMeshOceanMarksFromLand->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshOceanMarksFromLand->SetStaticMesh(MeshPlane);
		InstancedStaticMeshOceanMarksFromLand->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshOceanMarksFromLand->bCastDynamicShadow = false;
		InstancedStaticMeshOceanMarksFromLand->TranslucencySortPriority = 2;
		for (int32 i = 0; i < InstancedStaticMeshOceanMarksFromLand->GetNumMaterials(); i++)
		{
			InstancedStaticMeshOceanMarksFromLand->SetMaterial(i, OceanMarksFromLandMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshLandMarksFromOcean = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshLandMarksFromOcean != nullptr);
		InstancedStaticMeshLandMarksFromOcean->RegisterComponent();
		InstancedStaticMeshLandMarksFromOcean->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshLandMarksFromOcean->SetStaticMesh(MeshPlane);
		InstancedStaticMeshLandMarksFromOcean->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshLandMarksFromOcean->bCastDynamicShadow = false;
		InstancedStaticMeshLandMarksFromOcean->TranslucencySortPriority = 2;
		for (int32 i = 0; i < InstancedStaticMeshLandMarksFromOcean->GetNumMaterials(); i++)
		{
			InstancedStaticMeshLandMarksFromOcean->SetMaterial(i, LandMarksFromOceanMaterial);
		}

		UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshTransferPos = NewObject<UHierarchicalInstancedStaticMeshComponent>(ActorRegionTypeData);
		check(InstancedStaticMeshTransferPos != nullptr);
		InstancedStaticMeshTransferPos->RegisterComponent();
		InstancedStaticMeshTransferPos->AttachToComponent(ActorRegionTypeData->GetRootComponent(), FAttachmentTransformRules(EAttachmentRule::KeepRelative, false));
		InstancedStaticMeshTransferPos->SetStaticMesh(MeshPlane);
		InstancedStaticMeshTransferPos->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
		InstancedStaticMeshTransferPos->bCastDynamicShadow = false;
		InstancedStaticMeshTransferPos->TranslucencySortPriority = 3;
		for (int32 i = 0; i < InstancedStaticMeshTransferPos->GetNumMaterials(); i++)
		{
			InstancedStaticMeshTransferPos->SetMaterial(i, TransferPosMaterial);
		}

		uint16 Step = 1;
		const int32 RangeGridSize = 100;
		TArray<TEnumAsByte<EObjectTypeQuery>>  ObjectTypes;
		ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
		TArray<AActor*> ActorsToIgnore;
		FHitResult HitResult;

		for (int32 i = -RangeGridSize; i < RangeGridSize; i += Step)
		{
			for (int32 j = -RangeGridSize; j < RangeGridSize; j += Step)
			{
				FVector CurPos;
				CurPos.X = PlayerLoc.X + i * GridSizeX;
				CurPos.Y = PlayerLoc.Y + j * GridSizeY;
				CurPos.Z = 0.0f;

				UKismetSystemLibrary::LineTraceSingleForObjects(
					this, FVector(CurPos.X, CurPos.Y, 100000.f),
					FVector(CurPos.X, CurPos.Y, -10.f),
					ObjectTypes, false, ActorsToIgnore,
					EDrawDebugTrace::None, HitResult, true);

				CurPos.Z = (HitResult.bBlockingHit ? (HitResult.ImpactPoint.Z + 0.0f) : 0.0f);

				FTransform InstanceTransform;
				InstanceTransform.SetLocation(CurPos);
				InstanceTransform.SetScale3D(FVector(1.0f, 1.0f, 1.0f) * Step);

				if (EPiratesGridRegionType::Port == GetRegionType(CurPos.X, CurPos.Y))
				{
					InstancedStaticMeshPort->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Shore == GetRegionType(CurPos.X, CurPos.Y))
				{
					InstancedStaticMeshShore->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Land == GetRegionType(CurPos.X, CurPos.Y))
				{
					InstancedStaticMeshLand->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Ocean == GetRegionType(CurPos.X, CurPos.Y))
				{
					InstancedStaticMeshOcean->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Rock == GetRegionType(CurPos.X, CurPos.Y))
				{
					InstancedStaticMeshRock->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Lake == GetRegionType(CurPos.X, CurPos.Y))
				{
					InstancedStaticMeshLake->AddInstance(InstanceTransform);
				}
			}
		}

		// Port extend size
		int32 SearchDataEXtend = 50;
		FTransform InstanceTransform;
		InstanceTransform.SetScale3D(FVector(1.0f, 1.0f, 1.0f) * Step);

		// Mark search data
		for (int32 i = -(RangeGridSize + SearchDataEXtend); i < (RangeGridSize + SearchDataEXtend); i += Step)
		{
			for (int32 j = -(RangeGridSize + SearchDataEXtend); j < (RangeGridSize + SearchDataEXtend); j += Step)
			{
				FVector CurPos;
				CurPos.X = PlayerLoc.X + i * GridSizeX;
				CurPos.Y = PlayerLoc.Y + j * GridSizeY;
				CurPos.Z = 0.0f;

				if (EPiratesGridRegionType::Shore == GetRegionType(CurPos.X, CurPos.Y))
				{
					uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
					uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
					GetShoreSearchPortData(CurPos.X, CurPos.Y, GridPosX, GridPosY);

					check(GridPosX < GridCountX);
					check(GridPosY < GridCountY);

					FVector OutLocation;
					OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
					OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

					UKismetSystemLibrary::LineTraceSingleForObjects(
						this, FVector(OutLocation.X, OutLocation.Y, 100000.f),
						FVector(OutLocation.X, OutLocation.Y, -10.f),
						ObjectTypes, false, ActorsToIgnore,
						EDrawDebugTrace::None, HitResult, true);

					OutLocation.Z = (HitResult.bBlockingHit ? (HitResult.ImpactPoint.Z + 0.0f) : 0.0f);

					InstanceTransform.SetLocation(OutLocation);

					InstancedStaticMeshPortMarksFromShore->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Port == GetRegionType(CurPos.X, CurPos.Y))
				{
					uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
					uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
					GetPortSearchShoreData(CurPos.X, CurPos.Y, GridPosX, GridPosY);

					check(GridPosX < GridCountX);
					check(GridPosY < GridCountY);

					FVector OutLocation;
					OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
					OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

					UKismetSystemLibrary::LineTraceSingleForObjects(
						this, FVector(OutLocation.X, OutLocation.Y, 100000.f),
						FVector(OutLocation.X, OutLocation.Y, -10.f),
						ObjectTypes, false, ActorsToIgnore,
						EDrawDebugTrace::None, HitResult, true);

					OutLocation.Z = (HitResult.bBlockingHit ? (HitResult.ImpactPoint.Z + 0.0f) : 0.0f);

					InstanceTransform.SetLocation(OutLocation);

					InstancedStaticMeshShoreMarksFromPort->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Rock == GetRegionType(CurPos.X, CurPos.Y))
				{
					uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
					uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
					GetRockSearchOceanData(CurPos.X, CurPos.Y, GridPosX, GridPosY);

					check(GridPosX < GridCountX);
					check(GridPosY < GridCountY);

					FVector OutLocation;
					OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
					OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

					UKismetSystemLibrary::LineTraceSingleForObjects(
						this, FVector(OutLocation.X, OutLocation.Y, 100000.f),
						FVector(OutLocation.X, OutLocation.Y, -10.f),
						ObjectTypes, false, ActorsToIgnore,
						EDrawDebugTrace::None, HitResult, true);

					OutLocation.Z = (HitResult.bBlockingHit ? (HitResult.ImpactPoint.Z + 0.0f) : 0.0f);

					InstanceTransform.SetLocation(OutLocation);

					InstancedStaticMeshOceanMarksFromRock->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Land == GetRegionType(CurPos.X, CurPos.Y))
				{
					uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
					uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
					GetLandSearchOceanData(CurPos.X, CurPos.Y, GridPosX, GridPosY);

					check(GridPosX < GridCountX);
					check(GridPosY < GridCountY);

					FVector OutLocation;
					OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
					OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

					UKismetSystemLibrary::LineTraceSingleForObjects(
						this, FVector(OutLocation.X, OutLocation.Y, 100000.f),
						FVector(OutLocation.X, OutLocation.Y, -10.f),
						ObjectTypes, false, ActorsToIgnore,
						EDrawDebugTrace::None, HitResult, true);

					OutLocation.Z = (HitResult.bBlockingHit ? (HitResult.ImpactPoint.Z + 0.0f) : 0.0f);

					InstanceTransform.SetLocation(OutLocation);

					InstancedStaticMeshOceanMarksFromLand->AddInstance(InstanceTransform);
				}
				else if (EPiratesGridRegionType::Ocean == GetRegionType(CurPos.X, CurPos.Y))
				{
					uint16 GridPosX = GRIDTYPE_MAX_GRID_INDEX;
					uint16 GridPosY = GRIDTYPE_MAX_GRID_INDEX;
					GetOceanSearchLandData(CurPos.X, CurPos.Y, GridPosX, GridPosY);

					check(GridPosX < GridCountX);
					check(GridPosY < GridCountY);

					FVector OutLocation;
					OutLocation.X = (GridPosX + 0.5) *  GridSizeX - WorldSizeX * 0.5f;
					OutLocation.Y = (GridPosY + 0.5) *  GridSizeY - WorldSizeX * 0.5f;

					UKismetSystemLibrary::LineTraceSingleForObjects(
						this, FVector(OutLocation.X, OutLocation.Y, 100000.f),
						FVector(OutLocation.X, OutLocation.Y, -10.f),
						ObjectTypes, false, ActorsToIgnore,
						EDrawDebugTrace::None, HitResult, true);

					OutLocation.Z = (HitResult.bBlockingHit ? (HitResult.ImpactPoint.Z + 0.0f) : 0.0f);

					InstanceTransform.SetLocation(OutLocation);

					InstancedStaticMeshLandMarksFromOcean->AddInstance(InstanceTransform);
				}

			}
		}

		// Mark transfer pos
		check(LandIDGroupedShorePos.Num() == LandIDGroupedPortPos.Num());
		for (int32 i = 0; i < LandIDGroupedShorePos.Num(); i++)
		{
			check(LandIDGroupedShorePos[i].Num() == LandIDGroupedPortPos[i].Num());
			for (int32 j = 0; j < LandIDGroupedShorePos[i].Num(); j++)
			{
				FVector ShorePos;
				ShorePos.X = -WorldSizeX * 0.5f + LandIDGroupedShorePos[i][j].X * GridSizeX + GridSizeY * 0.5f;
				ShorePos.Y = -WorldSizeY * 0.5f + LandIDGroupedShorePos[i][j].Y * GridSizeY + GridSizeY * 0.5f;

				UKismetSystemLibrary::LineTraceSingleForObjects(
					this, FVector(ShorePos.X, ShorePos.Y, 100000.f),
					FVector(ShorePos.X, ShorePos.Y, -10.f),
					ObjectTypes, false, ActorsToIgnore,
					EDrawDebugTrace::None, HitResult, true);

				ShorePos.Z = (HitResult.bBlockingHit ? (HitResult.ImpactPoint.Z + 0.0f) : 0.0f);

				InstanceTransform.SetLocation(ShorePos);
				InstancedStaticMeshTransferPos->AddInstance(InstanceTransform);

				FVector PortPos;
				PortPos.X = -WorldSizeX * 0.5f + LandIDGroupedPortPos[i][j].X * GridSizeX + GridSizeY * 0.5f;
				PortPos.Y = -WorldSizeY * 0.5f + LandIDGroupedPortPos[i][j].Y * GridSizeY + GridSizeY * 0.5f;

				UKismetSystemLibrary::LineTraceSingleForObjects(
					this, FVector(PortPos.X, PortPos.Y, 100000.f),
					FVector(PortPos.X, PortPos.Y, -10.f),
					ObjectTypes, false, ActorsToIgnore,
					EDrawDebugTrace::None, HitResult, true);

				PortPos.Z = (HitResult.bBlockingHit ? (HitResult.ImpactPoint.Z + 0.0f) : 0.0f);

				InstanceTransform.SetLocation(PortPos);
				InstancedStaticMeshTransferPos->AddInstance(InstanceTransform);
			}
		}

	}
	else
	{
		if (ActorRegionTypeData->IsValidLowLevel())
		{
			// Destroy the temp region type actor
			World->DestroyActor(ActorRegionTypeData);
		}
	}

	return true;
}

///////////////////////////////////////////////////////////////////////////////////////
void UPiratesGridTypeManager::AddActor(AActor* Actor)
{
    for (int ii = 0; ii < ActorInfos.Num(); ii++)
    {
        if (Actor == ActorInfos[ii].Actor.Get())
        {
            return;
        }
    }

    ActorInfos.AddDefaulted();
    FActorInfo& Info = ActorInfos.Last();
    Info.Actor = Actor;
    Actor->OnDestroyed.AddDynamic(this, &UPiratesGridTypeManager::OnActorDestroyed);
}

void UPiratesGridTypeManager::RemoveActor(AActor* Actor)
{
    int FindIndex = -1;
    for (int ii = 0; ii < ActorInfos.Num(); ii++)
    {
        if (Actor == ActorInfos[ii].Actor.Get())
        {
            FindIndex = ii;
            break;
        }
    }
    if (FindIndex < 0)
    {
        return;
    }

    Actor->OnDestroyed.RemoveDynamic(this, &UPiratesGridTypeManager::OnActorDestroyed);
    auto Type = ActorInfos[FindIndex].RigionType;
    ActorInfos.RemoveAt(FindIndex);
    if (Type != EPiratesGridRegionType::Unknown)
    {
        OnGridTypeChanged(Actor, EPiratesGridRegionType::Unknown);
    }
}

void UPiratesGridTypeManager::SetUpdateInterval(float Interval)
{
    UpdateInterval = Interval;
}

void UPiratesGridTypeManager::Update(float DeltaTime)
{
    bool bExecute = false;
    CurrentTime += DeltaTime;
    while (CurrentTime >= UpdateInterval)
    {
        bExecute = true;
        CurrentTime -= UpdateInterval;
    }
    if (!bExecute)
    {
        return;
    }

    for (int ii = 0; ii < ActorInfos.Num(); )
    {
        auto& Info = ActorInfos[ii];
        AActor* Actor = Info.Actor.Get();
        if (!Actor)
        {
            ActorInfos.RemoveAt(ii);
            continue;
        }

        FVector Location = Actor->GetActorLocation();
        auto Type = GetRegionType(Location.X, Location.Y);
        if (Info.RigionType != Type)
        {
            Info.RigionType = Type;
            OnGridTypeChanged(Actor, Type);
        }
        ++ii;
    }
}

void UPiratesGridTypeManager::ClearActorInfos()
{
    for (int ii = 0; ii < ActorInfos.Num(); ii++)
    {
        auto& Info = ActorInfos[ii];
        if (Info.Actor.IsValid())
        {
            Info.Actor->OnDestroyed.RemoveDynamic(this, &UPiratesGridTypeManager::OnActorDestroyed);
        }
    }

    ActorInfos.Empty();
    CurrentTime = 0.0f;
}

void UPiratesGridTypeManager::OnActorDestroyed(AActor* ActorToDestroy)
{
    RemoveActor(ActorToDestroy);
}

void UPiratesGridTypeManager::OnGridTypeChanged(AActor* Actor, EPiratesGridRegionType Type)
{
    if (!Actor)
    {
        return;
    }

    auto GameDelegateManager = Cast<UGameCommon>(GetOuter())->GetGameDelegateManager();
    if (GameDelegateManager)
    {
        GameDelegateManager->GameMisc->OnActorGridTypeChanged.ExecuteIfBound(Actor->GetUniqueID(), Type);
    }
}
