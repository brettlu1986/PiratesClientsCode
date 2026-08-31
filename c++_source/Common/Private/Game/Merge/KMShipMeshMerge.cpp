#include "Game/Merge/KMShipMeshMerge.h"
#include "Common.h"


#include "KMStaticMeshMerge.h"
#include "Kismet/KismetMaterialLibrary.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "SkeletalMeshMerge.h"
#include "SkeletalMeshTypes.h"
#include "Engine/CanvasRenderTarget2D.h"
#include "Shell/EngineExtShell.h"
#include "TextureProcess/CookedTextureMerge.h"
//#include "KMSkeletalStaticMeshMerge.h"

DEFINE_LOG_CATEGORY_STATIC(LogKMSKMergeStatic, Log, All)

int32 UseShipMerge = 1;
FAutoConsoleVariableRef CVarUseShipMerge(
	TEXT("r.UseShipMerge"),
	UseShipMerge,
	TEXT("use shipmerge. Ex: 0 not use; 1 use")
);

FKMShipMeshMerge::FKMShipMeshMerge()
{
#if 0
	UKMMergeConfig* NewConfig = NewObject<UKMMergeConfig>(GetTransientPackage(), FName(TEXT("MergeConfig")));

	MergedMatUrl = NewConfig->MergedMatUrl/*FString(TEXT("/Game/Resources/Ships/BaseMaterials/M_Ship_Hull_Base.M_Ship_Hull_Base"))*/;
	DefaultMaskPath = NewConfig->DefaultMaskPath/*FString(TEXT("/Game/Resources/Ships/BaseTextures/T_ShipShellPT_C.T_ShipShellPT_C"))*/;
	FlagMergedMatUrl = NewConfig->FlagMergedMatUrl/*FString(TEXT("/Game/Resources/Ships/ChangeParts/Flag/Materials/MI_ShipFlag_01.MI_ShipFlag_01"))*/;

	ShipChannel = NewConfig->ShipChannel;
	FlagMaterialChannel = NewConfig->FlagMaterialChannel;
	//initial default alpha 
	DefaultAlphaSize = GPixelFormats[EPixelFormat::PF_ETC2_RGB].BlockBytes;
	DefaultAlpha.AddUninitialized(DefaultAlphaSize);
	for (int32 Index = 0; Index < DefaultAlpha.Num(); ++Index)
	{
		DefaultAlpha[Index] = 255;
	}

	//initial default mask for clear 
	//Texture2D'/Game/Game/Characters/Materials/T_DefaultMask_M.T_DefaultMask_M'
	UTexture2D* DefaultMask = Cast<UTexture2D>(UEngineExtShell::StaticLoadObjectWithoutFlush(DefaultMaskPath));

	if (!DefaultMask)
	{
		UE_LOG(LogKMSKMergeStatic, Warning, TEXT("Can not Load Default Mask, This May rise Render Error For Texture"));
	}

	//Copy data from texture;
	int32 NumMip = DefaultMask->PlatformData->Mips.Num();
	uint8* TempData = static_cast<uint8*>(DefaultMask->PlatformData->Mips[0].BulkData.Lock(LOCK_READ_ONLY));
	EPixelFormat Format = DefaultMask->PlatformData->PixelFormat;
	DefaultColor.AddUninitialized(GPixelFormats[Format].BlockBytes);
	FMemory::Memcpy(DefaultColor.GetData(), TempData, GPixelFormats[Format].BlockBytes);
	DefaultMask->PlatformData->Mips[0].BulkData.Unlock();

	//initail ship part desc
	for (int32 PIndex = 0; PIndex < NewConfig->ShipPartDescs.Num(); PIndex++)
	{
		FTransform UvTran = FTransform::Identity;
		UvTran.SetScale3D(NewConfig->ShipPartDescs[PIndex].UvScale);
		UvTran.SetTranslation(NewConfig->ShipPartDescs[PIndex].UvLocation);
		ShipParts.Add(FShipPartMergeDesc(NewConfig->ShipPartDescs[PIndex].ShipPart, UvTran, NewConfig->ShipPartDescs[PIndex].SlotName));
	}
#endif
/*
+ShipPartDescs=(ShipPart=0, UvLocation=(X=0.0,Y=0.0,Z=0.0), UvScale=(X=0.5,Y=0.5,Z=0.0), SlotName="hull")
+ShipPartDescs=(ShipPart=1, UvLocation=(X=0.0,Y=0.5,Z=0.0), UvScale=(X=0.5,Y=0.5,Z=0.0), SlotName="body")
+ShipPartDescs=(ShipPart=2, UvLocation=(X=0.5,Y=0.5,Z=0.0), UvScale=(X=0.25,Y=0.25,Z=0.0), SlotName="anchor")
+ShipPartDescs=(ShipPart=3, UvLocation=(X=0.75,Y=0.5,Z=0.0), UvScale=(X=0.25,Y=0.25,Z=0.0), SlotName="light")
+ShipPartDescs=(ShipPart=4, UvLocation=(X=0.5,Y=0.75,Z=0.0), UvScale=(X=0.25,Y=0.25,Z=0.0), SlotName="head")
+ShipPartDescs=(ShipPart=5, UvLocation=(X=0.75,Y=0.75,Z=0.0), UvScale=(X=0.25,Y=0.25,Z=0.0), SlotName="cannon")
+ShipPartDescs=(ShipPart=6, UvLocation=(X=0.0,Y=0.0,Z=0.0), UvScale=(X=1.0,Y=1.0,Z=1.0), SlotName="sail")
	*/
}


