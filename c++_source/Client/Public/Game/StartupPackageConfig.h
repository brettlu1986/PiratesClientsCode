// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/NoExportTypes.h"
#include "StartupPackageConfig.generated.h"

/**
 * 
 */
UCLASS(config = Game)
class CLIENT_API UStartupPackageConfig : public UObject
{
	GENERATED_BODY()
public:
	static void LoadStartupPackage(class UGameClient* InGameClient);

	static void Shutdown();

	UPROPERTY(config, EditAnywhere, Category = StartupPackage)
	TArray<FString> CachedPackages;

	UPROPERTY(config, EditAnywhere, Category = StartupPackage)
	TArray<FString> DisregardForGC;

	class UGameClient* GetGameClient() { return GameClient; }

private:
	TSharedPtr<class FRunnable> LoadingRunnable;

	FTimerHandle TimerHandle;

	class UGameClient* GameClient;

	FDelegateHandle TickHandle;

	int32 LastPackageIdx;

	void Start();

	void SetGameClient(class UGameClient* InGameClient) { GameClient = InGameClient; }
};
