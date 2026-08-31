#pragma once
#include "CoreMinimal.h"
#include "Camera/CameraModifier.h"
#include "KMCameraInfoInterface.h"
#include "KMCameraHandleMoveModifier.generated.h"

class UHandleMoveInfo;
UCLASS(config=Camera)
class ENGINEEXT_API UKMCameraHandleMoveModifier : public UCameraModifier, public IKMCameraInfoInterface
{
    GENERATED_BODY()

public:
    UKMCameraHandleMoveModifier(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    virtual bool ModifyCamera(float DeltaTime, struct FMinimalViewInfo& InOutPOV) override;

    virtual void ApplyCameraInfo(UInfoBase* Info) override;

	void InitDataCache();

	void ResetDataCache(bool bWithAnim, float InterpSpeed);

	FRotator GetCacheArmRot() const;

	bool IsArmBackAnim() const 
	{
		return bCameraArmBack;
	}

    void SetEnableCollisionCheck(bool bEnable) { bCollisionCheck = bEnable; }
	void SetIsResetOrigin(bool bInIsResetOrigin) { bIsResetOrigin = bInIsResetOrigin; }
	void ForceToResetFreeViewRotation();
private:
	void MoveCamera(float MoveX, float MoveY);
    bool CheckCanChangeYaw(const FRotator& Dir);

private:
	UPROPERTY()
	UHandleMoveInfo * HandleMoveInfo;

	FRotator CacheArmRot;
	bool bCameraArmBack;
	float InterpSpeed;

	float AnimTime;
	FVector MoveToGo;
	FVector MoveHasGo;
	FVector MoveWillGo;

    bool bCollisionCheck;
	bool bIsResetOrigin;
    UPROPERTY()
    FVector CollisionCheckBox;
};