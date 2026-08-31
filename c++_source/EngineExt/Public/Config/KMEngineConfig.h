// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GlobalDefinition.h"
#include "AndroidDeviceProfileMatchingRules.h"
#include "KMEngineConfig.generated.h"

UCLASS(config = DeviceProfile)
class ENGINEEXT_API UAdditionalDeviceProfileMatchingRules : public UObject
{
	GENERATED_BODY()
public:
	UPROPERTY(EditAnywhere, config, Category = "Matching Rules")
	TArray<FProfileMatch> MatchProfile;
};


UCLASS(config = Game, defaultconfig)
class ENGINEEXT_API UKMEngineConfig : public UObject
{
    GENERATED_UCLASS_BODY()

public:
    void Load();
    void OnLoadFinish();

    static FString GetConfigPath();

    UFUNCTION(BlueprintPure, Category = "KMEngineConfig", meta = (WorldContext = "WorldContextObject"))
    static UKMEngineConfig* GetConfig(UObject* WorldContextObject);

public:
    UPROPERTY(config)
    FString   ConfigFilePath;
 /* example:default section name is [Global]
 
    UPROPERTY(Transient)
    int32   TestNumber;

    different section if needed

    UPROPERTY(Transient, VisibleAnywhere, Category = SectionName)
    FString   TestStringWithDiffrentSection;

    UPROPERTY(Transient)
    TArray<FString>   TestArrays;

    */
    // add variable below

	UPROPERTY(Transient)
	TArray<FString> PreLoadExcludeMaps;

    // additional device profile
public:
	UPROPERTY(Transient)
	FString AdditionalDeviceProfileConfigPath;
protected:
	UPROPERTY()
	class UAdditionalDeviceProfileMatchingRules* AdditionalMatchingRules;
};
