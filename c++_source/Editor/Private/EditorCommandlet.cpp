// Fill out your copyright notice in the Description page of Project Settings.

#include "EditorCommandlet.h"
#include "PiratesEditor.h"
#include "LuaEditorHelper.h"
#include "EngineExtSetting.h"
#include "HAL/PlatformApplicationMisc.h"
#include "Misc/OutputDevice.h"
#include "Misc/OutputDeviceHelper.h"
#include "Misc/FileHelper.h"

//yangjingzhao for 4.20 Interrupt with editor.h in UnrealEd
DECLARE_LOG_CATEGORY_CLASS(LogEditorCommandlet, Log, All)

int32 UEditorCommandlet::Main(const FString & Params)
{
    TArray<FString> Tokens;
    TArray<FString> Switches;
    TMap<FString, FString> ParamMap;
    ParseCommandLine(*Params, Tokens, Switches, ParamMap);

    /*
    if (Switches.Contains(TEXT("UrlSetting")))
    {        
        FString* UrlMode = ParamMap.Find("urlmode");
        if (UrlMode)
        {
            UEngineExtSetting* Setting = GetMutableDefault<UEngineExtSetting>();
            Setting->UrlMode = *UrlMode;
            Setting->SaveConfig(CPF_Config, *Setting->GetDefaultConfigFilename());

            FString* Platform = ParamMap.Find("platform");
            if (Platform)
            {
                FString FilePath = FPaths::ProjectContentDir() / TEXT("GameData") / TEXT("client") / TEXT("url") / *UrlMode;
                if (FCString::Strcmp(**Platform, TEXT("android")) == 0)
                {
                    FilePath = FilePath / TEXT("android_url.json");
                }
                else if (FCString::Strcmp(**Platform, TEXT("ios")) == 0)
                {
                    FilePath = FilePath / TEXT("ios_url.json");
                }
                else
                {
                    FilePath = FilePath / TEXT("windows_url.json");
                }

                FString* Resource = ParamMap.Find("resource");
                FString* Announcement = ParamMap.Find("announcement");
                FString* Serverlist = ParamMap.Find("serverlist");

                if (Resource && Announcement && Serverlist)
                {
                    FString FileContent = FString::Printf(TEXT("{\n"
                        "\t\"resource\":\"%s\",\n"
                        "\t\"announcement\":\"%s\",\n"
                        "\t\"serverlist\" : \"%s\"\n"
                        "}"), **Resource, **Announcement, **Serverlist);

                    if (!FFileHelper::SaveStringToFile(*FileContent, *FilePath))
                    {
                        UE_LOG(LogEditorCommandlet, Error, TEXT("Save url to %s failed."), *FilePath);
                        return 1;
                    }
                    else
                    {
                        UE_LOG(LogEditorCommandlet, Log, TEXT("Save url to %s ok."), *FilePath);
                    }
                }
                //else
                //{
                //    UE_LOG(EditorLog, Warning, TEXT("UrlSetting not find url"));
                //}
            }
            //else
            //{
            //    UE_LOG(EditorLog, Warning, TEXT("UrlSetting not find dev"));

            //}
        }        
    }
    */

	if (Switches.Contains(TEXT("EditorScript")))
	{
		FString Temp;
		FString* LaunchScript = ParamMap.Find(TEXT("script"));
		FString* TempParams = ParamMap.Find(TEXT("params"));
		ULuaEditorHelper* Helper = NewObject<ULuaEditorHelper>();
		Helper->Init();
		bool bRet = Helper->PlayInCommandlet(LaunchScript ? *LaunchScript : Temp, TempParams ? *TempParams : Temp);
		Helper->Uninit();
        Helper->MarkPendingKill();

		if (!bRet)
		{
			return 1;
		}
	}
    return 0;
}