USkeletalMesh* FKMShipMeshMerge::KMMergeSkeletal_Cooked(TArray<USkeletalMeshComponent *>& SrcMeshes, TArray<int32>& PartIDs, int32 OverrideQuality /* = -1 */)
{
#if 0
#if PLATFORM_IOS
	return nullptr;
#endif

	if (UseShipMerge <= 0)
	{
		return nullptr;
	}
	
	//check is texture has already in mem
	TArray<int32> StaIDs;
	for (int32 StaIDIndex = 0; StaIDIndex < CachedStaticMeshes.Num(); ++StaIDIndex)
	{
		StaIDs.Add(CachedStaticMeshes[StaIDIndex].PartID);
	}

	//Create Merged Textures
	TMap<EShipMergeTexture::Texture, UTexture2D*> TextureMap;
	CreateShipMergedTextures(TextureMap, SrcMeshes, OverrideQuality);
	checkSlow(TextureMap.Num() == 5);

	//used for merge skeletal mesh section
	TArray<FSkelMeshMergeSectionMapping> SkeletonSections;
	FSkelMeshMergeUVTransforms MergeUVTransform;

	FSkeletalMeshMergeParams SkeletalPara;

	for (int32 SIndex = 0; SIndex < SrcMeshes.Num(); SIndex++)
	{
		SkeletalPara.SrcMeshList.Add(SrcMeshes[SIndex]->SkeletalMesh);
	}

	//used for flag empty texture part,use this flag to empty texture
	TMap<EShipMerge::MergePart, bool> EmptyMap;
	EmptyMap.Add(EShipMerge::Part_Body, true);
	EmptyMap.Add(EShipMerge::Part_Sail, true);
	EmptyMap.Add(EShipMerge::Part_Hull, true);
	EmptyMap.Add(EShipMerge::Part_Anchor, true);
	EmptyMap.Add(EShipMerge::Part_Cannon, true);
	EmptyMap.Add(EShipMerge::Part_Head, true);
	EmptyMap.Add(EShipMerge::Part_Light, true);

	//saved sail matIndex after merged
	int32 MergedMatIndex = 0;
	int32 SailMatIndex = 1;
	int32 FlagMatIndex = 2;
	UMaterialInterface* SavedSailMatInstance = nullptr;

	//SkeletalPara.SrcMeshList = SrcMeshes;
	SkeletalPara.SectionUVTransforms = new FSkelMeshSectionUVTransforms();
	SkeletalPara.MeshBufferAccess = EMeshBufferAccess::Default;
	SkeletalPara.StripTopLODs = 0;

	for (int32 MeshI = 0; MeshI < SrcMeshes.Num(); MeshI++)
	{
		FSkelMeshMergeSectionMapping TempMapping;
		TArray<FTransform> UVTransforms;

		for (int32 MatIndex = 0; MatIndex < SrcMeshes[MeshI]->SkeletalMesh->Materials.Num(); ++MatIndex)
		{
			FSkeletalMaterial* SkelMat = &SrcMeshes[MeshI]->SkeletalMesh->Materials[MatIndex];
			FString SlotName = SkelMat->MaterialSlotName.ToString();


			UMaterialInterface* Material;

			Material = SkelMat->MaterialInterface;

			//override material
			if (MatIndex < SrcMeshes[MeshI]->OverrideMaterials.Num() && MatIndex <= SrcMeshes[MeshI]->OverrideMaterials.Num() - 1 && SrcMeshes[MeshI]->OverrideMaterials[MatIndex])
			{
				Material = SrcMeshes[MeshI]->OverrideMaterials[MatIndex];
			}

			//mat interface,slotFShipPartMergeDesc& Part,TMap<EShipMaterialTexture, UTexture2D*>&,
			FShipPartMergeDesc* PartDesc = GetShipPartDescBySlotName(SlotName);
			if (!PartDesc)
			{
				FString DebugMessage = FString(TEXT("Can not find part for SlotName: "));
				DebugMessage.Append(SlotName);
				GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);

				continue;
			}


			EmptyMap[PartDesc->ShipPart] = false;

			switch (PartDesc->ShipPart)
			{
				case EShipMerge::Part_Sail:
					SavedSailMatInstance = Material;

					//UE_LOG(LogKMSKMergeStatic, Log, TEXT("*****************find material slot sail"));
					TempMapping.SectionIDs.Add(SailMatIndex);
					UVTransforms.Add(PartDesc->UvTransform);
					break;

				case EShipMerge::Part_Body:
				case EShipMerge::Part_Hull:
					MergeSinglePartTexture(Material, *PartDesc, TextureMap, OverrideQuality);

					//UE_LOG(LogKMSKMergeStatic, Log, TEXT("*****************find material slot: "), *PartDesc->SlotName);
					TempMapping.SectionIDs.Add(MergedMatIndex);
					UVTransforms.Add(PartDesc->UvTransform);
					break;

				default:
					TempMapping.SectionIDs.Add(0);
					UVTransforms.Add(FTransform::Identity);
					break;
			};
		}
		SkeletalPara.ForceSectionMapping.Add(TempMapping);

		//yangjingzhao for 4.20
		const_cast<FSkelMeshSectionUVTransforms*>(SkeletalPara.SectionUVTransforms)->SectionUVTransformPerMesh.Add(UVTransforms);
		
	}

	//merge material for staticmesh
	TArray<FStaticMeshMergeParam> StaticParams;
	for (int32 SIndex = 0; SIndex < this->CachedStaticMeshes.Num(); ++SIndex)
	{
		FStaticMeshMergeParam TempParam;

		TempParam.BoneName = CachedStaticMeshes[SIndex].BoneName;
		TempParam.RelativeTransform = CachedStaticMeshes[SIndex].Offset;
		TempParam.SrcMesh = CachedStaticMeshes[SIndex].Static.Get();
		TempParam.SectionsMapping.Add(0);

		//check static mesh exits in StaticParams? if so, we can use the same uv
		int32 AlreadyExitIndex = CheckStaticAlreadyExits(StaticParams, TempParam.SrcMesh);
		if(AlreadyExitIndex != -1)
		{
			TempParam.UVTransforms = StaticParams[AlreadyExitIndex].UVTransforms;
			StaticParams.Add(TempParam);
			continue;
		}

		FTransform UVTransform = FTransform::Identity;
		
		for (int32 MIndex = 0; MIndex < TempParam.SrcMesh->StaticMaterials.Num(); ++MIndex)
		{
			FString SlotName = TempParam.SrcMesh->StaticMaterials[MIndex].MaterialSlotName.ToString();
			UMaterialInterface* SecMat = TempParam.SrcMesh->StaticMaterials[MIndex].MaterialInterface;

			//mat interface,slotFShipPartMergeDesc& Part,TMap<EShipMaterialTexture, UTexture2D*>&,
			FShipPartMergeDesc* PartDesc = GetShipPartDescBySlotName(SlotName);
			if (PartDesc == nullptr) {
				UE_LOG(LogKMSKMergeStatic, Error, TEXT("Failed to get slot \"%s\"."), *SlotName);
				continue;
			}
			EmptyMap[PartDesc->ShipPart] = false;
			
			MergeSinglePartTexture(SecMat, *PartDesc, TextureMap, OverrideQuality);
			TempParam.UVTransforms.Add(PartDesc->UvTransform);
		}

		StaticParams.Add(TempParam);
	}

	CachedStaticMeshes.Empty();

	//clear empty begin
	//:此处可能浪费不必要的时间，等待优化确认
	FClearTexturePara ClearPara;
	ClearPara.DefaultColorData = &DefaultColor;
	ClearPara.DefaultColorize = DefaultAlphaSize;
	for (TMap<EShipMerge::MergePart, bool>::TIterator it = EmptyMap.CreateIterator(); it; ++it)
	{
		if (it.Value())
		{
			FShipPartMergeDesc* Part = GetShipPartDescByPartFlag(it.Key());
			ClearPara.UvTransform = Part->UvTransform;
			ClearPara.Tile = Part->ShipPart == EShipMerge::Part_Hull ? ETextureMergeTileMode::Mode_U : ETextureMergeTileMode::Mode_None;

			ClearPara.NewFormat = TextureMap[EShipMergeTexture::BaseColor]->PlatformData->PixelFormat;
			FCookedTextureMerge::ClearDataToMergedTexture(*TextureMap[EShipMergeTexture::BaseColor], ClearPara);

			ClearPara.NewFormat = TextureMap[EShipMergeTexture::BaseNormal]->PlatformData->PixelFormat;
			FCookedTextureMerge::ClearDataToMergedTexture(*TextureMap[EShipMergeTexture::BaseNormal], ClearPara);

			ClearPara.NewFormat = TextureMap[EShipMergeTexture::BaseMask]->PlatformData->PixelFormat;
			FCookedTextureMerge::ClearDataToMergedTexture(*TextureMap[EShipMergeTexture::BaseMask], ClearPara);

			ClearPara.NewFormat = TextureMap[EShipMergeTexture::AOemMap]->PlatformData->PixelFormat;
			FCookedTextureMerge::ClearDataToMergedTexture(*TextureMap[EShipMergeTexture::AOemMap], ClearPara);

			ClearPara.NewFormat = TextureMap[EShipMergeTexture::BaseColor_Mask]->PlatformData->PixelFormat;
			FCookedTextureMerge::ClearDataToMergedTexture(*TextureMap[EShipMergeTexture::BaseColor_Mask], ClearPara);

			//ClearDataToMergedTexture(it.Key(), *TextureMap[EShipMergeTexture::BaseColor], TextureMap[EShipMergeTexture::BaseColor]->PlatformData->PixelFormat);
			//ClearDataToMergedTexture(it.Key(), *TextureMap[EShipMergeTexture::BaseNormal], TextureMap[EShipMergeTexture::BaseNormal]->PlatformData->PixelFormat);
			//ClearDataToMergedTexture(it.Key(), *TextureMap[EShipMergeTexture::BaseMask], TextureMap[EShipMergeTexture::BaseMask]->PlatformData->PixelFormat);
			//ClearDataToMergedTexture(it.Key(), *TextureMap[EShipMergeTexture::AOemMap], TextureMap[EShipMergeTexture::AOemMap]->PlatformData->PixelFormat);
			//ClearDataToMergedTexture(it.Key(), *TextureMap[EShipMergeTexture::BaseColor_Mask], TextureMap[EShipMergeTexture::BaseColor_Mask]->PlatformData->PixelFormat);
		}
	}

	//todo:operation of clear runing cache platform data must follow all pairs of parts merged and saved,
	//or, cleaning rise issue, so we don't do it now

	//generate new material
	UMaterial* MatTemplate = Cast<UMaterial>(UEngineExtShell::StaticLoadObjectWithoutFlush(MergedMatUrl));
	//load material template
	UMaterialInstanceDynamic* NewMat = UKismetMaterialLibrary::CreateDynamicMaterialInstance(nullptr, MatTemplate);

	NewMat->SetTextureParameterValue(FName(TEXT("BaseMap")), TextureMap[EShipMergeTexture::BaseColor]);
	NewMat->SetTextureParameterValue(FName(TEXT("BaseMask")), TextureMap[EShipMergeTexture::BaseMask]);
	NewMat->SetTextureParameterValue(FName(TEXT("NormalMap")), TextureMap[EShipMergeTexture::BaseNormal]);
	NewMat->SetTextureParameterValue(FName(TEXT("AoEmMap")), TextureMap[EShipMergeTexture::AOemMap]);
	NewMat->SetTextureParameterValue(FName(TEXT("BaseMap_Mask")), TextureMap[EShipMergeTexture::BaseColor_Mask]);
	//generte new material completed

	//deal with flag seperately, append StaticParams for flags
	//StaticParams.Append(CachedFlagParams);

	USkeletalMesh* NewMesh = NewObject<USkeletalMesh>(GetTransientPackage(), USkeletalMesh::StaticClass());
	NewMesh->Skeleton = SrcMeshes[0]->SkeletalMesh->Skeleton;
	FSkeletalStaticMeshMerge MeshMerge(NewMesh, SkeletalPara, StaticParams);
	bool bRet = MeshMerge.DoMerge();

	if (bRet)
	{
		NewMesh->Materials[MergedMatIndex].MaterialInterface = NewMat;

		//reset sail mat
		if (SavedSailMatInstance && SailMatIndex <= NewMesh->Materials.Num() - 1)
		{
			NewMesh->Materials[SailMatIndex].MaterialInterface = SavedSailMatInstance;
		}

		//reset flag mat
		if (CachedFlagMergedMat && FlagMatIndex <= NewMesh->Materials.Num() - 1)
		{
			NewMesh->Materials[FlagMatIndex].MaterialInterface = CachedFlagMergedMat;
		}
		CachedFlagMergedMat = nullptr;
		//CachedFlagParams.Empty();

		return NewMesh;
	}

