
#include "RenderSettingsManager.h"
#include "Common.h"
#include "DeviceProfiles/DeviceProfile.h"
#include "DeviceProfiles/DeviceProfileManager.h"
#include "Engine/PostProcessVolume.h"
#include "GameEngineExt.h"

DEFINE_LOG_CATEGORY_STATIC(LogRenderSettingsManager, Log, All);

#define DEVICETYPE_ANDROID TEXT("Android")
#define DEVICETYPE_WINDOWS TEXT("Windows")
#define DEVICETYPE_IOS TEXT("IOS")
#define DEVICETYPE_WINDOWSCLIENT TEXT("WindowsClient")
#define DEVICETYPE_WINDOWSNOEDITOR TEXT("WindowsNoEditor")
#define DEVICETYPE_MAC TEXT("Mac")
#define DEVICETYPE_MACNOEDITOR TEXT("MacNoEditor")
#define DEVICETYPE_PS4 TEXT("PS4")
#define DEVICETYPE_XBOXONE TEXT("XboxOne")
#define DEVICETYPE_HTML5 TEXT("HTML5")
#define DEVICETYPE_LINUX TEXT("Linux")
#define DEVICETYPE_LINUXNOEDITOR TEXT("LinuxNoEditor")

#define PROFILE_ANDROID_ULTRAHIGH TEXT("Android_UltraHigh")
#define PROFILE_ANDROID_HIGH TEXT("Android_High")
#define PROFILE_ANDROID_MID TEXT("Android_Mid")
#define PROFILE_ANDROID_LOW TEXT("Android_Low")

#define PROFILE_IOS_ULTRAHIGH TEXT("IOS_UltraHigh")
#define PROFILE_IOS_HIGH TEXT("IOS_High")
#define PROFILE_IOS_MID TEXT("IOS_Mid")
#define PROFILE_IOS_LOW TEXT("IOS_Low")

#define PROFILE_WINDOWS_ULTRAHIGH TEXT("Windows_UltraHigh")
#define PROFILE_WINDOWS_HIGH TEXT("Windows_High")
#define PROFILE_WINDOWS_MID TEXT("Windows_Mid")
#define PROFILE_WINDOWS_LOW TEXT("Windows_Low")

#define CONSOLEVAR_SHADOWQUALITY TEXT("r.ShadowQuality")
#define CONSOLEVAR_SG_SHADOWQUALITY TEXT("sg.ShadowQuality")

#define CONSOLEVAR_EMITTERSPAWNRATESCALE TEXT("r.EmitterSpawnRateScale")
#define CONSOLEVAR_SG_EFFECTSQUALITY TEXT("sg.EffectsQuality")

#define CONSOLEVAR_FOLIAGEDENSITYSCALE TEXT("foliage.DensityScale")
#define CONSOLEVAR_SG_FOLIAGEQUALITY TEXT("sg.FoliageQuality")

#define CONSOLEVAR_VIEWDISTANCESCALE TEXT("r.ViewDistanceScale")
#define CONSOLEVAR_SG_VIEWDISTANCEQUALITY TEXT("sg.ViewDistanceQuality")

#define CONSOLEVAR_DEPTHOFFIELDQUALITY TEXT("r.DepthOfFieldQuality")

#define CONSOLEVAR_BLOOMQUALITY TEXT("r.BloomQuality")

#define CONSOLEVAR_FPSQUALITY TEXT("t.MaxFPS")
#define CONSOLECMD_SET_FRAME_PACE TEXT("r.SetFramePace")

#define CONSOLEVAR_SG_POSTPROCESSQUALITY TEXT("sg.PostProcessQuality")

#define PICTURE_STYPE_LUT_01 TEXT("/Game/Resources/FFA/LUT/T_PicutreStyle_Classic_D")
#define PICTURE_STYPE_LUT_02 TEXT("/Game/Resources/FFA/LUT/T_PicutreStyle_Bright_D")
#define PICTURE_STYPE_LUT_03 TEXT("/Game/Resources/FFA/LUT/T_PicutreStyle_Realism_D")
#define PICTURE_STYPE_LUT_04 TEXT("/Game/Resources/FFA/LUT/T_PicutreStyle_Gentle_D")
#define PICTURE_STYPE_LUT_05 TEXT("/Game/Resources/FFA/LUT/T_PicutreStyle_Movie_D")

#define PICTURE_BRIGHTNESS_NORMAL 100

TAutoConsoleVariable<FString> CVarRenderSettingStripCVars(
	TEXT("pir.RenderSettingStripCVars"),
	TEXT(""),
	TEXT("List of cvars to strip in render settings"),
	ECVF_Default);

int32 FPSLowValue = 20;
FAutoConsoleVariableRef CVarFPSLowValue(
	TEXT("pir.FPSLowValue"),
	FPSLowValue,
	TEXT("The value of low FPS.")
);

int32 FPSMidValue = 30;
FAutoConsoleVariableRef CVarFPSMidValue(
	TEXT("pir.FPSMidValue"),
	FPSMidValue,
	TEXT("The value of mid FPS.")
);

int32 FPSHighValue = 60;
FAutoConsoleVariableRef CVarFPSHighValue(
	TEXT("pir.FPSHighValue"),
	FPSHighValue,
	TEXT("The value of high FPS.")
);

void URenderSettingsManager::Init()
{
	RenderSettingItems.SetNum(QL_Num);
	RenderSettingItems.Shrink();

	QualityLevelProfiles.SetNum(QL_Num);
	QualityLevelProfiles.Shrink();

	DefualtDeviceQualityLevel = -1;

	InitConsoleVariables();

	InitStripCVars();

	GetDeviceDefualtQuality();

	check((DefualtDeviceQualityLevel >= 0) && (DefualtDeviceQualityLevel <= 3));
	CurrentQualityLevel = DefualtDeviceQualityLevel;
	AdaptiveQualityLevel = CurrentQualityLevel;

	InitDefaultDeviceValue();

	InitAllQualityLevelValues();

	CurrentPictureStyle = 0;
	CurrentPictureBrightness = PICTURE_BRIGHTNESS_NORMAL;
	FPSLow = FPSLowValue;
	FPSMid = FPSMidValue;
	FPSHigh = FPSHighValue;
	PictureMinBrightness = 50;
	PictureMaxBrightness = 150;
	PictureMinBrightnessInner = -0.5f;
	PictureMaxBrightnessInner = 0.5f;
	bCurrentAutoAdaptive = false;
	AdaptiveLowerFrameCount = 0;
	AdaptiveLowerCountedTime = 0.0f;
	AdaptiveEnhanceFrameCount = 0;
	AdaptiveEnhanceCountedTime = 0.0f;
	AdaptiveLowerInterval = 10.0f;
	AdaptiveEnhanceInterval = 30.0f;
	AdaptiveLowerFPSThreshold = 15;
	AdaptiveEnhanceFPSThreshold = 28;
	bLowFPSDetected = false;
	bNormalFPSDetected = false;
	bFreezeAutoAdaptive = false;

	LevelAddedToWorldHandle = FWorldDelegates::LevelAddedToWorld.AddUObject(this, &URenderSettingsManager::OnLevelAdded);
	LevelRemovedFromWorldHandle = FWorldDelegates::LevelRemovedFromWorld.AddUObject(this, &URenderSettingsManager::OnLevelRemoved);
	WorldCleanupHandle = FWorldDelegates::OnWorldCleanup.AddUObject(this, &URenderSettingsManager::OnWorldCleanUp);
}

