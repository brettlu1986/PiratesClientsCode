#pragma once
#include "Camera/CameraModifier_CameraShake.h"
#include "KMCameraInfoInterface.h"
#include "KMCameraShakeModifier.generated.h"

class UCameraShakeInfo;
class UKMCameraShake;

UCLASS(config=Camera)
class ENGINEEXT_API UKMCameraShakeModifier : public UCameraModifier_CameraShake, public IKMCameraInfoInterface
{       
    GENERATED_BODY()

public:
    UKMCameraShakeModifier(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

    virtual void ApplyCameraInfo(UInfoBase* Info) override;

	void StopCurrentShake();
	bool IsCurrentShakeFinished();

private:
	bool ShakeOnce();

	void ProcessShakeInfo();

	void CreateCurrentShake();

	void AddCameraShakeInstance(UCameraShake* NewShake, const FAddCameraShakeParams& Params);

	UPROPERTY()
	UCameraShakeInfo* ShakeInfo;

	UPROPERTY()
	UKMCameraShake* FireShakeInstance;

	int32 ShakeCount;
};