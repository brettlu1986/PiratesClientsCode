#include "Loading/KMMaterialPrecompiling.h"
#include "EngineExt.h"
//#include "VersionInfo.h"

DEFINE_LOG_CATEGORY_STATIC(MaterialPrecompilingLog, Log, All)

UKMMaterialPrecompiling::UKMMaterialPrecompiling(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
	FConfigCacheIni::LoadGlobalIniFile(GMaterialPrecompilingIni, TEXT("Game"), NULL, true);

	LoadConfig(GetClass(), *GMaterialPrecompilingIni);
}

void UKMMaterialPrecompiling::GatherMaterialsToSerialize()
{
	//bool isNeedUpdate = false;
	//const FCurrentVersionInfo CurrentVersion = UVersionInfoFunctionLibrary::GetCurrentVersionNumber();
	//if (CurrentVersion.CurrentVersion.Update > VersionUpdate || 
	//	CurrentVersion.CurrentVersion.Major > VersionMajor || 
	//	CurrentVersion.CurrentVersion.Minor > VersionMinor)
	//{
	//	isNeedUpdate = true;
	//}

	//if (!isNeedUpdate)
	//{
	//	return;
	//}

	////reset version
	//VersionUpdate = CurrentVersion.CurrentVersion.Update;
	//VersionMinor = CurrentVersion.CurrentVersion.Minor;
	//VersionMajor = CurrentVersion.CurrentVersion.Major;

	//SaveConfig(CPF_Config, *GMaterialPrecompilingIni);

	//serialize
	for (int32 DirIndex = 0; DirIndex < MaterialPaths.Num(); DirIndex++)
	{
		TArray<FString> FileNames;

		FString ContentDir = FPaths::ProjectContentDir();
		FString DirectorPath = ContentDir + MaterialPaths[DirIndex];
		IFileManager::Get().FindFilesRecursive(FileNames, *DirectorPath, TEXT("*.*"), true, false);

		for (int32 FileIndex = 0; FileIndex < FileNames.Num(); FileIndex++)
		{
			FString TempFileName = FileNames[FileIndex];

			TempFileName.RemoveFromEnd(FString(TEXT(".uasset")));

			TArray<FString> Routes;
			TempFileName.ParseIntoArray(Routes, TEXT("/"));
			//F:\trunk\src\Content\Resources\Scenes\BaseMaterials\M_BaseMaterials_Cloths_01.uasset
			if (Routes.Num() > 0 && (Routes[Routes.Num() - 1].Contains(TEXT("M_")) || Routes[Routes.Num() - 1].Contains(TEXT("MI_"))))
			{
				TempFileName.Append(FString(TEXT(".")));
				TempFileName.Append(Routes[Routes.Num() - 1]);

				TempFileName.RemoveFromStart(ContentDir);

				TempFileName = FString(TEXT("/Game/")) + TempFileName;

				UMaterialInterface* SerialiedMat = LoadObject<UMaterialInterface>(nullptr, *TempFileName, nullptr, LOAD_None, nullptr);
				//UMaterial* BrushMaterial = LoadObject<UMaterial>(nullptr, TEXT("/Engine/EditorLandscapeResources/FoliageBrushSphereMaterial.FoliageBrushSphereMaterial"), nullptr, LOAD_None, nullptr);

				UE_LOG(MaterialPrecompilingLog, Log, TEXT("GatherMaterialsToSerialize******  %s"), *TempFileName);
			}
		}
	}

}