void URenderSettingsManager::Clear()
{
	RestoreDeviceDefualtQuality(false);

	AutoExposureBiasMap.Empty();

	FWorldDelegates::LevelAddedToWorld.Remove(LevelAddedToWorldHandle);
	FWorldDelegates::LevelRemovedFromWorld.Remove(LevelRemovedFromWorldHandle);
}

void URenderSettingsManager::OnLevelAdded(ULevel* Level, UWorld* World)
{
	SetPictureStyle(CurrentPictureStyle);
	SetPictureBrightness(CurrentPictureBrightness);
}

void URenderSettingsManager::OnLevelRemoved(ULevel* Level, UWorld* World)
{
}

void URenderSettingsManager::OnWorldCleanUp(UWorld* World, bool bSessionEnded, bool bCleanupResources)
{
	AutoExposureBiasMap.Empty();
}

void URenderSettingsManager::Update(float DeltaTime)
{
	if (bCurrentAutoAdaptive && !bFreezeAutoAdaptive)
	{
		AdaptiveLowerCountedTime += DeltaTime;
		AdaptiveEnhanceCountedTime += DeltaTime;

		// Lower detector
		if (AdaptiveLowerCountedTime < AdaptiveLowerInterval)
		{
			AdaptiveLowerFrameCount++;
		}
		else
		{
			bLowFPSDetected = (AdaptiveLowerFrameCount < AdaptiveLowerFPSThreshold * AdaptiveLowerInterval);

			if (bLowFPSDetected)
			{
				AdaptiveQuality(AdaptiveQualityLevel - 1);
			}

			AdaptiveLowerFrameCount = 0;
			AdaptiveLowerCountedTime = 0.0f;
		}

		// Enhance detector
		if (AdaptiveEnhanceCountedTime < AdaptiveEnhanceInterval)
		{
			AdaptiveEnhanceFrameCount++;

		}
		else
		{
			if (CurrentQualityLevel > AdaptiveQualityLevel)
			{
				bNormalFPSDetected = (AdaptiveEnhanceFrameCount > AdaptiveEnhanceFPSThreshold * AdaptiveEnhanceInterval);

				if (bNormalFPSDetected)
				{
					AdaptiveQuality(AdaptiveQualityLevel + 1);
				}
			}

			AdaptiveEnhanceFrameCount = 0;
			AdaptiveEnhanceCountedTime = 0.0f;
		}

	}
}

int32 URenderSettingsManager::GetBaseDeviceProfileQuality(UDeviceProfile* Profile)
{
	if (nullptr != Profile)
	{
		DeviceType = Profile->DeviceType;

		if (DEVICETYPE_ANDROID == Profile->DeviceType)
		{
			if ((PROFILE_ANDROID_ULTRAHIGH == Profile->GetName()) || (PROFILE_ANDROID_ULTRAHIGH == Profile->BaseProfileName))
			{
				return 3;
			}
			else if ((PROFILE_ANDROID_HIGH == Profile->GetName()) || (PROFILE_ANDROID_HIGH == Profile->BaseProfileName))
			{
				return 2;
			}
			else if ((PROFILE_ANDROID_MID == Profile->GetName()) || (PROFILE_ANDROID_MID == Profile->BaseProfileName))
			{
				return 1;
			}
			else if ((PROFILE_ANDROID_LOW == Profile->GetName()) || (PROFILE_ANDROID_LOW == Profile->BaseProfileName))
			{
				return 0;
			}
			else if (!Profile->BaseProfileName.IsEmpty())
			{
				if (UDeviceProfile* BaseProfile = UDeviceProfileManager::Get().FindProfile(Profile->BaseProfileName))
				{
					return GetBaseDeviceProfileQuality(BaseProfile);
				}
			}
			else
			{
				UE_LOG(LogRenderSettingsManager, Warning, TEXT("GetBaseDeviceProfileQuality not find corresponding Profile DeviceType or name and return -1"));

				return -1;
			}
		}
		else if (DEVICETYPE_IOS == Profile->DeviceType)
		{
			if ((PROFILE_IOS_ULTRAHIGH == Profile->GetName()) || (PROFILE_IOS_ULTRAHIGH == Profile->BaseProfileName))
			{
				return 3;
			}
			else if ((PROFILE_IOS_HIGH == Profile->GetName()) || (PROFILE_IOS_HIGH == Profile->BaseProfileName))
			{
				return 2;
			}
			else if ((PROFILE_IOS_MID == Profile->GetName()) || (PROFILE_IOS_MID == Profile->BaseProfileName))
			{
				return 1;
			}
			else if ((PROFILE_IOS_LOW == Profile->GetName()) || (PROFILE_IOS_LOW == Profile->BaseProfileName))
			{
				return 0;
			}
			else if (!Profile->BaseProfileName.IsEmpty())
			{
				if (UDeviceProfile* BaseProfile = UDeviceProfileManager::Get().FindProfile(Profile->BaseProfileName))
				{
					return GetBaseDeviceProfileQuality(BaseProfile);
				}
			}
			else
			{
				UE_LOG(LogRenderSettingsManager, Warning, TEXT("GetBaseDeviceProfileQuality not find corresponding Profile DeviceType or name and return -1"));

				return -1;
			}
		}
		else if (DEVICETYPE_WINDOWS == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_WINDOWSCLIENT == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_WINDOWSNOEDITOR == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_MAC == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_MACNOEDITOR == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_PS4 == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_XBOXONE == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_HTML5 == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_LINUX == Profile->DeviceType)
		{
			return 3;
		}
		else if (DEVICETYPE_LINUXNOEDITOR == Profile->DeviceType)
		{
			return 3;
		}
	}

	UE_LOG(LogRenderSettingsManager, Warning, TEXT("GetBaseDeviceProfileQuality the Profile is null and return -1"));

	return -1;
}

FString URenderSettingsManager::GetDefualtDeviceProfileCVarValue(const FString& CVarName)
{
	UDeviceProfile* Profile = UDeviceProfileManager::Get().GetActiveProfile();
	auto Index = Profile->CVars.IndexOfByPredicate(
		[&CVarName](const FString& CVar) {
		FString Name;
		CVar.Split(TEXT("="), &Name, NULL);
		return Name == CVarName;
	});

	if (Index != INDEX_NONE)
	{
		FString Value;
		Profile->CVars[Index].Split(TEXT("="), NULL, &Value);
		return Value;
	}
	else
	{
		return FString();
	}
}

