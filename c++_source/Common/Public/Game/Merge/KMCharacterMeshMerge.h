#pragma once

#include "KMMergeConfig.h"

struct FMergingResult
{
	TArray<USkeletalMesh*> SrcMeshes;
	TArray<FMergedTexture> TextureMap;
	USkeletalMesh* SKMesh;
};

//struct FMergedTexturePair
//{
//	ECharacterMergeMaterial::Texture Channel;
//	UTexture2D* MergedTexture;
//};
//
//struct FPendingMergeTexturePair
//{
//	ECharacterMergeMaterial::Texture Channel;
//	TArray<FTextureMergeInfo> Parts;
//};

class COMMON_API FKMCharacterMeshMerge/* : public TThreadSingleton<FKMCharacterMeshMerge>*/
{
private:
	static FKMCharacterMeshMerge* Singleton;
	static void SetupSingleton();

public:
	static FKMCharacterMeshMerge& Get();

	typedef TArray<FTextureMergeInfo> FTextureMergeInfoArray;
	typedef TMap<ECharacterMergeMaterial::Texture, FTextureMergeInfoArray> FSourceTextureMap;
	typedef TMap<ECharacterMergeMaterial::Texture, UTexture2D*> FMergedTextureMap;

	FKMCharacterMeshMerge();
	//~FKMCharacterMeshMerge();
	//FKMCharacterMeshMerge(FKMCharacterMeshMerge const&);
	//FKMCharacterMeshMerge& operator=(FKMCharacterMeshMerge const&);

	FMergingResult KMMergeSkeletal(TArray<FMergedTexture> InTextureMap,
		TArray<FGatheredSourceTexture> InSourceTextures, TArray<USkeletalMesh*> SrcMeshes,
		TArray<int32>& PartIDs, int32 OverrideQuality = 0);

	/*
	*SectionIndex used for define section slot on skeletalmesh
	[face, eye, hair, hat, hat_accessory, body, cloth, body_accessory]
	[0,		1,	 2,		3,				4,	 5,		6,				7]
	___________________
	|		|		  |
	|	0	|	5	  |
	|		|		  |
	|_______|_________|
	|		|3	|2	  |
	|	6	|___|_____|
	|		|7	|1_|4_|
	|_______|___|_ |__|
	*/

	//OverrideQuality is for mipmap level
	FMergingResult KMMergeSkeletal_Cooked(TArray<FMergedTexture>& InTextureMap,
		TArray<FGatheredSourceTexture>& InSourceTextures, TArray<USkeletalMesh *>& InSrcMeshes, TArray<int32>& PartIDs, int32 OverrideQuality);

	void PrepareTextures(TArray<FMergedTexture>& OutMergedTextures,
		TArray<FGatheredSourceTexture>& OutSourceTextures, TArray<USkeletalMesh*>& SrcMeshes, int32 OverrideQuality);

	void MergeSinglePartTexture(UMaterialInterface* Material, FSkeletalPartMergeDesc& Part, TMap<ECharacterMergeMaterial::Texture, UTexture2D*>& MergedTextures, int32 OverrideQuality);

	bool KMMergeActorSkeletalMesh(AActor* InCharacter, TArray<USkeletalMesh*> InMeshes, TArray<FName> SocketNames, int32 OverrideQuality = -1);

	FSkeletalPartMergeDesc* GetSkeletalPartDescBySlotName(FString& SlotName);

	FSkeletalPartMergeDesc* GetSkeletalPartDescByPartFlag(uint8 PartFlag);

	void MergeTextures(TArray<FMergedTexture>& InOutMergedTextures, TArray<FGatheredSourceTexture>& InSourceTextures);

	bool FinalizeMerge(FMergingResult& InOutMergineResult);

private:

	bool DrawMaterialPropertyToRenderTarget(UMaterialInterface* InMat, UTextureRenderTarget2D* OutTarget);

	//FMergedTextureGroup* CheckIsMergedTextureExits(TArray<int32>& InIDs);
private:

	//TArray<TSharedPtr<FMergedTextureGroupPair>> MergedPairs;
	TArray<uint8> DefaultAlpha;
	TArray<uint8> DefaultColor;
	int32 DefaultAlphaSize;
	FString MergedMatUrl;

	TArray<FSkeletalPartMergeDesc> SkeletalParts;
	TArray<FCharacterMaterilChannel> CharacterChannel;
};