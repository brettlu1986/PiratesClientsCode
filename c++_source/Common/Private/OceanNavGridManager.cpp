#include "OceanNavGridManager.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "MapNavGridAsyncPathFindingManager.h"


//const FString FOceanNavGridData::RootDirectory = FPaths::ProjectContentDir() + "GameDataGenerated/common/navigation/";
const FString FOceanNavGridData::GridCostFileName = "grid_cost.config";
const FString FOceanNavGridData::GridInfoFileName = "nav_grid_info.data";


bool FOceanNavGridData::Load(const FString& MapName)
{
    if (CurrentMapName == MapName)
    {
        return true;
    }
    
    FString RootDirectory = FPaths::ProjectContentDir() + "GameDataGenerated/common/navigation/";
    FString MapDirectory = RootDirectory + MapName + "/";
    if (!IFileManager::Get().DirectoryExists(*MapDirectory))
    {
        return false;
    }

    FString GridCostFilePath = RootDirectory + GridCostFileName;
    if (IFileManager::Get().FileExists(*GridCostFilePath))
    {
        FString JsonString;
        if (!FFileHelper::LoadFileToString(JsonString, *GridCostFilePath))
        {
            return false;
        }

        TSharedPtr<FJsonObject> JsonObject;
        TSharedRef<TJsonReader<TCHAR>> Reader = TJsonReaderFactory<>::Create(JsonString);
        if (!FJsonSerializer::Deserialize(Reader, JsonObject))
        {
            return false;
        }

        float ObliqueFactor = (float)JsonObject->GetNumberField("ObliqueFactor");
        if (ObliqueFactor < 1.f)
        {
            return false;
        }

        auto& JsonDirectCostArray = JsonObject->GetArrayField("DirectCost");
        int32 DirectN = JsonDirectCostArray.Num();

        TArray<float>& DirectCost = GridCost.Direct;
        DirectCost.Reset(DirectN);
        TArray<float>& ObliqueCost = GridCost.Oblique;
        ObliqueCost.Reset(DirectN);

        for (const auto& item : JsonDirectCostArray)
        {
            float Cost = (float)item->AsNumber();

            DirectCost.Emplace(Cost);
            ObliqueCost.Emplace(Cost * ObliqueFactor);
        }

        auto& JsonTurnFactorArray = JsonObject->GetArrayField("TurnFactor");
        int TurnFactorN = JsonTurnFactorArray.Num();
        if (TurnFactorN != 5)
        {
            return false;
        }

        TArray<float>& TurnFactor = GridCost.TurnFactor;
        for (const auto& item : JsonTurnFactorArray)
        {
            TurnFactor.Emplace((float)item->AsNumber());
        }
    }
    else
    {
        return false;
    }

    FString NavInfoPath = MapDirectory + GridInfoFileName;
    if (IFileManager::Get().FileExists(*NavInfoPath))
    {
        bool bSuccess = false;
        do
        {
            FString JsonString;
            if (!FFileHelper::LoadFileToString(JsonString, *NavInfoPath))
            {
                break;
            }

            TSharedPtr<FJsonObject> JsonObject;
            TSharedRef<TJsonReader<TCHAR>> Reader = TJsonReaderFactory<>::Create(JsonString);
            if (!FJsonSerializer::Deserialize(Reader, JsonObject))
            {
                break;
            }

            float MapMinX = (float)(JsonObject->GetNumberField("MapMinX"));
            float MapMaxX = (float)(JsonObject->GetNumberField("MapMaxX"));
            float MapMinY = (float)(JsonObject->GetNumberField("MapMinY"));
            float MapMaxY = (float)(JsonObject->GetNumberField("MapMaxY"));

            auto& JsonGridLengthArray = JsonObject->GetArrayField("GridLength");
            int32 N = JsonGridLengthArray.Num();

            GridLengths.Empty(N);
            for (auto& i : JsonGridLengthArray)
            {
                GridLengths.Emplace((float)(i->AsNumber()));
            }

            TArray<FString> DataFilePath;
            auto& JsonDataFilePathArray = JsonObject->GetArrayField("DataFilePath");
            if (JsonDataFilePathArray.Num() != N)
            {
                break;
            }

            for (auto& i : JsonDataFilePathArray)
            {
                DataFilePath.Emplace(i->AsString());
            }

            GridLayouts.Empty(N);
            PathFindings.Empty(N);
            for (int32 i = 0; i < N; ++i)
            {
                GridLayouts.Emplace();
                if (!GridLayouts[i].Init(MapMinX, MapMinY, MapMaxX, MapMaxY, GridLengths[i]))
                {
                    return false;
                }
                if (!GridLayouts[i].LoadGridsFromFile(MapDirectory + DataFilePath[i]))
                {
                    return false;
                }

                PathFindings.Emplace();
                if (!PathFindings[i].Init(GridLayouts.GetData() + i, &GridCost))
                {
                    return false;
                }
            }

            bSuccess = true;

        } while (false);

        if (!bSuccess)
        {
            return false;
        }
    }

    CurrentMapName = MapName;
    return true;
}

