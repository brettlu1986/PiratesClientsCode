#include "Game/Merge/KMCharacterMeshMerge.h"
#include "Common.h"

#include "Kismet/KismetMaterialLibrary.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "SkeletalMeshMerge.h"
#include "SkeletalMeshTypes.h"
#include "Shell/EngineExtShell.h"
#include "TextureProcess/CookedTextureMerge.h"
#include "Rendering/SkeletalMeshRenderData.h"
#include "Rendering/SkeletalMeshLODRenderData.h"

DEFINE_LOG_CATEGORY_STATIC(LogKMSKMerge, Log, All)

FKMCharacterMeshMerge* FKMCharacterMeshMerge::Singleton;

int32 CharacterTargetRes = 2;
FAutoConsoleVariableRef CVarCharacterTargetRes(
	TEXT("r.CharacterTargetRes"),
	CharacterTargetRes,
	TEXT("CharacterTargetRes level. Ex: iphone7 is high, iphone 6 is medium;")
);

FKMCharacterMeshMerge::FKMCharacterMeshMerge()
{
	UKMMergeConfig* NewConfig = NewObject<UKMMergeConfig>(GetTransientPackage(), FName(TEXT("MergeConfig")));

	MergedMatUrl = NewConfig->MergedCharacterMatUrl/*FString(TEXT("/Game/Resources/Characters/BaseMaterials/M_Character_ARM_Mask_Combine.M_Character_ARM_Mask_Combine"))*/;


	DefaultAlphaSize = GPixelFormats[EPixelFormat::PF_ETC2_RGB].BlockBytes;
	DefaultAlpha.AddUninitialized(DefaultAlphaSize);
	for (int32 Index = 0; Index < DefaultAlpha.Num(); ++Index)
	{
		DefaultAlpha[Index] = 255;
	}

	//Texture2D'/Game/Game/Characters/Materials/T_DefaultMask_M.T_DefaultMask_M'
	FString DefaultMaskPath = NewConfig->CharacterDefaultMask /*FString(TEXT("/Game/Game/Characters/Materials/T_DefaultMask_M.T_DefaultMask_M"))*/;
	UTexture2D* DefaultMask = Cast<UTexture2D>(UEngineExtShell::StaticLoadObjectWithoutFlush(DefaultMaskPath));

	int32 NumMip = DefaultMask->PlatformData->Mips.Num();
	EPixelFormat Format = DefaultMask->PlatformData->PixelFormat;
	uint8* TempData = static_cast<uint8*>(DefaultMask->PlatformData->Mips[0].BulkData.Lock(LOCK_READ_ONLY));
	DefaultColor.AddUninitialized(GPixelFormats[Format].BlockBytes);
	FMemory::Memcpy(DefaultColor.GetData(), TempData, GPixelFormats[Format].BlockBytes);
	DefaultMask->PlatformData->Mips[0].BulkData.Unlock();

	CharacterChannel = NewConfig->CharacterChannel;

	//initail skeletal part desc
	for (int32 PIndex = 0; PIndex < NewConfig->CharacterPartDescs.Num(); PIndex ++)
	{
		FTransform UVran = FTransform::Identity;
		UVran.SetScale3D(NewConfig->CharacterPartDescs[PIndex].UvScale);
		UVran.SetTranslation(NewConfig->CharacterPartDescs[PIndex].UvLocation);
		SkeletalParts.Add(FSkeletalPartMergeDesc(NewConfig->CharacterPartDescs[PIndex].SkeletalPart, UVran, NewConfig->CharacterPartDescs[PIndex].SlotName));
	}

	/*示例 in DefaultMergeConfig
	+CharacterPartDescs=(SkeletalPart=0,UvLocation=(X=0.0,Y=0.0,Z=0.0),UvScale=(X=0.5,Y=0.5,Z=0.0),SlotName="face")
	+CharacterPartDescs=(SkeletalPart=1,UvLocation=(X=0.75,Y=0.75,Z=0),UvScale=(X=0.125,Y=0.125,Z=0.0),SlotName="eye")
	+CharacterPartDescs=(SkeletalPart=2,UvLocation=(X=0.75,Y=0.5,Z=0.0),UvScale=(X=0.25,Y=0.25,Z=0.0),SlotName="hair")
	+CharacterPartDescs=(SkeletalPart=3,UvLocation=(X=0.5,Y=0.5,Z=0.0),UvScale=(X=0.25,Y=0.25,Z=0.0),SlotName="hat")
	+CharacterPartDescs=(SkeletalPart=4,UvLocation=(X=0.875,Y=0.75,Z=0.0),UvScale=(X=0.125,Y=0.125,Z=0.0),SlotName="hat_accessory")
	+CharacterPartDescs=(SkeletalPart=5,UvLocation=(X=0.5,Y=0.0,Z=0.0),UvScale=(X=0.5,Y=0.5,Z=0.0),SlotName="body")
	+CharacterPartDescs=(SkeletalPart=6,UvLocation=(X=0.0,Y=0.5,Z=0.0),UvScale=(X=0.5,Y=0.5,Z=0.0),SlotName="clothing")
	+CharacterPartDescs=(SkeletalPart=7,UvLocation=(X=0.5,Y=0.75,Z=0.0),UvScale=(X=0.25,Y=0.25,Z=0.0),SlotName="body_accessory")
	+CharacterPartDescs=(SkeletalPart=8,UvLocation=(X=0.75,Y=0.875,Z=0.0),UvScale=(X=0.125,Y=0.125,Z=0.0),SlotName="weapon")
	*/
}

