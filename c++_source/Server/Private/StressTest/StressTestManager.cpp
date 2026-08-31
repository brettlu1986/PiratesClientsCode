#include "StressTest/StressTestManager.h"
#include "Server.h"
#include "Engine/Engine.h"

DEFINE_LOG_CATEGORY_STATIC(StressTestManagerLog, Log, All)

enum class EProfilerSwitchAction : uint8
{
    None,
    On,
    Off,
};

static EProfilerSwitchAction ProfileSwitch = EProfilerSwitchAction::None;

static void StartFile()
{
    UE_LOG(StressTestManagerLog, Log, TEXT("stat startfile"));
    GEngine->Exec(nullptr, TEXT("stat startfile"));
}

static void StopFile()
{
    UE_LOG(StressTestManagerLog, Log, TEXT("stat stopfile"));
    GEngine->Exec(nullptr, TEXT("stat stopfile"));
}

static void InitCustomSignalHandler()
{
#if PLATFORM_LINUX
    struct sigaction Action;
    FMemory::Memzero(Action);
    Action.sa_sigaction = [](int32 Signal, siginfo_t* Info, void* Context) {
        ProfileSwitch = EProfilerSwitchAction::On;
    };
    sigfillset(&Action.sa_mask);
    Action.sa_flags = SA_SIGINFO | SA_RESTART | SA_ONSTACK;
    sigaction(SIGUSR1, &Action, nullptr);

    FMemory::Memzero(Action);
    Action.sa_sigaction = [](int32 Signal, siginfo_t* Info, void* Context) {
        ProfileSwitch = EProfilerSwitchAction::Off;
    };
    sigfillset(&Action.sa_mask);
    Action.sa_flags = SA_SIGINFO | SA_RESTART | SA_ONSTACK;
    sigaction(SIGUSR2, &Action, nullptr);
#endif
}

void FStressTestManager::Init()
{
    InitCustomSignalHandler();
}

void FStressTestManager::Tick()
{
    switch (ProfileSwitch)
    {
    case EProfilerSwitchAction::None:
        break;
    case EProfilerSwitchAction::On:
        StartFile();
        break;
    case EProfilerSwitchAction::Off:
        StopFile();
        break;
    default:
        break;
    }

    ProfileSwitch = EProfilerSwitchAction::None;
}
