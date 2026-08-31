//-->add by yangjingzhao
//extension for mobile patching
#pragma once

#include "Engine/AssetManager.h"
#include "KMGameAssetManager.generated.h"

USTRUCT()
struct ENGINEEXT_API FGamePrimaryAssetRule
{
	GENERATED_BODY()
public:
	
	UPROPERTY()
	FString AssetName;

	UPROPERTY()
	FString AssetTypeName;

	UPROPERTY()
	int32 ChunkId;
};


UCLASS()
class ENGINEEXT_API UKMGameAssetmanager : public UAssetManager
{
	GENERATED_BODY()

public:
	UKMGameAssetmanager();

	virtual void ScanPrimaryAssetTypesFromConfig()override;

	virtual void ScanPrimaryAssetRulesFromConfig()override;

	virtual int32 ScanPathsForPrimaryAssets(FPrimaryAssetType PrimaryAssetType, const TArray<FString>& Paths, UClass* BaseClass, bool bHasBlueprintClasses, bool bIsEditorOnly /* = false */, bool bForceSynchronousScan /* = true */)override;

	DECLARE_MULTICAST_DELEGATE_OneParam(FOnCollectPrimaryAssetRule, TArray<FGamePrimaryAssetRule>&);
	FOnCollectPrimaryAssetRule OnCollectPrimaryAssetRule;

	//重写此接口解决WorldComposition的子关卡不能自动随PersistentLevel添加PrimaryRule, 从而不能分进同一个包的问题
	//目的是让子关卡和世界关卡自动的分进一个包里(因为大世界分出去的子关卡非常多!!, 不能手动添加)
	//cook的时候执行
#if WITH_EDITOR
	virtual void UpdateManagementDatabase(bool bForceRefresh /* = false */)override;

private:

	void UpdateWorldCompositionAssetRule();
	void ModifyPrimaryAssetRules();
#endif
};
