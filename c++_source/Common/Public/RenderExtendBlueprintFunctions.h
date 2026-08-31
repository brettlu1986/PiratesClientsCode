// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "RenderExtendBlueprintFunctions.generated.h"

UENUM()
enum EPerformanceLevel
{
	EPerformanceLow,
	EPerformanceMedium,
	EPerformanceHigh,
};

UCLASS()
class COMMON_API URenderExtendBlueprintFunctions : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
    /**
    * 读取UI渲染角色和船只时使用的伽马值
    */
    UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
    static float GetSceneCapturingGamma();
	
    UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
    static void ShowSceneCaptureFog(class USceneCaptureComponent* Capture, bool bShowFlag);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static int GetDevicePerformanceLevel();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool IsPlanarReflectShip();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool GetMobileHDR();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static int GetFeatureLevel();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static FString GetWorldLogicName();

    UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
    static int GetShadowQuality();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool GetEnableReflectionInstancedOptimization();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static void SetEnableReflectionInstancedOptimization(bool bEnable);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static float GetActorScreenPercent(AActor* actor);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static float GetComponentScreenPercent(USceneComponent* component);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static void SaveAsTextureAsset(UObject* Object, FString PackageName);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static void SaveRenderTargetAsTextureAsset(UTextureRenderTarget2D* RenderTarget, FString PackageName);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static UTexture2D* ConvertRenderTarget(UTextureRenderTarget2D* RenderTarget, float Base, float Range);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static void CreateScannerMeshVertexes(float Angle, float Radius, float InnerRadius, int Sections, float EdgeThinkness, TArray<FVector>& Positions, TArray<int>& Triangles, TArray<FVector2D>& UVs, TArray<FLinearColor>& VertexColors);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static void CreateScanRegionMeshVertexes(float Angle, float Radius, float InnerRadius, int Sections, float EdgeThinkness, TArray<FVector>& Positions, TArray<int>& Triangles, TArray<FVector2D>& UVs, TArray<FLinearColor>& VertexColors);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static void CreateShipWakeMaskMeshVertexes(int RTSize, float RegionSize, float FadeDistance, TArray<FVector>& Positions, TArray<int>& Triangles, TArray<FVector2D>& UVs, TArray<FLinearColor>& VertexColors);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool IsASTCSupport();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool IsReachMinimumRequirements();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static FString GetDeviceModel();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static FString GetGPUFamily();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static FString GetGLVersion();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static FString GetDeviceMake();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static FString GetOSVersion();

	// %.2fMB
	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static float GetPhysicalMemory();

	// %dGB approx
	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static float GetPhysicalMemoryApprox();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static void ReleaseSkeletonMeshCPUResources(class USkeletalMesh* SkeletalMesh);

    /**
    * wrapper function for queuing a calling of free unused resource of render target pool to rendering thread
    * memory optimization, render target pool
    * liujun
    */
    static void ReleaseUnusedRenderTargetPool();

	/**
	* get the scale factor based on the screen percentage cvar
	* liujun
	*/
	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static float GetScreenPercentageScale();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static class UTexture2D* CreateTexture2DFromPngFile(const FString& FilePath);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static UTexture2D* LoadTexture2DFromFile(const FString& ImagePath, int32& OutWidth, int32& OutHeight);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool SaveRenderTarget2DToPng(FString OutputDir, FString FileName, UTextureRenderTarget2D* TextureTarget);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool ImportFileToEdtior(FString FilFulleName, FString DestinationPath);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool SaveDepthRenderTargetToPng(FString OutputDir, FString FileName, UTextureRenderTarget2D* TextureTarget, float Base, float Range);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool SplitOceanRegionMapFromPngFile(const FString& FilePath, int32 Tiles);

	/** As UKismetSystemLibrary::ExecuteConsoleCommand rely on PlayerController, use this interface to execute render cmd */
	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool ExecuteCommand(const FString& Cmd);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool GetCVRIntValue(const FString& ConsoleVariableName, int32& OutValue);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool GetCVRFloatValue(const FString& ConsoleVariableName, float& OutValue);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool SetCVRIntByDeviceProfile(const FString& ConsoleVariableName, int32 NewValue);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool SetCVRFloatByDeviceProfile(const FString& ConsoleVariableName, float NewValue);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool SetCVRIntByScalability(const FString& ConsoleVariableName, int32 NewValue);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool SetCVRFloatByScalability(const FString& ConsoleVariableName, float NewValue);

	/** Convert XFOV To YFOV */
	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static float ConvertXFOVToYFOV(UObject* WorldContextObject, float XFOV, float AspectRatio);

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool GetShadowCacheEnabled();

	UFUNCTION(BlueprintCallable, Category = "Pirate Render Function")
	static bool SetShadowCacheEnabled(bool bEnable);

};