#pragma once
#include "KMCameraInfoInterface.h"
#include "KMCameraTrackModifier.generated.h"

class UCameraTrackInfo;

enum class ETrackType : uint8
{
	PlaceHolder = 0,
	TrackOnce = 1,
	Tracking,
};

UCLASS(config=Camera)
class ENGINEEXT_API UKMCameraTrackModifier : public UCameraModifier, public IKMCameraInfoInterface
{       
    GENERATED_BODY()

public:
	UKMCameraTrackModifier(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

    virtual void ApplyCameraInfo(UInfoBase* Info) override;

	UFUNCTION(BlueprintCallable)
	void ForceTrackOnce();

	UFUNCTION(BlueprintCallable)
	void SetTrackOnce();
private:

	void Tracking(float DeltaTime, const FVector& TargetLoc);
	FTransform GetRefTransform();
	bool IsCharacterMoving();
	bool IsPlayingMontage();
	bool IsUseTrackCurve();
	bool IsPlayShakeing();

	UPROPERTY(Category = "Camera", EditDefaultsOnly, BlueprintReadOnly, meta = (AllowPrivateAccess = "true"))
	UCurveFloat* StartToTargetCurve;

	UPROPERTY()
	UCameraTrackInfo* TrackInfo;

	float DelayBeginTime;
	ETrackType TrackType;
	FVector TrackOnceTarget;
	bool bTrackOnceInit;
	bool bTrackOnceStart;

	float TimeMin;
	float TimeRange;
	float TimeChange;

	float CacheTrackOnceTime;
	bool bBackFromMontage;
};