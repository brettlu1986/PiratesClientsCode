/**
author:yangjingzhao
used for precompiling material when start game first time
**/
#pragma once

#include "KMMaterialPrecompiling.generated.h"

UCLASS(config=Game)
class ENGINEEXT_API UKMMaterialPrecompiling : public UObject
{
	GENERATED_UCLASS_BODY()

public:

	void GatherMaterialsToSerialize();
	
	UPROPERTY(config)
	int32 VersionMajor;

	UPROPERTY(config)
	int32 VersionMinor;

	UPROPERTY(config)
	int32 VersionUpdate;

	UPROPERTY(config)
	TArray<FString>	MaterialPaths;

	FString GMaterialPrecompilingIni;

};