#endif
	//NewMesh->GetImportedResource()->RequiresCPUSkinning()
	return nullptr;
}

void FKMShipMeshMerge::CreateShipMergedTextures(TMap<EShipMergeTexture::Texture, UTexture2D*>& InMap, TArray<USkeletalMeshComponent*>& SrcMeshes, int32 OverrideQuality)
{
#if 0
	//init merged textures
	bool HasHull = false;

	//iterate all mats to find merged resoluton
	for (int32 MeI = 0; MeI < SrcMeshes.Num(); MeI++)
	{
		for (int32 MaI = 0; MaI < SrcMeshes[MeI]->SkeletalMesh->Materials.Num(); ++MaI)
		{
			FSkeletalMaterial* SkelMat = &SrcMeshes[MeI]->SkeletalMesh->Materials[MaI];
			FString SlotName = SkelMat->MaterialSlotName.ToString();
			if (SlotName.ToLower().Equals(ShipParts[EShipMerge::Part_Hull].SlotName))
			{
				HasHull = true;

				UMaterialInterface* Material = SkelMat->MaterialInterface;

				//override Material
				if (MaI < SrcMeshes[MeI]->OverrideMaterials.Num() && MaI <= SrcMeshes[MeI]->OverrideMaterials.Num() - 1 && SrcMeshes[MeI]->OverrideMaterials[MaI])
				{
					Material = SrcMeshes[MeI]->OverrideMaterials[MaI];
				}

				UTexture* TempBaseColor;
				bool bHasBaseColor = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::BaseColor].ParamaterName), TempBaseColor);

				EPixelFormat NewFormat = EPixelFormat::PF_ETC2_RGB;
				if (bHasBaseColor)
				{
					NewFormat = Cast<UTexture2D>(TempBaseColor)->PlatformData->PixelFormat;
#if PLATFORM_ANDROID
					NewFormat = PF_ETC2_RGBA;
#endif

#if PLATFORM_WINDOWS
					NewFormat = PF_DXT5;
#endif
					UTexture2D* MergedBaseColor = FCookedTextureMerge::CreateMergedTexture(NewFormat, Cast<UTexture2D>(TempBaseColor), OverrideQuality);

					InMap.Add(EShipMergeTexture::BaseColor, MergedBaseColor);
				}

				UTexture* NormalTexture;
				bool HasNormal = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::BaseNormal].ParamaterName), NormalTexture);
				if (HasNormal)
				{
					NewFormat = Cast<UTexture2D>(NormalTexture)->PlatformData->PixelFormat;

					UTexture2D* MergedNorma = FCookedTextureMerge::CreateMergedTexture(NewFormat, Cast<UTexture2D>(NormalTexture), OverrideQuality);
					InMap.Add(EShipMergeTexture::BaseNormal, MergedNorma);
				}

				UTexture * MaskTexture;
				bool HasMask = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::BaseMask].ParamaterName), MaskTexture);
				if (HasMask)
				{
					NewFormat = Cast<UTexture2D>(MaskTexture)->PlatformData->PixelFormat;

					UTexture2D* MergedBaseMask = FCookedTextureMerge::CreateMergedTexture(NewFormat, Cast<UTexture2D>(MaskTexture), OverrideQuality);
					InMap.Add(EShipMergeTexture::BaseMask, MergedBaseMask);
				}

				UTexture * AOTexture;
				bool HasAo = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::AOemMap].ParamaterName), AOTexture);
				if (HasAo)
				{
					NewFormat = Cast<UTexture2D>(AOTexture)->PlatformData->PixelFormat;
					UTexture2D* MergeAOEmMap = FCookedTextureMerge::CreateMergedTexture(NewFormat, Cast<UTexture2D>(AOTexture), OverrideQuality);
					InMap.Add(EShipMergeTexture::AOemMap, MergeAOEmMap);
				}

				UTexture * BaseMapMaskTexture;
				bool HasBaseMapMask = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::BaseColor_Mask].ParamaterName), BaseMapMaskTexture);
				if (HasBaseMapMask)
				{
					NewFormat = Cast<UTexture2D>(BaseMapMaskTexture)->PlatformData->PixelFormat;
					UTexture2D* MergeBaseColorMask = FCookedTextureMerge::CreateMergedTexture(NewFormat, Cast<UTexture2D>(BaseMapMaskTexture), OverrideQuality);
					InMap.Add(EShipMergeTexture::BaseColor_Mask, MergeBaseColorMask);
				}
			}
		}
	}

	if (!HasHull)
	{
		FString DebugMessage = FString(TEXT("Can not find hull for ship!"));
		GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
	}

	if (!InMap.Contains(EShipMergeTexture::BaseColor))
	{
		FString DebugMessage = FString(TEXT("Can not find BaseMap on hull material!"));
		GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
	}

	if (!InMap.Contains(EShipMergeTexture::BaseNormal))
	{
		FString DebugMessage = FString(TEXT("Can not find NormalMap on hull material!"));
		GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
	}

	if (!InMap.Contains(EShipMergeTexture::BaseMask))
	{
		FString DebugMessage = FString(TEXT("Can not find BaseMask on hull material!"));
		GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
	}

	if (!InMap.Contains(EShipMergeTexture::AOemMap))
	{
		FString DebugMessage = FString(TEXT("Can not find AoEmMap on hull material!"));
		GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
	}

	if (!InMap.Contains(EShipMergeTexture::BaseColor_Mask))
	{
		FString DebugMessage = FString(TEXT("Can not find BaseMap_Mask on hull material!"));
		GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
	}
