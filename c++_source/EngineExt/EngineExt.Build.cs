using UnrealBuildTool;

public class EngineExt : ModuleRules
{
    public EngineExt(ReadOnlyTargetRules Target) : base(Target)
    {
		PrivatePCHHeaderFile = "Public/EngineExt.h";

		PrivateIncludePaths.AddRange(new string[]{
            "EngineExt/Private/Camera",
		});

        PublicIncludePaths.AddRange(new string[]{
            "EngineExt",
            "EngineExt/Public",
            "EngineExt/Public/Config",
            "EngineExt/Public/Camera",
            "EngineExt/Public/Camera/CameraModify",
            "EngineExt/Public/Components",
            "EngineExt/Public/Timer",
            "EngineExt/Public/Game",
            "EngineExt/Public/Game/Actor",
            "EngineExt/Public/Game/Delegates",
            "EngineExt/Public/Loading",
        });

        PublicDependencyModuleNames.AddRange(
            new string[] {
                "Core",
                "CoreUObject",
                "RenderCore",
                "Engine",
                "AIModule",
                "Sockets",
                "Networking",
                "OnlineSubsystemUtils",
                "UMG",
                "Json",
				"SignificanceManager",
                "NavigationSystem",
                "RHI",
				"AndroidDeviceProfileSelector",
                "HTTP",
                "EngineSettings"
            }
        );

		if ((Target.Type == TargetRules.TargetType.Client) || (Target.Type == TargetRules.TargetType.Editor))
		{
			PublicDependencyModuleNames.Add("Ocean");
		}

		if (Target.Type == TargetRules.TargetType.Editor)
        {
            PrivateDependencyModuleNames.Add("UnrealEd");
            PublicDefinitions.Add("USEEDITORNETWORK=1");
        }
        else
        {
            PublicDefinitions.Add("USEEDITORNETWORK=0");
        }

        PrivateIncludePathModuleNames.AddRange(new string[] {
                "Settings"
            });
    }
}