FString URenderSettingsManager::GetDeviceProfileCVarValue(const FString& DeviceProfile, const FString& CVarName)
{
	if (UDeviceProfile* Profile = UDeviceProfileManager::Get().FindProfile(DeviceProfile))
	{
		auto Index = Profile->CVars.IndexOfByPredicate(
			[&CVarName](const FString& CVar) {
			FString Name;
			CVar.Split(TEXT("="), &Name, NULL);
			return Name == CVarName;
		});

		if (Index != INDEX_NONE)
		{
			FString Value;
			Profile->CVars[Index].Split(TEXT("="), NULL, &Value);
			return Value;
		}
		else
		{
			if (!Profile->BaseProfileName.IsEmpty())
			{
				return GetDeviceProfileCVarValue(Profile->BaseProfileName, CVarName);
			}

			return FString();
		}
	}

	return FString();
}

FString URenderSettingsManager::GetCVarValueFromScalabilityIni(const FString& ScalabilityGroup, int32 InQualityLevel, const FString& CVarName)
{
	FString SectionName = FString::Printf(TEXT("%s@%d"), *ScalabilityGroup, InQualityLevel);
	if (FConfigSection* Section = GConfig->GetSectionPrivate(*SectionName, false, true, *GScalabilityIni))
	{
		for (FConfigSectionMap::TConstIterator It(*Section); It; ++It)
		{
			const FString& KeyString = It.Key().GetPlainNameString();
			if (KeyString == CVarName)
			{
				return It.Value().GetValue();
			}
		}
	}

	return FString();
}

URenderSettingsManager::EQualityLevel URenderSettingsManager::GetDeviceProfileBaseQualityLevel(UDeviceProfile* Profile)
{
	EQualityLevel Level = (EQualityLevel)INDEX_NONE;

	if (DEVICETYPE_ANDROID == DeviceType)
	{
		if (Profile->BaseProfileName.Equals(PROFILE_ANDROID_LOW))
		{
			Level = QL_Low;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_ANDROID_MID))
		{
			Level = QL_Mid;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_ANDROID_HIGH))
		{
			Level = QL_High;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_ANDROID_ULTRAHIGH))
		{
			Level = QL_UltraHigh;
		}
	}
	else if (DEVICETYPE_IOS == DeviceType)
	{
		if (Profile->BaseProfileName.Equals(PROFILE_IOS_LOW))
		{
			Level = QL_Low;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_IOS_MID))
		{
			Level = QL_Mid;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_IOS_HIGH))
		{
			Level = QL_High;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_IOS_ULTRAHIGH))
		{
			Level = QL_UltraHigh;
		}
	}
	else if ((DEVICETYPE_WINDOWS == DeviceType) ||
		(DEVICETYPE_WINDOWSCLIENT == DeviceType)||
		(DEVICETYPE_WINDOWSNOEDITOR == DeviceType))
	{
		if (Profile->BaseProfileName.Equals(PROFILE_WINDOWS_LOW))
		{
			Level = QL_Low;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_WINDOWS_MID))
		{
			Level = QL_Mid;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_WINDOWS_HIGH))
		{
			Level = QL_High;
		}
		else if (Profile->BaseProfileName.Equals(PROFILE_WINDOWS_ULTRAHIGH))
		{
			Level = QL_UltraHigh;
		}
	}
	else
	{
		UE_LOG(LogRenderSettingsManager, Warning, TEXT("GetDeviceProfileBaseQualityLevel device type %s not find (profile name %s) "), *DeviceType, *Profile->GetName());
	}

	if (Level == (EQualityLevel)INDEX_NONE)
	{
		if (!Profile->BaseProfileName.IsEmpty())
		{
			UDeviceProfile* Parent = UDeviceProfileManager::Get().FindProfile(Profile->BaseProfileName);
			if (Parent && Parent != Profile)
			{
				Level = GetDeviceProfileBaseQualityLevel(Parent);
			}
		}
	}

	return Level;
}

bool URenderSettingsManager::ChangeQuality(int32 NewQualityLevel, int32 OldQualityLevel)
{
	if ((NewQualityLevel == OldQualityLevel) ||
		(NewQualityLevel < 0) || (NewQualityLevel > 3) ||
		(OldQualityLevel < 0) || (OldQualityLevel > 3))
	{
		return false;
	}

	// Tell client render quality begin change
	OnRenderQualityChangeBegin.Broadcast(OldQualityLevel, NewQualityLevel);

	// Apply quality level profile
	check(QualityLevelProfiles.Num() > NewQualityLevel);
	ApplyDeviceProfileSettings(QualityLevelProfiles[NewQualityLevel]);

	// Tell client render quality changed
	OnRenderQualityChanged.Broadcast(OldQualityLevel, NewQualityLevel);

	return true;
}