//MeshIndex used for locating index in srcmeshes for head:0, body:1, hair:2
FMergingResult FKMCharacterMeshMerge::KMMergeSkeletal(TArray<FMergedTexture> InTextureMap,
	TArray<FGatheredSourceTexture> InSourceTextures, TArray<USkeletalMesh*> SrcMeshes,
	TArray<int32>& PartIDs, int32 OverrideQuality)
{
	if (FPlatformProperties::RequiresCookedData())
	{
		return KMMergeSkeletal_Cooked(InTextureMap, InSourceTextures, SrcMeshes, PartIDs, OverrideQuality);
	}
	FMergingResult MergineResult;
	MergineResult.SrcMeshes = SrcMeshes;
	return MergineResult;
}

FMergingResult FKMCharacterMeshMerge::KMMergeSkeletal_Cooked(TArray<FMergedTexture>& InTextureMap,
	TArray<FGatheredSourceTexture>& InSourceTextures, TArray<USkeletalMesh *>& InSrcMeshes, TArray<int32>& PartIDs, int32 OverrideQuality)
{
	FMergingResult MergingResult;
	MergingResult.SrcMeshes = InSrcMeshes;
	MergingResult.TextureMap = InTextureMap;
	MergingResult.SKMesh = nullptr;

#if PLATFORM_IOS
	return MergingResult;
#else
	MergeTextures(InTextureMap, InSourceTextures);
	return MergingResult;
#endif
}

