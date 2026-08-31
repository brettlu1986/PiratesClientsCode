using UnrealBuildTool;

public class Server : ModuleRules
{
    public Server(ReadOnlyTargetRules Target) : base(Target)
    {
		PrivatePCHHeaderFile = "Public/Server.h";

        PrivateIncludePaths.AddRange(new string[] {
            "Server/Private/Game",
        });

        PublicIncludePaths.AddRange(new string[]{
            "Server/Public",
            "Server/Public/Game",
            "Server/Public/Shell",
            "Server/Public/TabFile",
        });

        PublicDependencyModuleNames.AddRange(
            new string[] {
                "Core",
                "Sockets",
                "CoreUObject",
                "Networking",
                "Engine",
                "EngineExt",
                "Common",
                "EngineSettings",
                "Protobuf",
                "DMS",
                "liblua",
                //"UE4SimpleLua",
                "U4Lua",
                "OnlineSubsystemUtils",
                "GPerf"
            }
        );
    }
}