FMapNavGridLayout* FOceanNavGridData::GetGridLayout(float NavAgentRadius)
{
    NavAgentRadius *= 2.f;

    int32 N = GridLengths.Num();
    for (int32 i = 0; i < N; ++i)
    {
        const float& GridLength = GridLengths[i];
        if (NavAgentRadius <= GridLength)
        {
            return &(GridLayouts[i]);
        }
    }

    return &(GridLayouts[N - 1]);
}

FMapNavGridPathFinding* FOceanNavGridData::GetPathFinding(float NavAgentRadius)
{
    NavAgentRadius *= 2.f;

    int32 N = GridLengths.Num();
    for (int32 i = 0; i < N; ++i)
    {
        const float& GridLength = GridLengths[i];
        if (NavAgentRadius <= GridLength)
        {
            return &(PathFindings[i]);
        }
    }

    return &(PathFindings[N - 1]);
}

void UOceanNavGridManager::Init()
{
    CurrentData = nullptr;
    FCoreUObjectDelegates::PreLoadMap.AddUObject(this, &UOceanNavGridManager::OnPreLoadMap);
}

void UOceanNavGridManager::Clear()
{
    FCoreUObjectDelegates::PreLoadMap.RemoveAll(this);
    AsyncPathFindingManager.Clear();
}

float UOceanNavGridManager::GetNavDistInOcean(float NavAgentRadius, const FVector& StartLocation, const FVector& EndLocation)
{
	if (!CurrentData)
	{
		return -1.0f;
	}
	auto PathFinding = CurrentData->GetPathFinding(NavAgentRadius);
	check(PathFinding != nullptr);

	TArray<FVector> NavPath;
	FMapNavGridPathFinding::EResult Result = PathFinding->FindPathSync(StartLocation, nullptr, EndLocation, NavPath);
	if (Result == FMapNavGridPathFinding::EResult::Successful)
	{
		float Dist = 0.f;
		FVector PrevLocation = StartLocation;

		for (auto& loc : NavPath)
		{
			Dist += (loc - PrevLocation).Size2D();
			PrevLocation = loc;
		}

		return Dist;
	}

	return -1.0f;
}

bool UOceanNavGridManager::GetNearestSafeLocation(float NavAgentRadius, float SearchRadius, const FVector& InLocation, FVector& OutLocation)
{
    FMapNavGridLayout* GridLayout = GetGridLayout(NavAgentRadius);
    if (GridLayout == nullptr)
    {
        return false;
    }

    return GridLayout->GetNearestLocation(InLocation, SearchRadius, EMapNavGridType::BlockEdge, OutLocation);
}

FMapNavGridLayout* UOceanNavGridManager::GetGridLayout(float NavAgentRadius)
{
    if (CurrentData == nullptr)
    {
        return nullptr;
    }

    return CurrentData->GetGridLayout(NavAgentRadius);
}

FMapNavGridPathFinding * UOceanNavGridManager::GetPathFinding(float NavAgentRadius)
{
    if (CurrentData == nullptr)
    {
        return nullptr;
    }

    return CurrentData->GetPathFinding(NavAgentRadius);
}

FMapNavGridCost* UOceanNavGridManager::GetGridCost()
{
    if (CurrentData == nullptr)
    {
        return nullptr;
    }
    
    return CurrentData->GetGridCost();
}

void UOceanNavGridManager::OnPreLoadMap(const FString& InMapName)
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

    if (DungeonData.Load(MapName))
    {
        CurrentData = &DungeonData;
    }
    else
    {
        CurrentData = nullptr;
    }
}