void FKMCharacterMeshMerge::MergeSinglePartTexture(UMaterialInterface* Material, FSkeletalPartMergeDesc& Part, TMap<ECharacterMergeMaterial::Texture, UTexture2D*>& MergedTextures, int32 OverrideQuality)
{
	UTexture* BaseColorTexture;
	UTexture* MaskTexture;
	UTexture* NormalTexture;

	bool HasBaseColor;
	bool HasBaseMask;
	bool HasBaseNormal;

	//Get parameter texture data
	HasBaseColor = Material->GetTextureParameterValue(FName(*CharacterChannel[ECharacterMergeMaterial::BaseColor].ParamaterName), BaseColorTexture);
	HasBaseMask = Material->GetTextureParameterValue(FName(*CharacterChannel[ECharacterMergeMaterial::BaseMask].ParamaterName), MaskTexture);
	HasBaseNormal = Material->GetTextureParameterValue(FName(*CharacterChannel[ECharacterMergeMaterial::BaseNormal].ParamaterName), NormalTexture);

	FMergeTexturePara MergePara;
	MergePara.DefaultAlphaData = &DefaultColor;
	MergePara.DefaultAlphaSize = DefaultAlphaSize;
	MergePara.UvTransform = Part.UvTransform;
	MergePara.Tile = ETextureMergeTileMode::Mode_None;

	FClearTexturePara ClearPara;
	ClearPara.DefaultColorData = &DefaultColor;
	ClearPara.DefaultColorize = DefaultAlphaSize;
	ClearPara.UvTransform = Part.UvTransform;
	ClearPara.Tile = ETextureMergeTileMode::Mode_None;

	if (HasBaseColor)
	{
		MergePara.NewFormat = MergedTextures[ECharacterMergeMaterial::BaseColor]->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(BaseColorTexture), Part.UvTransform, *MergedTextures[ECharacterMergeMaterial::BaseColor]);
		
		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(BaseColorTexture), *MergedTextures[ECharacterMergeMaterial::BaseColor], MergePara);	
	}
	else
	{
		ClearPara.NewFormat = MergedTextures[ECharacterMergeMaterial::BaseColor]->PlatformData->PixelFormat;
		FCookedTextureMerge::ClearDataToMergedTexture(*MergedTextures[ECharacterMergeMaterial::BaseColor], ClearPara);
	}

	if (HasBaseNormal)
	{
		MergePara.NewFormat = MergedTextures[ECharacterMergeMaterial::BaseNormal]->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(NormalTexture), Part.UvTransform, *MergedTextures[ECharacterMergeMaterial::BaseNormal]);

		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(NormalTexture), *MergedTextures[ECharacterMergeMaterial::BaseNormal], MergePara);
	}
	else
	{
		ClearPara.NewFormat = MergedTextures[ECharacterMergeMaterial::BaseNormal]->PlatformData->PixelFormat;
		FCookedTextureMerge::ClearDataToMergedTexture(*MergedTextures[ECharacterMergeMaterial::BaseNormal], ClearPara);
	}

	if (HasBaseMask)
	{
		MergePara.NewFormat = MergedTextures[ECharacterMergeMaterial::BaseMask]->PlatformData->PixelFormat;
		MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(Cast<UTexture2D>(MaskTexture), Part.UvTransform, *MergedTextures[ECharacterMergeMaterial::BaseMask]);

		FCookedTextureMerge::AddDataToMergedTexture(Cast<UTexture2D>(MaskTexture), *MergedTextures[ECharacterMergeMaterial::BaseMask], MergePara);
	}
	else
	{
		ClearPara.NewFormat = MergedTextures[ECharacterMergeMaterial::BaseMask]->PlatformData->PixelFormat;
		FCookedTextureMerge::ClearDataToMergedTexture(*MergedTextures[ECharacterMergeMaterial::BaseMask], ClearPara);
	}
}

static UTexture2D* GetMergedTextureByChannel(TArray<FMergedTexture>& OutMergedTextures, ECharacterMergeMaterial::Texture Channel)
{
	for (int32 Index = 0; Index < OutMergedTextures.Num(); ++Index)
	{
		if (OutMergedTextures[Index].Channel == Channel)
		{
			return OutMergedTextures[Index].MergedTexture;
		}
	}

	return nullptr;
}

static TArray<FTextureMergeInfo>* FindOrAddSourceTextureArray(TArray<FGatheredSourceTexture>& OutSourceTextures, ECharacterMergeMaterial::Texture Channel)
{
	int32 FoundIdx = -1;;

	for (int32 Index = 0; Index < OutSourceTextures.Num(); Index++)
	{
		if (OutSourceTextures[Index].Channel == Channel)
		{
			FoundIdx = Index;
			break;
		}
	}

	if (FoundIdx >= 0)
	{
		return &OutSourceTextures[FoundIdx].Parts;
	}

	FGatheredSourceTexture Pair;
	Pair.Channel = Channel;
	TArray<FTextureMergeInfo> Parts;
	Pair.Parts = Parts;
	OutSourceTextures.Add(Pair);

	return &OutSourceTextures[OutSourceTextures.Num() - 1].Parts;
}

