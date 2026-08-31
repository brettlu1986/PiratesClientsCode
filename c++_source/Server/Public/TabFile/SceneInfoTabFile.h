#pragma once
#include "TabFile/Base/TabFile.h"

TAB_FILE_DATA(SERVER_API, FSceneInfoTabFileData)
{
    int SceneId;
    int ResId;

    FSceneInfoTabFileData()
        : SceneId(0)
        , ResId(0)
    {}

    TAB_FILE_DATA_SINGLE_KEY(int, SceneId);

    virtual void RegisterParams() override
    {
        TAB_FILE_DATA_REGISTER(SceneId, "id");
        TAB_FILE_DATA_REGISTER(ResId, "res_id");
    }

    virtual void OnPostLoad() override
    {
        check(SceneId != 0 && ResId != 0);
    }
};

TAB_FILE_WITH_PATH(SERVER_API, FSceneInfoTabFile, FSceneInfoTabFileData, "common/scene/scene.tab");
