// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Json.h"
#include "PiratesGridTypeManager.generated.h"

#define REGIONTYPE_FILE_NAME "regiontype.data"
#define GRIDTYPE_MAX_GRID_INDEX 65535
#define GRIDTYPE_INVALID_LAND_ID 0
#define CURRENT_FILE_VERSION 4
#define LANDIDNAME_FILE_NAME "regiontype_land_id_name.tab"
#define UNKNOW_LANDNAME "unknow_land_name"

/**
* The type of the region
*/
UENUM(BlueprintType)
enum class EPiratesGridRegionType : uint8
{
	Unknown = 0 UMETA(DisplayName="Unknown"),
	Land UMETA(DisplayName = "Land"),
	Ocean UMETA(DisplayName = "Ocean"),
	Shore UMETA(DisplayName = "Shore"),
	Port UMETA(DisplayName = "Port"),
	Rock UMETA(DisplayName = "Rock"),
	Lake UMETA(DisplayName = "Lake"),
	MaxRegionType UMETA(DisplayName = "MaxRegionType"),
};

/**
* The manager of the grid type datas
*/

UCLASS()
class COMMON_API UPiratesGridTypeManager : public UObject
{
    GENERATED_UCLASS_BODY()
public:
    bool Init();

    bool Uninit();

    bool Load(const FString& WorldName);

	bool Unload();

    void OnWorldChanged(UWorld* NewWorld);

	/** Get file save dir */
	static void GetRegionDataSaveDir(FString& OutDir, const FString AutoSuffix = FString(""));

	/** Get the region type of the specified pos */
    UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
	EPiratesGridRegionType GetRegionType(float PosX, float PosY);

	/** Get the region type of the specified pos */
	UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
	uint8 GetLandID(float PosX, float PosY);

	/** Get the region name of the specified pos */
	UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
	FString GetRegionName(float PosX, float PosY);

	/** Get the closest pos of specified region type and the pos */
	UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
	bool GetClosestPositionOfRegionType(float PosX, float PosY, EPiratesGridRegionType RegionType, FVector2D& OutLocation);

	/** Get the a random pos */
	UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
	FVector2D GetRandomPosition(float LandProb = 0.5f, bool LandIDEqual = false);

	/** Get the mark pos of land or shore */
	UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
	bool GetMarkPositions(uint8 LandID, EPiratesGridRegionType RegionType, TArray<FVector2D>& PosList);

public:

	/** Show debug grid type */
	bool ShowDebugGridType(bool Show, UWorld* World);

public:

	/**
	* Data of a segment of the one world map line
	*/
	struct FSegmentTypeData
	{
		uint16 StartPos;
		uint16 Length;
		EPiratesGridRegionType Type;

		FSegmentTypeData() :StartPos(0),
			Length(0),
			Type(EPiratesGridRegionType::Unknown)
		{
		};

		~FSegmentTypeData()
		{};

        void ToJsonObject(TSharedRef<FJsonObject>& JsonObject) const
        {
            JsonObject->SetNumberField("StartPos", StartPos);
            JsonObject->SetNumberField("Length", Length);
            JsonObject->SetNumberField("Type", int32(Type));
        }
	};

	/**
	* Data of a line of the one world map
	*/
	struct FLineTypeData
	{
		TArray<FSegmentTypeData> SegmentDatas;

		FLineTypeData()
		{
		};

		~FLineTypeData()
		{};

        void ToJsonObject(TSharedRef<FJsonObject>& JsonObject) const
        {
            TArray< TSharedPtr<FJsonValue> > JsonSegmentDatas;
            for (size_t i = 0; i < SegmentDatas.Num(); i++)
            {
                TSharedRef<FJsonObject> JsonSegmentData = MakeShareable(new FJsonObject);
                SegmentDatas[i].ToJsonObject(JsonSegmentData);
                JsonSegmentDatas.Emplace(MakeShareable(new FJsonValueObject(JsonSegmentData)));
            }
            JsonObject->SetArrayField("SegmentDatas", JsonSegmentDatas);
        }

	};


	/**
	* Data of a segment of the one world map line
	*/
	struct FSegmentRandomData
	{
		uint16 StartPos;
		uint16 Length;

		FSegmentRandomData() : StartPos(0),
			Length(0)
		{
		};

		~FSegmentRandomData()
		{};

	};

	/**
	* Data of a line of the one world map
	*/
	struct FLineRandomData
	{
		TArray<FSegmentRandomData> SegmentDatas;

		FLineRandomData()
		{
		};

		~FLineRandomData()
		{};

	};

	/**
	* Data of a segment of the one world map line
	*/
	struct FSegmentSearchData
	{
		uint16 StartPos;
		uint16 Length;
		uint16 X;
		uint16 Y;