void FKMCharacterMeshMerge::PrepareTextures(TArray<FMergedTexture>& OutMergedTextures,
	TArray<FGatheredSourceTexture>& OutSourceTextures, TArray<USkeletalMesh*>& SrcMeshes, int32 OverrideQuality)
{
	//iterate all mats to find merged resoluton
	for (int32 MeI = 0; MeI < SrcMeshes.Num(); MeI++)
	{
		USkeletalMesh* SKMesh = SrcMeshes[MeI];
		FSkeletalMeshRenderData* RenderData = SKMesh->GetResourceForRendering();
		check(RenderData);
		check(RenderData->LODRenderData.Num());
		FSkeletalMeshLODRenderData& LODRenderData = RenderData->LODRenderData[0];

		for (FSkelMeshRenderSection& RenderSection : LODRenderData.RenderSections)
		{
			int32 MaI = RenderSection.MaterialIndex;
			// get material
			check(SrcMeshes[MeI]->Materials.IsValidIndex(MaI));
			FSkeletalMaterial* SkelMat = &SrcMeshes[MeI]->Materials[MaI];
			UMaterialInterface* Material = SkelMat->MaterialInterface;

			// get slot name
			FString SlotName = SkelMat->MaterialSlotName.ToString();

			// get the merging info
			FSkeletalPartMergeDesc* PartMergeInfo = GetSkeletalPartDescBySlotName(SlotName);
			check(PartMergeInfo);

			if (PartMergeInfo)
			{
				EPixelFormat NewFormat = EPixelFormat::PF_ETC2_RGB;

				// base color
				UTexture* TempBaseColor;
				bool bHasBaseColor = Material->GetTextureParameterValue(FName(*CharacterChannel[ECharacterMergeMaterial::BaseColor].ParamaterName), TempBaseColor);
				if (bHasBaseColor)
				{
					FTextureMergeInfo TextureMergeInfo;
					TextureMergeInfo.PartDesc = *PartMergeInfo;
					TextureMergeInfo.Texture = Cast<UTexture2D>(TempBaseColor);
					TArray<FTextureMergeInfo>* TextureMergeInfoAry = FindOrAddSourceTextureArray(OutSourceTextures, ECharacterMergeMaterial::BaseColor);
					TextureMergeInfoAry->Add(TextureMergeInfo);

					UTexture2D* BaseColorMerged = GetMergedTextureByChannel(OutMergedTextures, ECharacterMergeMaterial::BaseColor);

					if (!BaseColorMerged)
					{
						NewFormat = Cast<UTexture2D>(TempBaseColor)->PlatformData->PixelFormat;
						UE_LOG(LogTemp, Log, TEXT("[XSJ] Prepare Texture Merged base color format11 : %d."), (int)NewFormat);

#if PLATFORM_ANDROID
						if (NewFormat != PF_ASTC_8x8 && NewFormat != PF_ASTC_4x4)
						{
							NewFormat = PF_ETC2_RGBA;
						}
#elif PLATFORM_WINDOWS
						NewFormat = PF_DXT5;
#endif
						UE_LOG(LogTemp, Log, TEXT("[XSJ] Prepare Texture Merged base color format : %d."), (int)NewFormat);

						BaseColorMerged = FCookedTextureMerge::CreateMergedTexture(NewFormat, Cast<UTexture2D>(TempBaseColor), OverrideQuality);
						FMergedTexture MergedBaseColor;
						MergedBaseColor.Channel = ECharacterMergeMaterial::BaseColor;
						MergedBaseColor.MergedTexture = BaseColorMerged;
						OutMergedTextures.Add(MergedBaseColor);
					}
				}

				// normal texture
				UTexture* NormalTexture;
				bool HasNormal = Material->GetTextureParameterValue(FName(*CharacterChannel[ECharacterMergeMaterial::BaseNormal].ParamaterName), NormalTexture);
				if (HasNormal)
				{
					FTextureMergeInfo TextureMergeInfo;
					TextureMergeInfo.PartDesc = *PartMergeInfo;
					TextureMergeInfo.Texture = Cast<UTexture2D>(NormalTexture);
					FTextureMergeInfoArray* TextureMergeInfoAry = FindOrAddSourceTextureArray(OutSourceTextures, ECharacterMergeMaterial::BaseNormal);
					TextureMergeInfoAry->Add(TextureMergeInfo);

					UTexture2D* BaseNormalMerged = GetMergedTextureByChannel(OutMergedTextures, ECharacterMergeMaterial::BaseNormal);
					if (!BaseNormalMerged)
					{
						NewFormat = Cast<UTexture2D>(NormalTexture)->PlatformData->PixelFormat;
						UE_LOG(LogTemp, Log, TEXT("[XSJ] Prepare Texture Merged base normal format : %d."), (int)NewFormat);
						BaseNormalMerged = FCookedTextureMerge::CreateMergedTexture(NewFormat, Cast<UTexture2D>(NormalTexture), OverrideQuality);
						FMergedTexture MergedBaseNormal;
						MergedBaseNormal.Channel = ECharacterMergeMaterial::BaseNormal;
						MergedBaseNormal.MergedTexture = BaseNormalMerged;
						OutMergedTextures.Add(MergedBaseNormal);
					}
				}

				// mask texture
				UTexture * MaskTexture;
				bool HasMask = Material->GetTextureParameterValue(FName(*CharacterChannel[ECharacterMergeMaterial::BaseMask].ParamaterName), MaskTexture);
				if (HasMask)
				{
					FTextureMergeInfo TextureMergeInfo;
					TextureMergeInfo.PartDesc = *PartMergeInfo;
					TextureMergeInfo.Texture = Cast<UTexture2D>(MaskTexture);
					FTextureMergeInfoArray* TextureMergeInfoAry = FindOrAddSourceTextureArray(OutSourceTextures, ECharacterMergeMaterial::BaseMask);
					TextureMergeInfoAry->Add(TextureMergeInfo);

					UTexture2D* BaseMaskMerged = GetMergedTextureByChannel(OutMergedTextures, ECharacterMergeMaterial::BaseMask);
					if (!BaseMaskMerged)
					{
						NewFormat = Cast<UTexture2D>(MaskTexture)->PlatformData->PixelFormat;
						UE_LOG(LogTemp, Log, TEXT("[XSJ] Prepare Texture Merged base mask format : %d."), (int)NewFormat);
						BaseMaskMerged = FCookedTextureMerge::CreateMergedTexture(NewFormat, Cast<UTexture2D>(MaskTexture), OverrideQuality);
						FMergedTexture MergedBaseMask;
						MergedBaseMask.Channel = ECharacterMergeMaterial::BaseMask;
						MergedBaseMask.MergedTexture = BaseMaskMerged;
						OutMergedTextures.Add(MergedBaseMask);
					}
				}
			}
		}
	}
	checkSlow(OutMergedTextures.Num() == 3);
}

