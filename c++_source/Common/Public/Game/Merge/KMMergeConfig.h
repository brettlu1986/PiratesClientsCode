#pragma once
#include "KMMergeConfig.generated.h"


UENUM(BlueprintType)
namespace ECustomizeParaType
{
	enum Type
	{
		Para_Int,
		Para_Float,
		Para_Color
	};
}

USTRUCT(BlueprintType)
struct FCustomizeParameterPair
{
	GENERATED_BODY()

	FCustomizeParameterPair()
		:ParaType(ECustomizeParaType::Para_Int)
	{};

	FCustomizeParameterPair(FString InSlotName, FString InParameterName, TEnumAsByte<ECustomizeParaType::Type> InType, FString InValue)
	{
		SlotName = InSlotName;
		ParameterName = InParameterName;
		ParaType = InType;
		ValueStr = InValue;
	};

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SkeletalMesh)
	FString SlotName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SkeletalMesh)
	FString ParameterName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SkeletalMesh)
	TEnumAsByte<ECustomizeParaType::Type> ParaType;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SkeletalMesh)
	FString ValueStr;
};

//for character merge
UENUM()
namespace ESkeletalMerge
{
	enum MergePart
	{
		Part_None = -1,
		Part_Face,
		Part_Eye,
		Part_Hair,
		Part_HairAlpha,
		Part_Pants,
		Part_Body,
		Part_Cloth,
		Part_Legs,
		Part_Shoes,
		Part_EyeLash,
		Part_Reserve1,
		Part_Reserve2,
		Part_Reserve3
	};
}

UENUM()
namespace ECharacterMergeMaterial
{
	enum Texture
	{
		BaseColor,
		BaseNormal,
		BaseMask,
		Base_Reserve1,
		Base_Reserve2,
		Base_Reserve3
	};
}

USTRUCT()
struct FMergedTexture
{
	GENERATED_BODY()

	FMergedTexture()
		:Channel(ECharacterMergeMaterial::BaseColor)
		,MergedTexture(nullptr)
	{};

	FMergedTexture(ECharacterMergeMaterial::Texture InChannel, UTexture2D* InTexture)
	{
		MergedTexture = InTexture;
		Channel = InChannel;
	};

	UPROPERTY()
	TEnumAsByte<ECharacterMergeMaterial::Texture> Channel;

	UPROPERTY()
	UTexture2D* MergedTexture;
};

USTRUCT()
struct FSkeletalPartMergeDesc
{
	GENERATED_BODY()

	UPROPERTY()
	TEnumAsByte<ESkeletalMerge::MergePart> SkeletalPart;

	UPROPERTY()
	FTransform UvTransform;

	UPROPERTY()
	FString SlotName;

	FSkeletalPartMergeDesc()
		:SkeletalPart(ESkeletalMerge::Part_None)
	{}

	FSkeletalPartMergeDesc(ESkeletalMerge::MergePart Part, FTransform Tran, FString Slot)
	{
		SkeletalPart = Part;
		UvTransform = Tran;
		SlotName = Slot;
	};
	~FSkeletalPartMergeDesc() {};
};

USTRUCT()
struct FTextureMergeInfo
{
	GENERATED_BODY()
		/** texture to be merged */

		UPROPERTY()
		UTexture2D* Texture;
	/** merging specification */

	UPROPERTY()
		FSkeletalPartMergeDesc PartDesc;
};

USTRUCT()
struct FGatheredSourceTexture
{
	GENERATED_BODY()

	UPROPERTY()
	TEnumAsByte<ECharacterMergeMaterial::Texture> Channel;

	UPROPERTY()
	TArray<FTextureMergeInfo> Parts;

	FGatheredSourceTexture()
		:Channel(ECharacterMergeMaterial::BaseColor)
	{

	}
};


USTRUCT()
struct FSkeletalPartMergeDescConfig
{
	GENERATED_USTRUCT_BODY()

	FSkeletalPartMergeDescConfig()
		:SkeletalPart(ESkeletalMerge::Part_None)
		,UvLocation(FVector::ZeroVector)
		,UvScale(FVector::ZeroVector)
    {}

	FSkeletalPartMergeDescConfig(ESkeletalMerge::MergePart Part, FVector InLoc, FVector InScale, FString Slot)
	{
		SkeletalPart = Part;
		UvLocation = InLoc;
		UvScale = InScale;
		SlotName = Slot;
	};

	UPROPERTY()
	TEnumAsByte<ESkeletalMerge::MergePart> SkeletalPart;

	UPROPERTY()
	FVector UvLocation;

	UPROPERTY()
	FVector UvScale;

	UPROPERTY()
	FString SlotName;

};

