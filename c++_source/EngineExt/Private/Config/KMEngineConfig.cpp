// Fill out your copyright notice in the Description page of Project Settings.

#include "Config/KMEngineConfig.h"
#include "EngineExt.h"
#include "Game/GameEngineExt.h"
// additional device profile
#include "Misc/ConfigCacheIni.h"
#include "DeviceProfiles/DeviceProfileManager.h"
#if PLATFORM_ANDROID
#include "Android/AndroidPlatformMisc.h"
#endif
// ~

DEFINE_LOG_CATEGORY_STATIC(KMEngineConfigLog, Log, All);

FString FindMatchingProfile(const TArray<FProfileMatch>& MatchProfile);

// Sets default values
UKMEngineConfig::UKMEngineConfig(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{

}


void UKMEngineConfig::Load()
{
    FString FilePath = GetConfigPath();
    GConfig->LoadFile(*FilePath);
    UClass* ConfigClass = GetClass();
    static FName SectionFName(TEXT("Section"));
    for (FProperty* Property = ConfigClass->PropertyLink; Property; Property = Property->PropertyLinkNext)
    {
        if (Property->HasAnyPropertyFlags(CPF_Config))
        {
            continue;
        }
        FString Key = Property->GetName();
        FString Section = TEXT("Global");
		/*if (Property->HasMetaData(TEXT("Category")))
		{
			Section = Property->GetMetaData(TEXT("Category"));
		}*/
        int32 PortFlags = 0;
        FArrayProperty* Array = CastField<FArrayProperty>(Property);
        if (Array == NULL)
        {
            for (int32 i = 0; i < Property->ArrayDim; i++)
            {
                if (Property->ArrayDim != 1)
                {
                    Key = FString::Printf(TEXT("%s[%i]"), *Property->GetName(), i);
                }
                FString Value;
                bool bFoundValue = GConfig->GetString(*Section, *Key, Value, *FilePath);
                if (bFoundValue)
                {
                    if (Property->ImportText(*Value, Property->ContainerPtrToValuePtr<uint8>(this, i), PortFlags, this) == NULL)
                    {
                        UE_LOG(KMEngineConfigLog, Error, TEXT("LoadConfig (%s): import failed for %s in: %s"), *FilePath, *Property->GetName(), *Value);
                    }
                }

#if !UE_BUILD_SHIPPING
                if (!bFoundValue)
                {
                    UE_LOG(KMEngineConfigLog, Log, TEXT("LoadConfig (Warning) (%s): failed to find %s"), *FilePath, *Property->GetName());
                }
#endif
            }
        }
        else
        {
            FConfigSection* Sec = GConfig->GetSectionPrivate(*Section, false, true, *FilePath);

            if (Sec)
            {
                TArray<FConfigValue> List;
                const FName KeyName(*Key, FNAME_Find);
                Sec->MultiFind(KeyName, List);


                FScriptArrayHelper_InContainer ArrayHelper(Array, this);
                const int32 Size = Array->Inner->ElementSize;
                // Only override default properties if there is something to override them with.
                if (List.Num() > 0)
                {
                    ArrayHelper.EmptyAndAddValues(List.Num());
                    for (int32 i = List.Num() - 1, c = 0; i >= 0; i--, c++)
                    {
                        Array->Inner->ImportText(*List[i].GetValue(), ArrayHelper.GetRawPtr(c), PortFlags, this);
                    }
                }
                else
                {
                    int32 Index = 0;
                    const FConfigValue* ElementValue = nullptr;
                    do
                    {
                        // Add array index number to end of key
                        FString IndexedKey = FString::Printf(TEXT("%s[%i]"), *Key, Index);

                        // Try to find value of key
                        const FName IndexedName(*IndexedKey, FNAME_Find);
                        if (IndexedName == NAME_None)
                        {
                            break;
                        }
                        ElementValue = Sec->Find(IndexedName);

                        // If found, import the element
                        if (ElementValue != nullptr)
                        {
                            // expand the array if necessary so that Index is a valid element
                            ArrayHelper.ExpandForIndex(Index);
                            Array->Inner->ImportText(*ElementValue->GetValue(), ArrayHelper.GetRawPtr(Index), PortFlags, this);
                        }

                        Index++;
                    } while (ElementValue || Index < ArrayHelper.Num());
                }
            }
#if !UE_BUILD_SHIPPING
            else
            {
                UE_LOG(KMEngineConfigLog, Warning, TEXT("LoadConfig (%s): failed to find %s"), *FilePath, *Property->GetName());
            }
#endif
        }
    }
}

void UKMEngineConfig::OnLoadFinish()
{
#if !UE_SERVER
	FString FullFilePath = FPaths::ProjectContentDir() / AdditionalDeviceProfileConfigPath;
	FConfigFile ConfigFile;
	ConfigFile.Combine(FullFilePath);
	GConfig->Remove(FullFilePath);
	GConfig->Add(FullFilePath, ConfigFile);

	AdditionalMatchingRules = NewObject<UAdditionalDeviceProfileMatchingRules>(this);
	AdditionalMatchingRules->LoadConfig(0, *FullFilePath);
	FString NewMatchingProfile = FindMatchingProfile(AdditionalMatchingRules->MatchProfile);

	if (!NewMatchingProfile.IsEmpty())
	{
		FString ProfileSectionStr = FString::Printf(TEXT("%s %s"), *NewMatchingProfile, *UDeviceProfile::StaticClass()->GetName());
		if (ConfigFile.Find(ProfileSectionStr) != nullptr)
		{
			UE_LOG(KMEngineConfigLog, Display, TEXT("Additional matching profile found : %s"), *NewMatchingProfile);
			UDeviceProfile* DeviceProfile = UDeviceProfileManager::Get().CreateAdditionalProfileKs(NewMatchingProfile, FPlatformProperties::PlatformName(), TEXT(""), *FString(FPlatformProperties::PlatformName()), *FullFilePath);
			UDeviceProfileManager::Get().SetActiveDeviceProfileKs(DeviceProfile);
			UDeviceProfileManager::InitializeCVarsForActiveDeviceProfileKs(FullFilePath);
		}
		else
		{
			UE_LOG(KMEngineConfigLog, Warning, TEXT("[%s DeviceProfile] is not defined. Use original match [%s DeviceProfile]"), *NewMatchingProfile, *UDeviceProfileManager::Get().GetActiveDeviceProfileName());
		}
	}
	else
	{
		UE_LOG(KMEngineConfigLog, Display, TEXT("No additional matching profile found. Keep current profile : %s"), *UDeviceProfileManager::Get().GetActiveDeviceProfileName());
	}
#endif
}

FString UKMEngineConfig::GetConfigPath()
{
    UKMEngineConfig* EngineConfig = GetMutableDefault<UKMEngineConfig>();
    return FPaths::ProjectContentDir() / EngineConfig->ConfigFilePath;
}

UKMEngineConfig* UKMEngineConfig::GetConfig(UObject* WorldContextObject)
{
    return UGameEngineExt::Get(WorldContextObject)->GetEngineConfig();
}


FString FindMatchingProfile(const TArray<FProfileMatch>& MatchProfile)
{
	FString OutProfileName;
#if PLATFORM_ANDROID
	FString GPUFamily = FAndroidMisc::GetGPUFamily();
	FString GLVersion = FAndroidMisc::GetGLVersion();
	FString VulkanVersion = FAndroidMisc::GetVulkanVersion();
	FString VulkanAvailable = FAndroidMisc::IsVulkanAvailable() ? TEXT("true") : TEXT("false");
	FString AndroidVersion = FAndroidMisc::GetAndroidVersion();
	FString DeviceMake = FAndroidMisc::GetDeviceMake();
	FString DeviceModel = FAndroidMisc::GetDeviceModel();
	FString DeviceBuildNumber = FAndroidMisc::GetDeviceBuildNumber();
	FString* hardware = FAndroidMisc::GetConfigRulesVariable(TEXT("hardware"));

    #if !(PLATFORM_ANDROID_X86 || PLATFORM_ANDROID_X64)
    	// Not running an Intel libUE4.so with Houdini library present means we're emulated
    	bool bUsingHoudini = (access("/system/lib/libhoudini.so", F_OK) != -1);
    #else
    	bool bUsingHoudini = false;
#endif
	FString UsingHoudini = bUsingHoudini ? TEXT("true") : TEXT("false");

 	for (const FProfileMatch& Profile : MatchProfile)
 	{
 		FString PreviousRegexMatch;
 		bool bFoundMatch = true;
 		for (const FProfileMatchItem& Item : Profile.Match)
 		{
 			const FString* SourceString = nullptr;
 			switch (Item.SourceType)
 			{
 			case SRC_PreviousRegexMatch:
 				SourceString = &PreviousRegexMatch;
 				break;
 			case SRC_GpuFamily:
 				SourceString = &GPUFamily;
 				break;
 			case SRC_GlVersion:
 				SourceString = &GLVersion;
 				break;
 			case SRC_AndroidVersion:
 				SourceString = &AndroidVersion;
 				break;
 			case SRC_DeviceMake:
 				SourceString = &DeviceMake;
 				break;
 			case SRC_DeviceModel:
 				SourceString = &DeviceModel;
 				break;
 			case SRC_DeviceBuildNumber:
 				SourceString = &DeviceBuildNumber;
 				break;
 			case SRC_VulkanVersion:
 				SourceString = &VulkanVersion;
 				break;
 			case SRC_UsingHoudini:
 				SourceString = &UsingHoudini;
 				break;
 			case SRC_VulkanAvailable:
 				SourceString = &VulkanAvailable;
 				break;
 			case SRC_Hardware:
 				SourceString = hardware;
 				break;
 			default:
 				continue;
 			}
 
 			const bool bNumericOperands = SourceString->IsNumeric() && Item.MatchString.IsNumeric();
 
 			switch (Item.CompareType)
 			{
 			case CMP_Equal:
 			{
 				if (*SourceString != Item.MatchString)
 				{
 					bFoundMatch = false;
 				}
 			}
 			break;
 			case CMP_Less:
 				if ((bNumericOperands && FCString::Atof(**SourceString) >= FCString::Atof(*Item.MatchString)) || (!bNumericOperands && *SourceString >= Item.MatchString))
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_LessEqual:
 				if ((bNumericOperands && FCString::Atof(**SourceString) > FCString::Atof(*Item.MatchString)) || (!bNumericOperands && *SourceString > Item.MatchString))
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_Greater:
 				if ((bNumericOperands && FCString::Atof(**SourceString) <= FCString::Atof(*Item.MatchString)) || (!bNumericOperands && *SourceString <= Item.MatchString))
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_GreaterEqual:
 				if ((bNumericOperands && FCString::Atof(**SourceString) < FCString::Atof(*Item.MatchString)) || (!bNumericOperands && *SourceString < Item.MatchString))
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_NotEqual:
 				{
 					if (*SourceString == Item.MatchString)
 					{
 						bFoundMatch = false;
 					}
 				}
 				break;
 			case CMP_EqualIgnore:
 				if (SourceString->ToLower() != Item.MatchString.ToLower())
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_LessIgnore:
 				if (SourceString->ToLower() >= Item.MatchString.ToLower())
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_LessEqualIgnore:
 				if (SourceString->ToLower() > Item.MatchString.ToLower())
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_GreaterIgnore:
 				if (SourceString->ToLower() <= Item.MatchString.ToLower())
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_GreaterEqualIgnore:
 				if (SourceString->ToLower() < Item.MatchString.ToLower())
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_NotEqualIgnore:
 				if (SourceString->ToLower() == Item.MatchString.ToLower())
 				{
 					bFoundMatch = false;
 				}
 				break;
 			case CMP_Regex:
 			{
 				const FRegexPattern RegexPattern(Item.MatchString);
 				FRegexMatcher RegexMatcher(RegexPattern, *SourceString);
 				if (RegexMatcher.FindNext())
 				{
 					PreviousRegexMatch = RegexMatcher.GetCaptureGroup(1);
 				}
 				else
 				{
 					bFoundMatch = false;
 				}
 			}
 			break;
 			default:
 				bFoundMatch = false;
 			}
 
 			if (!bFoundMatch)
 			{
 				break;
 			}
 		}
 
 		if (bFoundMatch)
 		{
 			OutProfileName = Profile.Profile;
 			break;
 		}
 	}
#endif
#if PLATFORM_IOS
	OutProfileName = FIOSPlatformMisc::GetCPUBrand();
#endif
	return OutProfileName;
}