bool FKMCharacterMeshMerge::KMMergeActorSkeletalMesh(AActor* InCharacter, TArray<USkeletalMesh *> InMeshes, TArray<FName> SocketNames, int32 OverrideQuality)
{
	USkeleton* SavedSkeleton = nullptr;

	TArray<USkeletalMesh*> MergeSrcMeshes;
	TArray<USkeletalMesh*> DontMergeSrcMeshes;
	TArray<FName>	DontMergeSockets;

	for (int32 MeshI = 0 ; MeshI < InMeshes.Num(); ++ MeshI)
	{
		if (SocketNames.Num() <= MeshI)
		{
			return false;
		}

		if (!SavedSkeleton && SocketNames[MeshI].IsEqual(FName(TEXT(""))))
		{
			SavedSkeleton = InMeshes[MeshI]->Skeleton;
		}

		bool IsCanMerge = true;
		//check child component has individal skeleton
		if (!SocketNames[MeshI].IsEqual(FName(TEXT(""))))
		{
			FReferenceSkeleton RefSkeleton = InMeshes[MeshI]->Skeleton->GetReferenceSkeleton();
			//if has diffrent skeleton && BoneNodes.Num() > 1; USkeletalMesh may has individal animations
			//so, we dont't merge this skeletalmesh
			if (InMeshes[MeshI]->Skeleton != SavedSkeleton && RefSkeleton.GetNum() > 1)
			{
				IsCanMerge = false;
			}
		}
		
		if (IsCanMerge)
		{
			MergeSrcMeshes.Add(InMeshes[MeshI]);
		}
		else
		{
			DontMergeSrcMeshes.Add(InMeshes[MeshI]);
			DontMergeSockets.Add(SocketNames[MeshI]);
		}
	}

	return true;
}

bool FKMCharacterMeshMerge::DrawMaterialPropertyToRenderTarget(UMaterialInterface* InMat, UTextureRenderTarget2D* OutTarget)
{
	if (!GWorld)
	{
		return false;
	}

	UKismetRenderingLibrary::DrawMaterialToRenderTarget(GWorld, OutTarget, InMat);

	return true;
}

FSkeletalPartMergeDesc* FKMCharacterMeshMerge::GetSkeletalPartDescBySlotName(FString& SlotName)
{
	for (int32 PartIndex = 0; PartIndex < SkeletalParts.Num(); ++PartIndex)
	{
		if (SkeletalParts[PartIndex].SlotName.Equals(SlotName.ToLower()))
		{
			return &SkeletalParts[PartIndex];
		}
	}
	return nullptr;
}