#endif
}

void FKMShipMeshMerge::MergeSinglePartTexture(UMaterialInterface* Material, FShipPartMergeDesc& Part, TMap<EShipMergeTexture::Texture, UTexture2D*>& MergedTextures, int32 OverrideQuality)
{
#if 0
	UTexture* BaseColorTexture;
	UTexture* MaskTexture;
	UTexture* NormalTexture;
	UTexture* AoEmMapTexture;
	UTexture* BaseMapMaskTexture;

	bool HasBaseColor;
	bool HasBaseMask;
	bool HasBaseNormal;
	bool HasAoEmMapTexture;
	bool HasBasemapMaskTexture;

	//Get parameter texture data
	HasBaseColor = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::BaseColor].ParamaterName), BaseColorTexture);
	HasBaseMask = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::BaseMask].ParamaterName), MaskTexture);
	HasBaseNormal = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::BaseNormal].ParamaterName), NormalTexture);
	HasAoEmMapTexture = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::AOemMap].ParamaterName), AoEmMapTexture);
	HasBasemapMaskTexture = Material->GetTextureParameterValue(FName(*ShipChannel[EShipMergeTexture::BaseColor_Mask].ParamaterName), BaseMapMaskTexture);

	//UE_LOG(LogKMSKMergeStatic, Log, TEXT("*****************find material slot name : %s"), *Part.SlotName);

	//for skeletalmesh
	if (!HasBaseMask)
	{
		HasBaseMask = Material->GetTextureParameterValue(FName(TEXT("MaskMap")), MaskTexture);
	}

	//for staticmesh
	if (!HasBaseMask)
	{
		HasBaseMask = Material->GetTextureParameterValue(FName(TEXT("Mask")), MaskTexture);
	}

	FMergeTexturePara MergePara;
	MergePara.DefaultAlphaData = &DefaultColor;
	MergePara.DefaultAlphaSize = DefaultAlphaSize;
	MergePara.UvTransform = Part.UvTransform;
	MergePara.Tile = Part.ShipPart == EShipMerge::Part_Hull ? ETextureMergeTileMode::Mode_U : ETextureMergeTileMode::Mode_None;
	

	FClearTexturePara ClearPara;
	ClearPara.DefaultColorData = &DefaultColor;
	ClearPara.DefaultColorize = DefaultAlphaSize;
	ClearPara.UvTransform = Part.UvTransform;
	ClearPara.Tile = Part.ShipPart == EShipMerge::Part_Hull ? ETextureMergeTileMode::Mode_U : ETextureMergeTileMode::Mode_None;

	//merge texture
	if (HasBaseColor)
	{
		MergePara.NewFormat = MergedTextures[EShipMergeTexture::BaseColor]->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(BaseColorTexture), Part.UvTransform, *MergedTextures[EShipMergeTexture::BaseColor]);

		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(BaseColorTexture), *MergedTextures[EShipMergeTexture::BaseColor], MergePara);
		//AddDataToMergedTexture(Cast<UTexture2D>(BaseColorTexture), Part.ShipPart, *MergedTextures[EShipMergeTexture::BaseColor], OverrideQuality, MergedTextures[EShipMergeTexture::BaseColor]->PlatformData->PixelFormat);
	}

	if (HasBaseNormal)
	{
		MergePara.NewFormat = MergedTextures[EShipMergeTexture::BaseNormal]->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(NormalTexture), Part.UvTransform, *MergedTextures[EShipMergeTexture::BaseNormal]);

		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(NormalTexture), *MergedTextures[EShipMergeTexture::BaseNormal], MergePara);
		//AddDataToMergedTexture(Cast<UTexture2D>(NormalTexture), Part.ShipPart, *MergedTextures[EShipMergeTexture::BaseNormal], OverrideQuality, MergedTextures[EShipMergeTexture::BaseNormal]->PlatformData->PixelFormat);
	}

	if (HasBaseMask)
	{
		MergePara.NewFormat = MergedTextures[EShipMergeTexture::BaseMask]->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(MaskTexture), Part.UvTransform, *MergedTextures[EShipMergeTexture::BaseMask]);

		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(MaskTexture), *MergedTextures[EShipMergeTexture::BaseMask], MergePara);
		//AddDataToMergedTexture(Cast<UTexture2D>(MaskTexture), Part.ShipPart, *MergedTextures[EShipMergeTexture::BaseMask], OverrideQuality, MergedTextures[EShipMergeTexture::BaseMask]->PlatformData->PixelFormat);
	}
	else
	{
		ClearPara.NewFormat = MergedTextures[EShipMergeTexture::BaseMask]->PlatformData->PixelFormat;
		FCookedTextureMerge::ClearDataToMergedTexture(*MergedTextures[EShipMergeTexture::BaseMask], ClearPara);
		//ClearDataToMergedTexture(Part.ShipPart, *MergedTextures[EShipMergeTexture::BaseMask], MergedTextures[EShipMergeTexture::BaseMask]->PlatformData->PixelFormat);
	}

	if (HasAoEmMapTexture)
	{
		MergePara.NewFormat = MergedTextures[EShipMergeTexture::AOemMap]->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(AoEmMapTexture), Part.UvTransform, *MergedTextures[EShipMergeTexture::AOemMap]);

		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(AoEmMapTexture), *MergedTextures[EShipMergeTexture::AOemMap], MergePara);
		//AddDataToMergedTexture(Cast<UTexture2D>(AoEmMapTexture), Part.ShipPart, *MergedTextures[EShipMergeTexture::AOemMap], OverrideQuality, MergedTextures[EShipMergeTexture::AOemMap]->PlatformData->PixelFormat);
	}
	else
	{
		ClearPara.NewFormat = MergedTextures[EShipMergeTexture::AOemMap]->PlatformData->PixelFormat;
		FCookedTextureMerge::ClearDataToMergedTexture(*MergedTextures[EShipMergeTexture::AOemMap], ClearPara);
		//ClearDataToMergedTexture(Part.ShipPart, *MergedTextures[EShipMergeTexture::AOemMap], MergedTextures[EShipMergeTexture::AOemMap]->PlatformData->PixelFormat);
	}

	if (HasBasemapMaskTexture)
	{
		MergePara.NewFormat = MergedTextures[EShipMergeTexture::BaseColor_Mask]->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(BaseMapMaskTexture), Part.UvTransform, *MergedTextures[EShipMergeTexture::BaseColor_Mask]);

		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(BaseMapMaskTexture), *MergedTextures[EShipMergeTexture::BaseColor_Mask], MergePara);
		//AddDataToMergedTexture(Cast<UTexture2D>(BaseMapMaskTexture), Part.ShipPart, *MergedTextures[EShipMergeTexture::BaseColor_Mask], OverrideQuality, MergedTextures[EShipMergeTexture::BaseColor_Mask]->PlatformData->PixelFormat);
	}
	else
	{
		ClearPara.NewFormat = MergedTextures[EShipMergeTexture::BaseColor_Mask]->PlatformData->PixelFormat;
		FCookedTextureMerge::ClearDataToMergedTexture(*MergedTextures[EShipMergeTexture::BaseColor_Mask], ClearPara);
		//ClearDataToMergedTexture(Part.ShipPart, *MergedTextures[EShipMergeTexture::BaseColor_Mask], MergedTextures[EShipMergeTexture::BaseColor_Mask]->PlatformData->PixelFormat);
	}