bool URenderSettingsManager::ApplyDeviceProfileSettings(const FString& ProfileName)
{
	UE_LOG(LogRenderSettingsManager, Log, TEXT("ApplyDeviceProfileSettings %s "), *ProfileName);

	UDeviceProfile* ActiveProfile = UDeviceProfileManager::Get().FindProfile(ProfileName);
	// Load the device profile config
	FString DeviceProfileFileName;
	FConfigCacheIni::LoadGlobalIniFile(DeviceProfileFileName, TEXT("DeviceProfiles"));

	TArray< FString > AvailableProfiles;
	GConfig->GetSectionNames(DeviceProfileFileName, AvailableProfiles);

	FString AdditionalProfileFileName;

	if ((UGameEngineExt::Get(this) != nullptr) &&
		(UGameEngineExt::Get(this)->GetEngineConfig() != nullptr))
	{
		FString AdditionalProfilePath = UGameEngineExt::Get(this)->GetEngineConfig()->AdditionalDeviceProfileConfigPath;
		AdditionalProfileFileName = FPaths::ProjectContentDir() / AdditionalProfilePath;

		TArray< FString > AdditionalProfiles;
		GConfig->GetSectionNames(AdditionalProfileFileName, AdditionalProfiles);

		AvailableProfiles.Append(AdditionalProfiles);
	}

	// Next we need to create a hierarchy of CVars from the Selected Device Profile, to it's eldest parent
	TMap<FString, FString> CVarsAlreadySetList;
	// For each device profile, starting with the selected and working our way up the BaseProfileName tree,
	// Find all CVars and set them 
	FString BaseDeviceProfileName = ProfileName;
	
	bool bReachedEndOfTree = BaseDeviceProfileName.IsEmpty();
	while (bReachedEndOfTree == false)
	{
		FString CurrentSectionName = FString::Printf(TEXT("%s %s"), *BaseDeviceProfileName, *UDeviceProfile::StaticClass()->GetName());

		// Check the profile was available.
		bool bProfileExists = AvailableProfiles.Contains(CurrentSectionName) || ActiveProfile;;
		if (bProfileExists)
		{
			TArray< FString > CurrentProfilesCVars;

			if (ActiveProfile)
			{
				CurrentProfilesCVars = ActiveProfile->CVars;
			}
			else
			{
				GConfig->GetArray(*CurrentSectionName, TEXT("CVars"), CurrentProfilesCVars, AdditionalProfileFileName);

				if (CurrentProfilesCVars.Num() == 0)
				{
					GConfig->GetArray(*CurrentSectionName, TEXT("CVars"), CurrentProfilesCVars, DeviceProfileFileName);
				}
			}

			// Iterate over the profile and make sure we do not have duplicate CVars
			{
				TMap< FString, FString > ValidCVars;
				for (TArray< FString >::TConstIterator CVarIt(CurrentProfilesCVars); CVarIt; ++CVarIt)
				{
					FString CVarKey, CVarValue;
					if ((*CVarIt).Split(TEXT("="), &CVarKey, &CVarValue))
					{
						if (ValidCVars.Find(CVarKey))
						{
							ValidCVars.Remove(CVarKey);
						}

						ValidCVars.Add(CVarKey, CVarValue);
					}
				}

				// Empty the current list, and replace with the processed CVars. This removes duplicates
				CurrentProfilesCVars.Empty();

				for (TMap< FString, FString >::TConstIterator ProcessedCVarIt(ValidCVars); ProcessedCVarIt; ++ProcessedCVarIt)
				{
					CurrentProfilesCVars.Add(FString::Printf(TEXT("%s=%s"), *ProcessedCVarIt.Key(), *ProcessedCVarIt.Value()));
				}

			}

			// Iterate over this profiles cvars and set them if they haven't been already.
			for (TArray< FString >::TConstIterator CVarIt(CurrentProfilesCVars); CVarIt; ++CVarIt)
			{
				FString CVarKey, CVarValue;
				if ((*CVarIt).Split(TEXT("="), &CVarKey, &CVarValue))
				{
					if (!CVarsAlreadySetList.Find(CVarKey))
					{
						IConsoleVariable* CVar = IConsoleManager::Get().FindConsoleVariable(*CVarKey);
						if (nullptr == CVar)
						{
							UE_LOG(LogRenderSettingsManager, Warning, TEXT("Creating unregistered Device Profile CVar: [[%s:%s]]"), *CVarKey, *CVarValue);
						}

						// Only set that no in strip cvar list
						if (!IsInStripCVarList(CVarKey))
						{
							OnSetCVarFromIniEntry(*DeviceProfileFileName, *CVarKey, *CVarValue, ECVF_SetByDeviceProfile);
						}
						CVarsAlreadySetList.Add(CVarKey, CVarValue);
					}
				}
			}

			// Get the next device profile name, to look for CVars in, along the tree
			FString NextBaseDeviceProfileName = ActiveProfile ? ActiveProfile->BaseProfileName : TEXT("");
			if (!NextBaseDeviceProfileName.IsEmpty())
			{
				BaseDeviceProfileName = NextBaseDeviceProfileName;
				UE_LOG(LogInit, Log, TEXT("Going up to parent DeviceProfile [%s]"), *BaseDeviceProfileName);
			}
			else if (GConfig->GetString(*CurrentSectionName, TEXT("BaseProfileName"), NextBaseDeviceProfileName, AdditionalProfileFileName))
			{
				BaseDeviceProfileName = NextBaseDeviceProfileName;
				UE_LOG(LogInit, Log, TEXT("Going up to parent DeviceProfile [%s]"), *BaseDeviceProfileName);
			}
			else if (GConfig->GetString(*CurrentSectionName, TEXT("BaseProfileName"), NextBaseDeviceProfileName, BaseDeviceProfileName)) 
			{
				BaseDeviceProfileName = NextBaseDeviceProfileName;
				UE_LOG(LogInit, Log, TEXT("Going up to parent DeviceProfile [%s]"), *BaseDeviceProfileName);
			}
			else
			{
				BaseDeviceProfileName.Empty();
			}
		}

		// Check if we have inevitably reached the end of the device profile tree.
		bReachedEndOfTree = !bProfileExists || BaseDeviceProfileName.IsEmpty();
		ActiveProfile = ActiveProfile ? Cast<UDeviceProfile>(ActiveProfile->Parent) : nullptr;
	}

	return true;
}

void URenderSettingsManager::InitDefaultDeviceValue()
{
	// Shadow
	check(ShadowQualityCvar != nullptr);
	DefualtDeviceShadowValue = ShadowQualityCvar->GetInt();
	check(DefualtDeviceShadowValue >= 0);

	// Effect
	check(EffectQualityCvar != nullptr);
	DefualtDeviceEffectsValue = EffectQualityCvar->GetInt();
	check(DefualtDeviceEffectsValue >= 0);

	// Foliage
	check(FoliageQualityCvar != nullptr);
	DefualtDeviceFoliageValue = FoliageQualityCvar->GetInt();
	check(DefualtDeviceFoliageValue >= 0);

	// ViewDistance
	check(ViewDistanceQualityCvar != nullptr);
	DefualtDeviceViewDistanceValue = ViewDistanceQualityCvar->GetInt();
	check(DefualtDeviceViewDistanceValue >= 0);

	// DepthOfField
	check(DepthOfFieldQualityCvar != nullptr);
	DefualtDeviceDepthOfFieldValue = DepthOfFieldQualityCvar->GetInt();
	check(DefualtDeviceDepthOfFieldValue >= 0);

	// Bloom
	check(BloomQualityCvar != nullptr);
	DefualtDeviceBloomValue = BloomQualityCvar->GetInt();
	check(DefualtDeviceBloomValue >= 0);

	// Clamp to valid value as cinema mode > 3 in editor
#if WITH_EDITOR
	if (DefualtDeviceShadowValue > 3)
	{
		ShadowQualityCvar->Set(3);
	}

	if (DefualtDeviceEffectsValue > 3)
	{
		EffectQualityCvar->Set(3);
	}

	if (DefualtDeviceFoliageValue > 3)
	{
		FoliageQualityCvar->Set(3);
	}

	if (DefualtDeviceViewDistanceValue > 3)
	{
		ViewDistanceQualityCvar->Set(3);
	}

	if (DefualtDeviceDepthOfFieldValue > 3)
	{
		DepthOfFieldQualityCvar->Set(3);
	}

	if (DefualtDeviceBloomValue > 3)
	{
		BloomQualityCvar->Set(3);
	}
#endif

	UE_LOG(LogRenderSettingsManager, Log, TEXT("InitDefaultDeviceValue over."));

}

void URenderSettingsManager::InitConsoleVariables()
{
	// Shadow
	ShadowQualityCvar = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_SG_SHADOWQUALITY);
	check(ShadowQualityCvar != nullptr);

	// Effect
	EffectQualityCvar = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_SG_EFFECTSQUALITY);
	check(EffectQualityCvar != nullptr);

	// Foliage
	FoliageQualityCvar = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_SG_FOLIAGEQUALITY);
	check(FoliageQualityCvar != nullptr);

	// ViewDistance
	ViewDistanceQualityCvar = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_SG_VIEWDISTANCEQUALITY);
	check(ViewDistanceQualityCvar != nullptr);

	// DepthOfField
	DepthOfFieldQualityCvar = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_DEPTHOFFIELDQUALITY);
	check(DepthOfFieldQualityCvar != nullptr);

	// Bloom
	BloomQualityCvar = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_BLOOMQUALITY);
	check(BloomQualityCvar != nullptr);

	// FPS
	FPSQualityCvar = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_FPSQUALITY);
	check(FPSQualityCvar != nullptr);

	IConsoleObject* FramePaceObj = IConsoleManager::Get().FindConsoleObject(CONSOLECMD_SET_FRAME_PACE);
	FramePaceCmd = FramePaceObj ? FramePaceObj->AsCommand() : nullptr;
	check(FramePaceCmd != nullptr);

	UE_LOG(LogRenderSettingsManager, Log, TEXT("InitConsoleVariables over."));

}

