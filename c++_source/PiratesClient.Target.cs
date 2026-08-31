// Fill out your copyright notice in the Description page of Project Settings.

using System;
using System.Collections.Generic;
using UnrealBuildTool;

public class PiratesClientTarget : TargetRules
{
    public PiratesClientTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Client;
        DefaultBuildSettings = BuildSettingsVersion.V2;
        ExtraModuleNames.AddRange(new string[] {
            "EngineExt",
            "Common",
            "Client",
            "Pirates",
        });

        // Workaround Error C4577 with Visual Studio 2017 15.7
        // https://forums.unrealengine.com/community/general-discussion/1478630-can-t-package-my-project
        if (Platform == UnrealTargetPlatform.Win64 || Platform == UnrealTargetPlatform.Win32)
        {
            bForceEnableExceptions = true;
        }

        bUseLoggingInShipping = true;
        bUseChecksInShipping = true;
        //if (Target.Configuration == UnrealTargetConfiguration.Shipping)
        //{
        //    bLoggingToMemoryEnabled = true;
        //}

		// FramePro Setup
		if (Target.Configuration == UnrealTargetConfiguration.Test || Target.Configuration == UnrealTargetConfiguration.Development)
		{
			//GlobalDefinitions.Add("ENABLE_STATNAMEDEVENTS=1");
			//GlobalDefinitions.Add("ENABLE_STATNAMEDEVENTS_UOBJECT=1");

			//if (Target.Platform == UnrealTargetPlatform.Android
			//	|| Target.Platform == UnrealTargetPlatform.IOS
			//	|| Target.Platform == UnrealTargetPlatform.Win64)
			//{
			//	GlobalDefinitions.Add("FRAMEPRO_ENABLED=1");
			//}
		}

		if (Target.Configuration != UnrealTargetConfiguration.Shipping)
        {
			/* Open this for using malloc debuging */
			//GlobalDefinitions.Add("USE_MALLOC_DEBUG");
		}
		else
		{
			if(Target.Platform == UnrealTargetPlatform.Android)
			{
				GlobalDefinitions.Add("EXPERIMENTAL_OPENGL_RHITHREAD=1");
			}
		}

		// Headless client (automated tests)
		if (Target.Platform == UnrealTargetPlatform.Linux)
        {
            GlobalDefinitions.Add("USE_NULL_RHI=1");
        }
        else if (Target.Platform == UnrealTargetPlatform.IOS)
        {
            GlobalDefinitions.Add("FORCE_ANSI_ALLOCATOR=1");
            bForceBuildTargetPlatforms = true;
        }
        GlobalDefinitions.Add("PRESERVE_LOG_BACKUPS_IN_SHIPPING=1");
    }

}
