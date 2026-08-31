#pragma once

#include "Engine/StreamableManager.h"
#include "Delegates/KMDelegateManager.h"

class UKMDelegateManager;

class FGameAssetLoader
{
public:
    FGameAssetLoader();
    bool Init(UKMDelegateManager* Manager);
    void Uninit();
    bool LoadAssetAsync(const FString& AssetName);
    bool LoadMultiAssetsAsync(const TArray<FString>& AssetNames, FOnMultiAssetsLoaded Callback);

    bool Tick(float DeltaTime);
    void Flush();
    void Clear();

private:
    void Flush(float DeltaTime, float LimitTime);
    void OnAssetLoadFinished();
    int32 GenerateHandle();

    UKMDelegateManager* GetKMDelegateManager() const { return KMDelegateManager; }
private:
    const float HandleProcessMaxTimePerTick = 0.01f;
    const int32 AsyncLoadPriority = FStreamableManager::DefaultAsyncLoadPriority;

private:
    UKMDelegateManager* KMDelegateManager;
    bool FlushNextTick;
    FStreamableManager AssetLoader;
    TMap<FName, TSharedPtr<FStreamableHandle>> AssetNameToRequests;
    int32 MaxHandle;
    TMap<int, TSharedPtr<FStreamableHandle>> HandleToRequests;
};