void URenderSettingsManager::InitAllQualityLevelValues()
{
	UDeviceProfile* Profile = UDeviceProfileManager::Get().GetActiveProfile();
	check(Profile != nullptr);
	EQualityLevel ProfileBaseLevel = GetDeviceProfileBaseQualityLevel(Profile);

	// Now we only consider android platform, change here if ios needed.
	const TCHAR* AndroidLevelNames[] = {
		PROFILE_ANDROID_LOW,
		PROFILE_ANDROID_MID,
		PROFILE_ANDROID_HIGH,
		PROFILE_ANDROID_ULTRAHIGH,
	};
	const TCHAR* IOSLevelNames[] = {
		PROFILE_IOS_LOW,
		PROFILE_IOS_MID,
		PROFILE_IOS_HIGH,
		PROFILE_IOS_ULTRAHIGH,
	};
	const TCHAR* WindowsLevelNames[] = {
		PROFILE_WINDOWS_LOW,
		PROFILE_WINDOWS_MID,
		PROFILE_WINDOWS_HIGH,
		PROFILE_WINDOWS_ULTRAHIGH,
	};

	FString ProfileName;
	for (int32 i = 0; i < QL_Num; i++)
	{
		if (i == (int32)ProfileBaseLevel)
		{
			ProfileName = Profile->GetName();
		}
		else 
		{
			if (DEVICETYPE_ANDROID == DeviceType)
			{
				ProfileName = AndroidLevelNames[i];
			}
			else if (DEVICETYPE_IOS == DeviceType)
			{
				ProfileName = IOSLevelNames[i];
			}
			else if ((DEVICETYPE_WINDOWS == DeviceType) ||
				(DEVICETYPE_WINDOWSCLIENT == DeviceType) ||
				(DEVICETYPE_WINDOWSNOEDITOR == DeviceType))
			{
				ProfileName = WindowsLevelNames[i];
			}
			else
			{
				ProfileName = Profile->GetName();
			}
		}

		QualityLevelProfiles[i] = ProfileName;

		UE_LOG(LogRenderSettingsManager, Log, TEXT("QualityLevelProfiles %d : %s"), i, *ProfileName);

		// ShadowQuality
		FString ShadowQuality = GetDeviceProfileCVarValue(ProfileName, CONSOLEVAR_SG_SHADOWQUALITY);
		// No setting for shadow quality, set to default value
		if (ShadowQuality.IsEmpty())
		{
			RenderSettingItems[i].ShadowValue = ShadowQualityCvar->GetInt();
		}
		else
		{
			RenderSettingItems[i].ShadowValue = FCString::Atoi(*ShadowQuality);
		}
		check(RenderSettingItems[i].ShadowValue >= 0);

		// EffectsQuality
		FString EffectsQuality = GetDeviceProfileCVarValue(ProfileName, CONSOLEVAR_SG_EFFECTSQUALITY);
		// No setting for shadow quality, set to default value
		if (EffectsQuality.IsEmpty())
		{
			RenderSettingItems[i].EffectsValue = EffectQualityCvar->GetInt();
		}
		else
		{
			RenderSettingItems[i].EffectsValue = FCString::Atoi(*EffectsQuality);
		}
		check((RenderSettingItems[i].EffectsValue >= 0) && (RenderSettingItems[i].EffectsValue <= 3));

		// FoliageQuality
		FString FoliageQuality = GetDeviceProfileCVarValue(ProfileName, CONSOLEVAR_SG_FOLIAGEQUALITY);
		// No setting for shadow quality, set to default value
		if (FoliageQuality.IsEmpty())
		{
			RenderSettingItems[i].FoliageValue = FoliageQualityCvar->GetInt();
		}
		else
		{
			RenderSettingItems[i].FoliageValue = FCString::Atoi(*FoliageQuality);
		}
		check((RenderSettingItems[i].FoliageValue >= 0) && (RenderSettingItems[i].FoliageValue <= 3));

		// ViewDistanceQuality
		FString ViewDistanceQuality = GetDeviceProfileCVarValue(ProfileName, CONSOLEVAR_SG_VIEWDISTANCEQUALITY);
		// No setting for shadow quality, set to default value
		if (ViewDistanceQuality.IsEmpty())
		{
			RenderSettingItems[i].ViewDistanceValue = ViewDistanceQualityCvar->GetInt();
		}
		else
		{
			RenderSettingItems[i].ViewDistanceValue = FCString::Atoi(*ViewDistanceQuality);
		}
		check((RenderSettingItems[i].ViewDistanceValue >= 0) && (RenderSettingItems[i].ViewDistanceValue <= 3));

		// DepthOfFieldQuality
		FString DepthOfFieldQuality = GetDeviceProfileCVarValue(ProfileName, CONSOLEVAR_DEPTHOFFIELDQUALITY);
		if (DepthOfFieldQuality.IsEmpty())
		{
			DepthOfFieldQuality = GetDeviceProfileCVarValue(ProfileName, CONSOLEVAR_SG_POSTPROCESSQUALITY);
			if (!DepthOfFieldQuality.IsEmpty())
			{
				DepthOfFieldQuality = GetCVarValueFromScalabilityIni("PostProcessQuality", FCString::Atoi(*DepthOfFieldQuality), CONSOLEVAR_DEPTHOFFIELDQUALITY);
			}
		}
		// No setting for shadow quality, set to default value
		if (DepthOfFieldQuality.IsEmpty())
		{
			RenderSettingItems[i].DepthOfFieldValue = DepthOfFieldQualityCvar->GetInt();
		}
		else
		{
			RenderSettingItems[i].DepthOfFieldValue = FCString::Atoi(*DepthOfFieldQuality);
		}
		check(RenderSettingItems[i].DepthOfFieldValue >= 0);
		// Unify the value of different level
		if (RenderSettingItems[i].DepthOfFieldValue > 0)
		{
			RenderSettingItems[i].DepthOfFieldValue = (DefualtDeviceDepthOfFieldValue > 0) ? DefualtDeviceDepthOfFieldValue : 1;
		}

		// BloomQuality
		FString BloomQuality = GetDeviceProfileCVarValue(ProfileName, CONSOLEVAR_BLOOMQUALITY);
		if (BloomQuality.IsEmpty())
		{
			BloomQuality = GetDeviceProfileCVarValue(ProfileName, CONSOLEVAR_SG_POSTPROCESSQUALITY);
			if (!BloomQuality.IsEmpty())
			{
				BloomQuality = GetCVarValueFromScalabilityIni("PostProcessQuality", FCString::Atoi(*BloomQuality), CONSOLEVAR_BLOOMQUALITY);
			}
		}
		// No setting for shadow quality, set to default value
		if (BloomQuality.IsEmpty())
		{
			RenderSettingItems[i].BloomValue = BloomQualityCvar->GetInt();
		}
		else
		{
			RenderSettingItems[i].BloomValue = FCString::Atoi(*BloomQuality);
		}
		check(RenderSettingItems[i].BloomValue >= 0);
		// Unify the value of different level
		if (RenderSettingItems[i].BloomValue > 0)
		{
			RenderSettingItems[i].BloomValue = (DefualtDeviceBloomValue > 0) ? DefualtDeviceBloomValue : 1;
		}

	}

	UE_LOG(LogRenderSettingsManager, Log, TEXT("InitAllQualityLevelValues over."));

}

