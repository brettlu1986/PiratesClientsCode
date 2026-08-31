#include "LuaCustomDataWrapper.h"
#include "Common.h"

ULuaCustomDataWrapper::ULuaCustomDataWrapper(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , WithError(false)
{
}

ULuaCustomDataWrapper* ULuaCustomDataWrapper::Get()
{
    static ULuaCustomDataWrapper* Instance = nullptr;
    if (!Instance)
    {
        Instance = NewObject<ULuaCustomDataWrapper>(GetTransientPackage());
        Instance->AddToRoot();
    }
    return Instance;
}
