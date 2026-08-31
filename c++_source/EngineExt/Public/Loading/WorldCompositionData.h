#pragma once

#include "CoreMinimal.h"
#include "Templates/SubclassOf.h"
#include "WorldCompositionData.generated.h"

USTRUCT(Blueprintable)
struct FWorldCompositionSubLevel
{
	GENERATED_BODY()

	UPROPERTY(Blueprintable, EditAnyWhere, Category = "WorldComposition")
	bool IsUsed;

	UPROPERTY(Blueprintable, EditAnyWhere, Category = "WorldComposition")
	bool IsServerOnly;

	UPROPERTY(Blueprintable, EditAnyWhere, Category = "WorldComposition")
	FString DirectoryPath;
};

USTRUCT(Blueprintable)
struct FWorldCompositionPair
{
	GENERATED_BODY()

	UPROPERTY(Blueprintable, EditAnyWhere, Category = "WorldComposition")
	FString PersistentName;

	UPROPERTY(Blueprintable, EditAnyWhere, Category = "WorldComposition")
	TArray<FWorldCompositionSubLevel> Roots;
};

UCLASS(Blueprintable, Config = Game)
class ENGINEEXT_API UWorldCompositionData : public UObject
{
	GENERATED_UCLASS_BODY()

public:
	UPROPERTY(Blueprintable, EditAnyWhere, Category = "PersistentLevels")
	TArray<FWorldCompositionPair> WorldCompositions;

	UPROPERTY(config, BlueprintReadOnly, Category = WorldComposition)
	FString WCDataClassPath;
};

UCLASS(Config = Editor)
class ENGINEEXT_API UWorldCompositionConfig : public UObject
{
	GENERATED_BODY()

#if WITH_EDITORONLY_DATA

public:
	UPROPERTY(config, EditAnyWhere, Category = WorldComposition)
	TSubclassOf<UWorldCompositionData> WCDataLocalPath;
	

	UPROPERTY(config, EditAnyWhere, Category = WorldComposition)
	bool UseLocalPath;

#endif
};