void URenderSettingsManager::InitStripCVars()
{
	TArray<FString> CVarList;
	FString StripString = CVarRenderSettingStripCVars.GetValueOnAnyThread();
	StripString.ParseIntoArray(CVarList, TEXT(","), /*InCullEmpty=*/true);

	for (FString& ExtName : CVarList)
	{
		ExtName.TrimStartAndEndInline();
		StripCVars.Add(ExtName.ToLower());
	}
}

bool URenderSettingsManager::IsInStripCVarList(FString& CVar)
{
	FString LowerCVar = CVar;
	return StripCVars.Find(LowerCVar.ToLower()) >= 0;
}

void URenderSettingsManager::UpdateShadow()
{
    /*ASimpleShadow* ShadowActorPtr = ASimpleShadow::Get(GetOuter()->GetWorld());
    if (ShadowActorPtr)
    {
        ShadowActorPtr->InitializeShadow();
    }*/
}

bool URenderSettingsManager::AdaptiveQuality(int32 QualityLevel)
{
	// Avoid invalid setting
	if ((QualityLevel < 0) || (QualityLevel > 3))
	{
		return false;
	}

	float LastQualityLevel = AdaptiveQualityLevel;

	AdaptiveQualityLevel = QualityLevel;

	UE_LOG(LogRenderSettingsManager, Log, TEXT("AdaptiveQuality level %d "), QualityLevel);

	ChangeQuality(AdaptiveQualityLevel, LastQualityLevel);

	// Send an event to client
	OnRenderQualityAutoAdaptived.Execute(LastQualityLevel, QualityLevel);

	//check(RenderSettingItems.Num() >= QualityLevel);
	//SetShadowQuality(RenderSettingItems[QualityLevel].ShadowValue);
	//SetEffectsQuality(RenderSettingItems[QualityLevel].EffectsValue);
	//SetFoliageQuality(RenderSettingItems[QualityLevel].FoliageValue);
	//SetViewDistanceQuality(RenderSettingItems[QualityLevel].ViewDistanceValue);
	//SetDepthOfFieldEnabled(RenderSettingItems[QualityLevel].DepthOfFieldValue > 0);
	//SetBloomEnabled(RenderSettingItems[QualityLevel].BloomValue > 0);

	return true;
}

int32 URenderSettingsManager::GetDeviceDefualtQuality()
{
	if (DefualtDeviceQualityLevel < 0)
	{
		UDeviceProfile* Profile = UDeviceProfileManager::Get().GetActiveProfile();
		check(Profile != nullptr);
		DefualtDeviceQualityLevel = GetBaseDeviceProfileQuality(Profile);
	}

	return DefualtDeviceQualityLevel;
}

bool URenderSettingsManager::RestoreDeviceDefualtQuality(bool ApplyChanges)
{
	//UDeviceProfileManager::Get().InitializeCVarsForActiveDeviceProfile();

	// Shadow
	check(ShadowQualityCvar != nullptr);
	ShadowQualityCvar->Set(DefualtDeviceShadowValue, ECVF_SetByDeviceProfile);
	if (ApplyChanges)
	{
		UpdateShadow();
	}

	// Effect
	check(EffectQualityCvar != nullptr);
	EffectQualityCvar->Set(DefualtDeviceEffectsValue, ECVF_SetByDeviceProfile);

	// Foliage
	check(FoliageQualityCvar != nullptr);
	FoliageQualityCvar->Set(DefualtDeviceFoliageValue, ECVF_SetByDeviceProfile);

	// ViewDistance
	check(ViewDistanceQualityCvar != nullptr);
	ViewDistanceQualityCvar->Set(DefualtDeviceViewDistanceValue, ECVF_SetByDeviceProfile);

	// DepthOfField
	check(DepthOfFieldQualityCvar != nullptr);
	DepthOfFieldQualityCvar->Set(DefualtDeviceDepthOfFieldValue, ECVF_SetByDeviceProfile);

	// Bloom
	check(BloomQualityCvar != nullptr);
	BloomQualityCvar->Set(DefualtDeviceBloomValue, ECVF_SetByDeviceProfile);

	UE_LOG(LogRenderSettingsManager, Log, TEXT("RestoreDeviceDefualtQuality over."));

	return true;
}

int32 URenderSettingsManager::GetQuality()
{
	check((CurrentQualityLevel >= 0) && (CurrentQualityLevel <= 3));
	return CurrentQualityLevel;
}

bool URenderSettingsManager::SetQuality(int32 QualityLevel)
{
	// Avoid invalid setting
	if ((QualityLevel < 0) || (QualityLevel > 3))
	{
		return false;
	}

	int32 LastQualityLevel = CurrentQualityLevel;
	CurrentQualityLevel = QualityLevel;
	AdaptiveQualityLevel = QualityLevel;

	UE_LOG(LogRenderSettingsManager, Log, TEXT("URenderSettingsManager::SetQuality %d "), QualityLevel);

	//FString ProfileName = UDeviceProfileManager::Get().GetActiveProfile()->GetName();
	//switch (QualityLevel)
	//{
	//case 0 :
	//	ProfileName = "Android_Low";
	//	break;
	//case 1:
	//	ProfileName = "Android_Mid";
	//	break;
	//case 2:
	//	ProfileName = "Android_High";
	//	break;
	//case 3:
	//	ProfileName = "Android_UltraHigh";
	//	break;
	//default:
	//	break;
	//}

	//ApplyDeviceProfileSettings(ProfileName);

	ChangeQuality(QualityLevel, LastQualityLevel);

	//check(RenderSettingItems.Num() >= QualityLevel);
	//SetShadowQuality(RenderSettingItems[QualityLevel].ShadowValue);
	//SetEffectsQuality(RenderSettingItems[QualityLevel].EffectsValue);
	//SetFoliageQuality(RenderSettingItems[QualityLevel].FoliageValue);
	//SetViewDistanceQuality(RenderSettingItems[QualityLevel].ViewDistanceValue);
	//SetDepthOfFieldEnabled(RenderSettingItems[QualityLevel].DepthOfFieldValue > 0);
	//SetBloomEnabled(RenderSettingItems[QualityLevel].BloomValue > 0);

	return true;
}

int32 URenderSettingsManager::GetInnerQuality()
{
	check((CurrentQualityLevel >= 0) && (CurrentQualityLevel <= 3));
	check((AdaptiveQualityLevel >= 0) && (AdaptiveQualityLevel <= 3));

	return bCurrentAutoAdaptive ? AdaptiveQualityLevel : CurrentQualityLevel;
}

