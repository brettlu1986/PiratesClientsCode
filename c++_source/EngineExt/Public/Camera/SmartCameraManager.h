// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "CameraDefine.h"
#include "CameraHeadBase.h"
#include "SmartCameraManager.generated.h"

class AKMCameraActor;
class UFocusTargetCameraHead;
class ULazyFollowCameraHead;

UCLASS()
class ENGINEEXT_API USmartCameraManager : public UObject, public ICameraHeadDelegate
{
	GENERATED_BODY()
	struct Impl;
	TSharedPtr<Impl> impl;

    ~USmartCameraManager();

public:
	void Init();
	// 切换摄像机需要用到PlayerController，因此在使用之前必须初始化
	void SetPlayerController(APlayerController *Controller);
	// 切换到指定的摄像机类型
    UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void UseCamera(ECameraName::Type Name, AActor* AttachedActor = nullptr, float BlendTime = 1.0, bool AutoSwitch = true);

	virtual void UpdateCamera(float DeltaSeconds) override;

	// 在FocusPlayerCamera模式下使用，用来指定Focus对象
	UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void SetFocusActor(AActor *Actor);

	// 是否开启手动操作摄像机视角旋转
    UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void EnableRotateCameraManually(bool Enable);
	// 开启手动操作摄像机视角旋转后，可以传入偏移量
    UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void RotateCameraManually(const FRotator &RotationOffset);

	// 刷新摄像机附着的Player，当生成新Player后，或者切换跟随的Player时，需要调用一次
    UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void RefreshAttachedActor();

	// 重置摄像机到默认位置
	UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void ResetCameraLocation();
	// 设置摄像机臂长
	UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void SetCameraArmLength(float ArmLength);
	// 设置摄像机角度
	UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void SetCameraPitch(float Pitch);
	// 设置摄像机附着位置的偏移量
	UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void SetAttachLocationOffset(FVector Offset);
	// 使用场景中的其他自定义相机，所有切换自定义相机都需要通过此接口，而不是PlayerController的接口，否则可能出现摄像机状态错误
	UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void SetCustomViewTarget(class AActor* NewViewTarget, float BlendTime = 0, enum EViewTargetBlendFunction BlendFunc = VTBlend_Linear, float BlendExp = 0, bool bLockOutgoing = false);
	// 恢复到之前的自动模式
	UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void ResumeAutoCamera(float BlendTime = 0.0f);
	// 定住摄像机位置，只更新朝向
	UFUNCTION(BlueprintCallable, Category = "SmartCameraManager")
	void FreezeCameraLoc(bool Freeze);

    void UpdateSeamlessTravelCamera(bool bReload, FVector& Location, FRotator& Rotation, FTransform& Transform);
private:
	UPROPERTY()
	TArray<AKMCameraActor *> CameraActorArray;
	UPROPERTY()
	UFocusTargetCameraHead *FocusTargetCameraHead;
	UPROPERTY()
	ULazyFollowCameraHead *LazyFollowCameraHead;

	TWeakObjectPtr<APlayerController> PlayerController = nullptr;
	TWeakObjectPtr<UCameraHeadBase> CurrentCameraHead = nullptr;
	bool UsingCustomCamera = false;
	ECameraName::Type PendingCamera = ECameraName::None;

	bool CheckCameraHead(UCameraHeadBase *CameraHead);
	ECameraName::Type SwitchToAvailableCameraHead(float BlendTime);

    bool IsSeamlessTravel;
    FVector TravelSaveLocation;
    FRotator TravelSaveRotation;
    FTransform TravelSaveTransform;
};
