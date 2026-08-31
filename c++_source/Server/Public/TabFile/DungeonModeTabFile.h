#pragma once
#include "TabFile/Base/TabFile.h"
#include "SceneResInfoTabFile.h"
TAB_FILE_DATA(SERVER_API, FDungeonModeTabFileData)
{
    int Id;
    int ResId;

    FDungeonModeTabFileData()
        : Id(0)
        , ResId(0)
    {}

    TAB_FILE_DATA_SINGLE_KEY(int, Id);

    virtual void RegisterParams() override
    {
        TAB_FILE_DATA_REGISTER(Id, "id");
        TAB_FILE_DATA_REGISTER(ResId, "res_id");
    }

    virtual void OnPostLoad() override
    {
        check(Id != 0 && ResId != 0);
    }

    virtual void OnAllTabFilesLoaded() override
    {
        auto Info = FSceneResInfoTabFile::GetSingleton().Find(ResId);
        checkf(Info, TEXT("Dungeon mode Tab Error res_id %d."), ResId);
    }
};

TAB_FILE_WITH_PATH(SERVER_API, FDungeonModeTabFile, FDungeonModeTabFileData, "common/dungeon/dungeon_mode.tab");