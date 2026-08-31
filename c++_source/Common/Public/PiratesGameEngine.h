// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Engine/GameEngine.h"
#include "PiratesGameEngine.generated.h"

/**
 * 
 */
UCLASS()
class COMMON_API UPiratesGameEngine : public UGameEngine
{
	GENERATED_UCLASS_BODY()

public:
    virtual bool LoadMap(FWorldContext& WorldContext, FURL URL, class UPendingNetGame* Pending, FString& Error) override;

    virtual void Init(IEngineLoop* InEngineLoop) override;
	virtual void Start() override;
    virtual void Tick(float DeltaSeconds, bool bIdleMode) override;
    void CleanUp();

private:
    void CleanUpWorldContext(FWorldContext &WorldContext);
    void BroadcastOnWorldRestart(UWorld *World);

public:
    volatile bool LowMemoryWarning;
};
