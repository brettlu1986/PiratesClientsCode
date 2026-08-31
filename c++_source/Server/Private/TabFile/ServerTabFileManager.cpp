#include "ServerTabFileManager.h"
#include "Server.h"

#include "SceneResInfoTabFile.h"
#include "SceneInfoTabFile.h"
#include "DungeonInfoTabFile.h"
#include "DungeonModeTabFile.h"

void FServerTabFileManager::RegisterFiles()
{
    FCommonTabFileManager::RegisterFiles();

    Register<FSceneResInfoTabFile>();
    //Register<FSceneInfoTabFile>();
    Register<FDungeonInfoTabFile>();
    Register<FDungeonModeTabFile>();
}