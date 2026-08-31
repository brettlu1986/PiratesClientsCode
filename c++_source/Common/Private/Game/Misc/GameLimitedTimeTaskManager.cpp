#include "GameLimitedTimeTaskManager.h"
#include "Common.h"
#include "Containers/Ticker.h"

//#define ENABLE_DEBUG_INFO

#ifdef ENABLE_DEBUG_INFO
#define MAX_TIME_TO_PRINT_LOG 0.01f
DEFINE_LOG_CATEGORY_STATIC(LogGameLimitedTimeTaskManager, Log, All);
#endif

struct FTaskInfo
{
    int Index;
    int Handle;
    int Priority;
    bool bAutoDestroy;
    FGameLimitedTimeTask* Task;
    int PreIndex;
    int NextIndex;

    FTaskInfo()
        : Index(-1), Handle(-1), Priority(0), bAutoDestroy(false), Task(nullptr), PreIndex(-1), NextIndex(-1)
    {}

    ~FTaskInfo()
    {
        Clear(true);
    }

    bool IsValid()
    {
        return Handle > 0 && Task != nullptr;
    }

    void Set(int InHandle, FGameLimitedTimeTask* InTask, int InPriority, bool bInAutoDestroy)
    {
        check(!Task);
        Handle = InHandle;
        Task = InTask;
        Priority = InPriority;
        bAutoDestroy = bInAutoDestroy;
        PreIndex = -1;
        NextIndex = -1;
    }

    void Clear(bool TryDeleteTask)
    {
        if (TryDeleteTask && bAutoDestroy && Task)
        {
            delete Task;
        }
        Handle = -1;
        Task = nullptr;
        bAutoDestroy = false;
    }

    FTaskInfo& operator=(const FTaskInfo& Src)
    {
        FMemory::Memcpy(this, &Src, sizeof(FTaskInfo));
        return *this;
    }
};

class FTaskPriorityQueue
{
public:
    FTaskPriorityQueue()
        : UsedHeadIndex(-1)
        , MaxHandle(0)
        , InitSize(128)
        , StepSize(64)
    {}

    FTaskInfo& Insert(FGameLimitedTimeTask* Task, int Priority, bool bAutoDestroy)
    {
        FTaskInfo& Info = NewInfo();
        Info.Set(GenerateHandle(), Task, Priority, bAutoDestroy);
        HandleToIndex.Add(Info.Handle, Info.Index);

        if (!IsValidIndex(UsedHeadIndex))
        {
            UsedHeadIndex = Info.Index;
            return Info;
        }

        FTaskInfo* Last = nullptr;        
        for (auto TempInfo = GetInfo(UsedHeadIndex); TempInfo; TempInfo = GetInfo(TempInfo->NextIndex))
        {
            if (TempInfo->Priority < Info.Priority)
            {
                break;
            }
            Last = TempInfo;
        }
        
        if(Last)
        {
            Info.NextIndex = Last->NextIndex;
            Info.PreIndex = Last->Index;
            Last->NextIndex = Info.Index;
            auto NextInfo = GetInfo(Info.NextIndex);
            if (NextInfo)
            {
                NextInfo->PreIndex = Info.Index;
            }
        }
        else
        {
            auto OldHead = GetInfo(UsedHeadIndex);
            OldHead->PreIndex = Info.Index;
            Info.NextIndex = OldHead->Index;
            UsedHeadIndex = Info.Index;
        }

        return Info;
    }

    FTaskInfo* Erase(FTaskInfo& Info, bool TryDeleteTask)
    {
        check(IsValidIndex(UsedHeadIndex));

        FTaskInfo* PreInfo = GetInfo(Info.PreIndex);
        FTaskInfo* NextInfo = GetInfo(Info.NextIndex);
        if (PreInfo)
        {
            PreInfo->NextIndex = Info.NextIndex;
        }        
        if (NextInfo)
        {
            NextInfo->PreIndex = Info.PreIndex;
        }
        if (UsedHeadIndex == Info.Index)
        {
            UsedHeadIndex = Info.NextIndex;
        }
        
        HandleToIndex.Remove(Info.Handle);
        Info.Clear(TryDeleteTask);
        RecycleInfo(Info);
        return NextInfo;
    }

    void Insert(FTaskInfo& Info, int PosIndex)
    {
        if (Info.Index == PosIndex)
        {
            return;
        }

        FTaskInfo* NextInfo = GetInfo(PosIndex);
        FTaskInfo* PreInfo = NextInfo ? GetInfo(NextInfo->PreIndex) : nullptr;        
        if (PreInfo)
        {
            PreInfo->NextIndex = Info.Index;
            Info.PreIndex = PreInfo->Index;            
        }
        else
        {
            Info.PreIndex = -1;
        }

        if (NextInfo)
        {
            NextInfo->PreIndex = Info.Index;
            Info.NextIndex = NextInfo->Index;
        }
        else
        {
            Info.NextIndex = -1;
        }

        if (UsedHeadIndex == PosIndex)
        {
            UsedHeadIndex = Info.Index;
        }
    }

