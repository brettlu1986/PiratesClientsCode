#include "EngineExt.h"
#include "Game/EngineExtSetting.h"
#include "ISettingsModule.h"
#include "Loading/WorldCompositionData.h"

#define LOCTEXT_NAMESPACE "FEngineExtModule"

void FEngineExtModule::StartupModule()
{
    if (ISettingsModule* SettingsModule = FModuleManager::GetModulePtr<ISettingsModule>("Settings"))
    {
        SettingsModule->RegisterSettings("Project", "KMGame", "EngineExt",
            LOCTEXT("RuntimeSettingsName", "EngineExtConfig"),
            LOCTEXT("RuntimeSettingsDescription", "Configure EngineExt"),
            GetMutableDefault<UEngineExtSetting>());

		SettingsModule->RegisterSettings("Project", "KMGame", "EngineExt",
			LOCTEXT("RuntimeSettingsName", "WorldCompositionData Config"),
			LOCTEXT("RuntimeSettingsDescription", "Configure of  WorldCompositionData"),
			GetMutableDefault<UWorldCompositionConfig>());
    }
}

void FEngineExtModule::ShutdownModule()
{
    if (ISettingsModule* SettingsModule = FModuleManager::GetModulePtr<ISettingsModule>("Settings"))
    {
        SettingsModule->UnregisterSettings("Project", "KMGame", "EngineExt");
    }
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_GAME_MODULE(FEngineExtModule, EngineExt);
