// Fill out your copyright notice in the Description page of Project Settings.

using UnrealBuildTool;
using System.Collections.Generic;

public class PiratesEditorTarget : TargetRules
{
	public PiratesEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V2;
        ExtraModuleNames.AddRange(new string[] {
            "EngineExt",
            "Common",
            "Client",
            "Server",
            "Editor",
            "Pirates",
        });
    }
}
