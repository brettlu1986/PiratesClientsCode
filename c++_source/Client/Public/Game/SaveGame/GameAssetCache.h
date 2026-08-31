#pragma once

#include "Delegates/IDelegateInstance.h"
#include "GameAssetCache.generated.h"

UCLASS()
class CLIENT_API UGameAssetCache : public UObject
{
	GENERATED_UCLASS_BODY()

public:
	void Init();

	void Uninit();

	void AddCachedAsset(UObject* InObj);
	void RemoveCachedAsset(UObject* InObj);

	void ClearAllAssets();

	bool FindAssetCache(UObject* InObj) { return CachedAssets.Contains(InObj); }

private:
	
	FDelegateHandle OceanAssetCacheHandle;

	UPROPERTY()
	TArray<UObject*> CachedAssets;
};