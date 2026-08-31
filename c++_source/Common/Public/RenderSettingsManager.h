// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMObject.h"
#include "RenderSettingsManager.generated.h"


DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnRenderQualityAutoAdaptived, int32, LastQuality, int32, CurrentQuality);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnRenderQualityChangeBegin, int32, LastQuality, int32, CurrentQuality);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnRenderQualityChanged, int32, LastQuality, int32, CurrentQuality);

UCLASS(BlueprintType)
class COMMON_API URenderSettingsManager : public UKMObject
{
	GENERATED_BODY()

public:

	/** Init the default settings */
	void Init();

	/** Clear the default settings */
	void Clear();

	/** Update param */
	void Update(float DeltaTime);

	/** Get the default quality level of this device type QualityLevel -1:Error, 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetDeviceDefualtQuality();

	/** Restore the default quality settings for the device profile, param ApplyChanges for updating the relevance things */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool RestoreDeviceDefualtQuality(bool ApplyChanges = true);

	/** Get quality QualityLevel  -1:Error, 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetQuality();

	/** Set quality QualityLevel 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetQuality(int32 QualityLevel);

	/** Get quality QualityLevel  -1:Error, 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetInnerQuality();

	/** GetFPSQuality QualityLevel  0:Low, 1:Mid, 2:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetFPSQuality();

	/** GetDeviceDefualtFPSQuality QualityLevel 0:Low, 1:Mid, 2:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetDeviceDefualtFPSQuality();

	/** SetFPSQuality QualityLevel 0:Low, 1:Mid, 2:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetFPSQuality(int32 QualityLevel);

	/** SetFPSValueOfQuality */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetFPSValueOfQuality(int32 Low, int32 Mid, int32 High);

	/** GetShadowQuality QualityLevel  0:Low, 1:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetShadowQuality();

	/** GetDeviceDefualtShadowQuality QualityLevel 0:Low, 1:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetDeviceDefualtShadowQuality();

	/** SetShadowQuality QualityLevel 0:Low, 1:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetShadowQuality(int32 QualityLevel);

	/** GetEffectsQuality QualityLevel 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetEffectsQuality();

	/** GetDeviceDefualtEffectsQuality QualityLevel 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetDeviceDefualtEffectsQuality();

	/** SetEffectsQuality QualityLevel 0:Low, 1:Mid, 2:High, 3:UltraHigh*/
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetEffectsQuality(int32 QualityLevel);

	/** GetFoliageQuality QualityLevel 0:None 1:Low, 2:Mid, 3:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetFoliageQuality();

	/** GetDeviceDefualtFoliageQuality QualityLevel 0:None 1:Low, 2:Mid, 3:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetDeviceDefualtFoliageQuality();

	/** SetFoliageQuality QualityLevel 0:None 1:Low, 2:Mid, 3:High*/
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetFoliageQuality(int32 QualityLevel);

	/** GetViewDistanceQuality QualityLevel 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetViewDistanceQuality();

	/** GetDeviceDefualtViewDistanceQuality QualityLevel 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetDeviceDefualtViewDistanceQuality();

	/** SetViewDistanceQuality QualityLevel 0:Low, 1:Mid, 2:High, 3:UltraHigh */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetViewDistanceQuality(int32 QualityLevel);

	/** Is depth Of field enabled or not*/
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool IsDepthOfFieldEnabled();

	/** Is depth Of field enabled or not of the device */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool IsDeviceDefualtDepthOfFieldEnabled();

	/** Set depth Of field enabled or not */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetDepthOfFieldEnabled(bool Enable);

	/** Is bloom enabled or not*/
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool IsBloomEnabled();

	/** Is bloom enabled or not of the device */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool IsDeviceDefualtBloomEnabled();

	/** Set bloom enabled or not */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetBloomEnabled(bool Enable);

	/** Is aa enabled or not*/
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool IsAAEnabled();

	/** Is aa enabled or not of the device */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool IsDeviceDefualtAAEnabled();

	/** Set aa enabled or not */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetAAEnabled(bool Enable);

	/** GetPictureStyle QualityLevel  0:Low, 1:Mid, 2:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetPictureStyle();

	/** GetDeviceDefualtPictureStyle */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetDeviceDefualtPictureStyle();

