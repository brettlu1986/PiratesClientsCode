#include "EngineExtSetting.h"
#include "EngineExt.h"

UEngineExtSetting::UEngineExtSetting(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , DevMode(false)
{
}


bool UEngineExtSetting::IsDevMode()
{
    UEngineExtSetting* Setting = GetMutableDefault<UEngineExtSetting>();
    return Setting->DevMode;
}