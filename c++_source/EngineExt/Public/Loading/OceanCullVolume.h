#pragma once

#include "OceanCullVolume.generated.h"

UCLASS(BlueprintType, Blueprintable)
class ENGINEEXT_API AOceanCullVolume : public APhysicsVolume
{
	GENERATED_UCLASS_BODY()

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Low|Optimize")
	FString OceanName;

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Low|Optimize")
	float CullDistance;

	bool CheckVolumeInFrustum(UCanvas* Canvas);

private:

};

