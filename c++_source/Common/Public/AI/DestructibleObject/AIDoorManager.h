#pragma once

#include "CoreMinimal.h"
#include "Math/GenericOctree.h"
#include "AI/DestructibleObject/AIDoor.h"
#include "AI/DestructibleObject/AISpacePartitionalOctree.h"
#include "AI/DestructibleObject/AISpacePartitionalManager.h"

typedef AIOctreeSpacePartition<FAIDoor>   FAIDoorOctreeSpacePartition;
typedef AISpacePartitionalManager<FAIDoorOctreeSpacePartition, FAIDoor> AIDoorManagerBase;


class COMMON_API AIDoorManager : public AIDoorManagerBase
{
public:
    static const FString FileExtension;

    virtual FString GetConfigPath(const FString& WorldName) const;
    virtual void OnElementAdded(TSharedPtr<FAIDoor>& Door) override;
    virtual void OnRegionAdded(TSharedPtr<FAIDoorOctreeSpacePartition>& SPC) override;
    virtual bool UnLoad() override;

    void SetInstanceId(int32 TransformId, int32 InstanceId);
protected:
  
    typedef TMap<int32, TSharedPtr<FAIDoor>> DoorMap;
    DoorMap MapOfTransformIdToDoor;
};