#endif
}

//int32 FKMShipMeshMerge::CheckStaticAlreadyExits(TArray<FStaticMeshMergeParam>& StaticParas, UStaticMesh* InMesh)
//{
//	for (int PIndex = 0; PIndex < StaticParas.Num(); ++PIndex)
//	{
//		if (StaticParas[PIndex].SrcMesh == InMesh)
//		{
//			return PIndex;
//		}
//	}
//
//	return -1;
//}
//
//void FKMShipMeshMerge::AddDataToMergedTexture(UTexture2D* InTetxture, uint8 PartFlag, UTexture2D& MergedTexture, int32 OverrideQuality, EPixelFormat NewFormat)
//{
//	resolution of body is bigger, so we use next mipmap
//	int32 SrcOverrideQuality = GetMipIndexFromSource(*InTetxture, PartFlag, MergedTexture);
//	int32 SrcOverrideQuality = 0;
//	can not find available mipf
//	if (SrcOverrideQuality < 0)
//	{
//		don't crash here
//		UE_LOG(LogKMSKMergeStatic, Error, TEXT("Can not Find MipMap Level, Texture Path: %s"), *InTetxture->GetPathName());
//		return;
//	}
//
//	int32 SizeX = InTetxture->PlatformData->Mips[SrcOverrideQuality].SizeX;
//	int32 SizeY = InTetxture->PlatformData->Mips[SrcOverrideQuality].SizeY;
//
//	int32 MergedSizeX = MergedTexture.PlatformData->Mips[0].SizeX;
//	int32 MergedSizeY = MergedTexture.PlatformData->Mips[0].SizeY;
//	for pixel block 4*4
//	int32 MergeBlockNumX = MergedSizeX / 4;
//	int32 MergeBlockNumY = MergedSizeY / 4;
//
//	EPixelFormat InFormat = InTetxture->PlatformData->PixelFormat;
//	FByteBulkData& BulkData = InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData;
//	int32 BulkSize = BulkData.GetBulkDataSize();
//	void* RawBulkData = InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData.Lock(LOCK_READ_ONLY);
//
//	int32 BlockNum = SizeX / 4;
//	int32 HeightBlockNum = SizeY / 4;
//	int32 BitSize = BlockNum * GPixelFormats[NewFormat].BlockBytes;
//
//	int32 MergedRowSize = MergeBlockNumX * GPixelFormats[NewFormat].BlockBytes;
//
//	int32 TotalSize = MergedTexture.PlatformData->Mips[0].BulkData.GetBulkDataSize();
//	check(TotalSize == MergeBlockNumX * MergeBlockNumY * GPixelFormats[NewFormat].BlockBytes);
//	
//	prepare to merge data
//	uint8* DataDes = static_cast<uint8*>(MergedTexture.PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE));
//
//	add texture data to merged texture according uv transform
//	uint8* BulkDataSrc = static_cast<uint8*>(RawBulkData);
//
//	int32 HeightOffset = 0;
//	int32 WidthOffset = 0;
//
//	FShipPartMergeDesc* Part = GetShipPartDescByPartFlag(PartFlag);
//	HeightOffset = MergeBlockNumY * Part->UvTransform.GetTranslation().Y;
//	WidthOffset = MergeBlockNumX * Part->UvTransform.GetTranslation().X;
//	int32 SizeOffset = (MergeBlockNumX * HeightOffset + WidthOffset) * GPixelFormats[NewFormat].BlockBytes;
//	switch (EShipMerge::MergePart(PartFlag))
//	{
//		copy two times for wrap of x
//	case EShipMerge::Part_Hull:
//		find start address
//		DataDes += SizeOffset;
//
//		/*face 1/2 merged size*/
//		for (int32 HeiBlockIndex = 0; HeiBlockIndex < HeightBlockNum; ++HeiBlockIndex)
//		{
//			copy per 4*4 block directly
//			if (InFormat == NewFormat)
//			{
//				check(TotalSize >= SizeOffset + BitSize)
//				FMemory::Memcpy(DataDes, BulkDataSrc, BitSize);
//				DataDes += BitSize;
//				SizeOffset += BitSize;
//
//				copy again from uv tile for hull
//				check(TotalSize >= SizeOffset + BitSize)
//				FMemory::Memcpy(DataDes, BulkDataSrc, BitSize);
//				DataDes += BitSize;
//				SizeOffset += BitSize;
//
//				BulkDataSrc += BitSize;
//			}
//			copy RGB copy per 4*4 block & Set Alpha to default
//			for newformat is RGBA ,informat is RGB
//			else
//			{
//				merge alpha to texture without alpha
//				check((InFormat == EPixelFormat::PF_ETC2_RGB &&NewFormat == EPixelFormat::PF_ETC2_RGBA) ||
//					(InFormat == EPixelFormat::PF_DXT1 &&NewFormat == EPixelFormat::PF_DXT5)||
//					(InFormat == EPixelFormat::PF_BC4 &&NewFormat == EPixelFormat::PF_BC4));
//
//				for (int32 XBIndex = 0; XBIndex < BlockNum; ++XBIndex)
//				{
//					check(TotalSize >= SizeOffset + DefaultAlphaSize)
//					FMemory::Memcpy(DataDes, DefaultAlpha.GetData(), DefaultAlphaSize);
//					DataDes += DefaultAlphaSize;
//					SizeOffset += DefaultAlphaSize;
//
//					check(TotalSize >= SizeOffset + DefaultAlphaSize)
//					FMemory::Memcpy(DataDes, BulkDataSrc, GPixelFormats[InFormat].BlockBytes);
//					DataDes += GPixelFormats[InFormat].BlockBytes;
//					SizeOffset += DefaultAlphaSize;
//
//					BulkDataSrc += GPixelFormats[InFormat].BlockBytes;
//				}
//
//				BulkDataSrc -= BlockNum * GPixelFormats[InFormat].BlockBytes;
//
//				copy again from uv tile for hull
//				for (int32 XBIndex = 0; XBIndex < BlockNum; ++XBIndex)
//				{
//					check(TotalSize >= SizeOffset + DefaultAlphaSize)
//					FMemory::Memcpy(DataDes, DefaultAlpha.GetData(), DefaultAlphaSize);
//					DataDes += DefaultAlphaSize;
//					SizeOffset += DefaultAlphaSize;
//
//					check(TotalSize >= SizeOffset + GPixelFormats[InFormat].BlockBytes)
//					FMemory::Memcpy(DataDes, BulkDataSrc, GPixelFormats[InFormat].BlockBytes);
//					DataDes += GPixelFormats[InFormat].BlockBytes;
//					SizeOffset += GPixelFormats[InFormat].BlockBytes;
//
//					BulkDataSrc += GPixelFormats[InFormat].BlockBytes;
//				}
//
//			}
//
//		}
//		break;
//
//	case EShipMerge::Part_Body:
//	case EShipMerge::Part_Anchor:
//	case EShipMerge::Part_Light:
//	case EShipMerge::Part_Head:
//	case EShipMerge::Part_Cannon:
//
//		find start address
//		DataDes += SizeOffset;
//
//		for (int32 HeiBlockIndex = 0; HeiBlockIndex < HeightBlockNum; ++HeiBlockIndex)
//		{
//			copy per 4*4 block directly
//			if (InFormat == NewFormat)
//			{
//				check(TotalSize >= SizeOffset + BitSize);
//				FMemory::Memcpy(DataDes, BulkDataSrc, BitSize);
//				DataDes += MergedRowSize;
//				SizeOffset += MergedRowSize;
//
//				BulkDataSrc += BitSize;
//			}
//			copy RGB copy per 4*4 block & Set Alpha to default
//			for newformat is RGBA ,informat is RGB
//			else
//			{
//				merge alpha to texture without alpha
//				check((InFormat == EPixelFormat::PF_ETC2_RGB &&NewFormat == EPixelFormat::PF_ETC2_RGBA) ||
//					(InFormat == EPixelFormat::PF_DXT1 &&NewFormat == EPixelFormat::PF_DXT5) ||
//					(InFormat == EPixelFormat::PF_BC4 &&NewFormat == EPixelFormat::PF_BC4));
//
//				for (int32 XBIndex = 0; XBIndex < BlockNum; ++XBIndex)
//				{
//					check(TotalSize >= SizeOffset + DefaultAlphaSize);
//					FMemory::Memcpy(DataDes, DefaultAlpha.GetData(), DefaultAlphaSize);
//					DataDes += DefaultAlphaSize;
//					SizeOffset += DefaultAlphaSize;
//
//					check(TotalSize >= SizeOffset + GPixelFormats[InFormat].BlockBytes);
//					FMemory::Memcpy(DataDes, BulkDataSrc, GPixelFormats[InFormat].BlockBytes);
//					DataDes += GPixelFormats[InFormat].BlockBytes;
//					SizeOffset += GPixelFormats[InFormat].BlockBytes;
//
//					BulkDataSrc += GPixelFormats[InFormat].BlockBytes;
//				}
//
//				DataDes -= BitSize;
//				SizeOffset -= BitSize;
//				DataDes += MergedRowSize;
//				SizeOffset += MergedRowSize;
//			}
//
//		}
//		break;
//
//	default:
//		break;
//	}
//
//	MergedTexture.PlatformData->Mips[0].BulkData.Unlock();
//	MergedTexture.UpdateResource();
//
//	InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData.Unlock();
//}

