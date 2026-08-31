// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "PiratesGridTriggerManager.generated.h"

class UPiratesGameMiscDelegate;

#define DEFAULT_GRID_SIZE_X 100.0f    //单位cm
#define DEFAULT_GRID_SIZE_Y 100.0f    //单位cm

UCLASS()
class COMMON_API UPiratesGridTriggerManager : public UObject
{
    GENERATED_UCLASS_BODY()
public:
    bool Init();
    bool Uninit();
    bool LoadInfo(const FString& WorldName);
    bool UnloadInfo();
    void Update(float DeltaTime);
    UFUNCTION(BlueprintCallable, Category = "PiratesGridTriggerManager")
    void AddActor(AActor* Actor);
    UFUNCTION(BlueprintCallable, Category = "PiratesGridTriggerManager")
    void RemoveActor(AActor* Actor);
    UFUNCTION(BlueprintCallable, Category = "PiratesGridTriggerManager")
    bool CheckActor(AActor* Actor, int VolumeId);
    UFUNCTION(BlueprintCallable, Category = "PiratesGridTriggerManager")
    int32 GetActorVolume(AActor* Actor);

private:
    uint64 LocationVectorToGridIndex(const FVector2D& Location);
    void EnterGrid(TWeakObjectPtr<AActor> Actor, const TArray<int>& GridInfo);
    void LeaveGrid(TWeakObjectPtr<AActor> Actor, const TArray<int>& GridInfo);
    UPiratesGameMiscDelegate* GetGameMiscDelegate();
    void OnPostLoadMap(UWorld* CurrentWorld);
    void OnWorldCleanUp(UWorld* CurrentWorld, bool bSessionEnded, bool bCleanupResources);
    UFUNCTION()
    void OnActorDestroyed(AActor* Actor);

private:
    struct MapBasicInfo
    {
        MapBasicInfo()
            : MapCenterX(0.f)
            , MapCenterY(0.f)
            , TotalCountX(0)
            , TotalCountY(0)
            , MapSizeX(0.f)
            , MapSizeY(0.f)
            , GridSizeX(DEFAULT_GRID_SIZE_X)
            , GridSizeY(DEFAULT_GRID_SIZE_Y) {}

        float MapCenterX;
        float MapCenterY;
        int TotalCountX;
        int TotalCountY;
        float MapSizeX;     //cm
        float MapSizeY;     //cm
        float GridSizeX;    //cm
        float GridSizeY;    //cm
    };

    struct FGridInfo
    {
        TArray<int> VolumnIds;
    };

    struct FActorInfo
    {
        FActorInfo()
            : GridIndex(0) {}
        TWeakObjectPtr<AActor> Actor;
        uint64 GridIndex;
    };
    /**
    * GridIndex - FGridInfo, 其中index从左上角开始，沿X方向增加，计数从1开始
    */
    TMap<uint64, FGridInfo> CurrentGridInfos;
    TArray<FActorInfo> ActorInfos;

    float CurrentTime;
    bool HasInited;

    FDelegateHandle OnPostLoadMapHandle;
    FDelegateHandle OnWorldCleanUpHandle;
    MapBasicInfo BasicInfo;


//////////////////////////////// for editor //////////////////////////////////////////
public:

    static void BeginExport();
    static void EndExport();

    UFUNCTION(BlueprintCallable, Category = "PiratesGridTriggerManager")
    static void RecordExportInfo(AActor* Actor, int VolumeId, FVector2D Center, FVector2D Size, float Yaw);
    UFUNCTION(BlueprintCallable, Category = "PiratesGridTriggerManager")
    static void RecordMapSize(FVector2D MapSize);

private:
    friend class FEditorExporter;
    friend struct FGridTriggerManagerHelper;
};
