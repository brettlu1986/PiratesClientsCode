// Fill out your copyright notice in the Description page of Project Settings.

#include "Camera/CameraModify/KMCameraInfo.h"
#include "EngineExt.h"


UChangeTargetInfo::UChangeTargetInfo(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
    ,Target(nullptr)
    ,bChangeImmediatly(false)
    ,BlendTime(0.f)
	,BlendExp(0.f)
	,BlendFunc(EViewTargetBlendFunction::VTBlend_Linear)
{}

UChangeTargetInfo::UChangeTargetInfo(AActor* InTarget, bool bInChangeImmediatly, float InBlendTime, float InBlendExp, enum EViewTargetBlendFunction InBlendFunc)
    :Target(InTarget)
    ,bChangeImmediatly(bInChangeImmediatly)
    ,BlendTime(InBlendTime)
	,BlendExp(InBlendExp)
	,BlendFunc(InBlendFunc)
{}

bool UChangeTargetInfo::IsZero() const
{
    return false;
}

UFreeViewInfo::UFreeViewInfo(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
    ,StartRotator(FRotator::ZeroRotator)
    ,InterpSpeed(0.f)
    ,bInBackAnim(false)
{
}

UFreeViewInfo::UFreeViewInfo(const FRotator& InStartRot, float InSpeed, bool bInbackAnim)
    :StartRotator(InStartRot), InterpSpeed(InSpeed), bInBackAnim(bInbackAnim)
{
}

bool UFreeViewInfo::IsZero() const
{
    return false;
}

UHandleMoveInfo::UHandleMoveInfo(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
    ,MoveX(0.f)
    ,MoveY(0.f)
	,MoveType(EHandleInputType::UseNone)
	,bWithAnim(false)
	,AnimTime(0.f)
{
}

UHandleMoveInfo::UHandleMoveInfo(float InMoveX, float InMoveY, EHandleInputType InMoveType, bool bInWithAnim, float InAnimTime)
    :MoveX(InMoveX), MoveY(InMoveY), MoveType(InMoveType), bWithAnim(bInWithAnim), AnimTime(InAnimTime)
{
}


bool UHandleMoveInfo::IsZero() const
{
    return false;
}

UOffsetMoveInfo::UOffsetMoveInfo(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
    ,MoveOffset(FVector::ZeroVector)
    ,BlendTime(0.f)
    ,bNeedBlend(false)
	,InterpMode(1)
{
}

UOffsetMoveInfo::UOffsetMoveInfo(const FVector& InMoveOffset, float InBlendTime, bool bInNeedBlend,
	int32 InInterpMode)
    :MoveOffset(InMoveOffset)
    ,BlendTime(InBlendTime)
    ,bNeedBlend(bInNeedBlend)
	,InterpMode(InInterpMode)
{
}

bool UOffsetMoveInfo::IsZero() const
{
    return false;
}

UFovInfo::UFovInfo(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
	, TargetFovRate(0.f)
	, BlendTime(0.f)
{
}

UFovInfo::UFovInfo(float InTargetFovRate, float InBlendTime)
	:TargetFovRate(InTargetFovRate)
	,BlendTime(InBlendTime)
{
}

bool UFovInfo::IsZero() const
{
	return false;
}

UArmRotInfo::UArmRotInfo(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
	, TargetRot(FRotator::ZeroRotator)
	, BlendTime(0.f)
{
}

UArmRotInfo::UArmRotInfo(const FRotator& InTargetRotator, float InBlendTime)
	:TargetRot(InTargetRotator)
	,BlendTime(InBlendTime)
{

}

bool UArmRotInfo::IsZero() const
{
	return false;
}

UMoveArmLenInfo::UMoveArmLenInfo(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
	,ArmLenToGo(0.f)
	,BlendTime(0.f)
{
}

UMoveArmLenInfo::UMoveArmLenInfo(float InMoveToGo, float InBlendTime)
	:ArmLenToGo(InMoveToGo)
	,BlendTime(InBlendTime)
{
}

bool UMoveArmLenInfo::IsZero() const
{
	return false;
}

USyncArmRotInfo::USyncArmRotInfo(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
	, bSyncYaw(false)
	, SyncPawn(nullptr)
	, OffsetYaw(0.f)
	, InterpSpeed(0.f)
{
}

USyncArmRotInfo::USyncArmRotInfo(bool bInSyncYaw, APawn* InSyncPawn, float InOffsetYaw, float InInterpSpeed)
	:bSyncYaw(bInSyncYaw)
	,SyncPawn(InSyncPawn)
	,OffsetYaw(InOffsetYaw)
	,InterpSpeed(InInterpSpeed)
{
}

bool USyncArmRotInfo::IsZero() const
{
	return false;
}

UCameraShakeInfo::UCameraShakeInfo(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
	, TargetAngle(FVector::ZeroVector)
	, RecoverAngle(FVector::ZeroVector)
	, PosOffset(FVector::ZeroVector)
	, Duration(0.f)
	, FovChange(0.f)
	, DecayParam(0.f)
	, ShakeCount(1)
	, bRecoil(false)
	, bFollowPitch(false)
	, bUseRecoverV(false)
{
}

UCameraShakeInfo::UCameraShakeInfo(FVector InTargetAngle, FVector InRecoverAngle, FVector InPosOffset,
	float InDuration, float InFovChange, float InDecayParam, int32 InShakeCount, bool bInRecoil,
	bool bInFollowPitch, bool bInUseRecoverV)
    :TargetAngle(InTargetAngle)
    ,RecoverAngle(InRecoverAngle)
    ,PosOffset(InPosOffset)
	,Duration(InDuration)
	,FovChange(InFovChange)
	,DecayParam(InDecayParam)
	,ShakeCount(InShakeCount)
	,bRecoil(bInRecoil)
	,bFollowPitch(bInFollowPitch)
	,bUseRecoverV(bInUseRecoverV)
{
}

bool UCameraShakeInfo::IsZero() const
{
    return false;
}

UCameraTrackInfo::UCameraTrackInfo(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
	, TargetMeshComponent(nullptr)
	, TargetSocket(FName(""))
	, RefMeshComponent(nullptr)
	, SightRelativaTransform(FTransform::Identity)
	, TrackParam(0.2f)
	, DelayBeginTime(0.f)
	, DelayTrackOnceTime(0.f)
	, OffsetForward(0.f)
{
}

UCameraTrackInfo::UCameraTrackInfo(USceneComponent* InTargetMeshComponent,
	FName InTargetSocket, USceneComponent* InRefMeshComponent, FTransform InSightRelativaTransform, float InTrackParam, float InDelayBeginTime, float InDelayTrackOnceTime, float InOffsetForward)
	:TargetMeshComponent(InTargetMeshComponent)
	, TargetSocket(InTargetSocket)
	, RefMeshComponent(InRefMeshComponent)
	, SightRelativaTransform(InSightRelativaTransform)
	, TrackParam(InTrackParam)
	, DelayBeginTime(InDelayBeginTime)
	, DelayTrackOnceTime(InDelayTrackOnceTime)
	, OffsetForward(InOffsetForward)
{
}

bool UCameraTrackInfo::IsZero() const
{
	return false;
}