	/** SetPictureStyle */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetPictureStyle(int32 QualityLevel);

	/** GetPictureBrightness QualityLevel  0:Low, 1:Mid, 2:High */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetPictureBrightness();

	/** GetPictureMinBrightness */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetPictureMinBrightness();

	/** GetPictureMaxBrightness */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetPictureMaxBrightness();

	/** GetDeviceDefualtPictureBrightness */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	int32 GetDeviceDefualtPictureBrightness();

	/** SetPictureBrightness */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetPictureBrightness(int32 Brightness);

	/** SetPictureBrightnessRange (default 50, 150)*/
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetPictureBrightnessRange(int32 MinBrightness, int32 MaxBrightness);

	/** SetPictureBrightnessRangeInner (default -0.5, 0.5) 0: no adjustment, -1:2x darker, -2:4x darker, 1:2x brighter, 2:4x brighter, ... */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetPictureBrightnessRangeInner(float MinBrightness, float MaxBrightness);

	/** IsAutoAdaptive */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool IsAutoAdaptive();

	/** GetAutoAdaptive */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool IsDeviceDefualtAutoAdaptive();

	/** SetAutoAdaptive */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetAutoAdaptive(bool AutoAdaptive);

	/** Frame times period lower */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetAdaptiveLowerInterval(float Interval);

	/** Frame times period enhance */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetAdaptiveEnhanceInterval(float Interval);

	/** Frame times threshold lower */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetAdaptiveLowerFPSThreshold(int32 Threshold);

	/** Frame times threshold enhance */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool SetAdaptiveEnhanceFPSThreshold(int32 Threshold);

	/** FreezeAutoAdaptive */
	UFUNCTION(BlueprintCallable, Category = "URenderSettingsManager")
	bool FreezeAutoAdaptive(bool Freeze);

public:

	UPROPERTY()
	FOnRenderQualityAutoAdaptived OnRenderQualityAutoAdaptived;

	UPROPERTY(BlueprintAssignable)
	FOnRenderQualityChanged OnRenderQualityChanged;

	UPROPERTY(BlueprintAssignable)
	FOnRenderQualityChangeBegin OnRenderQualityChangeBegin;

protected:

	/** Items  */
	struct FRenderSettingItems
	{
		FRenderSettingItems():
			ShadowValue(-1),
			EffectsValue(-1.0f),
			FoliageValue(-1.0f),
			ViewDistanceValue(-1.0f),
			DepthOfFieldValue(-1),
			BloomValue(-1)
		{
		}

		/** Shadow  */
		int32 ShadowValue;

		/** Effect */
		int32 EffectsValue;

		/** Foliage */
		int32 FoliageValue;

		/** ViewDistance */
		int32 ViewDistanceValue;

		/** DepthOfField */
		int32 DepthOfFieldValue;

		/** Bloom */
		int32 BloomValue;
	};

	/** Quality level enum */
	enum EQualityLevel
	{
		QL_Low,
		QL_Mid,
		QL_High,
		QL_UltraHigh,
		QL_Num
	};

protected:

	/** Get the BaseDeviceProfile quality of the device */
	int32 GetBaseDeviceProfileQuality(UDeviceProfile* Profile);

	/** Get the BaseDeviceProfile  cvar value of */
	FString GetDefualtDeviceProfileCVarValue(const FString& CVarName);

	/** Get the DeviceProfile cvar value of */
	FString GetDeviceProfileCVarValue(const FString& DeviceProfile, const FString& CVarName);

	/** Get the cvar value from scalability ini file */
	FString GetCVarValueFromScalabilityIni(const FString& ScalabilityGroup, int32 InQualityLevel, const FString& CVarName);

	/** Get the DeviceProfile base quality level index (Low/Mid/High/UltraHigh) */
	EQualityLevel GetDeviceProfileBaseQualityLevel(UDeviceProfile* Profile);

	bool ChangeQuality(int32 NewQualityLevel, int32 OldQualityLevel);

	/** Apply theDeviceProfile to cvar value */
	bool ApplyDeviceProfileSettings(const FString& ProfileName);

	/** Init the default value of the postprocessing */
	void InitDefaultDeviceValue();

	/** Init Console variables */
	void InitConsoleVariables();

	/** Init the render setting value of all quality level */
	void InitAllQualityLevelValues();

