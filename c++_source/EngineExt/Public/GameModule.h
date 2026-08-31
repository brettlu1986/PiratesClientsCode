#pragma once

#include "Modules/ModuleManager.h"

// Client/Server module should implement this interface,
class IGameModule : public IModuleInterface
{
public:
    virtual void OnGameInstanceInit(UGameInstance* GameInstance) = 0;
    virtual void OnGameInstanceStart(UGameInstance* GameInstance) = 0;
    virtual void OnGameInstanceShutdown(UGameInstance* GameInstance) = 0;
    virtual void OnGameInstancePostShutdown(UGameInstance* GameInstance) = 0;
};
