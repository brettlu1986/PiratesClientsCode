#pragma once

#include "CoreMinimal.h"
#include "Math/GenericOctree.h"
#include "AI/DestructibleObject/AIDoor.h"
#include "AI/DestructibleObject/AISpacePartitionalOctree.h"
#include "AI/DestructibleObject/AISpacePartitionalManager.h"
#include "AIDoorExporter.generated.h"

UCLASS(BlueprintType, Blueprintable)
class COMMON_API UAIDoorExporter : public UObject
{
    GENERATED_UCLASS_BODY()

public:

    UFUNCTION(BlueprintCallable, Category = "Export", meta = (CallInEditor = "true"))
    static bool Export(const FString& LevelName, const TArray<int32>& DoorIds, const FString& SaveDir, bool bVerbose = false);

};
