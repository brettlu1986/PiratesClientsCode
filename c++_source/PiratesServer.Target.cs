// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

[SupportedPlatforms(UnrealPlatformClass.Server)]
public class PiratesServerTarget : TargetRules
{
    public PiratesServerTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Server;
        DefaultBuildSettings = BuildSettingsVersion.V2;
        ExtraModuleNames.AddRange(new string[] {
            "EngineExt",
            "Common",
            "Server",
            "Pirates",
        });

        // Workaround Error C4577 with Visual Studio 2017 15.7
        // https://forums.unrealengine.com/community/general-discussion/1478630-can-t-package-my-project
        if (Platform == UnrealTargetPlatform.Win64 || Platform == UnrealTargetPlatform.Win32)
        {
            bForceEnableExceptions = true;
        }

        // Enable LTO on Linux for better performance and smaller binary size
        if (Platform == UnrealTargetPlatform.Linux)
        {
            bAllowLTCG = true;
        }

        bUseLoggingInShipping = true;
        bUseChecksInShipping = true;
        bLoggingToMemoryEnabled = false;
        GlobalDefinitions.Add("PRESERVE_LOG_BACKUPS_IN_SHIPPING=0");
    }

    public List<UnrealTargetPlatform> GUBP_GetPlatforms_MonolithicOnly(UnrealTargetPlatform HostPlatform)
    {
        if (HostPlatform == UnrealTargetPlatform.Mac)
        {
            return new List<UnrealTargetPlatform>();
        }
        return new List<UnrealTargetPlatform> { HostPlatform, UnrealTargetPlatform.Win32, UnrealTargetPlatform.Linux };
    }

    public List<UnrealTargetConfiguration> GUBP_GetConfigs_MonolithicOnly(UnrealTargetPlatform HostPlatform, UnrealTargetPlatform Platform)
    {
        return new List<UnrealTargetConfiguration> { UnrealTargetConfiguration.Development };
    }
}
