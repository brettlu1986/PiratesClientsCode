#pragma once
#include "TabFile/Base/TabFileManagerBase.h"

class COMMON_API FCommonTabFileManager : public FTabFileManagerBase
{
public:
    virtual void RegisterFiles() override;
};