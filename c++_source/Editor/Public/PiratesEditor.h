#pragma once

#include "Engine.h"
//yangjingzhao for 4.20
//DECLARE_LOG_CATEGORY_EXTERN(EditorLog1, Log, All);

class IPiratesEditorModule : public IModuleInterface
{
public:

    /** IModuleInterface implementation */
    virtual void StartupModule() = 0;
    virtual void ShutdownModule() = 0;
};