#include "TextureProcess/CookedTextureMerge.h"
#include "EngineExt.h"

DEFINE_LOG_CATEGORY_STATIC(LogTextureMerge, Log, All)

UTexture2D* FCookedTextureMerge::CreateMergedTexture(EPixelFormat NewFormat, UTexture2D* BasedTexture, int32 OverrideQuality)
{
	UTexture2D* Ret = nullptr;
	int32 MergedSize = 0;
	int32 SizeX = BasedTexture->PlatformData->Mips[OverrideQuality].SizeX;

	//size of base texture is 1/2 of merged texture
	//we give size limitation for merged texture on device
	MergedSize = SizeX * 2;
	if (MergedSize >= 1024)
	{
		MergedSize = 1024;
	}

	// Create the mask texture
	Ret = UTexture2D::CreateTransient(MergedSize, MergedSize, NewFormat);//
	if (Ret)
	{
		Ret->CompressionSettings = BasedTexture->CompressionSettings;

		Ret->SRGB = BasedTexture->SRGB;
		Ret->LODGroup = BasedTexture->LODGroup;
		Ret->UpdateResource();

		return Ret;
	}
	
	return nullptr;
}

void FCookedTextureMerge::AddDataToMergedTexture(UTexture2D* InTetxture, UTexture2D& MergedTexture, FMergeTexturePara& Para)
{
	//resolution of body is bigger, so we use next mipmap
	int32 SrcOverrideQuality = Para.SrcMipIndex;

	if (SrcOverrideQuality < 0)
	{
		UE_LOG(LogTextureMerge, Error, TEXT("Can't find mip for merge texture, %s"), *InTetxture->GetPathName());
		return;
	}

	if (Para.Tile == ETextureMergeTileMode::Mode_U)
	{
		AddDataToMergedTextureTiling(InTetxture, MergedTexture, Para);
		return;
	}

	int32 SizeX = InTetxture->PlatformData->Mips[SrcOverrideQuality].SizeX;
	int32 SizeY = InTetxture->PlatformData->Mips[SrcOverrideQuality].SizeY;

	int32 MergedSizeX = MergedTexture.PlatformData->Mips[0].SizeX;
	int32 MergedSizeY = MergedTexture.PlatformData->Mips[0].SizeY;

	double startMergeTime = FPlatformTime::Seconds();

	EPixelFormat InFormat = InTetxture->PlatformData->PixelFormat;
	FByteBulkData& BulkData = InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData;
	int32 BulkSize = BulkData.GetBulkDataSize();

	FString FilePath = InTetxture->GetPathName();

	//wait if texture has been locked
	bool IsInTextureLocked = InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData.IsLocked();
	while (IsInTextureLocked)
	{
		UE_LOG(LogTemp, Log, TEXT("[XSJ] Merged textures  texture already locked :%s."), *FilePath);
		FPlatformProcess::Sleep(0.1f);
		IsInTextureLocked = InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData.IsLocked();
	}

	void* RawBulkData = InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData.Lock(LOCK_READ_ONLY);

	int32 BlockXDim = GPixelFormats[Para.NewFormat].BlockSizeX;
	int32 BlockYDim = GPixelFormats[Para.NewFormat].BlockSizeY;

	//UE_LOG(LogTemp, Warning, TEXT("[XSJ] Merged textures format :%d."), (int)Para.NewFormat);
	//UE_LOG(LogTemp, Warning, TEXT("[XSJ] Merged In textures format :%d."), (int)InFormat);

	//for pixel block 4*4
	int32 MergeBlockNumX = MergedSizeX / BlockXDim;
	int32 MergeBlockNumY = MergedSizeY / BlockYDim;

	//we must assure that merged texture and intexture have same block
	int32 BlockNum = SizeX / BlockXDim;
	int32 HeightBlockNum = SizeY / BlockYDim;
	int32 BitSize = BlockNum * GPixelFormats[Para.NewFormat].BlockBytes;

	int32 MergedRowSize = MergeBlockNumX * GPixelFormats[Para.NewFormat].BlockBytes;

	//prepare to merge data
	uint8* DataDes = static_cast<uint8*>(MergedTexture.PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE));

	double lockTime = FPlatformTime::Seconds();
	UE_LOG(LogTemp, Log, TEXT("[XSJ] Merge single textures lockTime: %f ms."), (lockTime - startMergeTime)*1000.0f);
	
	//add texture data to merged texture according uv transform
	uint8* BulkDataSrc = static_cast<uint8*>(RawBulkData);

	int32 HeightOffset = MergeBlockNumY * Para.UvTransform.GetTranslation().Y;
	int32 WidthOffset = MergeBlockNumX * Para.UvTransform.GetTranslation().X;
	//find start address
	int32 TotalSize = MergedTexture.PlatformData->Mips[0].BulkData.GetBulkDataSize();
	check(TotalSize == MergeBlockNumX * MergeBlockNumY * GPixelFormats[Para.NewFormat].BlockBytes)

	int32 CopyOffset = (MergeBlockNumX * HeightOffset + WidthOffset) * GPixelFormats[Para.NewFormat].BlockBytes;
	DataDes += CopyOffset;
	for (int32 HeiBlockIndex = 0; HeiBlockIndex < HeightBlockNum; ++HeiBlockIndex)
	{
		//copy per 4*4 block directly
		if (InFormat == Para.NewFormat)
		{
			check(TotalSize >= CopyOffset + BitSize);
			FMemory::Memcpy(DataDes, BulkDataSrc, BitSize);
			DataDes += MergedRowSize;
			CopyOffset += MergedRowSize;

			BulkDataSrc += BitSize;
		}
		//copy RGB copy per 4*4 block & Set Alpha to default
		//for newformat is RGBA ,informat is RGB
		else
		{
			//merge alpha to texture without alpha
			check((InFormat == EPixelFormat::PF_ETC2_RGB &&Para.NewFormat == EPixelFormat::PF_ETC2_RGBA) ||
				(InFormat == EPixelFormat::PF_DXT1 &&Para.NewFormat == EPixelFormat::PF_DXT5) ||
				(InFormat == EPixelFormat::PF_BC4 &&Para.NewFormat == EPixelFormat::PF_BC4));

			for (int32 XBIndex = 0; XBIndex < BlockNum; ++XBIndex)
			{
				check(TotalSize >= CopyOffset + Para.DefaultAlphaSize);
				FMemory::Memcpy(DataDes, Para.DefaultAlphaData->GetData(), Para.DefaultAlphaSize);
				DataDes += Para.DefaultAlphaSize;
				CopyOffset += Para.DefaultAlphaSize;

				check(TotalSize >= CopyOffset + GPixelFormats[InFormat].BlockBytes);
				FMemory::Memcpy(DataDes, BulkDataSrc, GPixelFormats[InFormat].BlockBytes);
				DataDes += GPixelFormats[InFormat].BlockBytes;
				CopyOffset += GPixelFormats[InFormat].BlockBytes;

				BulkDataSrc += GPixelFormats[InFormat].BlockBytes;
			}

			DataDes -= BitSize;
			CopyOffset -= BitSize;
			DataDes += MergedRowSize;
			CopyOffset += MergedRowSize;
		}

	}

	double CopyMemoryTime = FPlatformTime::Seconds();
	UE_LOG(LogTemp, Log, TEXT("[XSJ] Merge single textures CopyMemoryTime: %f ms."), (CopyMemoryTime - lockTime)*1000.0f);

	MergedTexture.PlatformData->Mips[0].BulkData.Unlock();
	//MergedTexture.UpdateResource();

	InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData.Unlock();

	double Unlocktime = FPlatformTime::Seconds();
	UE_LOG(LogTemp, Log, TEXT("[XSJ] Merge single textures Unlocktime: %f ms."), (Unlocktime - CopyMemoryTime)*1000.0f);
}