USkeletalMesh* FKMShipMeshMerge::KMMergeStaticWithSkeleton(TArray<FSkeletalMergeParameter>& Skeletals, TArray<FStaticMergeParameter>& Statics, TArray<FStaticMergeParameter1>&Flags, int32 OverrideQuality)
{
#if 0
	for (int32 SIndex = 0; SIndex < Statics.Num(); ++SIndex)
	{
		//add protection for allowcpuaccess
		if (Statics[SIndex].Static.IsValid() && !Statics[SIndex].Static.Get()->bAllowCPUAccess)
		{
			FString DebugMessage = FString(TEXT("Property: bAllowCPUAccess should be true for staticMesh: "));
			DebugMessage.Append(*Statics[SIndex].Static.Get()->GetPathName());
			GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
			return nullptr;
		}

		CachedStaticMeshes.Add(Statics[SIndex]);
	}

	TArray<USkeletalMeshComponent*> SkeletalMeshes;
	TArray<int32> PartIDs;
	for (int32 KIndex = 0; KIndex < Skeletals.Num(); ++KIndex)
	{
		SkeletalMeshes.Add(Skeletals[KIndex].Skeletal.Get());
		PartIDs.Add(Skeletals[KIndex].PartID);
	}

	//deal with flag seperately, append StaticParams for flags
	TArray<UStaticMeshComponent*> FlagComs;
	TArray<int32> FlagPartIDs;
	for (int FlagIndex = 0; FlagIndex < Flags.Num(); FlagIndex++)
	{
		FlagComs.Add(Flags[FlagIndex].Static.Get());
		FlagPartIDs.Add(Flags[FlagIndex].PartID);

		FStaticMeshMergeParam FlagParam;
		FlagParam.BoneName = Flags[FlagIndex].BoneName;
		FlagParam.RelativeTransform = Flags[FlagIndex].Offset;
		FlagParam.SrcMesh = Flags[FlagIndex].Static.Get()->GetStaticMesh();

		TArray<FTransform> UVTransforms;
		FTransform TempTrans = FTransform::Identity;
		switch (FlagIndex)
		{
		case 0:
			TempTrans.SetScale3D(FVector(0.5, 0.5, 0));
			TempTrans.SetTranslation(FVector(0, 0, 0));
			break;

		case 1:
			TempTrans.SetScale3D(FVector(0.5, 0.5, 0));
			TempTrans.SetTranslation(FVector(0.5, 0, 0));
			break;

		case 2:
			TempTrans.SetScale3D(FVector(0.5, 0.5, 0));
			TempTrans.SetTranslation(FVector(0, 0.5, 0));
			break;

		default:
			break;
		}
		UVTransforms.Add(TempTrans);
		FlagParam.UVTransforms = UVTransforms;

		TArray<int32> ForceSection;
		ForceSection.Add(2);
		FlagParam.SectionsMapping = ForceSection;

		//CachedFlagParams.Add(FlagParam);
	}

	if (FPlatformProperties::RequiresCookedData())
	{
		//merge flag material
		CachedFlagMergedMat = MergeShipFlagMat_Cooked(FlagComs, FlagPartIDs);

		return KMMergeSkeletal_Cooked(SkeletalMeshes, PartIDs, OverrideQuality);
	}
#endif
	return nullptr;
}

