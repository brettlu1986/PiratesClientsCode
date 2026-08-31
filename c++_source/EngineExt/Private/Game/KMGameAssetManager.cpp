#include "KMGameAssetManager.h"
#include "EngineExt.h"
#include "Engine/AssetManagerSettings.h"
#include "Game//GameEngineExt.h"

DECLARE_LOG_CATEGORY_CLASS(LogKMGameAssetManager, Log, All);

UKMGameAssetmanager::UKMGameAssetmanager()
{

}

void UKMGameAssetmanager::ScanPrimaryAssetTypesFromConfig()
{
	Super::ScanPrimaryAssetTypesFromConfig();
}

void UKMGameAssetmanager::ScanPrimaryAssetRulesFromConfig()
{
	Super::ScanPrimaryAssetRulesFromConfig();
}

int32 UKMGameAssetmanager::ScanPathsForPrimaryAssets(FPrimaryAssetType PrimaryAssetType, const TArray<FString>& Paths, UClass* BaseClass, bool bHasBlueprintClasses, bool bIsEditorOnly, bool bForceSynchronousScan)
{
	return Super::ScanPathsForPrimaryAssets(PrimaryAssetType, Paths, BaseClass, bHasBlueprintClasses, bIsEditorOnly, bForceSynchronousScan);
}

#if WITH_EDITOR
void UKMGameAssetmanager::UpdateManagementDatabase(bool bForceRefresh)
{
	//for world composition
	UpdateWorldCompositionAssetRule();

	//update customized asset rules
	ModifyPrimaryAssetRules();
	

	Super::UpdateManagementDatabase(bForceRefresh);
}

//todo:customized rules from game logic
//Asset ID Form:"Map:/Game/sss/Map"
//SetPrimaryAssetRules
//end
void UKMGameAssetmanager::ModifyPrimaryAssetRules()
{
	//for customzed asset
	if (OnCollectPrimaryAssetRule.IsBound())
	{
		TArray<FGamePrimaryAssetRule> AssetRules;
		OnCollectPrimaryAssetRule.Broadcast(AssetRules);

		if (AssetRules.Num() > 0)
		{
			for (int32 RIndex = 0; RIndex < AssetRules.Num(); RIndex++)
			{
				FPrimaryAssetId AssetId;
				FPrimaryAssetType AssetType(FName(*AssetRules[RIndex].AssetTypeName));
				FPrimaryAssetRules AssetRule;

				AssetId.PrimaryAssetName = FName(*AssetRules[RIndex].AssetName);
				AssetId.PrimaryAssetType = AssetType;

				AssetRule.ChunkId = AssetRules[RIndex].ChunkId;

				SetPrimaryAssetRules(AssetId, AssetRule);
			}
		}
	}
}

void UKMGameAssetmanager::UpdateWorldCompositionAssetRule()
{
	//Super::ScanPrimaryAssetRulesFromConfig();
	const UAssetManagerSettings& Settings = GetSettings();

	// Read primary asset rule overrides
	for (const FPrimaryAssetRulesOverride& Override : Settings.PrimaryAssetRules)
	{
		if (Override.PrimaryAssetId.PrimaryAssetType == PrimaryAssetLabelType)
		{
			UE_LOG(LogKMGameAssetManager, Error, TEXT("Cannot specify Rules overrides for Labels in ini! You most modify asset %s!"), *Override.PrimaryAssetId.ToString());
			continue;
		}

		//SetPrimaryAssetRules(Override.PrimaryAssetId, Override.Rules);

		UE_LOG(LogKMGameAssetManager, Display, TEXT("**** UKMGameAssetmanager::ScanPrimaryAssetRulesFromConfig asset %s!"), *Override.PrimaryAssetId.ToString());

		//check is world composition map ; && get sublevels' primaryAssetID
		TArray<FString> SublevelPaths = UGameEngineExt::CheckWorldCompositionAndGetSubleves(Override.PrimaryAssetId);
		if (SublevelPaths.Num() > 0)
		{
			for (int32 IdIndex = 0; IdIndex < SublevelPaths.Num(); IdIndex++)
			{
				FPrimaryAssetId AssetId(SublevelPaths[IdIndex]);
				AssetId.PrimaryAssetType = Override.PrimaryAssetId.PrimaryAssetType;
				AssetId.PrimaryAssetName = FName(*SublevelPaths[IdIndex]);

				UE_LOG(LogKMGameAssetManager, Display, TEXT("**** UKMGameAssetmanager::ScanPrimaryAssetRulesFromConfig Additional asset %s!"), *AssetId.ToString());
				SetPrimaryAssetRules(AssetId, Override.Rules);
			}
		}
		//--<end
	}

}
#endif