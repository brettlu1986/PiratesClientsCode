#pragma once
#include "Misc/OutputDeviceError.h"

class COMMON_API FFatalLogCatcher : public FOutputDeviceError
{
public:
    static FFatalLogCatcher * Get();

    virtual void Serialize(const TCHAR* Msg, ELogVerbosity::Type Verbosity, const class FName& Category) override;
    virtual void HandleError() override;

};
