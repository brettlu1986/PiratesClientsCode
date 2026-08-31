#include "Game/SaveGame/GameAssetCache.h"
#include "Client.h"
#include "Ocean.h"

UGameAssetCache::UGameAssetCache(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{

}

void UGameAssetCache::Init()
{
	//register ocean module event; to hold ocean asset
	if (!GIsEditor)
	{
		FOceanModule& OceanModule = FModuleManager::GetModuleChecked<FOceanModule>("Ocean");
		if (!OceanModule.GetCacheOceanAssetDelegate().IsBound())
		{
			OceanAssetCacheHandle = OceanModule.RegisterCacheOceanAsset(FOceanModule::FOnCacheOceanAsset::CreateLambda([this](UObject* InObj)
			{
				this->AddCachedAsset(InObj);
			}));
		}
		
	}
	
}

void UGameAssetCache::Uninit()
{
	if (!GIsEditor)
	{
		FOceanModule& OceanModule = FModuleManager::GetModuleChecked<FOceanModule>("Ocean");
		if (OceanModule.GetCacheOceanAssetDelegate().IsBound())
		{
			OceanModule.UnRegisterCacheOceanAsset();
		}
	}
	ClearAllAssets();
}

void UGameAssetCache::AddCachedAsset(UObject* InObj)
{
	CachedAssets.AddUnique(InObj);
}

void UGameAssetCache::RemoveCachedAsset(UObject* InObj)
{
	CachedAssets.Remove(InObj);
}

void UGameAssetCache::ClearAllAssets()
{
	CachedAssets.Empty();
}
