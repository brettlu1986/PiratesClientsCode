#pragma once
#include "Camera/PlayerCameraManager.h"
#include "Camera/CameraShake.h"
#include "Camera/CameraModify/KMCameraShakeModifier.h"
#include "Camera/CameraModify/KMCameraInfo.h"
#include "KMGameCameraActor.h"
#include "KMGameCameraManager.generated.h"

UENUM(BlueprintType)
enum class ECameraModeType : uint8
{
    PlaceHolder = 0,
    ModeChangeTarget = 1,
    ModeHandleMove,
    ModeOffsetMove,
    ModeShake,
	ModeFov,
	ModeArmLen,
	ModeSyncArmRot,
	ModeArmRot,
	ModeCameraTrack,
};

UENUM(BlueprintType)
enum class ECameraAngleType : uint8
{
    PlaceHolder = 0,
	LookUp = 1,
	LookForward,
	LookDown,
};

UENUM(BlueprintType)
enum class ECameraFollowType : uint8
{
    PlaceHolder = 0,
	FollowNone = 1,
	Attach,
	AttachToSocket,
	NotAttachFollowLocation,
	NotAttachFollowLocationXY,
	NotAttachFollowLocXYRotYaw,
	NotAttackFollowLocRotYaw,
	NotAttachFollowMeshLocation,
};

USTRUCT(BlueprintType)
struct FInitCameraInfo
{
	GENERATED_USTRUCT_BODY()

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float SpringArmLength;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	FRotator SpringArmRotation;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	FVector SpringArmLocation;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	FVector SocketOffset;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	FRotator CameraRotation;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float PitchViewMax;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float PitchViewMin;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float LookUpLimit;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float LookDownLimit;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float InitFov;

	FInitCameraInfo()
		:SpringArmLength(0.f)
		,SpringArmRotation(FRotator::ZeroRotator)
		,SpringArmLocation(FVector::ZeroVector)
		,SocketOffset(FVector::ZeroVector)
		,CameraRotation(FRotator::ZeroRotator)
		,PitchViewMax(89.9f)
		,PitchViewMin(-89.9f)
		,LookUpLimit(0.f)
		,LookDownLimit(0.f)
		,InitFov(90)
	{}

};

class AKMGameCameraActor;

UCLASS(notplaceable, transient, BlueprintType, Blueprintable)
class ENGINEEXT_API AKMGameCameraManager : public APlayerCameraManager
{
    GENERATED_BODY()

public:
    AKMGameCameraManager(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

    virtual void PostInitializeComponents() override;

    UFUNCTION(BlueprintCallable, Category = "Camera Shakes")
    void PlayCameraShakeInstance(TSubclassOf<UCameraShake> ShakeClass, float Scale = 1.f, enum ECameraAnimPlaySpace::Type PlaySpace = ECameraAnimPlaySpace::CameraLocal, FRotator UserPlaySpaceRot = FRotator::ZeroRotator);

    UFUNCTION(BlueprintCallable, Category = "Camera")
    void ActiveCameraMode(ECameraModeType InfoType, UInfoBase* Info);

    UFUNCTION(BlueprintCallable, Category = "Camera")
    void DeactiveCameraMode(ECameraModeType InfoType);

    UFUNCTION(BlueprintCallable, Category = "Camera")
    void InitCameraActorParam(const FInitCameraInfo& CameraInfo);

	UFUNCTION(BlueprintCallable, Category = "Camera")
	void UnInitCameraActorParam();

	UFUNCTION(BlueprintCallable, Category = "Camera")
	void UnInitCameraForDead();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	ECameraAngleType GetCameraVerticleAngleType();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	class AKMGameCameraActor* GetPlayerCameraActor();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void SetFollowLocationOffset(FVector FollowOffset);
 
	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void InitFollowTarget(AActor* InFollowTarget, ECameraFollowType InFollowType, bool bSetControlRot, USceneComponent* Parent, FVector InOffset, FName SocketName = NAME_None);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void InitCacheArmParam();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void UnInitCacheArmParam(bool bWithAnim, float InterpSpeed);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void InitAimParam(float AimArmLen, float AimRate);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void UnInitAimParam();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void InitAttachAimParam(float AimArmLen, FVector CameraOffset, float AimRate, FName SocketName, USceneComponent* Parent);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void UnInitAttachAimParam();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void ResetPitchView(float PitchMax, float PitchMin);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void ResetBaseSocketOffset(FVector SocketOffset);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void EnableCameraMoveCollisionCheck(bool bEnable, bool bCrawl);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void EnableCameraMoveBackOrigin(bool bReset);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void ForceToResetFreeViewRotation();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	FRotator GetMoveCameraRotation() const;

	void StopCurrentShake();

	bool IsCurrentShakeFinished();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	bool IsArmBackRotBack() const;

	UFUNCTION(BlueprintPure, Category = "CameraControl")
	APawn* GetCameraTargetPawn();

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void SetWatchTarget(APawn* InSyncPawn);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void SetForceUpdateClientCamera(bool bForce, APawn* Target);

	UFUNCTION(BlueprintCallable, Category = "CameraControl")
	void ForceSendClientCamera();

	UFUNCTION()
	void SpawnCameraActor();

	UFUNCTION()
	void SetCacheArmRotator(bool bCache, FRotator Rot);
	
	virtual void Tick(float DeltaSeconds);

	UPROPERTY(BlueprintReadOnly)
	AKMGameCameraActor* CameraActor;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TSubclassOf<AKMGameCameraActor> CameraActorClass;

	UPROPERTY(BlueprintReadOnly)
	AActor* FollowTarget;

	float RefFov;

	UPROPERTY(BlueprintReadOnly, Category = CameraModifier)
	TMap<ECameraModeType, UCameraModifier*> CurrentMorifierMap;
private:
	
	void UpdateFollowTarget(float DeltaSeconds);
	void UpdateSendClientCamera(float DeltaSeconds);

	UPROPERTY()
	APawn* WatchedPawn;

	ECameraFollowType  CameraFollowType;
   // AKMGameCameraActor* CameraActor;
	
	float LookAngleUpLimit;
	float LookAngleDownLimit;

	bool bUseCacheRotation;

	UPROPERTY()
	FRotator CacheCameraRotator;

	UPROPERTY()
	FVector FollowLocOffset;

	float CacheArmLen;

	bool bForceUpdateClientCamera;

	UPROPERTY()
	APawn* TargetPawn;
	
	USceneComponent* FollowComponent;
};