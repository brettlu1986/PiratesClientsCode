#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "Engine/EngineTypes.h"
#include "Components/SceneComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "KMSpringArmComponent.generated.h"


UCLASS(ClassGroup = Camera, meta = (BlueprintSpawnableComponent), hideCategories = (Mobility))

class ENGINEEXT_API UKMSpringArmComponent : public USpringArmComponent
{
	GENERATED_UCLASS_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	float XVel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	float ZVel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	float ZRecoverVel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	float UpMinDistance;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	float UpTraceValidDistance;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	float FixOffset;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	float FixBackStartOffset;

	UPROPERTY(EditAnywhere, Category = "Trace")
	TArray<TEnumAsByte<EObjectTypeQuery> > TraceObjectTypes;

	UPROPERTY(EditAnywhere, Category = "LocationTimeLag")
	float LocationLagRecoverMaxSpeed;

	UPROPERTY(EditAnywhere, Category = "LocationTimeLag")
	float LocationLagRecoverAccSpeed;

	UFUNCTION(BlueprintCallable, Category = "LocationTimeLag")
	void EnableCameraLocationLagWithTimeAndSpeed(bool enable, float time, float speed);

	UFUNCTION()
	void UpdatePreArmLocationZ(float LocZ);

	UFUNCTION()
	void AddArmCollisionIgnoreActor(AActor* IgnoreActor);
protected:
	/** Updates the desired arm location, calling BlendLocations to do the actual blending if a trace is done */
	virtual void UpdateDesiredArmLocation(bool bDoTrace, bool bDoLocationLag, bool bDoRotationLag, float DeltaTime);

private:

	void BlendLocationsForUpTrace(const FVector& ArmStartLocation, const FVector& TraceHitLocation, bool bHitSomething, float DeltaTime);

	FVector BlendLocationsForBackTrace(const FVector& UpResultLocation, const FVector& TraceHitLocation, const FRotator& DesireRot, bool bHitSomething, float DeltaTime);
	//float UpTraceLength;
	FVector UpTargetLocation;

	bool bBackHitted;
	FVector BackTargetLocation;

	bool bEnableLocationLag;
	float LocationLagTime;
	float LocationLagSpeed;
	float LocationLagRecoverCurSpeed;

	float PreArmLocationZ;
	bool bUpHitted;

	FCollisionQueryParams QueryParams;
	

};