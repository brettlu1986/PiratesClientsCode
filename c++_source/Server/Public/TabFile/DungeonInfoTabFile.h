#pragma once
#include "TabFile/Base/TabFile.h"
#include "SceneResInfoTabFile.h"
#include "DungeonModeTabFile.h"
#include "Runtime/Core/Public/Math/UnrealMathUtility.h"
TAB_FILE_DATA(SERVER_API, FDungeonInfoTabFileData)
{
    int TemplateId;
    int ResId;
    TArray<int> Modes;

    FString ModesStr;

    FDungeonInfoTabFileData()
        : TemplateId(0)
        , ResId(0)
    {}

    TAB_FILE_DATA_SINGLE_KEY(int, TemplateId);

    virtual void RegisterParams() override
    {
        TAB_FILE_DATA_REGISTER(TemplateId, "id");
        TAB_FILE_DATA_REGISTER(ResId, "res_id");
        TAB_FILE_DATA_REGISTER(ModesStr, "modes");
    }

    virtual void OnPostLoad() override
    {
        TArray<FString> OutModes;
        ModesStr.ParseIntoArray(OutModes, TEXT(","), true);
        for (int i = 0; i < OutModes.Num(); i++)
        {
            int Mode = FCString::Atoi(*OutModes[i]);
            check(Mode > 0);
            Modes.Add(Mode);
        }
    }

    virtual void OnAllTabFilesLoaded() override
    {
        if (Modes.Num() > 0)
        {
            for (int i = 0; i < Modes.Num(); i++)
            {
                checkf(FDungeonModeTabFile::GetSingleton().Find(Modes[i]), TEXT("Dungeon Tab Error mode %d."), Modes[i]);
            }
        }
        else
        {
            checkf(TemplateId != 0 && ResId != 0, TEXT("Dungeon Tab Error TemplateId %d, ResId %d."), TemplateId, ResId);
            auto Info = FSceneResInfoTabFile::GetSingleton().Find(ResId);
            checkf(Info, TEXT("Dungeon Tab Error res_id %d."), ResId);
            SceneMap = Info->SceneMap;
        }
    }

    FString GetSceneMap(int& OutMode) const
    {
        if (SceneMap.Compare(TEXT("")) != 0)
        {
            OutMode = 0;
            return SceneMap;
        }
        else if (Modes.Num() > 0)
        {
            OutMode = Modes[FMath::Rand() % Modes.Num()];
            auto Mode = FDungeonModeTabFile::GetSingleton().Find(OutMode);
            checkf(Mode, TEXT("Dungeon Tab GetSceneMap Error mode_id %d."), OutMode);
            int SelectedResId = Mode->ResId;
            auto Info = FSceneResInfoTabFile::GetSingleton().Find(SelectedResId);
            checkf(Info, TEXT("Dungeon Tab GetSceneMap Error res_id %d."), SelectedResId);
            return Info->SceneMap;
        }
        else
        {
            OutMode = 0;
            checkf(false, TEXT("Dungeon Tab Error GetSceneMap %d."), TemplateId);
        }
        return TEXT("");
    }

private:
    FString SceneMap;
};

TAB_FILE_WITH_PATH(SERVER_API, FDungeonInfoTabFile, FDungeonInfoTabFileData, "common/dungeon/dungeon.tab");