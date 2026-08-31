
#include "FGameAssetLoader.h"
#include "EngineExt.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Engine/StreamableManager.h"

DEFINE_LOG_CATEGORY_STATIC(LogFGameAssetLoader, Log, All);


//////////////////////////////////////////////////////////////////////////
FGameAssetLoader::FGameAssetLoader() 
    : KMDelegateManager(nullptr)
    , FlushNextTick(false)
    , MaxHandle(0)
{
    
}

bool FGameAssetLoader::Init(UKMDelegateManager* Manager)
{
    this->KMDelegateManager = Manager;
    return true;
}


void FGameAssetLoader::Uninit()
{
    Clear();
    this->KMDelegateManager = nullptr;
}

bool FGameAssetLoader::LoadAssetAsync(const FString& AssetName)
{
    UE_LOG(LogFGameAssetLoader, Log, TEXT("LoadAssetAsync, asset: %s"), *AssetName);
    FName TempName(*AssetName);
    TSharedPtr<FStreamableHandle>* Ret = AssetNameToRequests.Find(TempName);
    if (Ret)
    {
        return Ret->IsValid();
    }

    TSharedPtr<FStreamableHandle> ptrHandle = AssetLoader.RequestAsyncLoad(FStringAssetReference(AssetName),
        FStreamableDelegate::CreateRaw(this, &FGameAssetLoader::OnAssetLoadFinished), AsyncLoadPriority);
    if (!ptrHandle.IsValid())
    {
        return false;
    }
    AssetNameToRequests.Add(TempName, ptrHandle);
    return true;
}

int32 FGameAssetLoader::GenerateHandle()
{
    return ++MaxHandle;
}

bool FGameAssetLoader::LoadMultiAssetsAsync(const TArray<FString>& AssetNames, FOnMultiAssetsLoaded Callback)
{
    if (AssetNames.Num() == 0)
    {
        return false;
    }
    TArray<FSoftObjectPath> Names;
    for (const auto& AssetName : AssetNames)
    {
        Names.Add(AssetName);
    }

    int32 nHandle = GenerateHandle();
    auto& NewHandle = HandleToRequests.FindOrAdd(nHandle);
    auto TempCallback = [&, nHandle, Callback]()
    {
        TSharedPtr<FStreamableHandle>* ptrHandle = HandleToRequests.Find(nHandle);
        if (ptrHandle)
        {
            // 如果已经加载了，RequestAsyncLoad会立即调用TempCallback，这时ptrHandle还没有被赋值，
            // 因此ptrHandle有可能是Valid
            if (ptrHandle->IsValid() && Callback.IsBound())
            {
                // 只有当该handle真正走了加载流程，才会执行回调
                TArray<UObject*> LoadedAssets;
                (*ptrHandle)->GetLoadedAssets(LoadedAssets);
                Callback.Execute(LoadedAssets);
            }
            HandleToRequests.Remove(nHandle);
        }
    };

    TSharedPtr<FStreamableHandle> ptrHandle = AssetLoader.RequestAsyncLoad(Names, TempCallback);
    if (!ptrHandle.IsValid())
    {
        HandleToRequests.Remove(nHandle);
        return false;
    }

    // 如果已经加载了，RequestAsyncLoad会立即调用TempCallback，TempCallback中会把Handle删掉，
    // 因此HandleToRequests 中找不到该Handle
    if (!HandleToRequests.Find(nHandle))
    {
        // 已经加载了，则立即执行回调
        TArray<UObject*> LoadedAssets;
        ptrHandle->GetLoadedAssets(LoadedAssets);
        Callback.Execute(LoadedAssets);
        return true;
    }
    
    NewHandle = ptrHandle;

    return true;
}


bool FGameAssetLoader::Tick(float DeltaTime)
{
    if (FlushNextTick)
    {
        Flush(DeltaTime, HandleProcessMaxTimePerTick);
    }
    return true;
}

void FGameAssetLoader::Flush()
{
    Flush(0, 0);
}

void FGameAssetLoader::Clear()
{
    for (auto Iterator = AssetNameToRequests.CreateIterator(); Iterator; ++Iterator)
    {
        auto& ptrHandle = Iterator.Value();
        if (ptrHandle.IsValid())
        {
            ptrHandle->CancelHandle();
        }
    }
    AssetNameToRequests.Empty();

    for (auto Iterator = HandleToRequests.CreateIterator(); Iterator; ++Iterator)
    {
        auto& ptrHandle = Iterator.Value();
        if (ptrHandle.IsValid())
        {
            ptrHandle->CancelHandle();
        }
    }
    HandleToRequests.Empty();
}

void FGameAssetLoader::Flush(float DeltaTime, float LimitTime)
{
	QUICK_SCOPE_CYCLE_COUNTER(STAT_FGameAssetLoader_Flush);
    FlushNextTick = false;
    float RemainTime = LimitTime;
    double StartTime = FPlatformTime::Seconds();
    FString TempName;
    auto& OnLoadAssetAsync = GetKMDelegateManager()->OnLoadAssetAsync;
    for (auto Iterator = AssetNameToRequests.CreateIterator(); Iterator; ++Iterator)
    {
        TempName = Iterator.Key().ToString();
        auto& ptrHandle = Iterator.Value();
        if (ptrHandle->HasLoadCompleted())
        {
            if (RemainTime < 0)
            {
                FlushNextTick = true;
                break;
            }
            OnLoadAssetAsync.ExecuteIfBound(TempName, ptrHandle->GetLoadedAsset());
            double Now = FPlatformTime::Seconds();
            float CostTime = (float)(Now - StartTime);
            RemainTime -= CostTime;
            StartTime = Now;
            Iterator.RemoveCurrent();
            UE_LOG(LogFGameAssetLoader, Log, TEXT("LoadAssetAsync, asset: %s, cost time: %f s"), *TempName, CostTime);
        }
    }
}

void FGameAssetLoader::OnAssetLoadFinished()
{
    FlushNextTick = true;
}