void FCookedTextureMerge::AddDataToMergedTextureTiling(UTexture2D* InTetxture, UTexture2D& MergedTexture, FMergeTexturePara& Para)
{
	//resolution of body is bigger, so we use next mipmap
	int32 SrcOverrideQuality = Para.SrcMipIndex;
	//can not find available mipf
	if (SrcOverrideQuality < 0)
	{
		//don't crash here
		UE_LOG(LogTextureMerge, Error, TEXT("Can not Find MipMap Level, Texture Path: %s"), *InTetxture->GetPathName());
		return;
	}

	int32 SizeX = InTetxture->PlatformData->Mips[SrcOverrideQuality].SizeX;
	int32 SizeY = InTetxture->PlatformData->Mips[SrcOverrideQuality].SizeY;

	int32 MergedSizeX = MergedTexture.PlatformData->Mips[0].SizeX;
	int32 MergedSizeY = MergedTexture.PlatformData->Mips[0].SizeY;

	EPixelFormat InFormat = InTetxture->PlatformData->PixelFormat;
	FByteBulkData& BulkData = InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData;
	int32 BulkSize = BulkData.GetBulkDataSize();
	void* RawBulkData = InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData.Lock(LOCK_READ_ONLY);

	int32 BlockXDim = GPixelFormats[Para.NewFormat].BlockSizeX;
	int32 BlockYDim = GPixelFormats[Para.NewFormat].BlockSizeY;

	UE_LOG(LogTemp, Warning, TEXT("[XSJ] Merged textures format :%d."), (int)Para.NewFormat);
	UE_LOG(LogTemp, Warning, TEXT("[XSJ] Merged In textures format :%d."), (int)InFormat);

	//for pixel block 4 * 4
	int32 MergeBlockNumX = MergedSizeX / BlockXDim;
	int32 MergeBlockNumY = MergedSizeY / BlockYDim;

	int32 BlockNum = SizeX / BlockXDim;
	int32 HeightBlockNum = SizeY / BlockYDim;
	int32 BitSize = BlockNum * GPixelFormats[Para.NewFormat].BlockBytes;

	int32 MergedRowSize = MergeBlockNumX * GPixelFormats[Para.NewFormat].BlockBytes;

	int32 TotalSize = MergedTexture.PlatformData->Mips[0].BulkData.GetBulkDataSize();

	check(TotalSize == MergeBlockNumX * MergeBlockNumY * GPixelFormats[Para.NewFormat].BlockBytes);

	//prepare to merge data
	uint8* DataDes = static_cast<uint8*>(MergedTexture.PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE));

	//add texture data to merged texture according uv transform
	uint8* BulkDataSrc = static_cast<uint8*>(RawBulkData);

	int32 HeightOffset = 0;
	int32 WidthOffset = 0;

	HeightOffset = MergeBlockNumY * Para.UvTransform.GetTranslation().Y;
	WidthOffset = MergeBlockNumX * Para.UvTransform.GetTranslation().X;
	int32 SizeOffset = (MergeBlockNumX * HeightOffset + WidthOffset) * GPixelFormats[Para.NewFormat].BlockBytes;
	
	DataDes += SizeOffset;

	/*face 1/2 merged size*/
	for (int32 HeiBlockIndex = 0; HeiBlockIndex < HeightBlockNum; ++HeiBlockIndex)
	{
		//copy per 4 * 4 block directly
		if (InFormat == Para.NewFormat)
		{
			check(TotalSize >= SizeOffset + BitSize)
			FMemory::Memcpy(DataDes, BulkDataSrc, BitSize);
			DataDes += BitSize;
			SizeOffset += BitSize;

			//copy again from uv tile for hull
			check(TotalSize >= SizeOffset + BitSize)
			FMemory::Memcpy(DataDes, BulkDataSrc, BitSize);
			DataDes += BitSize;
			SizeOffset += BitSize;

			BulkDataSrc += BitSize;
		}
		//copy RGB copy per 4 * 4 block & Set Alpha to default
		//for newformat is RGBA, informat is RGB
		else
		{
			//merge alpha to texture without alpha
			check((InFormat == EPixelFormat::PF_ETC2_RGB &&Para.NewFormat == EPixelFormat::PF_ETC2_RGBA) ||
				(InFormat == EPixelFormat::PF_DXT1 &&Para.NewFormat == EPixelFormat::PF_DXT5) ||
				(InFormat == EPixelFormat::PF_BC4 &&Para.NewFormat == EPixelFormat::PF_BC4));

			for (int32 XBIndex = 0; XBIndex < BlockNum; ++XBIndex)
			{
				check(TotalSize >= SizeOffset + Para.DefaultAlphaSize)
				FMemory::Memcpy(DataDes, Para.DefaultAlphaData->GetData(), Para.DefaultAlphaSize);
				DataDes += Para.DefaultAlphaSize;
				SizeOffset += Para.DefaultAlphaSize;

				check(TotalSize >= SizeOffset + Para.DefaultAlphaSize)
				FMemory::Memcpy(DataDes, BulkDataSrc, GPixelFormats[InFormat].BlockBytes);
				DataDes += GPixelFormats[InFormat].BlockBytes;
				SizeOffset += Para.DefaultAlphaSize;

				BulkDataSrc += GPixelFormats[InFormat].BlockBytes;
			}

			BulkDataSrc -= BlockNum * GPixelFormats[InFormat].BlockBytes;

			//copy again from uv tile for hull
			for (int32 XBIndex = 0; XBIndex < BlockNum; ++XBIndex)
			{
				check(TotalSize >= SizeOffset + Para.DefaultAlphaSize)
				FMemory::Memcpy(DataDes, Para.DefaultAlphaData->GetData(), Para.DefaultAlphaSize);
				DataDes += Para.DefaultAlphaSize;
				SizeOffset += Para.DefaultAlphaSize;

				check(TotalSize >= SizeOffset + GPixelFormats[InFormat].BlockBytes)
				FMemory::Memcpy(DataDes, BulkDataSrc, GPixelFormats[InFormat].BlockBytes);
				DataDes += GPixelFormats[InFormat].BlockBytes;
				SizeOffset += GPixelFormats[InFormat].BlockBytes;

				BulkDataSrc += GPixelFormats[InFormat].BlockBytes;
			}

		}

	}

	MergedTexture.PlatformData->Mips[0].BulkData.Unlock();
	MergedTexture.UpdateResource();

	InTetxture->PlatformData->Mips[SrcOverrideQuality].BulkData.Unlock();
}

