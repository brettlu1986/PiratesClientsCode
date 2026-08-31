// Fill out your copyright notice in the Description page of Project Settings.

#include "GameCameraShotShell.h"
#include "Client.h"
#include "ClientShell.h"
#include "GamePlatformMisc.h"
#include "Misc/FileHelper.h"
#include "ImageUtils.h"
#include "Modules/ModuleManager.h"
#include "IImageWrapperModule.h"
#include "IImageWrapper.h"

static void OnRequestScreenshotCmdExecuted(const TArray<FString>& Args)
{
    UGameCameraShotShell* ShellPtr = UClientShell::GetClient(GWorld)->GetCameraShotShell();
    if (ShellPtr)
	{
		bool bInShowUI = Args.IsValidIndex(0) ? Args[0].ToBool() : true;
		bool bInImmediatelySave = Args.IsValidIndex(1) ? Args[1].ToBool() : true;
		const FString& InScreenshotFilename = Args.IsValidIndex(2) ? Args[2] : TEXT("");
		bool bInJPEGFormat = Args.IsValidIndex(3) ? Args[3].ToBool() : true;
		float InScreenshotScale = Args.IsValidIndex(4) ? FCString::Atof(*Args[4]) : 1.f;
		ShellPtr->RequestScreenshot(bInShowUI, bInImmediatelySave, InScreenshotFilename, bInJPEGFormat, InScreenshotScale);
    }
}

static FAutoConsoleCommand RequestScreenshotCmd(
    TEXT("RequestScreenshot"),
    TEXT("RequestScreenshot <bShowUI=1> <bImmediatelySave=1> <ScreenshotFileName=\"\"> <bJPEGFormat=1> <ScreenshotScale=1.0>"),
    FConsoleCommandWithArgsDelegate::CreateStatic(&OnRequestScreenshotCmdExecuted)
);

void UGameCameraShotShell::RequestScreenshot(bool bInShowUI, bool bInImmediatelySave, FString InScreenshotFilename, bool bInJPEGFormat, float InScreenshotScale)
{
	bImmediatelySave = bInImmediatelySave;
	ScreenshotFilename = InScreenshotFilename;
	bJPEGFormat = bInJPEGFormat;
	ScreenshotScale = InScreenshotScale;

	UGameViewportClient::OnScreenshotCaptured().AddUObject(this, &UGameCameraShotShell::OnScreenshotCaptured);
    FScreenshotRequest::RequestScreenshot(bInShowUI);
}

void UGameCameraShotShell::OnScreenshotCaptured(int32 InWidth, int32 InHeight, const TArray<FColor>& InColors)
{
	UGameViewportClient::OnScreenshotCaptured().RemoveAll(this);

	LastCapturedWidth = InWidth;
	LastCapturedHeight = InHeight;
	LastCapturedColors = InColors;

	if (ScreenshotFilename.IsEmpty())
	{
		ScreenshotFilename = FScreenshotRequest::GetFilename();
	}
	else
	{
		ScreenshotFilename = GetDefault<UEngine>()->GameScreenshotSaveDirectory.Path / ScreenshotFilename;
	}

	if (bImmediatelySave)
	{
		SaveScreenshot();
	}

    if (ScreenshotCaptureFinishedDelegate.IsBound())
	{
		UTexture2D* ScreenshotTexture = CreateTexture2D(InWidth, InHeight, InColors);
        ScreenshotCaptureFinishedDelegate.Broadcast(InWidth, InHeight, ScreenshotTexture);
    }
}

UTexture2D* UGameCameraShotShell::CreateTexture2D(int32 InWidth, int32 InHeight, const TArray<FColor>& InColors)
{
	// Create the texture
	UTexture2D* ReturnTexture = UTexture2D::CreateTransient(InWidth, InHeight, PF_B8G8R8A8);

	// Lock the checkerboard texture so it can be modified
	//FColor* MipData = static_cast<FColor*>(ReturnTexture->PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE));
	FTexture2DMipMap& Mip = ReturnTexture->PlatformData->Mips[0];
	void* MipData = Mip.BulkData.Lock(LOCK_READ_WRITE);

	check(InColors.Num() * sizeof(FColor) == Mip.BulkData.GetBulkDataSize());
	FMemory::Memcpy(MipData, InColors.GetData(), Mip.BulkData.GetBulkDataSize());
	Mip.BulkData.Unlock();
	ReturnTexture->UpdateResource();

	return ReturnTexture;
}

void UGameCameraShotShell::SaveScreenshot()
{
	ReturnIfFalse(LastCapturedColors.Num() > 0);

	// Resize
	int32 Width = LastCapturedWidth;
	int32 Height = LastCapturedHeight;
	TArray<FColor> UncompressedBitmap;
	if ((ScreenshotScale < 1.f) && (ScreenshotScale > 0))
	{
		Width = Width * ScreenshotScale;
		Height = Height * ScreenshotScale;
		FImageUtils::ImageResize(LastCapturedWidth, LastCapturedHeight, LastCapturedColors, Width, Height, UncompressedBitmap, false);
	}
	else
	{
		UncompressedBitmap = LastCapturedColors;
	}

	// Compress And Save
#if PLATFORM_ANDROID || PLATFORM_IOS
	TArray<uint8> CompressedBitmap;
	FImageUtils::CompressImageArray(Width, Height, UncompressedBitmap, CompressedBitmap);
	FGamePlatformMisc::SaveBitMapFile(CompressedBitmap);
#else
	TArray<uint8> CompressedBitmap;
	if (bJPEGFormat)
	{
		CompressBitmapToJPEG(Width, Height, UncompressedBitmap, CompressedBitmap);
	}
	else
	{
		FImageUtils::CompressImageArray(Width, Height, UncompressedBitmap, CompressedBitmap);
	}
	FFileHelper::SaveArrayToFile(CompressedBitmap, *ScreenshotFilename);
#endif

	// Reset
	LastCapturedWidth = 0;
	LastCapturedHeight = 0;
	LastCapturedColors.Empty();
}

void UGameCameraShotShell::CompressBitmapToJPEG(int32 InWidth, int32 InHeight, const TArray<FColor>& InUncompressedColors, TArray<uint8>& OutCompressedData)
{
	IImageWrapperModule* ImageWrapperModule = FModuleManager::GetModulePtr<IImageWrapperModule>(FName("ImageWrapper"));
	ReturnIfNullptr(ImageWrapperModule);

	// TArray<FColor> to TArray<uint8>
	TArray<uint8> UncompressedData;
	int32 MemorySize = InWidth * InHeight * sizeof(FColor);
	UncompressedData.AddUninitialized(MemorySize);
	FMemory::Memcpy(UncompressedData.GetData(), InUncompressedColors.GetData(), MemorySize);

	// Compress
	TSharedPtr<IImageWrapper> ImageWrapper = ImageWrapperModule->CreateImageWrapper(EImageFormat::JPEG);
	ImageWrapper->SetRaw(&UncompressedData[0], UncompressedData.Num(), InWidth, InHeight, ERGBFormat::BGRA, 8);
	OutCompressedData = ImageWrapper->GetCompressed();
}