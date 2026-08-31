using UnrealBuildTool;

public class Common : ModuleRules
{
    public Common(ReadOnlyTargetRules Target) : base(Target)
    {
		PrivatePCHHeaderFile = "Public/Common.h";

        PrivateIncludePaths.AddRange(new string[]{
            "Common/Private/UI",
            "Common/Private/UI/HUD",
            "Common/Private/UI/HUD/HUDModule",
            "Common/Private/UI/HUD/CustomWidget",
            "Common/Private/AI",
            "Common/Private/Game",
        });

        PublicIncludePaths.AddRange(
            new string[] {
                "Common/Public",
                "Common/Public/Util",
                "Common/Public/Pawns",
                "Common/Public/Gestures",
                "Common/Public/Gestures/Base",
                "Common/Public/Shell",
                "Common/Public/Components",
                "Common/Public/PacketHandlers",
                "Common/Public/Network",
                "Common/Public/Network/Http",
                "Common/Public/TabFile",
                "Common/Public/TabFile/Base",
                "Common/Public/AI",
                "Common/Public/AI/Components",
                "Common/Public/AI/OceanGrid",
                "Common/Public/AI/EnvQuery",
                "Common/Public/Game",
                "Common/Public/Game/Avatar",
                "Common/Public/Game/PathNode",
                "Common/Public/Game/Battle",
                "Common/Public/Game/Lua",
                "Common/Public/Game/Misc",
                "Common/Public/Game/Input",
            }
        );

        PublicDependencyModuleNames.AddRange(
            new string[] {
                "Core",
                "CoreUObject",
                "Sockets",
                "NetCore",
                "Networking",
                "Engine",
                "RHI",
                "EngineExt",
                "Json",
                "JsonUtilities",
                "AIModule",
                "Protobuf",
                "MapNavGrid",
                "HTTP",
                "Slate",
                "SlateCore",
                "UMG",
                "InputCore",
                "ProceduralMeshComponent",
                "LevelSequence",
				"KMMeshUtilities",
                "KMUMGPlugin",
				"Ocean",
                "GamePlatformMisc",
                "BuglyCrashReport",
                "RenderCore",
                "MovieScene",
                "MovieSceneTracks",                
                "liblua",
                "SignificanceManager",
                "NavigationSystem",
                "PacketHandler",
                "GameplayTasks",
                "ApplicationCore",
                "ExportAICoverPoints",
                "OpenSSL",
                "GPerf",
                "U4Lua",
            }
        );

		if (Target.Type == TargetType.Editor)
		{
			PublicDependencyModuleNames.Add("UnrealEd");
		}

        //PrivateDependencyModuleNames.Add("OnlineSubsystemUtils");
        PrivateDependencyModuleNames.AddRange(
            new string[] {
                "OnlineSubsystemUtils",
                "ReplicationGraph",
                "MapNavGrid",
                "Landscape"
            }
        );

        if (Target.bBuildDeveloperTools || (Target.Configuration != UnrealTargetConfiguration.Shipping && Target.Configuration != UnrealTargetConfiguration.Test))
        {
            PrivateDependencyModuleNames.Add("GameplayDebugger");
            PublicDefinitions.Add("WITH_GAMEPLAY_DEBUGGER=1");
        }
        else
        {
            PublicDefinitions.Add("WITH_GAMEPLAY_DEBUGGER=0");
        }

        PublicDefinitions.Add("ENABLE_U4LUA=1");

        SetUDPMessageEncryptionEnabled(true);
        SetUDPGameMessageObfuscationEnabled(false);
    }

    private void SetUDPMessageEncryptionEnabled(bool Enabled)
    {
        if (Enabled)
        {
            // 如果disable的话得记得改DefaultEngine.ini中的PacketHandlerComponents
            PublicDependencyModuleNames.Add("AESHandlerComponent");
        }
    }

    private void SetUDPGameMessageObfuscationEnabled(bool Enabled)
    {
        if (Enabled)
        {
            PublicDefinitions.Add("ENABLE_GAME_MESSAGE_OBFUSCATION=1");
            PublicDependencyModuleNames.Add("zlib");
        }
        else
        {
            PublicDefinitions.Add("ENABLE_GAME_MESSAGE_OBFUSCATION=0");
        }
    }
}