    void AllocCount(int NewCount)
    {
        check(FreedIndices.Num() == 0);
        int OldIndex = Allocator.AddDefaulted(NewCount);
        int NewTotalCount = Allocator.Num();
        FreedIndices.Reserve(NewCount);
        for (int ii = NewTotalCount-1; ii >= OldIndex; ii--)
        {
            auto& Info = Allocator[ii];
            Info.Index = ii;
            FreedIndices.Add(ii);
        }
    }

    FTaskInfo& NewInfo()
    {
        if (FreedIndices.Num() == 0)
        {
            AllocCount(Allocator.Num() == 0 ? InitSize : StepSize);
        }

        int NewIndex = FreedIndices.Pop(false);
        return *GetInfo(NewIndex);
    }

    void RecycleInfo(FTaskInfo& Info)
    {
#if WITH_EDITOR
        check(FreedIndices.Find(Info.Index) == INDEX_NONE);
#endif
        FreedIndices.Add(Info.Index);
    }

    FTaskInfo* GetInfo(int Index)
    {
        if (IsValidIndex(Index))
        {
            return &Allocator[Index];
        }
        return nullptr;
    }

    bool IsValidIndex(int Index)
    {
        return Index >= 0 && Index < Allocator.Num();
    }

    void ClearAll()
    {
        Allocator.Empty();
        HandleToIndex.Empty();
        FreedIndices.Empty();
        UsedHeadIndex = -1;
    }

    int GenerateHandle()
    {
        return ++MaxHandle;
    }

    FTaskInfo* FindByHandle(int Handle)
    {
        int* FindIndex = HandleToIndex.Find(Handle);
        if (FindIndex)
        {
            check(IsValidIndex(*FindIndex));
            return GetInfo(*FindIndex);
        }
        return nullptr;
    }

    FTaskInfo* GetHead()
    {
        return GetInfo(UsedHeadIndex);
    }

    FTaskInfo* GetNext(FTaskInfo* Info)
    {
        if (!Info)
        {
            return nullptr;
        }
        return GetInfo(Info->NextIndex);
    }

    bool IsEmpty()
    {
        return !IsValidIndex(UsedHeadIndex);
    }

private:
    TArray<FTaskInfo> Allocator;
    TMap<int, int> HandleToIndex;
    TArray<int> FreedIndices;
    int UsedHeadIndex;
    int MaxHandle;
    int InitSize;
    int StepSize;
};

struct UGameLimitedTimeTaskManager::Implement
{
    FTaskPriorityQueue Queue;
    UGameLimitedTimeTaskManager* Owner;
    FDelegateHandle TickHandle;
    FDelegateHandle OnBeginFrameHandle;
    FDelegateHandle OnEndFrameHandle;
    float MaxLimitedTimePerFrame;
    float MaxWorkFrameTime; // 每针超过此时间就不工作了
    double FrameBeginTime;

