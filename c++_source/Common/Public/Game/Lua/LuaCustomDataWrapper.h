#pragma once

#include "LuaCustomDataWrapper.generated.h"

UCLASS()
class ULuaCustomDataWrapper : public UObject
{
    GENERATED_UCLASS_BODY()

public:
    UFUNCTION()
    static ULuaCustomDataWrapper* Get();

    void SetError(bool bError)
    {
        WithError = bError;
    }

    void ClearError()
    {
        WithError = false;
    }

    UFUNCTION()
    const bool IsError() const { return WithError; }

public:
    TArray<uint8> RawData;
    bool WithError;
};
