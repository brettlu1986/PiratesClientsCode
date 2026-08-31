#pragma once
#include "CoreMinimal.h"
#include "Camera/CameraModifier.h"
#include "KMCameraInfoInterface.h"
#include "KMCameraOffsetMoveModifier.generated.h"

class UOffsetMoveInfo;

UCLASS(config=Camera)
class ENGINEEXT_API UKMCameraOffsetMoveModifier : public UCameraModifier, public IKMCameraInfoInterface
{
    GENERATED_BODY()

public:
    UKMCameraOffsetMoveModifier(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

    virtual void ApplyCameraInfo(UInfoBase* Info) override;

	UPROPERTY()
	FVector BaseSocketOffset;
private: 
	UPROPERTY()
	UOffsetMoveInfo* OffsetMoveInfo;

	float BlendTimeToGo;

	FVector OffsetToGo;

	FVector OffsetStart;

};