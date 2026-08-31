// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CameraHeadBase.generated.h"

class AKMCameraActor;
/**
 * 
 */
UCLASS()
class ENGINEEXT_API UCameraHeadBase : public UObject
{
	GENERATED_BODY()
	
public:
	UCameraHeadBase();

	virtual void UpdateCamera(float DeltaSeconds);
	virtual bool IsAvailable();

	void SetCameraActor(AKMCameraActor *Actor);
	void SetRotationManually(bool Manual);
	void RotateCameraManually(const FRotator &RotationOffset);
	void AttachToActor(AActor *Actor);

	void SetCameraArmLength(float ArmLength);
	void SetCameraPitch(float Pitch);
	void SetAttachLocationOffset(FVector Offset);
	void SyncCameraParamsWithHead(const UCameraHeadBase *OriginHead);

    void GetTargetTransform(FVector &Location, FRotator &Rotation);
    void SetTargetTransform(const FVector &Location, const FRotator &Rotation);

	void SetTargetCameraTransform(const FTransform &Transform);
	void ResetCameraLocRot();

	void FreezeCameraLoc(bool Freeze);

    bool GetCameraLocationAndRotation(FVector &Location, FRotator &Rotation);
    void SetCameraLocationAndRotation(const FVector &Location, const FRotator &Rotation);
protected:
	FVector TargetCameraLocation = FVector::ZeroVector;
	FRotator TargetCameraRotation = FRotator::ZeroRotator;
	FRotator InitCameraArmRotation = FRotator::ZeroRotator;
	FVector AttachedLocationOffset = FVector::ZeroVector;
	FVector TargetLocationOffset;
	float CameraLocationResumeSpeed;
	float CameraRotationResumeSpeed;
	float CameraArmLength;
	float TargetArmLength;
	float DistanceToGround;
	bool NeedResetCameraLocRot = true;
	bool NeedUpdateCameraLocRot = true; // 在InterpCameraToTarget时，如果位置没有改变，则为false
	bool NeedUpdateTargetCameraLocRot = true; // 当摄像机参数改变时，需要重新计算TargetCameraLocRot，所以需要设为true，否则为false
	bool CameraLocWasFrozen = false;
	TWeakObjectPtr<AActor> AttachedActor = nullptr;

	void ResetCameraToDefaultLocation();

	float AdapterPitchToGround();
	bool InterpToTargetPitch(float DeltaSeconds, float TargetPitch);
	FVector GetFixedAttachLocation();

	void InterpCameraToTarget(const FVector &TargetLocation, const FRotator &TargetRotation, float DeltaSeconds);
	void InterpCameraParamTotarget(float DeltaSeconds);
	FVector GetCameraLocation();
	void SetCameraLocation(const FVector &Location);
	void SetCameraRotation(const FRotator &Rotation);

	void RecaculateDistanceToGround();
private:
	TWeakObjectPtr<AKMCameraActor> CameraActor;
	bool RotateManually = false;

};
