using UnrealBuildTool;

public class Editor : ModuleRules
{
    public Editor(ReadOnlyTargetRules Target) : base(Target)
    {
		PrivatePCHHeaderFile = "Public/PiratesEditor.h";

        PrivateIncludePaths.AddRange(new string[]{
            "Editor/Private",
        });

        PublicIncludePaths.AddRange(new string[]{
            "Editor/Public",
        });

        PrivateDependencyModuleNames.AddRange(
            new string[] {
                "PropertyEditor",
                "DetailCustomizations",
            }
        );

        PublicDependencyModuleNames.AddRange(
            new string[] {
                "Core",
                "CoreUObject",
                "Engine",
                "EngineSettings",
                "UnrealEd",
                "EngineExt",
                "EditorStyle",
                "SlateCore",
                "Slate",
                "AssemblyEditor",
                "BlueprintGraph",
                "GraphEditor",
                "ApplicationCore",
                //"UE4SimpleLua",
                "Common",
                "LevelEditor",
                "ContentBrowser",
                "ExportShipLuaTemplate",
                "LevelSequence",
                "MovieScene",
                "U4Lua",
                "Landscape",
                "Json",
                "JsonUtilities",
                "Foliage",
            }
        );

        PublicDefinitions.Add("ENABLE_U4LUA=1");
        AddEngineThirdPartyPrivateStaticDependencies(Target, "FBX");
    }
}
