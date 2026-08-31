#pragma once
#include "CoreMinimal.h"
#include "Camera/CameraModifier.h"
#include "KMCameraInfoInterface.h"
#include "KMCameraArmSyncRotModifier.generated.h"

class USyncArmRotInfo;

UCLASS(config = Camera)
class ENGINEEXT_API UKMCameraArmSyncRotModifier : public UCameraModifier, public IKMCameraInfoInterface
{
	GENERATED_BODY()

public:
	UKMCameraArmSyncRotModifier(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

	virtual void ApplyCameraInfo(UInfoBase* Info) override;

private:
	UPROPERTY()
	USyncArmRotInfo* ArmSyncInfo;

	float InterpSpeed;

	FRotator TargetRot;

};