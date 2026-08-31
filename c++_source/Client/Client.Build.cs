using UnrealBuildTool;
using System.Collections.Generic;
using Tools.DotNETCommon;
using System.IO;

public class Client : ModuleRules
{
    public Client(ReadOnlyTargetRules Target) : base(Target)
    {
		PrivatePCHHeaderFile = "Public/Client.h";

        PrivateIncludePaths.AddRange(new string[]{
            "Client/Public/Shell",
            "Client/Public/Components",
        });

        PublicIncludePaths.AddRange(
            new string[] {
                "Client/Public",
                "Client/Public/Shell",
                "Client/Public/Components",
                "Client/Public/TabFile",
                "Client/Public/Game",
           }
        );

        PublicDependencyModuleNames.AddRange(
            new string[] {
                "Core",
                "CoreUObject",
                "Engine",
                "RenderCore",
                "EngineExt",
                "Common",
                "Hydra",
                "Networking",
                "AIModule",
                "IncrementalUpdate",
                "GamePlatformMisc",
                "UMG",
                "KMUMGPlugin",
				"LoadingScreen",
                "PacketHandler",
                "GameTestAutomation",
                "Ocean",
                "U4Lua",
                "liblua",
                "RHI",
                "SignalProcessing",
                "GPerf"
               }
        );

        //if (Target.Type == TargetType.Client)
        //{
            //PrivateDependencyModuleNames.AddRange(
            //    new string[] {
            //        "GPerf"
            //    }
            //);
        //}

        RegisterSdk();

		PrivateDependencyModuleNames.AddRange(
            new string[] {
            }
        );

        PublicDefinitions.Add("ENABLE_U4LUA=1");
    }

    private Dictionary<string, string> PluginDictionary = new Dictionary<string, string>();

    private void DefineSdkMacro()
    {
        // 【插件模块名字， 定义模块的宏】
        PluginDictionary.Add("XGSdk", "WITH_XGSDK");
        PluginDictionary.Add("EGSdk", "WITH_EGSDK");
        if (Target.Platform == UnrealTargetPlatform.Android)
        {
            PluginDictionary.Add("SGSDK", "WITH_SGSDK");
        }
        if (Target.Platform == UnrealTargetPlatform.IOS || Target.Platform == UnrealTargetPlatform.Android)
        {
            PluginDictionary.Add("GVoiceSDK", "WITH_GVOICESDK");
        }
        if (Target.Platform == UnrealTargetPlatform.Android || Target.Platform == UnrealTargetPlatform.IOS)
        {
            PluginDictionary.Add("DataSDK", "WITH_DATASDK");
        }
    }

    private void RegisterSdk()
    {
        DefineSdkMacro();

        DirectoryReference ProjectDir = new DirectoryReference(ModuleDirectory + "../../../");        
        FileReference PiratesProject = FileReference.Combine(ProjectDir, new string[] { "Pirates.uproject"});        

        ProjectDescriptor Descriptor = ProjectDescriptor.FromFile(PiratesProject);
        foreach (KeyValuePair<string, string> kvp in PluginDictionary)
        {
            bool bFindResult = false;
            foreach (PluginReferenceDescriptor PluginDescriptor in Descriptor.Plugins)
            {
                if (string.Compare(PluginDescriptor.Name, kvp.Key, true) == 0)
                {
                    bFindResult = true;
                    if (PluginDescriptor.bEnabled)
                    {
                        PrivateDependencyModuleNames.Add(kvp.Key);
                        PublicDefinitions.Add(kvp.Value);
                    }
                    break;
                }
            }
            if (!bFindResult)
            {
                PrivateDependencyModuleNames.Add(kvp.Key);
                PublicDefinitions.Add(kvp.Value);
            }
        }
    }
}