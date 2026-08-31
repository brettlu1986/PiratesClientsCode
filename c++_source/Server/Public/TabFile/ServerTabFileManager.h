#pragma once
#include "CommonTabFileManager.h"

class SERVER_API FServerTabFileManager : public FCommonTabFileManager
{
public:
    virtual void RegisterFiles() override;
};