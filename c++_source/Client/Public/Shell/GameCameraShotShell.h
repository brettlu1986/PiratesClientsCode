#pragma once

#include "CoreMinimal.h"
#include "GameCameraShotShell.generated.h"

UCLASS()
class CLIENT_API UGameCameraShotShell : public UObject
{
	GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable)
	void RequestScreenshot(bool bInShowUI = true, bool bInImmediatelySave = true, FString InScreenshotFilename = TEXT(""), bool bInJPEGFormat = false, float InScreenshotScale = 1.f);

	UFUNCTION(BlueprintCallable)
	void SaveScreenshot();

protected:
	UTexture2D* CreateTexture2D(int32 InWidth, int32 InHeight, const TArray<FColor>& InColors);
	void OnScreenshotCaptured(int32 InWidth, int32 InHeight, const TArray<FColor>& InColors);
	void CompressBitmapToJPEG(int32 InWidth, int32 InHeight, const TArray<FColor>& InUncompressedColors, TArray<uint8>& OutCompressedData);

public:
	DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnScreenshotCaptureFinished, int32, Width, int32, Height, UTexture2D*, ScreenshotTexture);
    UPROPERTY(BlueprintAssignable)
	FOnScreenshotCaptureFinished ScreenshotCaptureFinishedDelegate;

protected:
	bool bImmediatelySave;
	FString ScreenshotFilename;
	bool bJPEGFormat;
	float ScreenshotScale;

	int32 LastCapturedWidth;
	int32 LastCapturedHeight;
	TArray<FColor> LastCapturedColors;
};