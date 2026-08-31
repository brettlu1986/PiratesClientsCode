// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Engine/EngineBaseTypes.h"

#include "KMObject.h"
#include "KMTickableObject.generated.h"

/**
 * Object with tick event
 */
UCLASS(Blueprintable)
class ENGINEEXT_API UKMTickableObject : public UKMObject , public FTickableGameObject
{
	GENERATED_BODY()
public:

    /**
    * Default constructor for UKMTickableObject
    */
    UKMTickableObject();

    /**
    * Constructor for UKMTickableObject that takes an ObjectInitializer
    */
    UKMTickableObject(const FObjectInitializer& ObjectInitializer);

private:
    /** Called from the constructor to initialize the class to its default settings */
    void InitializeDefaults();

public:

    /** Allow each Object to run at a different time speed. The DeltaTime for a frame is multiplied by the global TimeDilation (in WorldSettings) and this CustomTimeDilation for this Object's tick.  */
    UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, AdvancedDisplay, Category = "Tick")
    float CustomTimeDilation;

    /** Allow each Object to run at a different time speed. The DeltaTime for a frame is multiplied by the global TimeDilation (in WorldSettings) and this CustomTimeDilation for this Object's tick.  */
    UPROPERTY(EditDefaultsOnly, Category = "Tick", meta=(UIMin = "0.0"))
    float MinTickInterval;

    UPROPERTY(EditDefaultsOnly, Category = "Tick")
    bool bTickableWhenPaused;

    UPROPERTY(EditDefaultsOnly, Category = "Tick")
    bool bTickableInEditor;

    UPROPERTY(EditDefaultsOnly, Category = "Tick")
    bool bTickableInDedicatedServer;

    UPROPERTY(BlueprintReadWrite, VisibleAnywhere, Category = "Tick")
    bool bTickable;

    /**
    *	Function called every frame on this Object. Override this function to implement custom logic to be executed every frame.
    *	Note that Tick is disabled by default, and you will need to check PrimaryObjectTick.bCanEverTick is set to true to enable it.
    *
    *	@param	DeltaSeconds	Game time elapsed during last frame modified by the time dilation
    */
    virtual void Tick(float DeltaSeconds);


    /** Event called every frame */
    UFUNCTION(BlueprintImplementableEvent, meta = (DisplayName = "Tick"))
    void ReceiveTick(float DeltaSeconds);

public:
    /** FTickableGameObject interface begin */
    virtual bool IsTickableWhenPaused() const override;

    virtual bool IsTickableInEditor() const override;

    virtual UWorld* GetTickableGameObjectWorld() const override;
	
    virtual TStatId GetStatId() const override;

    virtual bool IsTickable() const override;
    /** FTickableGameObject interface end */

private:
    float LastTickDeltaSeconds;
};
