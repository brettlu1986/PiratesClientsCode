#pragma once


#include "GameFramework/SpringArmComponent.h"
#include "KMGameCameraActor.generated.h"

class UKMSpringArmComponent;

UCLASS()
class ENGINEEXT_API AKMGameCameraActor : public AActor
{
    GENERATED_BODY()
public:

    AKMGameCameraActor();

    virtual void BeginPlay() override;

    UFUNCTION(BlueprintCallable)
	UKMSpringArmComponent* GetSpringArm() const;

    UFUNCTION(BlueprintCallable)
    UCameraComponent* GetCamera() const;

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Euler To Quaternion"))
	FQuat EulerToQuaternion(FRotator CurrentRotation);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Add Local Rotation (Quaternion)"))
	void AddLocalRotationQuat(USceneComponent* SceneComponent, const FQuat& DeltaRotation);

public:

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BaseCameraActor")
	UKMSpringArmComponent*  CameraSpringArm;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BaseCameraActor")
    UCameraComponent*  CameraComponent;

	UPROPERTY()
	UArrowComponent* TestArrow;

};
