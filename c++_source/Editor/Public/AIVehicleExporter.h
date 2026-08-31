#pragma once

#include "AI/Vehicle/AIVehicle.h"
#include "AI/Vehicle/AIVehicleManager.h"
#include "AIVehicleExporter.generated.h"

UCLASS(BlueprintType, Blueprintable)
class EDITOR_API UAIVehicleExporter : public UObject
{
    GENERATED_UCLASS_BODY()

public:

    UFUNCTION(BlueprintCallable, Category = "Export", meta = (CallInEditor = "true"))
    static bool Export(const FString& LevelName, int32 CellSize, const FString& SaveDir, bool bVerbose = false);

};
