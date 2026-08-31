
#include "Util/FatalLogCatcher.h"
#include "Common.h"

FFatalLogCatcher* FFatalLogCatcher::Get()
{
#if PLATFORM_ANDROID || PLATFORM_IOS
    static FFatalLogCatcher Singleton;
    return &Singleton;
#else
    return nullptr;
#endif
}

void FFatalLogCatcher::Serialize(const TCHAR* Msg, ELogVerbosity::Type Verbosity, const class FName& Category)
{
    FPlatformMisc::LowLevelOutputDebugString(*FOutputDeviceHelper::FormatLogLine(Verbosity, Category, Msg, GPrintLogTimes));

    if (GIsGuarded)
    {
        UE_DEBUG_BREAK();
    }
    else
    {
        HandleError();
        FPlatformMisc::RequestExit(true);
    }
}

void FFatalLogCatcher::HandleError()
{
    static int32 CallCount = 0;
    int32 NewCallCount = FPlatformAtomics::InterlockedIncrement(&CallCount);

    if (NewCallCount != 1)
    {
        return;
    }

    FCoreDelegates::OnHandleSystemError.Broadcast();

    GLog->Flush();

    /* 对严重错误，强制走崩溃流程 */
    {
        *((int32*)3) = 13;
    }
}