FSkeletalPartMergeDesc* FKMCharacterMeshMerge::GetSkeletalPartDescByPartFlag(uint8 PartFlag)
{
	for (int32 PartIndex = 0; PartIndex < SkeletalParts.Num(); ++PartIndex)
	{
		if (SkeletalParts[PartIndex].SkeletalPart == ESkeletalMerge::MergePart(PartFlag))
		{
			return &SkeletalParts[PartIndex];
		}
	}
	return nullptr;
}

FKMCharacterMeshMerge& FKMCharacterMeshMerge::Get()
{
	if (!Singleton)
	{
		SetupSingleton();
	}
	return *Singleton;
}

void FKMCharacterMeshMerge::SetupSingleton()
{
	check(!Singleton);
	if (!Singleton)
	{
		Singleton = new FKMCharacterMeshMerge;
	}
	check(Singleton);
}

void FKMCharacterMeshMerge::MergeTextures(TArray<FMergedTexture>& InOutMergedTextures, TArray<FGatheredSourceTexture>& InSourceTextures)
{
	double StartTime = FPlatformTime::Seconds();

	for (auto& SourceTextures : InSourceTextures)
	{
		ECharacterMergeMaterial::Texture TextureType = SourceTextures.Channel;
		TArray<FTextureMergeInfo>& Textures = SourceTextures.Parts;

		FMergeTexturePara MergePara;
		MergePara.DefaultAlphaData = &DefaultColor;
		MergePara.DefaultAlphaSize = DefaultAlphaSize;
		MergePara.Tile = ETextureMergeTileMode::Mode_None;

		UTexture2D* MergedTexture = GetMergedTextureByChannel(InOutMergedTextures, TextureType);
		check(MergedTexture);

		MergePara.NewFormat = MergedTexture->PlatformData->PixelFormat;

		/*FClearTexturePara ClearPara;
		ClearPara.DefaultColorData = &DefaultColor;
		ClearPara.DefaultColorize = DefaultAlphaSize;
		ClearPara.UvTransform = Part.UvTransform;
		ClearPara.Tile = ETextureMergeTileMode::Mode_None;*/

		for (auto TexInfo : Textures)
		{
			MergePara.UvTransform = TexInfo.PartDesc.UvTransform;

			MergePara.SrcMipIndex = FCookedTextureMerge::GetMipIndexFromSource(
				TexInfo.Texture, TexInfo.PartDesc.UvTransform, *MergedTexture);

			FCookedTextureMerge::AddDataToMergedTexture(TexInfo.Texture,
				*MergedTexture, MergePara);
		}
	}

	UE_LOG(LogTemp, Log, TEXT("[XSJ] Merge textures : %f ms."), (FPlatformTime::Seconds() - StartTime)*1000.0f);
}

