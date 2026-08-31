#pragma once
#include "CoreMinimal.h"
#include "Camera/CameraModifier.h"
#include "KMCameraInfoInterface.h"
#include "KMCameraArmLenModifier.generated.h"

class UMoveArmLenInfo;

UCLASS(config = Camera)
class ENGINEEXT_API UKMCameraArmLenModifier : public UCameraModifier, public IKMCameraInfoInterface
{
	GENERATED_BODY()

public:
	UKMCameraArmLenModifier(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

	virtual void ApplyCameraInfo(UInfoBase* Info) override;

private:
	UPROPERTY()
	UMoveArmLenInfo* ArmLenInfo;

	float AnimTime;
	float MoveToGo;
	float MoveHasGo;
	float MoveWillGo;
	float EndLen;
	bool bNeedBlend;
};