		FSegmentSearchData() : StartPos(0),
			Length(0), X(0), Y(0)
		{
		};

		~FSegmentSearchData()
		{};

	};

	/**
	* Data of a line of the one world map
	*/
	struct FLineSearchData
	{
		TArray<FSegmentSearchData> SegmentDatas;

		FLineSearchData()
		{
		};

		~FLineSearchData()
		{};

	};

	/**
	* Data of a segment of the one world map line
	*/
	struct FSegmentIDData
	{
		uint16 StartPos;
		uint16 Length;
		uint8 ID;

		FSegmentIDData() :StartPos(0),
			Length(0),
			ID(0)
		{
		};

		~FSegmentIDData()
		{};

		void ToJsonObject(TSharedRef<FJsonObject>& JsonObject) const
		{
			JsonObject->SetNumberField("StartPos", StartPos);
			JsonObject->SetNumberField("Length", Length);
			JsonObject->SetNumberField("ID", int32(ID));
		}

	};

	/**
	* Data of a line of the one world map
	*/
	struct FLineIDData
	{
		TArray<FSegmentIDData> SegmentDatas;

		FLineIDData()
		{
		};

		~FLineIDData()
		{};

		void ToJsonObject(TSharedRef<FJsonObject>& JsonObject) const
		{
			TArray< TSharedPtr<FJsonValue> > JsonSegmentDatas;
			for (size_t i = 0; i < SegmentDatas.Num(); i++)
			{
				TSharedRef<FJsonObject> JsonSegmentData = MakeShareable(new FJsonObject);
				SegmentDatas[i].ToJsonObject(JsonSegmentData);
				JsonSegmentDatas.Emplace(MakeShareable(new FJsonValueObject(JsonSegmentData)));
			}
			JsonObject->SetArrayField("SegmentDatas", JsonSegmentDatas);
		}

	};

	/**
	* Data of a pos of grid
	*/
	struct FGridPos
	{
		uint16 X;
		uint16 Y;

		FGridPos() : X(0),
			Y(0)
		{
		};
		FGridPos(uint16 inX, uint16 inY) : X(inX),
			Y(inY)
		{
		};

		~FGridPos()
		{};

		bool operator==(const FGridPos & Other) const
		{
			return (Other.X == X) && (Other.Y == Y);
		}

		bool operator!=(const FGridPos & Other) const
		{
			return (Other.X != X) || (Other.Y != Y);
		}

		void ToJsonObject(TSharedRef<FJsonObject>& JsonObject) const
		{
			JsonObject->SetNumberField("X", X);
			JsonObject->SetNumberField("Y", Y);
		}
	};

protected:

	/** Get the region type of the specified pos */
	EPiratesGridRegionType GetRegionType(uint16 PosX, uint16 PosY);

	/** Get the region ID of the specified pos */
	uint8 GetRegionID(uint16 PosX, uint16 PosY);

	/** Binary get the search data */
	bool BinaryGetSearchData(TArray<UPiratesGridTypeManager::FSegmentSearchData>& SegmentDatas, uint16 PosX, uint16& GridPosX, uint16& GridPosY);

	/** Get the shore search ocean data */
	bool GetShoreSearchPortData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY);

	/** Get the port search land data */
	bool GetPortSearchShoreData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY);

	/** Get the rock search ocean data */
	bool GetRockSearchOceanData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY);

	/** Get the ocean search shore data */
	bool GetOceanSearchShoreData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY);

	/** Get the land search ocean data */
	bool GetLandSearchOceanData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY);

	/** Get the ocean search land data */
	bool GetOceanSearchLandData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY);

	/** Get the lake search shore data */
	bool GetLakeSearchShoreData(float WorldPosX, float WorldPosY, uint16& GridPosX, uint16& GridPosY);

	bool CleanData();