UMaterialInterface* FKMShipMeshMerge::MergeShipFlagMat_Cooked(TArray<UStaticMeshComponent*>& SrcMeshes, TArray<int32>& PartIDs, int32 OverrideQuality)
{
#if 0
	int MeshNum = SrcMeshes.Num();

	//calc texture dived
	int NeedPower = 0;
	for (int Power = 1; Power < 4; Power++)
	{
		if (FMath::Pow(2, Power) * FMath::Pow(2, Power) > MeshNum && FMath::Pow(2, Power - 1) * FMath::Pow(2, Power - 1) < MeshNum)
		{
			NeedPower = Power;
			break;
		}
	}

	TArray<FTransform> DividedUVTransforms;
	int32 DividedNum = FMath::RoundToInt(FMath::Pow(2, NeedPower));

	for (int32 RowIndex = 0; RowIndex < DividedNum; RowIndex++)
	{
		for (int32 ColIndex = 0; ColIndex < DividedNum; ColIndex++)
		{
			FTransform TempTrans = FTransform::Identity;
			TempTrans.SetScale3D(FVector(1.0f / DividedNum, 1.0f / DividedNum, 0));
			TempTrans.SetTranslation(FVector(ColIndex * 1.0f / DividedNum, RowIndex * 1.0f / DividedNum, 0));
			
			DividedUVTransforms.Add(TempTrans);
		}
	}

	UTexture2D* BaseFlagTexture = nullptr;

	for (int32 MIndex = 0; MIndex < SrcMeshes.Num(); MIndex++)
	{
		UMaterialInterface* Material = nullptr;

		if (SrcMeshes[MIndex]->OverrideMaterials.Num() > 0)
		{
			Material = SrcMeshes[MIndex]->OverrideMaterials[0];
		}
		else
		{
			Material = SrcMeshes[MIndex]->GetStaticMesh()->StaticMaterials[0].MaterialInterface;
		}
		
		UTexture * MaskTexture;
		bool HasBase = Material->GetTextureParameterValue(FName(*FlagMaterialChannel), MaskTexture);
		if (HasBase)
		{
			int32 SizeX = Cast<UTexture2D>(MaskTexture)->PlatformData->Mips[OverrideQuality].SizeX;
			int32 SizeY = Cast<UTexture2D>(MaskTexture)->PlatformData->Mips[OverrideQuality].SizeY;

			EPixelFormat NewFormatMask = Cast<UTexture2D>(MaskTexture)->PlatformData->PixelFormat;
			// Create the mask texture
			if (MIndex == 0)
			{
				BaseFlagTexture = UTexture2D::CreateTransient(SizeX * DividedNum, SizeX * DividedNum, NewFormatMask);//
				BaseFlagTexture->CompressionSettings = TextureCompressionSettings::TC_Default;
				BaseFlagTexture->SRGB = 0;
				BaseFlagTexture->UpdateResource();
			}
		}

		FMergeTexturePara MergePara;
		MergePara.DefaultAlphaData = &DefaultColor;
		MergePara.DefaultAlphaSize = DefaultAlphaSize;
		MergePara.UvTransform = DividedUVTransforms[MIndex];
		MergePara.Tile = ETextureMergeTileMode::Mode_None;
		MergePara.NewFormat = Cast<UTexture2D>(BaseFlagTexture)->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(MaskTexture), DividedUVTransforms[MIndex], *Cast<UTexture2D>(BaseFlagTexture));
		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(MaskTexture), *Cast<UTexture2D>(BaseFlagTexture), MergePara);
		//AddTextureToMergedTexture(Cast<UTexture2D>(MaskTexture), Cast<UTexture2D>(BaseFlagTexture), DividedUVTransforms[MIndex]);
	}

	//mat url /Game/Resources/Ships/ChangeParts/Flag/Materials/MI_ShipFlag_01.MI_ShipFlag_01
	UMaterialInterface* MatTemplate = Cast<UMaterialInterface>(UEngineExtShell::StaticLoadObjectWithoutFlush(FlagMergedMatUrl));
	//load material template
	UMaterialInstanceDynamic* NewMat = UKismetMaterialLibrary::CreateDynamicMaterialInstance(nullptr, MatTemplate);
	if (NewMat)
	{
		NewMat->SetTextureParameterValue(FName(*FlagMaterialChannel), BaseFlagTexture);
		return NewMat;
	}
#endif
	return nullptr;
}
//
//void FKMShipMeshMerge::AddTextureToMergedTexture(UTexture2D* InTexture, UTexture2D* MergedTexture, FTransform& InUvTrans)
//{
//	int32 MergedSizeX = MergedTexture->PlatformData->SizeX;
//	int32 MergedSizeY = MergedTexture->PlatformData->SizeY;
//
//	int32 UseSize = MergedTexture->PlatformData->SizeX * InUvTrans.GetScale3D().X;
//	int32 SelectedMipIndex = -1;
//	for(int32 MipIndex = 0; MipIndex < InTexture->PlatformData->Mips.Num(); MipIndex++)
//	{
//		if (InTexture->PlatformData->Mips[MipIndex].SizeX == UseSize)
//		{
//			SelectedMipIndex = MipIndex;
//			break;
//		}
//	}
//
//	if (SelectedMipIndex == -1)
//	{
//		return;
//	}
//
//	EPixelFormat InFormat = InTexture->PlatformData->PixelFormat;
//
//	int32 MergeBlockNumX = MergedSizeX / 4;
//	int32 MergeBlockNumY = MergedSizeY / 4;
//
//	int32 SizeX = InTexture->PlatformData->Mips[SelectedMipIndex].SizeX;
//	int32 SizeY = InTexture->PlatformData->Mips[SelectedMipIndex].SizeY;
//
//	int32 BlockNum = SizeX / 4;
//	int32 HeightBlockNum = SizeY / 4;
//	int32 BitSize = BlockNum * GPixelFormats[InFormat].BlockBytes;
//
//	EPixelFormat NewFormat = MergedTexture->PlatformData->PixelFormat;
//
//	FByteBulkData& BulkData = InTexture->PlatformData->Mips[SelectedMipIndex].BulkData;
//	int32 BulkSize = BulkData.GetBulkDataSize();
//	void* RawBulkData = InTexture->PlatformData->Mips[SelectedMipIndex].BulkData.Lock(LOCK_READ_ONLY);
//
//	int32 MergedRowSize = MergeBlockNumX * GPixelFormats[NewFormat].BlockBytes;
//
//	//prepare to merge data
//	uint8* DataDes = static_cast<uint8*>(MergedTexture->PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE));
//
//	//add texture data to merged texture according uv transform
//	uint8* BulkDataSrc = static_cast<uint8*>(RawBulkData);
//
//	int32 HeightOffset = 0;
//	int32 WidthOffset = 0;
//
//	//copy memory of texture
//	/* eye 1/8 merged size*/
//	HeightOffset = MergeBlockNumY * InUvTrans.GetTranslation().Y;
//	WidthOffset = MergeBlockNumX * InUvTrans.GetTranslation().X;
//
//	int32 TotalSize = MergedTexture->PlatformData->Mips[0].BulkData.GetBulkDataSize();
//	check(TotalSize == MergeBlockNumX * MergeBlockNumY * GPixelFormats[NewFormat].BlockBytes);
//
//	//find start address
//	int32 SizeOffset = (MergeBlockNumX * HeightOffset + WidthOffset) * GPixelFormats[NewFormat].BlockBytes;
//	DataDes += SizeOffset;
//
//	for (int32 HeiBlockIndex = 0; HeiBlockIndex < HeightBlockNum; ++HeiBlockIndex)
//	{
//		//copy per 4*4 block directly
//		if (InFormat == NewFormat)
//		{
//			check(TotalSize >= SizeOffset + BitSize);
//			FMemory::Memcpy(DataDes, BulkDataSrc, BitSize);
//			DataDes += MergedRowSize;
//			SizeOffset += MergedRowSize;
//
//			BulkDataSrc += BitSize;
//		}
//		//copy RGB copy per 4*4 block & Set Alpha to default
//		//for newformat is RGBA ,informat is RGB
//		else
//		{
//			//merge alpha to texture without alpha
//			check((InFormat == EPixelFormat::PF_ETC2_RGB &&NewFormat == EPixelFormat::PF_ETC2_RGBA) ||
//				(InFormat == EPixelFormat::PF_DXT1 &&NewFormat == EPixelFormat::PF_DXT5) ||
//				(InFormat == EPixelFormat::PF_BC4 &&NewFormat == EPixelFormat::PF_BC4));
//
//			for (int32 XBIndex = 0; XBIndex < BlockNum; ++XBIndex)
//			{
//				check(TotalSize >= SizeOffset + DefaultAlphaSize);
//				FMemory::Memcpy(DataDes, DefaultAlpha.GetData(), DefaultAlphaSize);
//				DataDes += DefaultAlphaSize;
//				SizeOffset += DefaultAlphaSize;
//
//				check(TotalSize >= SizeOffset + GPixelFormats[InFormat].BlockBytes);
//				FMemory::Memcpy(DataDes, BulkDataSrc, GPixelFormats[InFormat].BlockBytes);
//				DataDes += GPixelFormats[InFormat].BlockBytes;
//				SizeOffset += GPixelFormats[InFormat].BlockBytes;
//
//				BulkDataSrc += GPixelFormats[InFormat].BlockBytes;
//			}
//
//			DataDes -= BitSize;
//			SizeOffset -= BitSize;
//			DataDes += MergedRowSize;
//			SizeOffset += MergedRowSize;
//		}
//
//	}
//
//	MergedTexture->PlatformData->Mips[0].BulkData.Unlock();
//	InTexture->PlatformData->Mips[0].BulkData.Unlock();
//
//	MergedTexture->UpdateResource();
//}


