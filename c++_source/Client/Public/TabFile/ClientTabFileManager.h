#pragma once
#include "CommonTabFileManager.h"

class CLIENT_API FClientTabFileManager : public FCommonTabFileManager
{
public:
    virtual void RegisterFiles() override;
};