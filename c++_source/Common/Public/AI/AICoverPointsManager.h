#pragma once

#include "CoreMinimal.h"
#include "CoverPoint.h"
#include "CoverPointOctree.h"
#include "AICoverPointsManager.generated.h"

UCLASS()
class COMMON_API UAICoverPointsManager : public UObject
{

    GENERATED_UCLASS_BODY()

public:
    bool Init();
    bool Uninit();
    void Load(const FString& WorldName);
    void UnLoad();
    TArray<UCoverPoint*> GetCoverWithinBounds(const FBoxCenterAndExtent& BoundsIn);
    void AddCoverPointOctree(FCoverPointOctreeProxy* CoverPointOctree);
    virtual void BeginDestroy() override;
    void ParseOneOctree(FArchive& Ar);
    void Update(float DeltaTime);

    UFUNCTION()
    void PrintDebugInfo();

protected:
    void OnPostLoadMap(UWorld* CurrentWorld);
    void OnWorldCleanUp(UWorld* CurrentWorld, bool bSessionEnded, bool bCleanupResources);

    typedef TArray<FCoverPointOctreeProxy*>  CoverPointOctreeContainer;

    UPROPERTY(Transient)
    TArray<UCoverPoint*>  CoverPoints;

    CoverPointOctreeContainer CoverPointOctrees;
    FDelegateHandle OnPostLoadMapHandle;
    FDelegateHandle OnWorldCleanUpHandle;
};