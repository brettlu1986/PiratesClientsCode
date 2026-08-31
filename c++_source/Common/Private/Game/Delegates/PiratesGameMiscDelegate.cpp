#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Common.h"
#include "Misc/CoreDelegates.h"
#include "GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"

DECLARE_LOG_CATEGORY_CLASS(LogGameMiscDelegate, Log, All);

enum EApplicationNoParamDelegateType
{
    WillDeactivate,

    WillEnterBackground,

    HasEnteredForeground
};

class FGameThreadApplicationNoParamDelegateAsyncTasks
{
public:
    FGameThreadApplicationNoParamDelegateAsyncTasks(EApplicationNoParamDelegateType InDelegateType)
        : DelegateType(InDelegateType)
    {

    }

    FORCEINLINE TStatId GetStatId() const
    {
        RETURN_QUICK_DECLARE_CYCLE_STAT(FGameThreadApplicationNoParamDelegateAsyncTasks, STATGROUP_TaskGraphTasks);
    }

    ENamedThreads::Type GetDesiredThread()
    {
        return ENamedThreads::GameThread;
    }

    static ESubsequentsMode::Type GetSubsequentsMode() { return ESubsequentsMode::FireAndForget; }

    void DoTask(ENamedThreads::Type CurrentThread, const FGraphEventRef& MyCompletionGraphEvent)
    {
        check(IsInGameThread());

        auto GameCommon = UGameCommon::Get(GWorld);
        if (GameCommon)
        {
            UE_LOG(LogGameMiscDelegate, Log, TEXT("GameThreadApplicationNoParamDelegateAsyncTasks Do Task, DelegateType=%d"), DelegateType);

            auto Delegate = GameCommon->GetGameDelegateManager()->GameMisc;
            switch (DelegateType)
            {
            case WillDeactivate:
                Delegate->OnApplicationWillDeactivateDelegate.ExecuteIfBound();
                //release mouse button state
                FSlateApplication::Get().ReleaseAllPointerCapture();
                break;
            case WillEnterBackground:
                Delegate->OnApplicationWillEnterBackgroundDelegate.ExecuteIfBound();
                break;
            case HasEnteredForeground:
                Delegate->OnApplicationHasEnteredForegroundDelegate.ExecuteIfBound();
                break;
            default:
                break;
            }
        }
    }
private:
    EApplicationNoParamDelegateType DelegateType;
};

void UPiratesGameMiscDelegate::Init()
{
    FCoreDelegates::ApplicationWillDeactivateDelegate.AddStatic(&UPiratesGameMiscDelegate::OnApplicationWillDeactivateHandle);
    FCoreDelegates::ApplicationWillEnterBackgroundDelegate.AddStatic(&UPiratesGameMiscDelegate::OnApplicationWillEnterBackgroundHandle);
    FCoreDelegates::ApplicationHasEnteredForegroundDelegate.AddStatic(&UPiratesGameMiscDelegate::OnApplicationHasEnteredForegroundHandle);

    FViewport::ViewportResizedEvent.AddUObject(this, &UPiratesGameMiscDelegate::ViewportResized);
}

void UPiratesGameMiscDelegate::OnApplicationWillDeactivateHandle()
{
    UE_LOG(LogGameMiscDelegate, Log, TEXT("OnApplicationWillDeactivateHandle"));
    TGraphTask<FGameThreadApplicationNoParamDelegateAsyncTasks>::CreateTask().ConstructAndDispatchWhenReady(EApplicationNoParamDelegateType::WillDeactivate);
}

void UPiratesGameMiscDelegate::OnApplicationWillEnterBackgroundHandle()
{
    UE_LOG(LogGameMiscDelegate, Log, TEXT("OnApplicationWillEnterBackgroundHandle"));
    TGraphTask<FGameThreadApplicationNoParamDelegateAsyncTasks>::CreateTask().ConstructAndDispatchWhenReady(EApplicationNoParamDelegateType::WillEnterBackground);
}

void UPiratesGameMiscDelegate::OnApplicationHasEnteredForegroundHandle()
{
    UE_LOG(LogGameMiscDelegate, Log, TEXT("OnApplicationHasEnteredForegroundHandle"));
    TGraphTask<FGameThreadApplicationNoParamDelegateAsyncTasks>::CreateTask().ConstructAndDispatchWhenReady(EApplicationNoParamDelegateType::HasEnteredForeground);
}