protected:

	// Serialize

	/** File data version */
	uint8 FileDataVersion;

	/** World size of width */
	float WorldSizeX;

	/** World size of height */
	float WorldSizeY;

	/** Grid size width */
	float GridSizeX;

	/** Get size height */
	float GridSizeY;

	/** Grid count width */
	int32 GridCountX;

	/** Grid count height */
	int32 GridCountY;

	/** Compressed region datas */
	TArray<FLineTypeData> LineTypeDatas;

	/** Compressed region datas */
	TArray<FLineIDData> LineIDDatas;

	/** The shore pos grouped by land ID */
	TArray<TArray<FGridPos>> LandIDGroupedShorePos;

	/** The port pos grouped by land ID */
	TArray<TArray<FGridPos>> LandIDGroupedPortPos;

	/** The search data of shore region */
	TArray<FLineSearchData> LineShoreSearchPortDatas;

	/** The search data of port region */
	TArray<FLineSearchData> LinePortSearchShoreDatas;

	/** The search data of port region */
	TArray<FLineSearchData> LineRockSearchOceanDatas;

	/** The search data of shore region */
	TArray<FLineSearchData> LineOceanSearchShoreDatas;

	/** The search data of land region */
	TArray<FLineSearchData> LineLandSearchOceanDatas;

	/** The search data of ocean region */
	TArray<FLineSearchData> LineOceanSearchLandDatas;

	/** The search data of shore region */
	TArray<FLineSearchData> LineLakeSearchShoreDatas;

	///** The world size random data */
	//TArray<FLineRandomData> LineRandomDatas;

	/** The land random data */
	TArray<FGridPos> LandRandomDatas;

	/** The ocean random data */
	TArray<FGridPos> OceanRandomDatas;

	/** The land random data grouped by land ID */
	TMap<uint8, TArray<UPiratesGridTypeManager::FGridPos>> LandIDGroupedRandomDatas;

	/** The index of the line random data */
	TArray<uint16> LineRandomIndexes;

	/** Size of one unit for shore search */
	int32 ShoreSearchPortUnitScale;

	/** Size of one unit for port search */
	int32 PortSearchShoreUnitScale;

	/** Size of one unit for rock search */
	int32 RockSearchOceanUnitScale;

	/** Size of one unit for ocean search */
	int32 OceanSearchShoreUnitScale;

	/** Size of one unit for land search */
	int32 LandSearchOceanUnitScale;

	/** Size of one unit for ocean search */
	int32 OceanSearchLandUnitScale;

	/** Size of one unit for lake search */
	int32 LakeSearchShoreUnitScale;

	/** The scale of region type mark ID */
	int32 RegionTypeMarkIDScale;

	/** The scale of land mark pos*/
	int32 LandMarkPosScale;

	/** The land id name pairs data */
	TMap<uint8, FString> LandIDNames;

	// Delegate

	FDelegateHandle OnPostLoadMapHandle;

	FDelegateHandle OnWorldCleanUpHandle;

	/** Mark inited or not */
	bool bHasInited;

protected:

	// The shore and port region for debug rendering actor
	AActor* ActorRegionTypeData;

protected:

	/** Is the position valid or not */
	bool IsPositionValid(float PosX, float PosY);

private:

	void OnPostLoadMap(UWorld* CurrentWorld);

	void OnWorldCleanUp(UWorld* CurrentWorld, bool bSessionEnded, bool bCleanupResources);

    ///////////////////////////////////////////////////////////////////////////////////////
public:
    UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
    void AddActor(AActor* Actor);

    UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
    void RemoveActor(AActor* Actor);

    UFUNCTION(BlueprintCallable, Category = "PiratesGridTypeManager")
    void SetUpdateInterval(float Interval);

    void Update(float DeltaTime);

private:    
    void ClearActorInfos();
    void OnGridTypeChanged(AActor* Actor, EPiratesGridRegionType Type);

    UFUNCTION()
    void OnActorDestroyed(AActor* ActorToDestroy);

private:
    struct FActorInfo
    {
        TWeakObjectPtr<AActor> Actor;
        int RegionId;
        EPiratesGridRegionType RigionType;

        FActorInfo()
            : RegionId(-1)
            , RigionType(EPiratesGridRegionType::Unknown)
        {}
    };
    TArray<FActorInfo> ActorInfos;
    float CurrentTime;
    float UpdateInterval;
};

static FArchive& operator <<(FArchive& Ar, EPiratesGridRegionType& Ref)
{
	Ar.Serialize(&Ref, sizeof(EPiratesGridRegionType));
	return Ar;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FSegmentTypeData& Ref)
{
	return Ar << Ref.StartPos << Ref.Length << Ref.Type;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FLineTypeData& Ref)
{
	return Ar << Ref.SegmentDatas;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FSegmentRandomData& Ref)
{
	return Ar << Ref.StartPos << Ref.Length;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FLineRandomData& Ref)
{
	return Ar << Ref.SegmentDatas;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FSegmentIDData& Ref)
{
	return Ar << Ref.StartPos << Ref.Length << Ref.ID;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FLineIDData& Ref)
{
	return Ar << Ref.SegmentDatas;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FSegmentSearchData& Ref)
{
	return Ar << Ref.StartPos << Ref.Length << Ref.X << Ref.Y;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FLineSearchData& Ref)
{
	return Ar << Ref.SegmentDatas;
}

static FArchive& operator <<(FArchive& Ar, UPiratesGridTypeManager::FGridPos& Ref)
{
	return Ar << Ref.X << Ref.Y;
}