bool FKMCharacterMeshMerge::FinalizeMerge(FMergingResult& InOutMergingResult)
{
	double StartTime = FPlatformTime::Seconds();

	

	// no texture merged, it is not a cooked platform
	if (InOutMergingResult.TextureMap.Num() == 0) return false;

	// update texture resource
	for (int32 ChannelI = 0; ChannelI < InOutMergingResult.TextureMap.Num(); ChannelI++)
	{
		if (!InOutMergingResult.TextureMap[ChannelI].MergedTexture)
		{
			UE_LOG(LogTemp, Log, TEXT("[XSJ] FKMCharacterMeshMerge::FinalizeMerge MergingResult.TextureMap Texture invalid."));
		}

		InOutMergingResult.TextureMap[ChannelI].MergedTexture->UpdateResource();
	}

	// create a dynamic material
	UMaterial* MatTemplate = Cast<UMaterial>(UEngineExtShell::StaticLoadObjectWithoutFlush(MergedMatUrl));
	UMaterialInstanceDynamic* NewMaterial = UKismetMaterialLibrary::CreateDynamicMaterialInstance(nullptr, MatTemplate);

	UTexture2D* BaseColorMerged = GetMergedTextureByChannel(InOutMergingResult.TextureMap, ECharacterMergeMaterial::BaseColor);
	check(BaseColorMerged);
	NewMaterial->SetTextureParameterValue(FName(TEXT("BaseMap")), BaseColorMerged);

	UTexture2D* BaseMaskMerged = GetMergedTextureByChannel(InOutMergingResult.TextureMap, ECharacterMergeMaterial::BaseMask);
	check(BaseMaskMerged);
	NewMaterial->SetTextureParameterValue(FName(TEXT("MaskMap")), BaseMaskMerged);

	UTexture2D* BaseNormalMerged = GetMergedTextureByChannel(InOutMergingResult.TextureMap, ECharacterMergeMaterial::BaseNormal);
	check(BaseNormalMerged);
	NewMaterial->SetTextureParameterValue(FName(TEXT("NormalMap")), BaseNormalMerged);

	UE_LOG(LogTemp, Log, TEXT("[XSJ] FKMCharacterMeshMerge::FinalizeMerge SetMaterial Parameter."));

	TArray<FSkelMeshMergeSectionMapping> SkeletonSections;
	FSkelMeshMergeUVTransforms MergeUVTransform;

	int32 MergeLODStrip = 1;

	for (int32 MeshI = 0; MeshI < InOutMergingResult.SrcMeshes.Num(); MeshI++)
	{
		USkeletalMesh* SrcMesh = InOutMergingResult.SrcMeshes[MeshI];

		if (!SrcMesh)
		{
			UE_LOG(LogTemp, Log, TEXT("[XSJ] FKMCharacterMeshMerge::FinalizeMerge InOutMergingResult.SrcMeshes invalide."));
		}

		FSkelMeshMergeSectionMapping TempMapping;
		TArray<FTransform> UVTransforms;

		FSkeletalMeshRenderData* RenderData = SrcMesh->GetResourceForRendering();

		//reset strip
		if (MergeLODStrip >= RenderData->LODRenderData.Num())
		{
			FString FilePathname = SrcMesh->GetPathName();
			UE_LOG(LogTemp, Error, TEXT("[XSJ] MergeLODStrip Error for mesh %s"), *FilePathname);
			MergeLODStrip = 0;
		}

		FSkeletalMeshLODRenderData& LODRenderData = RenderData->LODRenderData[MergeLODStrip];
		check(RenderData);

		for (FSkelMeshRenderSection& RenderSection : LODRenderData.RenderSections)
		{
			int32 MatIndex = RenderSection.MaterialIndex;

			FSkeletalMaterial* SkelMat = &SrcMesh->Materials[MatIndex];

			FString SlotName = SkelMat->MaterialSlotName.ToString();

			FSkeletalPartMergeDesc* Part = GetSkeletalPartDescBySlotName(SlotName);

			if (!Part)
			{
				FString DebugMessage = FString(TEXT("Can not find part for SlotName: "));
				DebugMessage.Append(SlotName);
				GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, DebugMessage);
				continue;
			}

			TempMapping.SectionIDs.Add(0);
			UVTransforms.Add(Part->UvTransform);
		}

		SkeletonSections.Add(TempMapping);
		MergeUVTransform.UVTransformsPerMesh.Add(UVTransforms);
	}

	InOutMergingResult.SKMesh = NewObject<USkeletalMesh>(GetTransientPackage(), USkeletalMesh::StaticClass());
	InOutMergingResult.SKMesh->Skeleton = InOutMergingResult.SrcMeshes[0]->Skeleton;

	FSkeletalMeshMerge MeshMerger(InOutMergingResult.SKMesh, InOutMergingResult.SrcMeshes, SkeletonSections, MergeLODStrip, EMeshBufferAccess::Default, &MergeUVTransform);

	double TimePremerge = FPlatformTime::Seconds();
	UE_LOG(LogTemp, Log, TEXT("[XSJ] Merge skeleton meshes finalize prepare merege: %f ms."), (TimePremerge - StartTime)*1000.0f);
	bool bSuccess = MeshMerger.DoMerge();
	double DoMergeTime = FPlatformTime::Seconds();
	UE_LOG(LogTemp, Log, TEXT("[XSJ] Merge skeleton meshes finalize do merge: %f ms."), (DoMergeTime - TimePremerge)*1000.0f);
	// set the new material to skel mesh
	InOutMergingResult.SKMesh->Materials[0].MaterialInterface = NewMaterial;

	// log the time
	UE_LOG(LogTemp, Log, TEXT("[XSJ] Merge skeleton meshes finalize : %f ms."), (FPlatformTime::Seconds() - StartTime)*1000.0f);

	return bSuccess;
}
