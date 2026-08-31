#pragma once

#include "CoreMinimal.h"
#include "Math/GenericOctree.h"
#include "AI/DestructibleObject/AIDoorManager.h"
#include "AI/DestructibleObject/AIDoor.h"
#include "AIDestructibleObjectManagerRoot.generated.h"

UCLASS()
class COMMON_API UAIDestructibleObjectManagerRoot : public UObject
{
public:
    GENERATED_UCLASS_BODY()

    bool Init();
    bool Uninit();

    void Clear();

    UFUNCTION()
    bool GetDoors(const FVector& Location, float Extent, TArray<int32>& OutDoorInstanceIds);

    UFUNCTION()
    int32 GetNearestDoor(const FVector& Location, float Extent);

    UFUNCTION()
    void SetDoorInstanceId(int32 TransformId, int32 InstanceId);

    UFUNCTION()
    void DumpStat();

protected:
    TUniquePtr<AIDoorManager>  DoorManager;
};