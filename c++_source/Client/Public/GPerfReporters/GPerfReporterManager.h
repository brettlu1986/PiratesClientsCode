// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GPerfReporterManager.generated.h"

UCLASS()
class UGPerfReporterManager : public UObject
{
	GENERATED_BODY()

#ifdef WITH_GPERF
public:
	void Init(class UGameClient* GameClient);
	void Uninit();

private:
    void InitReporters(UGameClient* GameClient);

private:
    TArray<TSharedPtr<class FGPerfReporter>> Reporters;
    TSharedPtr<class FGPerfTransformReporter> TransformReporter;
#endif
};
