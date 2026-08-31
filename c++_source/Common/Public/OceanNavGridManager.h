#pragma once

#include "MapNavGridLayout.h"
#include "MapNavGridPathFinding.h"
#include "MapNavGridAsyncPathFindingManager.h"
#include "MapNavWaypointGraph.h"
#include "KMObject.h"
#include "OceanNavGridManager.generated.h"


USTRUCT(BlueprintType)
struct FOceanAreaPortData
{
    GENERATED_USTRUCT_BODY()
    
    FOceanAreaPortData()
        : SceneId(0), Distance(0.f)
    {}

    UPROPERTY(Transient)
    int32 SceneId;

    UPROPERTY(Transient)
    float Distance;
};

USTRUCT(BlueprintType)
struct FOceanAreaTeleportPointData
{
    GENERATED_USTRUCT_BODY()

     FOceanAreaTeleportPointData()
        : Id(-1), Distance(0.f)
    {}

    UPROPERTY(Transient)
    int32 Id;

    UPROPERTY(Transient)
    float Distance;
};

class FOceanNavGridData
{
public:

    //const static FString RootDirectory;
    const static FString GridCostFileName;
    const static FString GridInfoFileName;  

public:

    bool Load(const FString& MapName);

    FMapNavGridLayout* GetGridLayout(float NavAgentRadius);

    FMapNavGridPathFinding* GetPathFinding(float NavAgentRadius);

    FMapNavGridCost* GetGridCost() { return &GridCost; }

private:

    TArray<FMapNavGridLayout> GridLayouts;
    TArray<FMapNavGridPathFinding> PathFindings;
    TArray<float> GridLengths;
    FMapNavGridCost GridCost;

    FString CurrentMapName;
};

UCLASS()
class COMMON_API UOceanNavGridManager : public UKMObject
{
    GENERATED_BODY()

public:

    void Init();

    void Clear();

    UFUNCTION()
    float GetNavDistInOcean(float NavAgentRadius, const FVector& StartLocation, const FVector& EndLocation);

    UFUNCTION()
    bool GetNearestSafeLocation(float NavAgentRadius, float SearchRadius, const FVector& InLocation, FVector& OutLocation);

    FMapNavGridLayout* GetGridLayout(float NavAgentRadius);

    FMapNavGridPathFinding* GetPathFinding(float NavAgentRadius);

    FMapNavGridCost* GetGridCost();

    FMapNavGridAsyncPathFindingManager* GetAsyncPathFindingManager() { return &AsyncPathFindingManager; }

private:

    FOceanNavGridData DungeonData;
    FOceanNavGridData* CurrentData;

    FMapNavGridAsyncPathFindingManager AsyncPathFindingManager;

private:

    void OnPreLoadMap(const FString& InMapName);
};