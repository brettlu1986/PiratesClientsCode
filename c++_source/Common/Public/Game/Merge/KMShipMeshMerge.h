#pragma once

#include "KMCharacterMeshMerge.h"
#include "KMSkeletalStaticMeshMerge.h"
//#include "KMStaticMeshMerge.h"
#include "KMMergeConfig.h"

class COMMON_API FKMShipMeshMerge : public TThreadSingleton<FKMShipMeshMerge>
{
public:

	FKMShipMeshMerge();
	//static FKMShipMeshMerge& GetSMMerge()
	//{
	//	static FKMShipMeshMerge Instance;
	//	return Instance;
	//};


	//USkeletalMesh* KMMergeSkeletal(TArray<USkeletalMesh*>& SrcMeshes, TArray<int32>& PartIDs, int32 OverrideQuality = 0);
	USkeletalMesh* KMMergeStaticWithSkeleton(TArray<FSkeletalMergeParameter>& Skeletals, TArray<FStaticMergeParameter>& Statics, TArray<FStaticMergeParameter1>&Flags, int32 OverrideQuality = 0);

	/*
	*SectionIndex used for define section slot on skeletalmesh
	[hull, body, anchor, light, head, cannon]
	[0,		1,	  2,		3,	 4,	     5, ]
	___________________
	|				  |
	|		0		  |
	|				  |
	|_______ _________|
	|		|2	|3	  |
	|	1	|___|_____|
	|		|4	|  5  |
	|_______|___|__ __|
	*/

	//OverrideQuality is for mipmap level
	USkeletalMesh* KMMergeSkeletal_Cooked(TArray<USkeletalMeshComponent*>& SrcMeshes, TArray<int32>& PartIDs, int32 OverrideQuality = 0);

	void CreateShipMergedTextures(TMap<EShipMergeTexture::Texture, UTexture2D*>& InMap,TArray<USkeletalMeshComponent*>& SrcMeshes, int32 OverrideQuality);

	void MergeSinglePartTexture(UMaterialInterface* Material, FShipPartMergeDesc& Part, TMap<EShipMergeTexture::Texture, UTexture2D*>& MergedTextures, int32 OverrideQuality);

	//void AddDataToMergedTexture(UTexture2D* InTetxture, uint8 PartFlag, UTexture2D& MergedTexture, int32 OverrideQuality, EPixelFormat NewFormat);

	UMaterialInterface* MergeShipFlagMat_Cooked(TArray<UStaticMeshComponent*>& SrcMeshes, TArray<int32>& PartIDs, int32 OverrideQuality = 0);

	//void AddTextureToMergedTexture(UTexture2D* InTexture, UTexture2D* MergedTexture, FTransform& InUvTrans);

	//for flag interface
	UStaticMeshComponent* MergeFlagofShip(TArray<UStaticMeshComponent*> Flags, TArray<int32> PartIDs, AActor* OwnerActorOfNode);

	UStaticMeshComponent* MergeSameStaticMesh(TArray<FStaticMergeParameter>& StaticMeshes, const FVector& Pivot, UStaticMesh*& OutMesh, AActor* OwnerActor);

	FShipPartMergeDesc* GetShipPartDescBySlotName(FString& SlotName);
	FShipPartMergeDesc* GetShipPartDescByPartFlag(uint8 PartFlag);
	
private:
	//FKMShipMeshMerge(FKMShipMeshMerge const&);
	//FKMShipMeshMerge& operator=(FKMShipMeshMerge const&);
	//~FKMShipMeshMerge();

protected:
private:
	//FMergedTextureGroup* CheckIsMergedTextureExits(TArray<int32>& InSkeIDs, TArray<int32>& InStaIDs);
	//int32 CheckStaticAlreadyExits(TArray<FStaticMeshMergeParam>& StaticParas, UStaticMesh* InMesh);
private:

	TArray<uint8> DefaultColor;
	TArray<uint8> DefaultAlpha;
	int32 DefaultAlphaSize;
	
	//cached 
	//need clearing after merge
	//TArray<FStaticMeshMergeParam> CachedFlagParams;
	UMaterialInterface* CachedFlagMergedMat;

	TArray<FStaticMergeParameter> CachedStaticMeshes;
	

	FString MergedMatUrl;
	FString FlagMergedMatUrl;
	FString DefaultMaskPath;
	FString FlagMaterialChannel;
	TArray<FShipPartMergeDesc> ShipParts;
	TArray<FShipMaterilChannel> ShipChannel;
};
