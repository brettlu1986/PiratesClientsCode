#pragma once
#include "CoreMinimal.h"
#include "Camera/CameraModifier.h"
#include "KMCameraInfoInterface.h"
#include "KMCameraArmRotModifier.generated.h"

class UFovInfo;

UCLASS(config = Camera)
class ENGINEEXT_API UKMCameraArmRotModifier : public UCameraModifier, public IKMCameraInfoInterface
{
	GENERATED_BODY()

public:
	UKMCameraArmRotModifier(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

	virtual void ApplyCameraInfo(UInfoBase* Info) override;

private:
	UPROPERTY()
	UArmRotInfo* ArmRotInfo;

	float BlendTimeToGo;

	FRotator RotStart;

	FRotator RotToGo;
};