int32 FCookedTextureMerge::GetMipIndexFromSource(UTexture2D* InTetxture, FTransform& UvTransform, UTexture2D& MergedTexture)
{
	int32 MergedSizeX = MergedTexture.PlatformData->Mips[0].SizeX;
	int32 MergedSizeY = MergedTexture.PlatformData->Mips[0].SizeY;

	int32 ReturnMipLevel = -1;

	for (int32 MipIndex = 0; MipIndex < InTetxture->PlatformData->Mips.Num(); ++MipIndex)
	{
		if (InTetxture->PlatformData->Mips[MipIndex].SizeX == MergedSizeX * UvTransform.GetScale3D().X && InTetxture->PlatformData->Mips[MipIndex].SizeY == MergedSizeY * UvTransform.GetScale3D().Y)
		{
			ReturnMipLevel = MipIndex;
		}

		if (ReturnMipLevel >= 0)
		{
			break;
		}
	}

	return ReturnMipLevel;
}

void FCookedTextureMerge::ClearDataToMergedTexture(UTexture2D& MergedTexture, FClearTexturePara& Para)
{
	int32 MergedSizeX = MergedTexture.PlatformData->Mips[0].SizeX;
	int32 MergedSizeY = MergedTexture.PlatformData->Mips[0].SizeY;
	int32 MergeBlockNumX = MergedSizeX / 4;
	int32 MergeBlockNumY = MergedSizeY / 4;

	int32 RectBlockX = MergeBlockNumX * Para.UvTransform.GetScale3D().X;
	int32 RectBlockY = MergeBlockNumY * Para.UvTransform.GetScale3D().X;

	int32 HeightOffset = MergeBlockNumY * Para.UvTransform.GetTranslation().Y;
	int32 WidthOffset = MergeBlockNumX * Para.UvTransform.GetTranslation().X;

	//prepare to merge data
	uint8* DataDes = static_cast<uint8*>(MergedTexture.PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE));

	int32 TotalSize = MergedTexture.PlatformData->Mips[0].BulkData.GetBulkDataSize();
	check(TotalSize == MergeBlockNumX * MergeBlockNumY * GPixelFormats[Para.NewFormat].BlockBytes);

	//find start address
	int32 SizeOffSet = (MergeBlockNumX * HeightOffset + WidthOffset) * GPixelFormats[Para.NewFormat].BlockBytes;
	DataDes += SizeOffSet;
	for (int32 HeightIndex = 0; HeightIndex < RectBlockY; ++HeightIndex)
	{
		for (int32 WidthIndex = 0; WidthIndex < RectBlockX; ++WidthIndex)
		{
			check(TotalSize >= SizeOffSet + Para.DefaultColorize);
			FMemory::Memcpy(DataDes, Para.DefaultColorData->GetData(), Para.DefaultColorize);
			DataDes += Para.DefaultColorize;
			SizeOffSet += Para.DefaultColorize;

			//empty with alpha
			if (Para.NewFormat == EPixelFormat::PF_DXT5 || Para.NewFormat == EPixelFormat::PF_ETC2_RGBA || Para.NewFormat == EPixelFormat::PF_BC5)
			{
				check(TotalSize >= SizeOffSet + Para.DefaultColorize);
				FMemory::Memcpy(DataDes, Para.DefaultColorData->GetData(), Para.DefaultColorize);
				DataDes += Para.DefaultColorize;
				SizeOffSet += Para.DefaultColorize;
			}
		}

		DataDes -= RectBlockX * GPixelFormats[Para.NewFormat].BlockBytes;
		SizeOffSet -= RectBlockX * GPixelFormats[Para.NewFormat].BlockBytes;
		DataDes += MergeBlockNumX * GPixelFormats[Para.NewFormat].BlockBytes;
		SizeOffSet += MergeBlockNumX * GPixelFormats[Para.NewFormat].BlockBytes;
	}

	MergedTexture.PlatformData->Mips[0].BulkData.Unlock();
	MergedTexture.UpdateResource();
}