	/** Init strip onsole variables */
	void InitStripCVars();

	/** Is in strip var list or not */
	bool IsInStripCVarList(FString& CVar);

	/** Update shadow when setting changed */
	void UpdateShadow();

	/** Adaptive quality */
	bool AdaptiveQuality(int32 QualityLevel);

	/** Level add */
	void OnLevelAdded(ULevel* Level, UWorld* World);

	/** level removed */
	void OnLevelRemoved(ULevel* Level, UWorld* World);

	/** World clean up */
	void OnWorldCleanUp(UWorld* World, bool bSessionEnded, bool bCleanupResources);

protected:

	/** Render setting items of diff quality level */
	TArray<FRenderSettingItems> RenderSettingItems;
	TArray<FString> QualityLevelProfiles;

	/** Back up the default quality level of the default device profile */
	int32 DefualtDeviceQualityLevel;

	/** Device type */
	FString DeviceType;

	/** Current quality level */
	int32 CurrentQualityLevel;

	/** Current quality level */
	int32 AdaptiveQualityLevel;

	/** Back up the default value of the default device profile */
	int32 DefualtDeviceShadowValue;

	/** Back up the default value of the default device profile */
	float DefualtDeviceEffectsValue;

	/** Back up the default value of the default device profile */
	float DefualtDeviceFoliageValue;

	/** Back up the default value of the default device profile */
	float DefualtDeviceViewDistanceValue;

	/** Back up the default value of the default device profile */
	int32 DefualtDeviceDepthOfFieldValue;

	/** Back up the default value of the default device profile */
	int32 DefualtDeviceBloomValue;

	/** Current picture style */
	int32 CurrentPictureStyle;

	/** Current picture brightness */
	int32 CurrentPictureBrightness;

	/** FPS low */
	int32 FPSLow;

	/** FPS low */
	int32 FPSMid;

	/** FPS high */
	int32 FPSHigh;

	/** Min picture brightness */
	int32 PictureMinBrightness;

	/** Max picture brightness */
	int32 PictureMaxBrightness;

	/** Min picture brightness */
	float PictureMinBrightnessInner;

	/** Max picture brightness */
	float PictureMaxBrightnessInner;

	/** Current auto adaptive */
	bool bCurrentAutoAdaptive;

	/** Frame count in a period */
	int32 AdaptiveLowerFrameCount;

	/** Frame times in a period */
	float AdaptiveLowerCountedTime;

	/** Frame count in a period */
	int32 AdaptiveEnhanceFrameCount;

	/** Frame times in a period */
	float AdaptiveEnhanceCountedTime;

	/** Frame times period lower */
	float AdaptiveLowerInterval;

	/** Frame times period enhance */
	float AdaptiveEnhanceInterval;

	/** Frame times threshold lower */
	int32 AdaptiveLowerFPSThreshold;

	/** Frame times threshold enhance */
	int32 AdaptiveEnhanceFPSThreshold;

	/** Is low fps detected or not */
	bool bLowFPSDetected;

	/** Is normal fps detected or not */
	bool bNormalFPSDetected;

	/** Freeze auto adaptive */
	bool bFreezeAutoAdaptive;

	/** CVars list to strip */
	TArray<FString> StripCVars;

	/** Cvar for shadow */
	IConsoleVariable* ShadowQualityCvar;

	/** Cvar for effect */
	IConsoleVariable* EffectQualityCvar;

	/** Cvar for foliage */
	IConsoleVariable* FoliageQualityCvar;

	/** Cvar for view distance */
	IConsoleVariable* ViewDistanceQualityCvar;

	/** Cvar for depth of field */
	IConsoleVariable* DepthOfFieldQualityCvar;

	/** Cvar for bloom */
	IConsoleVariable* BloomQualityCvar;

	/** Cvar for fps quality */
	IConsoleVariable* FPSQualityCvar;

	/** Cmd for fps quality */
	IConsoleCommand* FramePaceCmd;

	/** Auto exposure bias list */
	TMap<uint32, float> AutoExposureBiasMap;

	/** Level added to world handle */
	FDelegateHandle LevelAddedToWorldHandle;

	/** Level removed from world handle */
	FDelegateHandle LevelRemovedFromWorldHandle;

	/** World clean up handle */
	FDelegateHandle WorldCleanupHandle;

};