    // 先Erase在process，防止在process中erase掉自己
#define DO_AND_ERASE(Info, __code) { \
        auto Task = Info->Task; \
        bool bDestroy = Info->bAutoDestroy; \
        check(Info->IsValid()); \
        Info = Queue.Erase(*Info, false); \
        __code; \
        if (bDestroy) \
        { \
            delete Task; \
        } \
    }

    Implement(UGameLimitedTimeTaskManager* InOwner)
        : Owner(InOwner)
        , MaxLimitedTimePerFrame(0.f)
        , MaxWorkFrameTime(0.02f)
        , FrameBeginTime(0)
    {}

    void Init(float InMaxLimitedTimePerFrame, float InMaxWorkFrameTime)
    {
        MaxLimitedTimePerFrame = InMaxLimitedTimePerFrame;
        MaxWorkFrameTime = InMaxWorkFrameTime;
    }

    void Uninit()
    {
        RemoveAll();
    }

    int AddTask(FGameLimitedTimeTask* Task, int Priority, bool bAutoDestroy)
    {
        check(Task);
        auto& NewInfo = Queue.Insert(Task, Priority, bAutoDestroy);
        TryCreateTicker();
        return NewInfo.Handle;
    }

    void RemoveTask(int TaskHandle)
    {
        auto Info = Queue.FindByHandle(TaskHandle);
        if (!Info)
        {
            return;
        }

        DO_AND_ERASE(Info, 
            {
                Task->Cancel();
            });

        if (Queue.IsEmpty())
        {
            TryRemoveTicker();
        }
    }

    bool FlushTask(int TaskHandle)
    {
        auto Info = Queue.FindByHandle(TaskHandle);
        if (!Info)
        {
            return false;
        }

        DO_AND_ERASE(Info, 
            {
                Task->Process();
            });

        if (Queue.IsEmpty())
        {
            TryRemoveTicker();
        }

        return true;
    }

    void FlushAll()
    {
        auto Info = Queue.GetHead();
        while(Info)
        {
            DO_AND_ERASE(Info, 
                {
                    Task->Process();
                });
        }

        check(Queue.IsEmpty());
        TryRemoveTicker();
    }

    void RemoveAll()
    {
        Queue.ClearAll();
        TryRemoveTicker();
    }

    void OnBeginFrame()
    {
        FrameBeginTime = FPlatformTime::Seconds();
    }

    void OnEndFrame()
    {
        Tick(0.0f);
    }

    void TryCreateTicker()
    {
        if (!OnBeginFrameHandle.IsValid())
        {
            OnBeginFrameHandle = FCoreDelegates::OnBeginFrame.AddRaw(this, &UGameLimitedTimeTaskManager::Implement::OnBeginFrame);
            OnEndFrameHandle = FCoreDelegates::OnEndFrame.AddRaw(this, &UGameLimitedTimeTaskManager::Implement::OnEndFrame);
            //TickHandle = FTicker::GetCoreTicker().AddTicker(FTickerDelegate::CreateRaw(this, &UGameLimitedTimeTaskManager::Implement::Tick));
        }
    }

    void TryRemoveTicker()
    {
        if (OnBeginFrameHandle.IsValid())
        {
            FrameBeginTime = 0;
            //FTicker::GetCoreTicker().RemoveTicker(TickHandle);
            //TickHandle.Reset();

            FCoreDelegates::OnBeginFrame.Remove(OnBeginFrameHandle);
            OnBeginFrameHandle.Reset();

            FCoreDelegates::OnEndFrame.Remove(OnEndFrameHandle);
            OnEndFrameHandle.Reset();
        }
    }

    bool Tick(float fDeltaTime)
    {
        if (FrameBeginTime <= 0)
        {
            return true;
        }

        float fUsedTimeInThisFrame = (float)(FPlatformTime::Seconds() - FrameBeginTime);
        if (fUsedTimeInThisFrame > MaxWorkFrameTime)
        {
            // 此针时间已经不够用了，直接退出
            return true;
        }

        float fRemainTime = MaxLimitedTimePerFrame;
        double fOldTime = FPlatformTime::Seconds();
        auto Info = Queue.GetHead();
        while (Info && fRemainTime > 0.0f)
        {            
#ifdef ENABLE_DEBUG_INFO
            FString DebugInfo = Info->Task->GetInfo();
#endif

            DO_AND_ERASE(Info, 
                {
                    Task->Process();
                });

            double fNewTime = FPlatformTime::Seconds();
            float fElapsedTime = (float)(fNewTime - fOldTime);
            fRemainTime -= fElapsedTime;
            fOldTime = fNewTime;

#ifdef ENABLE_DEBUG_INFO
            if (fElapsedTime >= MAX_TIME_TO_PRINT_LOG)
            {
                UE_LOG(LogGameLimitedTimeTaskManager, Warning, TEXT("GameLimitedTimeTask elapsed %.2f ms, info: %s"), 
                    fElapsedTime*1000.0f, *DebugInfo);
            }
#endif
        }

        if (Queue.IsEmpty())
        {
            TryRemoveTicker();
        }
        return true;
    }

    void AddReferencedObjects(FReferenceCollector& Collector)
    {
        for (auto Info = Queue.GetHead(); Info; Info = Queue.GetNext(Info))
        {
            Info->Task->AddReferencedObjects(Collector);
        }
    }
#undef DO_AND_ERASE
};

//////////////////////////////////////////////////////////////////////////
UGameLimitedTimeTaskManager::UGameLimitedTimeTaskManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , Impl(new UGameLimitedTimeTaskManager::Implement(this))
    , LimitedTimePerFrame(0.005f)
    , MaxWorkFrameTime(0.02f)
{

}

void UGameLimitedTimeTaskManager::Init()
{
    Impl->Init(LimitedTimePerFrame, MaxWorkFrameTime);
}

void UGameLimitedTimeTaskManager::Uninit()
{
    Impl->Uninit();
}

int UGameLimitedTimeTaskManager::AddTask(FGameLimitedTimeTask* Task, int Priority, bool bAutoDestroy)
{
    return Impl->AddTask(Task, Priority, bAutoDestroy);
}

void UGameLimitedTimeTaskManager::RemoveTask(int TaskHandle)
{
    Impl->RemoveTask(TaskHandle);
}

bool UGameLimitedTimeTaskManager::FlushTask(int TaskHandle)
{
    return Impl->FlushTask(TaskHandle);
}

void UGameLimitedTimeTaskManager::FlushAll()
{
    Impl->FlushAll();
}

void UGameLimitedTimeTaskManager::RemoveAll()
{
    Impl->RemoveAll();
}

void UGameLimitedTimeTaskManager::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
    UGameLimitedTimeTaskManager* Manager = Cast<UGameLimitedTimeTaskManager>(InThis);
    if (Manager && Manager->Impl.IsValid())
    {
        Manager->Impl->AddReferencedObjects(Collector);
    }    
}

#ifdef ENABLE_DEBUG_INFO
#undef ENABLE_DEBUG_INFO
#endif