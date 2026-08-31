#pragma once

#include "CoreMinimal.h"
#include "Camera/CameraModifier.h"
#include "KMCameraInfoInterface.h"
#include "KMCameraChangeTargetModifier.generated.h"

class UChangeTargetInfo;

UCLASS(config=Camera)
class ENGINEEXT_API UKMCameraChangeTargetModifier : public UCameraModifier, public IKMCameraInfoInterface
{
    GENERATED_BODY()

public:
    UKMCameraChangeTargetModifier(
        const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

    virtual void ApplyCameraInfo(UInfoBase* Info) override;

private:
	UPROPERTY()
	UChangeTargetInfo* TargetInfo;
};