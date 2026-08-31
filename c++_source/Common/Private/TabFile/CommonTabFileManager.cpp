#include "TabFile/CommonTabFileManager.h"
#include "Common.h"

#include "TabFile/GameAvatarPartTypeTabFile.h"
#include "TabFile/GameAvatarPartTabFile.h"


void FCommonTabFileManager::RegisterFiles()
{
    Register<FGameAvatarPartTypeTabFile>();
    Register<FGameAvatarPartTabFile>();
}