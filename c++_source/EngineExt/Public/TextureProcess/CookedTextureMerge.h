#pragma once

namespace ETextureMergeTileMode
{
	enum TileMode
	{
		Mode_None,
		Mode_U,
		Mode_V
	};
}

struct FMergeTexturePara
{
	FMergeTexturePara() {};
	~FMergeTexturePara() {};

	EPixelFormat NewFormat;
	int32 SrcMipIndex;
	int32 DefaultAlphaSize;
	FTransform UvTransform;
	TArray<uint8>* DefaultAlphaData;

	ETextureMergeTileMode::TileMode Tile;
};

struct FClearTexturePara
{
	FClearTexturePara() {};
	~FClearTexturePara() {};

	EPixelFormat NewFormat;
	int32 DefaultColorize;
	FTransform UvTransform;
	TArray<uint8>* DefaultColorData;
	ETextureMergeTileMode::TileMode Tile;
};

class ENGINEEXT_API FCookedTextureMerge
{
	FCookedTextureMerge() {};
	~FCookedTextureMerge() {};

public:
	static UTexture2D* CreateMergedTexture(EPixelFormat NewFormat, UTexture2D* BasedTexture, int32 OverrideQuality);

	static void AddDataToMergedTexture(UTexture2D* InTetxture, UTexture2D& MergedTexture, FMergeTexturePara& Para);
	static void AddDataToMergedTextureTiling(UTexture2D* InTetxture, UTexture2D& MergedTexture, FMergeTexturePara& Para);

	//寻找对应的mipindex，如果找不到对应的，贴图合并会失败
	static int32 GetMipIndexFromSource(UTexture2D* InTetxture, FTransform& UvTransform, UTexture2D& MergedTexture);

	//不需要合并的区域，或者找不到对应的color data的区域，使用默认填充；防止出现渲染错误
	static void ClearDataToMergedTexture(UTexture2D& MergedTexture, FClearTexturePara& Para);

private:
};
