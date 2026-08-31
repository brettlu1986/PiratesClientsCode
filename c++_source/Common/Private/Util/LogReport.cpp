// Fill out your copyright notice in the Description page of Project Settings.

#include "Util/LogReport.h"
#include "Common.h"

class FLogReport : public FOutputDevice
{
public:
    FLogReport(ULogReport* Owner) : LogOwner(Owner) {}
    ~FLogReport() { LogOwner = nullptr; }
    virtual void Serialize(const TCHAR* V, ELogVerbosity::Type Verbosity, const class FName& Category) override
    {
        LogOwner->OnLogReport.ExecuteIfBound(Verbosity, FString(V), Category.ToString(), FDateTime::UtcNow().ToUnixTimestamp(), GFrameCounter % 1000);
    }
private:
    ULogReport* LogOwner;
};

bool ULogReport::Init()
{
    return true;
}

bool ULogReport::Uninit()
{
    SetEnabled(false);
    return true;
}

bool ULogReport::IsEnabled()
{
    return LogReport != nullptr;
}

void ULogReport::SetEnabled(bool bEnabled)
{
    if (bEnabled)
    {
        if (LogReport == nullptr)
        {
            LogReport = new FLogReport(this);
            FOutputDeviceRedirector::Get()->AddOutputDevice(LogReport);
        }
    }
    else if (LogReport)
    {
        FOutputDeviceRedirector::Get()->RemoveOutputDevice(LogReport);
        delete LogReport;
        LogReport = nullptr;
    }
}