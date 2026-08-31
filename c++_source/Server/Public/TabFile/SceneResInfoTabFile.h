#pragma once
#include "TabFile/Base/TabFile.h"

TAB_FILE_DATA(SERVER_API, FSceneResInfoTabFileData)
{
    int ResId;
    FString SceneMap;

    FSceneResInfoTabFileData()
        : ResId(0)
    {}

    TAB_FILE_DATA_SINGLE_KEY(int, ResId);

    virtual void RegisterParams() override
    {
        TAB_FILE_DATA_REGISTER(ResId, "ID");
        TAB_FILE_DATA_REGISTER(SceneMap, "LevelName");
    }

    virtual void OnPostLoad() override
    {
        check(ResId != 0 && !SceneMap.IsEmpty());
    }
};

TAB_FILE_WITH_PATH(SERVER_API, FSceneResInfoTabFile, FSceneResInfoTabFileData, "common/res/scene_res.tab");