int32 URenderSettingsManager::GetFPSQuality()
{
	check(FPSQualityCvar != nullptr);
	int32 FPS = FPSQualityCvar->GetInt();

	int32 QualityLevel = 1;
	if (FPS == FPSLow)
	{
		QualityLevel = 0;
	}
	else if (FPS == FPSMid)
	{
		QualityLevel = 1;
	}
	else if (FPS == FPSHigh)
	{
		QualityLevel = 2;
	}
	// Default value uncapped
	else if (FPS == 0)
	{
		QualityLevel = 1;
	}
	else
	{
		UE_LOG(LogRenderSettingsManager, Error, TEXT("URenderSettingsManager::GetFPSQuality FPS error : %d."), FPS);
	}

	return QualityLevel;
}

int32 URenderSettingsManager::GetDeviceDefualtFPSQuality()
{
	return 1;
}

bool URenderSettingsManager::SetFPSQuality(int32 QualityLevel)
{
	// Avoid invalid setting
	if ((QualityLevel < 0) || (QualityLevel > 3))
	{
		return false;
	}

	int32 FPS = FPSMid;
	switch (QualityLevel)
	{
	case 0:
		{
			FPS = FPSLow;
		}
		break;
	case 1:
		{
			FPS = FPSMid;
		}
		break;
	case 2:
		{
			FPS = FPSHigh;
		}
		break;
	}

	check(FPSQualityCvar != nullptr);
	FPSQualityCvar->Set(FPS, ECVF_SetByDeviceProfile);

	check(FramePaceCmd != nullptr);
	TArray<FString> Args;
	Args.Add(FString::Printf(TEXT("%i"), FPS));
	FramePaceCmd->Execute(Args, nullptr, *GLog);

	return true;
}

bool URenderSettingsManager::SetFPSValueOfQuality(int32 Low, int32 Mid, int32 High)
{
	if ((Low <= 0) || (Mid <= 0) || (High <= 0) || (Low > Mid) || (Mid > High))
	{
		return false;
	}

	FPSLow = Low;
	FPSMid = Mid;
	FPSHigh = High;

	return true;
}

int32 URenderSettingsManager::GetShadowQuality()
{
	// For PIE we only check greater than 0
	check(ShadowQualityCvar != nullptr);
	check((ShadowQualityCvar->GetInt() >= 0));
	return ShadowQualityCvar->GetInt();
}

int32 URenderSettingsManager::GetDeviceDefualtShadowQuality()
{
	return DefualtDeviceShadowValue;
}

bool URenderSettingsManager::SetShadowQuality(int32 QualityLevel)
{
	// Avoid invalid setting
	if ((QualityLevel < 0) || (QualityLevel > 3))
	{
		return false;
	}

	check(ShadowQualityCvar != nullptr);
	ShadowQualityCvar->Set(QualityLevel, ECVF_SetByDeviceProfile);

	UpdateShadow();

	return true;
}

int32 URenderSettingsManager::GetEffectsQuality()
{
	check(EffectQualityCvar != nullptr);
	check((EffectQualityCvar->GetInt() >= 0) && (EffectQualityCvar->GetInt() <= 3));
	return EffectQualityCvar->GetInt();
}

int32 URenderSettingsManager::GetDeviceDefualtEffectsQuality()
{
	return DefualtDeviceEffectsValue;
}

bool URenderSettingsManager::SetEffectsQuality(int32 QualityLevel)
{
	// Avoid invalid setting
	if ((QualityLevel < 0) || (QualityLevel > 3))
	{
		return false;
	}

	check(EffectQualityCvar != nullptr);
	EffectQualityCvar->Set(QualityLevel, ECVF_SetByDeviceProfile);

	return true;
}

int32 URenderSettingsManager::GetFoliageQuality()
{
	check(FoliageQualityCvar != nullptr);
	check((FoliageQualityCvar->GetInt() >= 0) && (FoliageQualityCvar->GetInt() <= 3));
	return FoliageQualityCvar->GetInt();
}

int32 URenderSettingsManager::GetDeviceDefualtFoliageQuality()
{
	return DefualtDeviceFoliageValue;
}

bool URenderSettingsManager::SetFoliageQuality(int32 QualityLevel)
{
	// Avoid invalid setting
	if ((QualityLevel < 0) || (QualityLevel > 3))
	{
		return false;
	}

	check(FoliageQualityCvar != nullptr);
	FoliageQualityCvar->Set(QualityLevel, ECVF_SetByDeviceProfile);

	return true;
}

int32 URenderSettingsManager::GetViewDistanceQuality()
{
	check(ViewDistanceQualityCvar != nullptr);
	check((ViewDistanceQualityCvar->GetInt() >= 0) && (ViewDistanceQualityCvar->GetInt() <= 3));
	return ViewDistanceQualityCvar->GetInt();
}

int32 URenderSettingsManager::GetDeviceDefualtViewDistanceQuality()
{
	return DefualtDeviceViewDistanceValue;
}

bool URenderSettingsManager::SetViewDistanceQuality(int32 QualityLevel)
{
	// Avoid invalid setting
	if ((QualityLevel < 0) || (QualityLevel > 3))
	{
		return false;
	}

	check(ViewDistanceQualityCvar != nullptr);
	ViewDistanceQualityCvar->Set(QualityLevel, ECVF_SetByDeviceProfile);

	return true;
}

bool URenderSettingsManager::IsDepthOfFieldEnabled()
{
	check(DepthOfFieldQualityCvar != nullptr);
	return DepthOfFieldQualityCvar->GetInt() > 0;
}

bool URenderSettingsManager::IsDeviceDefualtDepthOfFieldEnabled()
{
	return DefualtDeviceDepthOfFieldValue > 0;
}

bool URenderSettingsManager::SetDepthOfFieldEnabled(bool Enable)
{
	// Low device can not enable 
	if (Enable && (0 == DefualtDeviceQualityLevel))
	{
		return false;
	}

	check(DepthOfFieldQualityCvar != nullptr);
	DepthOfFieldQualityCvar->Set(Enable ? (DefualtDeviceDepthOfFieldValue > 0 ? DefualtDeviceDepthOfFieldValue : 1) : 0, ECVF_SetByDeviceProfile);

	return true;
}

bool URenderSettingsManager::IsBloomEnabled()
{
	check(BloomQualityCvar != nullptr);
	return BloomQualityCvar->GetInt() > 0;
}

bool URenderSettingsManager::IsDeviceDefualtBloomEnabled()
{
	return DefualtDeviceBloomValue > 0;
}

bool URenderSettingsManager::SetBloomEnabled(bool Enable)
{
	// Low device can not enable 
	if (Enable && (0 == DefualtDeviceQualityLevel))
	{
		return false;
	}

	check(BloomQualityCvar != nullptr);
	BloomQualityCvar->Set(Enable ? (DefualtDeviceBloomValue > 0 ? DefualtDeviceBloomValue : 1) : 0, ECVF_SetByDeviceProfile);

	return true;
}

bool URenderSettingsManager::IsAAEnabled()
{
	return true;
}

bool URenderSettingsManager::IsDeviceDefualtAAEnabled()
{
	return true;
}

bool URenderSettingsManager::SetAAEnabled(bool Enable)
{
	return true;
}

