// Fill out your copyright notice in the Description page of Project Settings.

using System;
using System.Collections.Generic;
using UnrealBuildTool;

public class Pirates : ModuleRules
{
    public Pirates(ReadOnlyTargetRules Target) : base(Target)
    {
		PrivatePCHHeaderFile = "Pirates.h";

        Console.WriteLine("Building Pirates, TargetType is: {0}", Target.Type);

        PublicDependencyModuleNames.AddRange(new List<string> {
            "Core",
            "CoreUObject",
            "Engine",
            "InputCore"
        });


        //CircularlyReferencedDependentModules.AddRange(
        //    new string[] {
        //        "Client",
        //        "Server",
        //    }
        //);
        // Uncomment if you are using Slate UI
        // PrivateDependencyModuleNames.AddRange(new string[] { "Slate", "SlateCore" });

        // Uncomment if you are using online features
        // PrivateDependencyModuleNames.Add("OnlineSubsystem");
        // if ((Target.Platform == UnrealTargetPlatform.Win32) || (Target.Platform == UnrealTargetPlatform.Win64))
        // {
        //		if (UEBuildConfiguration.bCompileSteamOSS == true)
        //		{
        //			DynamicallyLoadedModuleNames.Add("OnlineSubsystemSteam");
        //		}
        // }
    }
}
