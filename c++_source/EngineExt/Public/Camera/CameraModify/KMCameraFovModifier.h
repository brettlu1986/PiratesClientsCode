#pragma once
#include "CoreMinimal.h"
#include "Camera/CameraModifier.h"
#include "KMCameraInfoInterface.h"
#include "KMCameraFovModifier.generated.h"

class UFovInfo;

UCLASS(config = Camera)
class ENGINEEXT_API UKMCameraFovModifier : public UCameraModifier, public IKMCameraInfoInterface
{
	GENERATED_BODY()

public:
	UKMCameraFovModifier(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

	virtual void ApplyCameraInfo(UInfoBase* Info) override;

private:
	UPROPERTY()
	UFovInfo* FovInfo;

	float BlendTimeToGo;

	float FovStart;

	float FovToGo;

	float Key; 
	float KeyReduce;
};