USTRUCT()
struct FCharacterMaterilChannel
{
	GENERATED_USTRUCT_BODY()
	FCharacterMaterilChannel()
		:TextureChannel(ECharacterMergeMaterial::BaseColor) 
	{}

	FCharacterMaterilChannel(ECharacterMergeMaterial::Texture Channel, FString Paramater)
	{
		TextureChannel = Channel;
		ParamaterName = Paramater;
	};

	UPROPERTY()
	TEnumAsByte<ECharacterMergeMaterial::Texture> TextureChannel;

	UPROPERTY()
	FString ParamaterName;
};

USTRUCT()
struct FUnMergedSkeletalMeshPart
{
	GENERATED_BODY()

	UPROPERTY()
	USkeletalMesh* SkeletalMesh;

	UPROPERTY()
	int32 Priority;

	UPROPERTY()
	FName Socketname;
};


//for ship merge
struct FSkeletalMergeParameter
{
	int32 PartID;
	TWeakObjectPtr<USkeletalMeshComponent> Skeletal;
	FName BoneName;
	FTransform Offset;
};

struct FStaticMergeParameter
{
	int32 PartID;
	TWeakObjectPtr<UStaticMesh> Static;
	FName BoneName;
	FTransform Offset;
};

struct FStaticMergeParameter1
{
	int32 PartID;
	TWeakObjectPtr<UStaticMeshComponent> Static;
	FName BoneName;
	FTransform Offset;
};

UENUM()
namespace EShipMerge
{
	enum MergePart
	{
		Part_None = -1,
		Part_Hull,
		Part_Body,
		Part_Anchor,
		Part_Light,
		Part_Head,
		Part_Cannon,
		Part_Sail
	};
}

UENUM()
namespace EShipMergeTexture
{
	enum Texture
	{
		BaseColor,
		BaseNormal,
		BaseMask,
		AOemMap,
		BaseColor_Mask
	};
}



struct FShipPartMergeDesc
{
	FShipPartMergeDesc(EShipMerge::MergePart Part, FTransform Tran, FString Slot)
	{
		ShipPart = Part;
		UvTransform = Tran;
		SlotName = Slot;
	};
	~FShipPartMergeDesc() {};

	TEnumAsByte<EShipMerge::MergePart> ShipPart;

	FTransform UvTransform;

	FString SlotName;

};

USTRUCT(Blueprintable)
struct FShipPartMergeDescConfig
{
	GENERATED_USTRUCT_BODY()

	FShipPartMergeDescConfig()
		:ShipPart(EShipMerge::Part_None)
        ,UvLocation(FVector::ZeroVector)
        ,UvScale(FVector::ZeroVector)
	{}

	FShipPartMergeDescConfig(EShipMerge::MergePart Part, FVector Location, FVector Scale, FString Slot)
	{
		ShipPart = Part;
		UvLocation = Location;
		UvScale = Scale;
		SlotName = Slot;
	};

	UPROPERTY()
	TEnumAsByte<EShipMerge::MergePart> ShipPart;

	UPROPERTY()
	FVector UvLocation;

	UPROPERTY()
	FVector UvScale;

	UPROPERTY()
	FString SlotName;

};

USTRUCT()
struct FShipMaterilChannel
{
	GENERATED_USTRUCT_BODY()
	FShipMaterilChannel():TextureChannel(EShipMergeTexture::BaseColor) {}
	FShipMaterilChannel(EShipMergeTexture::Texture Channel, FString Paramater)
	{
		TextureChannel = Channel;
		ParamaterName = Paramater;
	};

	UPROPERTY()
	TEnumAsByte<EShipMergeTexture::Texture> TextureChannel;

	UPROPERTY()
	FString ParamaterName;
};

UCLASS(Blueprintable, config=MergeConfig)
class COMMON_API UKMMergeConfig : public UObject
{
	GENERATED_UCLASS_BODY()

public:
	//UPROPERTY(config)
	//TArray<FMaterilChannel> MaterialChannels;

	UPROPERTY(config)
	TArray<FShipPartMergeDescConfig> ShipPartDescs;

	UPROPERTY(config)
	TArray<FShipMaterilChannel> ShipChannel;

	UPROPERTY(config)
	FString MergedMatUrl;

	UPROPERTY(config)
	FString DefaultMaskPath;

	UPROPERTY(config)
	FString FlagMergedMatUrl;

	UPROPERTY(config)
	FString FlagMaterialChannel;


	UPROPERTY(config)
	FString MergedCharacterMatUrl;

	UPROPERTY(config)
	FString CharacterDefaultMask;

	UPROPERTY(config)
	TArray<FSkeletalPartMergeDescConfig> CharacterPartDescs;

	UPROPERTY(config)
	TArray<FCharacterMaterilChannel> CharacterChannel;

private:
	FString GDefaultMergeConfig;
};