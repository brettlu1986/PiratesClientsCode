// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/NoExportTypes.h"
#include "KMObject.h"
#include "CustomizedTickableObject.generated.h"

/**
 * 
 */
UCLASS(ClassGroup = (Utility, Common), BlueprintType, Blueprintable, meta = (BlueprintSpawnableComponent, IgnoreCategoryKeywordsInSubclasses))
class COMMON_API UCustomizedTickableObject : public UKMObject, public FTickableGameObject
{
	GENERATED_BODY()
	
public:
    /**
    * Default constructor for UKMTickableObject
    */
    UCustomizedTickableObject()
    {
        LastTickDeltaSeconds = 0;
    };

    /**
    * Constructor for UKMTickableObject that takes an ObjectInitializer
    */
    UCustomizedTickableObject(const FObjectInitializer& ObjectInitializer)
    {
        LastTickDeltaSeconds = 0;
    };

public:



    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tick")
    bool TickEnabled;

    /** Allow each Object to run at a different time speed. The DeltaTime for a frame is multiplied by the global TimeDilation (in WorldSettings) and this CustomTimeDilation for this Object's tick.  */
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tick", meta = (UIMin = "0.0"))
    float CustomizedTickInterval;

    virtual void Tick(float DeltaSeconds) override final;


    // BP customized tick.
    UFUNCTION(BlueprintImplementableEvent, meta = (DisplayName = "Tick"))
    void ReceiveTick(float DeltaSeconds);


private:

    float LastTickDeltaSeconds;
	
    // CPP customized tick.
    virtual void OnTick(float DeltaSeconds);





public:
    virtual TStatId GetStatId() const override;

    virtual bool IsTickable() const override;

};
