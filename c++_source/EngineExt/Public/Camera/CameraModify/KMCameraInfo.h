// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "Camera/CameraShake.h"
#include "KMCameraInfo.generated.h"

UENUM(BlueprintType)
enum class EHandleInputType : uint8
{
    PlaceHolder = 0,
	UseNone = 1,
	UseController,
	UseControllerArmPitch,
	UseArm,
	UseControllerArm,
	UseControllerPitchNegativeArm,
};

UCLASS(Blueprintable)
class ENGINEEXT_API UInfoBase : public UObject
{
    GENERATED_BODY()
public:
    virtual bool IsZero() const { return false; }
};

UCLASS(Blueprintable)
class ENGINEEXT_API UChangeTargetInfo : public UInfoBase
{
    GENERATED_BODY()

public:

    UChangeTargetInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    UChangeTargetInfo(AActor* InTarget, bool bInChangeImmediatly, float InBlendTime, float BlendExp, enum EViewTargetBlendFunction InBlendFunc);

    UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|TargetInfo")
    AActor* Target;

    UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|TargetInfo")
    bool bChangeImmediatly;

    UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|TargetInfo")
    float BlendTime;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|TargetInfo")
	float BlendExp;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|TargetInfo")
	TEnumAsByte<enum EViewTargetBlendFunction>  BlendFunc;

    virtual bool IsZero() const override;
};

UCLASS(Blueprintable)
class ENGINEEXT_API UFreeViewInfo : public UInfoBase
{
    GENERATED_BODY()

public:
    UFreeViewInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    UFreeViewInfo(const FRotator& InStartRot, float InSpeed, bool bInbackAnim);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|FreeViewInfo")
    FRotator StartRotator;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|FreeViewInfo")
    float InterpSpeed;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|FreeViewInfo")
    bool bInBackAnim;

    virtual bool IsZero() const override;
};

UCLASS(Blueprintable)
class ENGINEEXT_API UHandleMoveInfo : public UInfoBase
{
    GENERATED_BODY()

public:

    UHandleMoveInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	UHandleMoveInfo(float InMoveX, float InMoveY, EHandleInputType InMoveType, bool bInWithAnim, float InAnimTime);

    UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|HandleMoveInfo")
    float MoveX;

    UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|HandleMoveInfo")
    float MoveY;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|HandleMoveInfo")
	EHandleInputType MoveType;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|HandleMoveInfo")
	bool bWithAnim;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|HandleMoveInfo")
	float AnimTime;

    virtual bool IsZero() const override;
};

UCLASS(Blueprintable)
class ENGINEEXT_API UOffsetMoveInfo : public UInfoBase
{
    GENERATED_BODY()

public:

    UOffsetMoveInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    UOffsetMoveInfo(const FVector& InMoveOffset, float InBlendTime, bool bInNeedBlend, int32 InInterpMode);

    UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|OffsetMoveInfo")
    FVector MoveOffset;

    UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|OffsetMoveInfo")
    float BlendTime;

    UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|OffsetMoveInfo")
    bool bNeedBlend;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|OffsetMoveInfo")
	int32 InterpMode;

    virtual bool IsZero() const override;
};

UCLASS(Blueprintable)
class ENGINEEXT_API UFovInfo : public UInfoBase
{
	GENERATED_BODY()

public:

	UFovInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	UFovInfo(float InTargetFovRate, float InBlendTime);

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|FovInfo")
	float TargetFovRate;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|FovInfo")
	float BlendTime;

	virtual bool IsZero() const override;
};

UCLASS(Blueprintable)
class ENGINEEXT_API UArmRotInfo : public UInfoBase
{
	GENERATED_BODY()

public:

	UArmRotInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	UArmRotInfo(const FRotator& InTargetRotator, float InBlendTime);

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|ArmRotInfo")
	FRotator TargetRot;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|ArmRotInfo")
	float BlendTime;

	virtual bool IsZero() const override;
};

UCLASS(Blueprintable)
class ENGINEEXT_API UMoveArmLenInfo : public UInfoBase
{
	GENERATED_BODY()

public:

	UMoveArmLenInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	UMoveArmLenInfo(float InMoveToGo, float InBlendTime);

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|MoveArmLen")
	float ArmLenToGo;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|MoveArmLen")
	float BlendTime;

	virtual bool IsZero() const override;
};

UCLASS(Blueprintable)
class ENGINEEXT_API USyncArmRotInfo : public UInfoBase
{
	GENERATED_BODY()

public:

	USyncArmRotInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	USyncArmRotInfo(bool bSyncYaw, APawn* InSyncPawn, float InOffsetYaw, float InInterpSpeed);

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|SyncArmRot")
	bool bSyncYaw;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|SyncArmRot")
	APawn* SyncPawn;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|SyncArmRot")
	float OffsetYaw;

	UPROPERTY(BlueprintReadWrite, Category = "CameraInfo|SyncArmRot")
	float InterpSpeed;


	virtual bool IsZero() const override;
};

UCLASS(Blueprintable)
class ENGINEEXT_API UCameraShakeInfo : public UInfoBase
{
    GENERATED_BODY()

public:

    UCameraShakeInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    UCameraShakeInfo(FVector InTargetAngle, FVector InRecoverAngle, FVector InPosOffset,
		float InDuration, float InFovChange, float InDecayParam, int32 InShakeCount, bool bInRecoil,
		bool bInFollowPitch, bool bInUseRecoverV);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
    FVector TargetAngle;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	FVector RecoverAngle;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	FVector PosOffset;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	float Duration;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	float FovChange;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	float DecayParam;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	int32 ShakeCount;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	bool bRecoil;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	bool bFollowPitch;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|ShakeInfo")
	bool bUseRecoverV;

    virtual bool IsZero() const override;
};


UCLASS(Blueprintable)
class ENGINEEXT_API UCameraTrackInfo : public UInfoBase
{
	GENERATED_BODY()

public:

	UCameraTrackInfo(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	UCameraTrackInfo(USceneComponent* InTargetMeshComponent, 
		FName InTargetSocket, USceneComponent* InRefMeshComponent, FTransform InSightRelativaTransform, float InTrackSpeed, float InDelayBeginTime, float InDelayTrackOnceTime, float InOffsetForward);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|TrackInfo")
	USceneComponent* TargetMeshComponent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|TrackInfo")
	FName TargetSocket;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|TrackInfo")
	USceneComponent* RefMeshComponent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|TrackInfo")
	FTransform SightRelativaTransform;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|TrackInfo")
	float TrackParam;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|TrackInfo")
	float DelayBeginTime;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|TrackInfo")
	float DelayTrackOnceTime;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraInfo|TrackInfo")
	float OffsetForward;

	virtual bool IsZero() const override;
};
