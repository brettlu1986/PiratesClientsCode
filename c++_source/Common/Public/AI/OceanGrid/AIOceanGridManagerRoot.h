#pragma once

#include "CoreMinimal.h"
#include "AIOceanGridManager.h"
#include "AIOceanGridCell.h"
#include "AIOceanGridManagerRoot.generated.h"


enum class EAIOceanItemType : uint8
{
    OCEAN_ITEM_TORPEDO = 1,
};

struct FAITorpedo 
{
    TWeakObjectPtr<AActor> TorpedoActor;

    FAITorpedo(AActor* InActor = nullptr) : TorpedoActor(InActor) {}

    static int32 GetItemId() 
    { 
        return (int32)(EAIOceanItemType::OCEAN_ITEM_TORPEDO);
    }
};

UCLASS()
class COMMON_API UAIOceanGridManagerRoot : public UObject
{
public:
    GENERATED_UCLASS_BODY()

    bool Init();
    bool Uninit();

    UFUNCTION(BlueprintCallable, Category = "AIOceanGridManager")
    void InitCells(float Width, float Height, float CenterX, float CenterY, float CellSize);

    UFUNCTION(BlueprintCallable, Category = "AIOceanGridManager")
    bool AddTorpedo(AActor* TorpedoActor);

    UFUNCTION(BlueprintCallable, Category = "AIOceanGridManager")
    bool RemoveTorpedo(int32 UniqueId);

    UFUNCTION(BlueprintCallable, Category = "AIOceanGridManager")
    void FindTorpedo(APawn* Pawn, float SightDist, float SightFOV, UWorld* World, TArray<int32>& OutIds);

    const FAIOceanItem<FAITorpedo>* GetTorpedo(int32 UniqueId) const;

    UFUNCTION(BlueprintCallable, Category = "AIOceanGridManager")
    void Dump();

protected:

    TUniquePtr<AIOceanGridManager>  OceanGridManager;
};