//used for merge flag
UStaticMeshComponent* FKMShipMeshMerge::MergeFlagofShip(TArray<UStaticMeshComponent*> Flags, TArray<int32> PartIDs, AActor* OwnerActorOfNode)
{
	//return null for temprarily
	return nullptr;
#if 0
	TArray<UStaticMesh*> StaticMeshes;
	TArray<FTransform> PosTrans;
	//yangjingzhao for 4.20
	//TArray<FStaticMeshUVTransform> InTrans;
	for (int32 SIndex = 0; SIndex < Flags.Num(); SIndex++)
	{
		//add protection for allowcpuaccess
		if (Flags[SIndex]->GetStaticMesh() && !Flags[SIndex]->GetStaticMesh()->bAllowCPUAccess)
		{
			FString DebugMessage = FString(TEXT("Property: bAllowCPUAccess should be true for staticMesh: "));
			DebugMessage.Append(*Flags[SIndex]->GetStaticMesh()->GetPathName());
			GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
			return nullptr;
		}

		StaticMeshes.Add(Flags[SIndex]->GetStaticMesh());
		PosTrans.Add(Flags[SIndex]->GetRelativeTransform());
		PartIDs.Add(0);

		FTransform TempTrans;
		switch (SIndex)
		{
		case 0:
			TempTrans.SetScale3D(FVector(0.5, 0.5, 0));
			TempTrans.SetTranslation(FVector(0, 0, 0));
			break;

		case 1:
			TempTrans.SetScale3D(FVector(0.5, 0.5, 0));
			TempTrans.SetTranslation(FVector(0.5, 0, 0));
			break;

		case 2:
			TempTrans.SetScale3D(FVector(0.5, 0.5, 0));
			TempTrans.SetTranslation(FVector(0, 0.5, 0));
			break;

		default:
			break;
		}

		//yangjingzhao for 4.20
		//FStaticMeshUVTransform StaticTrans;
		//StaticTrans.UVTransformsPerMesh.Add(TempTrans);
		//InTrans.Add(StaticTrans);

		//Flags[SIndex]->SetVisibility(false);
	}

	UMaterialInterface* OutMat = MergeShipFlagMat_Cooked(Flags, PartIDs);

	//yangjingzhao for 4.20
	//FKMStaticMeshMerge Merger;
	UStaticMesh* OutMesh = nullptr;
	//yangjingzhao for 4.20
	//Merger.MaterialIdxToSectionIdx.Empty();
	//Merger.MaterialIdxToSectionIdx.Add(FIntPoint(0, 0), { 0 });
	//Merger.MaterialIdxToSectionIdx.Add(FIntPoint(1, 0), { 0 });
	//Merger.MaterialIdxToSectionIdx.Add(FIntPoint(2, 0), { 0 });
	//Merger.MergeStaticMeshes(StaticMeshes, PosTrans, FVector::ZeroVector, OutMesh, InTrans);
	//OutMesh->StaticMaterials[0].MaterialInterface = OutMat;

	UStaticMeshComponent* FlagCom = NewObject<UStaticMeshComponent>(OwnerActorOfNode, UStaticMeshComponent::StaticClass());
	FlagCom->SetStaticMesh(OutMesh);
	FlagCom->RegisterComponentWithWorld(OwnerActorOfNode->GetWorld());

	OwnerActorOfNode->AddOwnedComponent(FlagCom);
	FlagCom->AttachToComponent(OwnerActorOfNode->GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform);

	return FlagCom;
#endif
}



UStaticMeshComponent* FKMShipMeshMerge::MergeSameStaticMesh(TArray<FStaticMergeParameter>& StaticMeshes, const FVector& Pivot, UStaticMesh*& OutMesh, AActor* OwnerActor)
{
#if 0
	UStaticMeshComponent* StaticMeshComponent = NewObject<UStaticMeshComponent>(OwnerActor, UStaticMeshComponent::StaticClass());
	
	if (!StaticMeshComponent)
	{
		return nullptr;
	}
	
	StaticMeshComponent->RegisterComponentWithWorld(OwnerActor->GetWorld());
	OwnerActor->AddOwnedComponent(StaticMeshComponent);

	if (StaticMeshes.Num() == 0)
	{
		return nullptr;
	}

	TArray<UStaticMesh*> MeshesToMerge;
	TArray<FTransform> ToWorldTransforms;

	for (int32 SIndex = 0; SIndex < StaticMeshes.Num(); SIndex ++)
	{
		if (!StaticMeshes[SIndex].Static.IsValid())
		{
			UE_LOG(LogKMSKMergeStatic, Error, TEXT("static mesh to merge can not be null ptr**"));
			continue;
		}

		//add protection for allowcpuaccess
		if (StaticMeshes[SIndex].Static.IsValid() && !StaticMeshes[SIndex].Static.Get()->bAllowCPUAccess)
		{
			FString DebugMessage = FString(TEXT("Property: bAllowCPUAccess should be true for staticMesh: "));
			DebugMessage.Append(*StaticMeshes[SIndex].Static.Get()->GetPathName());
			GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
			return nullptr;
		}

		MeshesToMerge.Add(StaticMeshes[SIndex].Static.Get());
		ToWorldTransforms.Add(StaticMeshes[SIndex].Offset);
	}

	double StartTime = FPlatformTime::Seconds();
	OutMesh = FKMStaticMeshMerge().MergeStaticMeshes(MeshesToMerge, ToWorldTransforms, Pivot);
	UE_LOG(LogKMSKMergeStatic, Log, TEXT("Merge static mesh time: %f ms."), (FPlatformTime::Seconds() - StartTime)*1000.0f);

	return StaticMeshComponent;
#else
	return nullptr;
#endif
}

FShipPartMergeDesc* FKMShipMeshMerge::GetShipPartDescBySlotName(FString& SlotName)
{
	//ShipParts
	for (int32 PartIndex = 0; PartIndex < ShipParts.Num(); ++PartIndex)
	{
		if (ShipParts[PartIndex].SlotName.Equals(SlotName.ToLower()))
		{
			return &ShipParts[PartIndex];

		}
	}
	return nullptr;
}

FShipPartMergeDesc* FKMShipMeshMerge::GetShipPartDescByPartFlag(uint8 PartFlag)
{
	//ShipParts
	for (int32 PartIndex = 0; PartIndex < ShipParts.Num(); ++PartIndex)
	{
		if (ShipParts[PartIndex].ShipPart == EShipMerge::MergePart(PartFlag))
		{
			return &ShipParts[PartIndex];
		}
	}
	return nullptr;
}