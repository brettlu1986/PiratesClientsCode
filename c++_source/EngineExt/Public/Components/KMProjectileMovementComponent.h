// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/ProjectileMovementComponent.h"
#include "KMProjectileMovementComponent.generated.h"

/**
 * 
 */
UCLASS(ClassGroup = Movement, meta = (BlueprintSpawnableComponent), ShowCategories = (Projectile))
class ENGINEEXT_API UKMProjectileMovementComponent : public UProjectileMovementComponent
{
	GENERATED_BODY()
public:

	/**
	* Default UObject constructor.
	*/
    UKMProjectileMovementComponent(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

public:
    virtual void SetUpdatedComponent(USceneComponent* NewUpdatedComponent) override;
	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;

public:
    UPROPERTY(Category = "Projectile", EditAnywhere, BlueprintReadWrite)
    float MaxRange;

    UPROPERTY(Category = "Projectile", EditAnywhere, BlueprintReadWrite)
    bool CheckSeaLevel;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnIntoWater);
    UPROPERTY(BlueprintAssignable, Category = "Projectile")
    FOnIntoWater OnIntoWater;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnOutOfRange);
    UPROPERTY(BlueprintAssignable, Category = "Projectile")
    FOnOutOfRange OnOutOfRange;

private:
    FVector OriginalLocation;
};