int32 URenderSettingsManager::GetPictureStyle()
{
	return CurrentPictureStyle;
}

int32 URenderSettingsManager::GetDeviceDefualtPictureStyle()
{
	return 0;
}

bool URenderSettingsManager::SetPictureStyle(int32 QualityLevel)
{
	CurrentPictureStyle = QualityLevel;

	TArray<AActor*> PostProcessVolumes;
	UGameplayStatics::GetAllActorsOfClass(GetOuter()->GetWorld(), APostProcessVolume::StaticClass(), PostProcessVolumes);
	for (auto& Actor : PostProcessVolumes)
	{
		APostProcessVolume* PostProcessVolume = Cast<APostProcessVolume>(Actor);
		if (PostProcessVolume->IsValidLowLevel())
		{
			FString LUTTextureName;
			switch (QualityLevel)
			{
			case 0:
			{
				LUTTextureName = PICTURE_STYPE_LUT_01;
			}
			break;
			case 1:
			{
				LUTTextureName = PICTURE_STYPE_LUT_02;
			}
			break;
			case 2:
			{
				LUTTextureName = PICTURE_STYPE_LUT_03;
			}
			break;
			case 3:
			{
				LUTTextureName = PICTURE_STYPE_LUT_04;
			}
			break;
			case 4:
			{
				LUTTextureName = PICTURE_STYPE_LUT_05;
			}
			break;
			}

			UTexture2D* LUTTexture = LoadObject<UTexture2D>(nullptr, *LUTTextureName);

			if (LUTTexture->IsValidLowLevel())
			{
				PostProcessVolume->Settings.bOverride_ColorGradingLUT = true;
				PostProcessVolume->Settings.ColorGradingLUT = LUTTexture;
			}
		}
	}

	return true;
}

bool URenderSettingsManager::SetPictureBrightness(int32 Brightness)
{
	if ((Brightness < PictureMinBrightness) || (Brightness > PictureMaxBrightness))
	{
		return false;
	}

	CurrentPictureBrightness = Brightness;

	const float BrightnessRange = 0.5f;

	TArray<AActor*> PostProcessVolumes;
	UGameplayStatics::GetAllActorsOfClass(GetOuter()->GetWorld(), APostProcessVolume::StaticClass(), PostProcessVolumes);
	for (auto& Actor : PostProcessVolumes)
	{
		APostProcessVolume* PostProcessVolume = Cast<APostProcessVolume>(Actor);
		if (PostProcessVolume->IsValidLowLevel())
		{
			float AutoExposureBias = 0.0f;

			float* ExposureValuePtr = AutoExposureBiasMap.Find(PostProcessVolume->GetUniqueID());
			if (nullptr == ExposureValuePtr)
			{
				AutoExposureBiasMap.Add(PostProcessVolume->GetUniqueID(), PostProcessVolume->Settings.AutoExposureBias);

				AutoExposureBias = PostProcessVolume->Settings.AutoExposureBias;

				UE_LOG(LogRenderSettingsManager, Log, TEXT("URenderSettingsManager::SetPictureBrightness %s (ID %d): AutoExposureBias %f"), *PostProcessVolume->GetName(), PostProcessVolume->GetUniqueID(), AutoExposureBias);
			}
			else
			{
				AutoExposureBias = *ExposureValuePtr;
			}

			float ExposureBias = 0.0f;
			if (Brightness < PICTURE_BRIGHTNESS_NORMAL)
			{
				float Factor = (float) (Brightness - PictureMinBrightness) / (float) (PICTURE_BRIGHTNESS_NORMAL - PictureMinBrightness);
				ExposureBias = FMath::Lerp(PictureMinBrightnessInner, 0.0f, Factor);
			}
			else
			{
				float Factor = (float) (Brightness - PICTURE_BRIGHTNESS_NORMAL) / (float) (PictureMaxBrightness - PICTURE_BRIGHTNESS_NORMAL);
				ExposureBias = FMath::Lerp(0.0f, PictureMaxBrightnessInner, Factor);
			}

			PostProcessVolume->Settings.bOverride_AutoExposureBias = true;
			PostProcessVolume->Settings.AutoExposureBias = AutoExposureBias + ExposureBias;
		}
	}

	return true;
}

bool URenderSettingsManager::SetPictureBrightnessRange(int32 MinBrightness, int32 MaxBrightness)
{
	if ((MinBrightness < 0) || (MaxBrightness < 0) ||
		(MinBrightness > PICTURE_BRIGHTNESS_NORMAL) || (MaxBrightness < PICTURE_BRIGHTNESS_NORMAL) || 
		(MinBrightness > MaxBrightness))
	{
		return false;
	}

	PictureMinBrightness = MinBrightness;
	PictureMaxBrightness = MaxBrightness;

	return true;
}

bool URenderSettingsManager::SetPictureBrightnessRangeInner(float MinBrightness, float MaxBrightness)
{
	if ((MinBrightness > MaxBrightness) ||
		(MinBrightness > 0.0f) || (MaxBrightness < 0.0f))
	{
		return false;
	}

	PictureMinBrightnessInner = MinBrightness;
	PictureMaxBrightnessInner = MaxBrightness;

	return true;
}

int32 URenderSettingsManager::GetPictureBrightness()
{
	return CurrentPictureBrightness;
}

int32 URenderSettingsManager::GetPictureMinBrightness()
{
	return PictureMinBrightness;
}

int32 URenderSettingsManager::GetPictureMaxBrightness()
{
	return PictureMaxBrightness;
}

int32 URenderSettingsManager::GetDeviceDefualtPictureBrightness()
{
	return PICTURE_BRIGHTNESS_NORMAL;
}

bool URenderSettingsManager::IsAutoAdaptive()
{
	return bCurrentAutoAdaptive;
}

bool URenderSettingsManager::IsDeviceDefualtAutoAdaptive()
{
	return false;
}

bool URenderSettingsManager::SetAutoAdaptive(bool AutoAdaptive)
{
	bCurrentAutoAdaptive = AutoAdaptive;

	UE_LOG(LogRenderSettingsManager, Log, TEXT("URenderSettingsManager::SetAutoAdaptive %d "), AutoAdaptive);

	return true;
}

bool URenderSettingsManager::SetAdaptiveLowerInterval(float Interval)
{
	AdaptiveLowerInterval = Interval;

	return true;
}

bool URenderSettingsManager::SetAdaptiveEnhanceInterval(float Interval)
{
	AdaptiveEnhanceInterval = Interval;

	return true;
}

bool URenderSettingsManager::SetAdaptiveLowerFPSThreshold(int32 Threshold)
{
	AdaptiveLowerFPSThreshold = Threshold;

	return true;
}

bool URenderSettingsManager::SetAdaptiveEnhanceFPSThreshold(int32 Threshold)
{
	AdaptiveEnhanceFPSThreshold = Threshold;

	return true;
}

bool URenderSettingsManager::FreezeAutoAdaptive(bool Freeze)
{
	bFreezeAutoAdaptive = Freeze;

	UE_LOG(LogRenderSettingsManager, Log, TEXT("URenderSettingsManager::FreezeAutoAdaptive %d "), Freeze);

	return true;
}

