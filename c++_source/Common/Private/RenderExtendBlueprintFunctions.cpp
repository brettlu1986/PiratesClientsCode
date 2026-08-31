#include "RenderExtendBlueprintFunctions.h"
#include "Common.h"
#include "Engine/SkeletalMesh.h"
#include "Components/SceneCaptureComponent.h"

#if WITH_EDITOR
#include "ImageUtils.h"
#include "HAL/FileManagerGeneric.h"  
#include "IImageWrapper.h"    
#include "IImageWrapperModule.h"
#include "AssetToolsModule.h"
#include "FileHelpers.h"
#endif

DECLARE_LOG_CATEGORY_CLASS(RenderExtendBlueprintLog, Log, All);

#define CONSOLEVAR_ANDROID_DISABLEASTCSUPPORT TEXT("r.Android.DisableASTCSupport")
#define CONSOLEVAR_SHADOWCACHE TEXT("xsj.Mobile.StaticPrimitivesCSMCache")

int32 DevicePerformanceLevel = EPerformanceHigh;
FAutoConsoleVariableRef CVarPerformanceLevel(
    TEXT("r.PerformanceLevel"),
    DevicePerformanceLevel,
    TEXT("Device performance level. Ex: iphone7 is high, iphone 6 is medium;")
);

/**
* UI渲染角色和船只时使用的伽马值，见BP_RenderActor
*/
static TAutoConsoleVariable<float> CVarCaptureSceneWithGamma(
    TEXT("r.SceneCapturingGamma"),
    1.0,
    TEXT("The gamma used in scene capturing."),
    ECVF_ReadOnly
);
/**
* Planar reflect ship
*/
int32 PlanarReflectShip = 1;
FAutoConsoleVariableRef CVarPlanarReflectShip(
	TEXT("r.PlanarReflectShip"),
	PlanarReflectShip,
	TEXT("Planar reflect ship or not")
);
/**
* 用于按DeviceProfile设置不同取值
* 跳伞落地后将此值传送给xsj.LevelLODDistanceScale
*/
static TAutoConsoleVariable<float> CPirLevelLODDistanceScale(
	TEXT("pir.LevelLODDistanceScale"),
	1.0,
	TEXT("[Pir] User controlled level lod distance scale.")
);

/**
* 用于按DeviceProfile设置不同取值
* 加速跑降分辨率的比值 (0,1]
*/
static TAutoConsoleVariable<float> CPirHighSpeedScreenPercentageScale(
    TEXT("pir.HighSpeedScreenPercentageScale"),
    0.9,
    TEXT("[Pir] High Speed ScreenPercentage Scale.")
);


/**
*通过consolevarible实时开关postprocessing
*/
static TAutoConsoleVariable<int32> CVarXSJMERenderingEnablePostProcessing(
	TEXT("pir.EnablePostProcessing"),
	1,
	TEXT("1 to enable post processing pass\n0 to disable post processing pass"),
	ECVF_Scalability | ECVF_RenderThreadSafe
);
static void OnCVarXSJEnablePPSink()
{
	static int32 XSJEnablePostProcessing = 1;
	auto PostProcessingCVar = IConsoleManager::Get().FindConsoleVariable(TEXT("pir.EnablePostProcessing"));
	int32 NewEnablePostProcessing = PostProcessingCVar->GetInt();
	if (XSJEnablePostProcessing != NewEnablePostProcessing)
	{
		XSJEnablePostProcessing = NewEnablePostProcessing;

		if (GEngine && GEngine->GameViewport)
		{
			int32 FlagIndex = FEngineShowFlags::FindIndexByName(TEXT("PostProcessing"));

			if (FlagIndex != -1)
			{
				GEngine->GameViewport->EngineShowFlags.SetSingleFlag(FlagIndex, XSJEnablePostProcessing > 0 );
			}
		}

	}
};

static FAutoConsoleVariableSink CVarXSJEnablePPSink(FConsoleCommandDelegate::CreateStatic(&OnCVarXSJEnablePPSink));

/**
* 读取UI渲染角色和船只时使用的伽马值
*/
float URenderExtendBlueprintFunctions::GetSceneCapturingGamma()
{
    static auto* SceneCaptureGamma = IConsoleManager::Get().FindTConsoleVariableDataFloat(TEXT("r.SceneCapturingGamma"));
    return SceneCaptureGamma->GetValueOnAnyThread();
}

void URenderExtendBlueprintFunctions::ShowSceneCaptureFog(USceneCaptureComponent* Capture, bool bShowFlag)
{
	Capture->ShowFlags.SetFog(bShowFlag);
}

bool URenderExtendBlueprintFunctions::IsPlanarReflectShip()
{
    return PlanarReflectShip > 0;
}

int URenderExtendBlueprintFunctions::GetDevicePerformanceLevel()
{
	return DevicePerformanceLevel;
}

bool URenderExtendBlueprintFunctions::GetMobileHDR()
{
    static auto* MobileHDRCvar = IConsoleManager::Get().FindTConsoleVariableDataInt(TEXT("r.MobileHDR"));
    return MobileHDRCvar->GetValueOnAnyThread() == 1;
}

int URenderExtendBlueprintFunctions::GetFeatureLevel()
{
    check(GWorld != NULL)
        return GWorld->FeatureLevel;
}

FString URenderExtendBlueprintFunctions::GetWorldLogicName()
{
    check(GWorld != NULL)
        FString WorldName = GWorld->GetName();
    FString LogicName;
    FString Prefix, Name;
    if (WorldName.Split(FString("_"), &Prefix, &Name))
    {
        LogicName = Name;
        //FString LastName;
        //if (Name.Split(FString("_"), &Prefix, &LastName))
        //{
        //	LogicName = Prefix;
        //}
    }

    return LogicName;
}

int URenderExtendBlueprintFunctions::GetShadowQuality()
{
    static auto* ShadowQualityCvar = IConsoleManager::Get().FindTConsoleVariableDataInt(TEXT("r.ShadowQuality"));
    return ShadowQualityCvar->GetValueOnAnyThread();
}

bool URenderExtendBlueprintFunctions::GetEnableReflectionInstancedOptimization()
{
	static IConsoleVariable* EnableReflectionInstancedCvar = IConsoleManager::Get().FindConsoleVariable(TEXT("r.EnableReflectionInstancedOptimization"));
	check(EnableReflectionInstancedCvar != nullptr)
    return EnableReflectionInstancedCvar->GetInt() >= 1;
}

void URenderExtendBlueprintFunctions::SetEnableReflectionInstancedOptimization(bool bEnable)
{
	static IConsoleVariable* EnableReflectionInstancedCvar = IConsoleManager::Get().FindConsoleVariable(TEXT("r.EnableReflectionInstancedOptimization"));
	check(EnableReflectionInstancedCvar != nullptr)
	EnableReflectionInstancedCvar->Set(bEnable ? 1 : 0);
}

float URenderExtendBlueprintFunctions::GetActorScreenPercent(AActor* actor)
{
    if ((NULL == actor) || (NULL == GEngine) || (NULL == GEngine->GetFirstLocalPlayerController(GWorld)))
        return 1.0f;

    FVector CamLoc = GEngine->GetFirstLocalPlayerController(GWorld)->PlayerCameraManager->GetCameraLocation();
    float CamFOV = GEngine->GetFirstLocalPlayerController(GWorld)->PlayerCameraManager->GetFOVAngle();
    float BoundingRadius = actor->GetRootComponent()->Bounds.SphereRadius;
    float DistanceToObject = FVector(actor->GetActorLocation() - CamLoc).Size();

    return BoundingRadius / (DistanceToObject * FMath::Tan(FMath::DegreesToRadians(CamFOV * 0.5f)));
}

float URenderExtendBlueprintFunctions::GetComponentScreenPercent(USceneComponent* component)
{
    if ((NULL == component) || (NULL == GEngine) || (NULL == GEngine->GetFirstLocalPlayerController(GWorld)))
        return 1.0f;

    FVector CamLoc = GEngine->GetFirstLocalPlayerController(GWorld)->PlayerCameraManager->GetCameraLocation();
    float CamFOV = GEngine->GetFirstLocalPlayerController(GWorld)->PlayerCameraManager->GetFOVAngle();
    float BoundingRadius = component->Bounds.SphereRadius;
    float DistanceToObject = FVector(component->GetComponentLocation() - CamLoc).Size();

    return BoundingRadius / (DistanceToObject * FMath::Tan(FMath::DegreesToRadians(CamFOV * 0.5f)));

}

void URenderExtendBlueprintFunctions::SaveAsTextureAsset(UObject* Object, FString PackageName)
{
#if WITH_EDITOR

    FString ResultFilename;

    if (!FPackageName::TryConvertLongPackageNameToFilename(PackageName, ResultFilename, FPackageName::GetAssetPackageExtension()))
    {
        return;
    }

    UTexture2D* SrcTexture = Cast<UTexture2D>(Object);
    if (SrcTexture != NULL)
    {
        UPackage* Package = CreatePackage(NULL, *PackageName);
        check(Package != NULL);
        Package->FullyLoad();
        Package->Modify();

        FCreateTexture2DParameters texParams;
        texParams.bDeferCompression = SrcTexture->DeferCompression;
        texParams.bSRGB = SrcTexture->SRGB;
        texParams.bUseAlpha = SrcTexture->HasAlphaChannel();
        texParams.CompressionSettings = SrcTexture->CompressionSettings;

        TArray<FColor> ColorToSave;
        ColorToSave.SetNum(SrcTexture->GetSizeX() * SrcTexture->GetSizeY(), false);

        TArray64<uint8> SrcMipData;
        SrcTexture->Source.GetMipData(SrcMipData, 0);
        for (int32 y = 0; y < SrcTexture->GetSizeY(); y++)
        {
            uint8* SrcPtr = &SrcMipData[(SrcTexture->GetSizeY() - 1 - y) * SrcTexture->GetSizeX() * sizeof(FColor)];
            FColor* DestPtr = const_cast<FColor*>(&ColorToSave[(SrcTexture->GetSizeY() - 1 - y) * SrcTexture->GetSizeX()]);
            for (int32 x = 0; x < SrcTexture->GetSizeX(); x++)
            {
                DestPtr->B = *SrcPtr++;
                DestPtr->G = *SrcPtr++;
                DestPtr->R = *SrcPtr++;

                if (SrcTexture->HasAlphaChannel())
                {
                    DestPtr->A = *SrcPtr++;
                }
                else
                {
                    DestPtr->A = 0xFF;
                    SrcPtr++;
                }
                DestPtr++;
            }
        }

        EObjectFlags flag = SrcTexture->GetFlags();
        UTexture2D* SaveTexture = FImageUtils::CreateTexture2D(SrcTexture->GetSizeX(), SrcTexture->GetSizeY(), ColorToSave, Package, PackageName, flag, texParams);
        SaveTexture->MarkPackageDirty();

        if (Package != NULL)
        {
            FString const PackageFileName = FPackageName::LongPackageNameToFilename(PackageName, FPackageName::GetAssetPackageExtension());
            FSavePackageResultStruct Result = UPackage::Save(Package, SaveTexture, SaveTexture->GetFlags(), *PackageFileName);
        }
    }

#endif
}

void URenderExtendBlueprintFunctions::SaveRenderTargetAsTextureAsset(UTextureRenderTarget2D* RenderTarget, FString PackageName)
{
#if WITH_EDITOR

    FString ResultFilename;

    if (!FPackageName::TryConvertLongPackageNameToFilename(PackageName, ResultFilename, FPackageName::GetAssetPackageExtension()))
    {
        return;
    }

    if (RenderTarget != NULL)
    {
        UPackage* Package = CreatePackage(NULL, *PackageName);
        check(Package != NULL);
        Package->FullyLoad();
        Package->Modify();

        UTexture2D* SaveTexture = RenderTarget->ConstructTexture2D(Package, PackageName, RenderTarget->GetMaskedFlags(), CTF_Default, NULL);

        check(SaveTexture != NULL);
        SaveTexture->UpdateResource();
        SaveTexture->MarkPackageDirty();

        if (Package != NULL)
        {
            FString const PackageFileName = FPackageName::LongPackageNameToFilename(PackageName, FPackageName::GetAssetPackageExtension());
            FSavePackageResultStruct Result = UPackage::Save(Package, SaveTexture, SaveTexture->GetFlags(), *PackageFileName);
        }
    }

#endif
}

UTexture2D* URenderExtendBlueprintFunctions::ConvertRenderTarget(UTextureRenderTarget2D* RenderTarget, float Base, float Range)
{
#if WITH_EDITOR

    if (RenderTarget != NULL)
    {
        FString PackageName("/Game/OceanDepthTexture");
        UPackage* Package = CreatePackage(NULL, *PackageName);
        check(Package != NULL);
        Package->FullyLoad();
        Package->Modify();

        UTexture2D* SaveTexture = RenderTarget->ConstructTexture2D(Package, FString("OceanDepthTexture"), RenderTarget->GetMaskedFlags(), CTF_Default, NULL);


        float HeightmapWidth = RenderTarget->SizeX;
        float HeightmapHeight = RenderTarget->SizeY;

        FFloat16Color* FormatedImageData = (FFloat16Color*)SaveTexture->Source.LockMip(0);

        if (FormatedImageData != NULL)
        {
            for (int i = 0; i < HeightmapWidth * HeightmapHeight; i++)
            {
                FFloat16Color& Pixel16 = FormatedImageData[i];
                float R = Pixel16.R.GetFloat();

                FormatedImageData[i].R = FFloat16(FMath::Clamp((R - Base), 0.0f, Range) / Range);
            }
        }

        SaveTexture->Source.UnlockMip(0);

        check(SaveTexture != NULL);
        SaveTexture->UpdateResource();
        SaveTexture->MarkPackageDirty();

        //if (Package != NULL)
        //{
        //	FString const PackageFileName = FPackageName::LongPackageNameToFilename(PackageName, FPackageName::GetAssetPackageExtension());
        //	FSavePackageResultStruct Result = UPackage::Save(Package, SaveTexture, SaveTexture->GetFlags(), *PackageFileName);
        //}

        return SaveTexture;

    }
#endif

    return NULL;
}

void URenderExtendBlueprintFunctions::CreateScannerMeshVertexes(float Angle, float Radius, float InnerRadius, int Sections, float EdgeThinkness, TArray<FVector>& Positions, TArray<int>& Triangles, TArray<FVector2D>& UVs, TArray<FLinearColor>& VertexColors)
{
    float EdgeAngle = FMath::Asin(EdgeThinkness * 0.5f / Radius) * 2.0f;
    float AnglePerSection = (FMath::DegreesToRadians(Angle) - EdgeAngle * 2.0f) / Sections;
    float EdgeAngleInner = FMath::Asin(EdgeThinkness * 0.5f / (InnerRadius + EdgeThinkness)) * 2.0f;
    float EdgeAngleInnerEdge = FMath::Asin(EdgeThinkness * 0.5f / Radius) * 2.0f;

    // Inner mesh
    for (int i = 0; i < (Sections + 1); i++)
    {
        float InnerAngleBase = -AnglePerSection * Sections * 0.5f;
        FVector InnerPos;
        FVector2D InnerUV;
        FLinearColor InnerColor;

        if (i == 0)
        {
            InnerPos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
        }
        else if (i == Sections)
        {
            InnerPos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
        }
        else
        {
            InnerPos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(InnerAngleBase + AnglePerSection * i);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        }
        InnerPos.Z = 0.0f;

        InnerUV.X = 1.0f;
        InnerUV.Y = i / Sections;

        InnerColor = FLinearColor::Black;

        Positions.Add(InnerPos);
        UVs.Add(InnerUV);
        VertexColors.Add(InnerColor);

        FVector CenterPos;
        FVector2D CenterUV;
        FLinearColor CenterColor;

        FVector Pos;
        FVector2D UV;
        FLinearColor Color;

        if (i == 0)
        {
            Pos.X = Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
            Pos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
        }
        else if (i == Sections)
        {
            Pos.X = Radius * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
            Pos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
        }
        else
        {
            Pos.X = Radius * FMath::Cos(InnerAngleBase + AnglePerSection * i);
            Pos.Y = Radius * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        }
        Pos.Z = 0.0f;

        UV.X = 0.0f;
        UV.Y = i / Sections;

        Color = FLinearColor::Black;

        Positions.Add(Pos);
        UVs.Add(UV);
        VertexColors.Add(Color);
    }

    // Triangles
    for (int i = 0; i < Sections; i++)
    {
        int LeftDown = i * 2;
        int LeftTop = i * 2 + 1;
        int RightDown = (i + 1) * 2;
        int RightTop = (i + 1) * 2 + 1;

        Triangles.Add(LeftDown);
        Triangles.Add(RightDown);
        Triangles.Add(LeftTop);

        Triangles.Add(RightDown);
        Triangles.Add(RightTop);
        Triangles.Add(LeftTop);
    }

    float Base = Positions.Num();

    // Border
    for (int i = 0; i < (Sections + 1); i++)
    {
        float InnerAngleBase = -AnglePerSection * Sections * 0.5f;
        FVector InnerPos;
        FVector2D InnerUV;
        FLinearColor InnerColor;

        InnerPos.X = InnerRadius * FMath::Cos(InnerAngleBase + AnglePerSection * i);
        InnerPos.Y = InnerRadius * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        InnerPos.Z = 0.0f;

        InnerUV.X = 0.0f;
        InnerUV.Y = i / Sections;

        InnerColor = FLinearColor::White;

        Positions.Add(InnerPos);
        UVs.Add(InnerUV);
        VertexColors.Add(InnerColor);

        FVector CenterPos;
        FVector2D CenterUV;
        FLinearColor CenterColor;

        FVector Pos;
        FVector2D UV;
        FLinearColor Color;

        Pos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(InnerAngleBase + AnglePerSection * i);
        Pos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        Pos.Z = 0.0f;

        UV.X = 0.0f;
        UV.Y = i / Sections;

        Color = FLinearColor::White;

        Positions.Add(Pos);
        UVs.Add(UV);
        VertexColors.Add(Color);
    }

    // Triangles
    for (int i = 0; i < Sections; i++)
    {
        int LeftDown = Base + i * 2;
        int LeftTop = Base + i * 2 + 1;
        int RightDown = Base + (i + 1) * 2;
        int RightTop = Base + (i + 1) * 2 + 1;

        Triangles.Add(LeftDown);
        Triangles.Add(RightDown);
        Triangles.Add(LeftTop);

        Triangles.Add(RightDown);
        Triangles.Add(RightTop);
        Triangles.Add(LeftTop);
    }

    Base = Positions.Num();

    FVector Pos;
    FVector2D UV;
    FLinearColor Color;

    // Left left
    Pos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f);
    Pos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f);
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    Pos.X = Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f);
    Pos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f);
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Left right
    Pos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
    Pos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);


    Pos.X = Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
    Pos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    int LeftDown = Base;
    int LeftTop = Base + 1;
    int RightDown = Base + 2;
    int RightTop = Base + 2 + 1;

    Triangles.Add(LeftDown);
    Triangles.Add(RightDown);
    Triangles.Add(LeftTop);

    Triangles.Add(RightDown);
    Triangles.Add(RightTop);
    Triangles.Add(LeftTop);

    Base = Positions.Num();

    // Right left
    Pos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
    Pos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    Pos.X = Radius * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
    Pos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Right right
    Pos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f);
    Pos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f);
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    Pos.X = Radius * FMath::Cos(AnglePerSection * Sections * 0.5f);
    Pos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f);
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    LeftDown = Base;
    LeftTop = Base + 1;
    RightDown = Base + 2;
    RightTop = Base + 2 + 1;

    Triangles.Add(LeftDown);
    Triangles.Add(RightDown);
    Triangles.Add(LeftTop);

    Triangles.Add(RightDown);
    Triangles.Add(RightTop);
    Triangles.Add(LeftTop);
}


void URenderExtendBlueprintFunctions::CreateScanRegionMeshVertexes(float Angle, float Radius, float InnerRadius, int Sections, float EdgeThinkness, TArray<FVector>& Positions, TArray<int>& Triangles, TArray<FVector2D>& UVs, TArray<FLinearColor>& VertexColors)
{
    float EdgeAngle = FMath::Asin(EdgeThinkness * 0.5f / Radius) * 2.0f;
    float AnglePerSection = (FMath::DegreesToRadians(Angle) - EdgeAngle * 2.0f) / Sections;
    float EdgeAngleInner = FMath::Asin(EdgeThinkness * 0.5f / (InnerRadius + EdgeThinkness)) * 2.0f;
    float EdgeAngleInnerEdge = FMath::Asin(EdgeThinkness * 0.5f / Radius) * 2.0f;

    // Inner mesh
    for (int i = 0; i < (Sections + 1); i++)
    {
        float InnerAngleBase = -AnglePerSection * Sections * 0.5f;
        FVector InnerPos;
        FVector2D InnerUV;
        FLinearColor InnerColor;

        if (i == 0)
        {
            InnerPos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
        }
        else if (i == Sections)
        {
            InnerPos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
        }
        else
        {
            InnerPos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(InnerAngleBase + AnglePerSection * i);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        }
        InnerPos.Z = 0.0f;

        InnerUV.X = 1.0f;
        InnerUV.Y = i / Sections;

        InnerColor = FLinearColor::Black;

        Positions.Add(InnerPos);
        UVs.Add(InnerUV);
        VertexColors.Add(InnerColor);

        FVector CenterPos;
        FVector2D CenterUV;
        FLinearColor CenterColor;

        FVector Pos;
        FVector2D UV;
        FLinearColor Color;

        if (i == 0)
        {
            Pos.X = Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
            Pos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
        }
        else if (i == Sections)
        {
            Pos.X = Radius * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
            Pos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
        }
        else
        {
            Pos.X = Radius * FMath::Cos(InnerAngleBase + AnglePerSection * i);
            Pos.Y = Radius * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        }
        Pos.Z = 0.0f;

        UV.X = 0.0f;
        UV.Y = i / Sections;

        Color = FLinearColor::Black;

        Positions.Add(Pos);
        UVs.Add(UV);
        VertexColors.Add(Color);
    }

    // Triangles
    for (int i = 0; i < Sections; i++)
    {
        int LeftDown = i * 2;
        int LeftTop = i * 2 + 1;
        int RightDown = (i + 1) * 2;
        int RightTop = (i + 1) * 2 + 1;

        Triangles.Add(LeftDown);
        Triangles.Add(RightDown);
        Triangles.Add(LeftTop);

        Triangles.Add(RightDown);
        Triangles.Add(RightTop);
        Triangles.Add(LeftTop);
    }

    float Base = Positions.Num();

    // Border
    for (int i = 0; i < (Sections + 1); i++)
    {
        float InnerAngleBase = -AnglePerSection * Sections * 0.5f;
        FVector InnerPos;
        FVector2D InnerUV;
        FLinearColor InnerColor;

        InnerPos.X = InnerRadius * FMath::Cos(InnerAngleBase + AnglePerSection * i);
        InnerPos.Y = InnerRadius * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        InnerPos.Z = 0.0f;

        InnerUV.X = 0.0f;
        InnerUV.Y = i / Sections;

        InnerColor = FLinearColor::White;

        Positions.Add(InnerPos);
        UVs.Add(InnerUV);
        VertexColors.Add(InnerColor);

        FVector CenterPos;
        FVector2D CenterUV;
        FLinearColor CenterColor;

        FVector Pos;
        FVector2D UV;
        FLinearColor Color;

        Pos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(InnerAngleBase + AnglePerSection * i);
        Pos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        Pos.Z = 0.0f;

        UV.X = 0.0f;
        UV.Y = i / Sections;

        Color = FLinearColor::White;

        Positions.Add(Pos);
        UVs.Add(UV);
        VertexColors.Add(Color);
    }

    // Triangles
    for (int i = 0; i < Sections; i++)
    {
        int LeftDown = Base + i * 2;
        int LeftTop = Base + i * 2 + 1;
        int RightDown = Base + (i + 1) * 2;
        int RightTop = Base + (i + 1) * 2 + 1;

        Triangles.Add(LeftDown);
        Triangles.Add(RightDown);
        Triangles.Add(LeftTop);

        Triangles.Add(RightDown);
        Triangles.Add(RightTop);
        Triangles.Add(LeftTop);
    }

    Base = Positions.Num();

    FVector EdgePos;
    FVector2D EdgeUV;
    FLinearColor EdgeColor;

    // Left left
    EdgePos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f);
    EdgePos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::White;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgePos.X = Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f);
    EdgePos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::Black;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    // Left right
    EdgePos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
    EdgePos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::White;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);


    EdgePos.X = Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
    EdgePos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::Black;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    int EdgeLeftDown = Base;
    int EdgeLeftTop = Base + 1;
    int EdgeRightDown = Base + 2;
    int EdgeRightTop = Base + 2 + 1;

    Triangles.Add(EdgeLeftDown);
    Triangles.Add(EdgeRightDown);
    Triangles.Add(EdgeLeftTop);

    Triangles.Add(EdgeRightDown);
    Triangles.Add(EdgeRightTop);
    Triangles.Add(EdgeLeftTop);

    Base = Positions.Num();

    // Right left
    EdgePos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
    EdgePos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::White;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgePos.X = Radius * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
    EdgePos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::Black;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    // Right right
    EdgePos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f);
    EdgePos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::White;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgePos.X = Radius * FMath::Cos(AnglePerSection * Sections * 0.5f);
    EdgePos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::Black;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgeLeftDown = Base;
    EdgeLeftTop = Base + 1;
    EdgeRightDown = Base + 2;
    EdgeRightTop = Base + 2 + 1;

    Triangles.Add(EdgeLeftDown);
    Triangles.Add(EdgeRightDown);
    Triangles.Add(EdgeLeftTop);

    Triangles.Add(EdgeRightDown);
    Triangles.Add(EdgeRightTop);
    Triangles.Add(EdgeLeftTop);


    //-----------------------------------------------------------------------------

    // Inner mesh
    for (int i = 0; i < (Sections + 1); i++)
    {
        float InnerAngleBase = -AnglePerSection * Sections * 0.5f;
        FVector InnerPos;
        FVector2D InnerUV;
        FLinearColor InnerColor;

        if (i == 0)
        {
            InnerPos.X = -(InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
        }
        else if (i == Sections)
        {
            InnerPos.X = -(InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
        }
        else
        {
            InnerPos.X = (InnerRadius + EdgeThinkness) * FMath::Cos(InnerAngleBase + AnglePerSection * i);
            InnerPos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        }
        InnerPos.Z = 0.0f;

        InnerUV.X = 1.0f;
        InnerUV.Y = i / Sections;

        InnerColor = FLinearColor::Black;

        Positions.Add(InnerPos);
        UVs.Add(InnerUV);
        VertexColors.Add(InnerColor);

        FVector CenterPos;
        FVector2D CenterUV;
        FLinearColor CenterColor;

        FVector Pos;
        FVector2D UV;
        FLinearColor Color;

        if (i == 0)
        {
            Pos.X = -Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
            Pos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
        }
        else if (i == Sections)
        {
            Pos.X = -Radius * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
            Pos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
        }
        else
        {
            Pos.X = -Radius * FMath::Cos(InnerAngleBase + AnglePerSection * i);
            Pos.Y = Radius * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        }
        Pos.Z = 0.0f;

        UV.X = 0.0f;
        UV.Y = i / Sections;

        Color = FLinearColor::Black;

        Positions.Add(Pos);
        UVs.Add(UV);
        VertexColors.Add(Color);
    }

    Base = Positions.Num();

    // Triangles
    for (int i = 0; i < Sections; i++)
    {
        int LeftDown = i * 2;
        int LeftTop = i * 2 + 1;
        int RightDown = (i + 1) * 2;
        int RightTop = (i + 1) * 2 + 1;

        Triangles.Add(LeftDown);
        Triangles.Add(LeftTop);
        Triangles.Add(RightDown);

        Triangles.Add(RightDown);
        Triangles.Add(LeftTop);
        Triangles.Add(RightTop);
    }

    Base = Positions.Num();

    // Border
    for (int i = 0; i < (Sections + 1); i++)
    {
        float InnerAngleBase = -AnglePerSection * Sections * 0.5f;
        FVector InnerPos;
        FVector2D InnerUV;
        FLinearColor InnerColor;

        InnerPos.X = -InnerRadius * FMath::Cos(InnerAngleBase + AnglePerSection * i);
        InnerPos.Y = -InnerRadius * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        InnerPos.Z = 0.0f;

        InnerUV.X = 0.0f;
        InnerUV.Y = i / Sections;

        InnerColor = FLinearColor::White;

        Positions.Add(InnerPos);
        UVs.Add(InnerUV);
        VertexColors.Add(InnerColor);

        FVector CenterPos;
        FVector2D CenterUV;
        FLinearColor CenterColor;

        FVector Pos;
        FVector2D UV;
        FLinearColor Color;

        Pos.X = -(InnerRadius + EdgeThinkness) * FMath::Cos(InnerAngleBase + AnglePerSection * i);
        Pos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(InnerAngleBase + AnglePerSection * i);
        Pos.Z = 0.0f;

        UV.X = 0.0f;
        UV.Y = i / Sections;

        Color = FLinearColor::White;

        Positions.Add(Pos);
        UVs.Add(UV);
        VertexColors.Add(Color);
    }

    // Triangles
    for (int i = 0; i < Sections; i++)
    {
        int LeftDown = Base + i * 2;
        int LeftTop = Base + i * 2 + 1;
        int RightDown = Base + (i + 1) * 2;
        int RightTop = Base + (i + 1) * 2 + 1;

        Triangles.Add(LeftDown);
        Triangles.Add(LeftTop);
        Triangles.Add(RightDown);

        Triangles.Add(RightDown);
        Triangles.Add(LeftTop);
        Triangles.Add(RightTop);
    }

    Base = Positions.Num();


    // Left left
    EdgePos.X = -(InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f);
    EdgePos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::White;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgePos.X = -Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f);
    EdgePos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::Black;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    // Left right
    EdgePos.X = -(InnerRadius + EdgeThinkness) * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
    EdgePos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInner);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::White;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);


    EdgePos.X = -Radius * FMath::Cos(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
    EdgePos.Y = Radius * FMath::Sin(-AnglePerSection * Sections * 0.5f + EdgeAngleInnerEdge);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::Black;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgeLeftDown = Base;
    EdgeLeftTop = Base + 1;
    EdgeRightDown = Base + 2;
    EdgeRightTop = Base + 2 + 1;

    Triangles.Add(EdgeLeftDown);
    Triangles.Add(EdgeLeftTop);
    Triangles.Add(EdgeRightDown);

    Triangles.Add(EdgeRightDown);
    Triangles.Add(EdgeLeftTop);
    Triangles.Add(EdgeRightTop);

    Base = Positions.Num();

    // Right left
    EdgePos.X = -(InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
    EdgePos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInner);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::White;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgePos.X = -Radius * FMath::Cos(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
    EdgePos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f - EdgeAngleInnerEdge);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::Black;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    // Right right
    EdgePos.X = -(InnerRadius + EdgeThinkness) * FMath::Cos(AnglePerSection * Sections * 0.5f);
    EdgePos.Y = (InnerRadius + EdgeThinkness) * FMath::Sin(AnglePerSection * Sections * 0.5f);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::White;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgePos.X = -Radius * FMath::Cos(AnglePerSection * Sections * 0.5f);
    EdgePos.Y = Radius * FMath::Sin(AnglePerSection * Sections * 0.5f);
    EdgePos.Z = 0.0f;

    EdgeUV.X = 0.0f;
    EdgeUV.Y = 0.0f;

    EdgeColor = FLinearColor::Black;

    Positions.Add(EdgePos);
    UVs.Add(EdgeUV);
    VertexColors.Add(EdgeColor);

    EdgeLeftDown = Base;
    EdgeLeftTop = Base + 1;
    EdgeRightDown = Base + 2;
    EdgeRightTop = Base + 2 + 1;

    Triangles.Add(EdgeLeftDown);
    Triangles.Add(EdgeLeftTop);
    Triangles.Add(EdgeRightDown);

    Triangles.Add(EdgeRightDown);
    Triangles.Add(EdgeLeftTop);
    Triangles.Add(EdgeRightTop);
}

void URenderExtendBlueprintFunctions::CreateShipWakeMaskMeshVertexes(int RTSize, float RegionSize, float FadeDistance, TArray<FVector>& Positions, TArray<int>& Triangles, TArray<FVector2D>& UVs, TArray<FLinearColor>& VertexColors)
{
    float PixelSize = RegionSize / RTSize;

    // Clamp the FadeDistance
    if ((FadeDistance * 0.5f + PixelSize) > RegionSize * 0.5f)
    {
        FadeDistance = RegionSize * 0.5f - PixelSize;
    }
    else if (FadeDistance < 0.0f)
    {
        FadeDistance = 0.0f;
    }

    FVector Pos;
    FVector2D UV;
    FLinearColor Color;

    // Outside
    // Corner1
    Pos.X = RegionSize * 0.5f;
    Pos.Y = RegionSize * 0.5f;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner2
    Pos.X = -RegionSize * 0.5f;
    Pos.Y = RegionSize * 0.5f;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner3
    Pos.X = -RegionSize * 0.5f;
    Pos.Y = -RegionSize * 0.5f;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner4
    Pos.X = RegionSize * 0.5f;
    Pos.Y = -RegionSize * 0.5f;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Edge
    // Corner1
    Pos.X = RegionSize * 0.5f - PixelSize;
    Pos.Y = RegionSize * 0.5f - PixelSize;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner2
    Pos.X = -RegionSize * 0.5f + PixelSize;
    Pos.Y = RegionSize * 0.5f - PixelSize;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner3
    Pos.X = -RegionSize * 0.5f + PixelSize;
    Pos.Y = -RegionSize * 0.5f + PixelSize;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner4
    Pos.X = RegionSize * 0.5f - PixelSize;
    Pos.Y = -RegionSize * 0.5f + PixelSize;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::White;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Fade
    // Corner1
    Pos.X = RegionSize * 0.5f - PixelSize - FadeDistance;
    Pos.Y = RegionSize * 0.5f - PixelSize - FadeDistance;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner2
    Pos.X = -RegionSize * 0.5f + PixelSize + FadeDistance;
    Pos.Y = RegionSize * 0.5f - PixelSize - FadeDistance;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner3
    Pos.X = -RegionSize * 0.5f + PixelSize + FadeDistance;
    Pos.Y = -RegionSize * 0.5f + PixelSize + FadeDistance;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Corner4
    Pos.X = RegionSize * 0.5f - PixelSize - FadeDistance;
    Pos.Y = -RegionSize * 0.5f + PixelSize + FadeDistance;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Center
    Pos.X = 0.0f;
    Pos.Y = 0.0f;
    Pos.Z = 0.0f;

    UV.X = 0.0f;
    UV.Y = 0.0f;

    Color = FLinearColor::Black;

    Positions.Add(Pos);
    UVs.Add(UV);
    VertexColors.Add(Color);

    // Edge 
    Triangles.Add(0);
    Triangles.Add(4);
    Triangles.Add(1);

    Triangles.Add(4);
    Triangles.Add(5);
    Triangles.Add(1);

    Triangles.Add(2);
    Triangles.Add(1);
    Triangles.Add(5);

    Triangles.Add(5);
    Triangles.Add(6);
    Triangles.Add(2);

    Triangles.Add(2);
    Triangles.Add(6);
    Triangles.Add(3);

    Triangles.Add(6);
    Triangles.Add(7);
    Triangles.Add(3);

    Triangles.Add(3);
    Triangles.Add(7);
    Triangles.Add(0);

    Triangles.Add(7);
    Triangles.Add(4);
    Triangles.Add(0);

    // Fade 
    Triangles.Add(8);
    Triangles.Add(5);
    Triangles.Add(4);

    Triangles.Add(8);
    Triangles.Add(9);
    Triangles.Add(5);

    Triangles.Add(6);
    Triangles.Add(5);
    Triangles.Add(9);

    Triangles.Add(6);
    Triangles.Add(9);
    Triangles.Add(10);

    Triangles.Add(6);
    Triangles.Add(10);
    Triangles.Add(7);

    Triangles.Add(10);
    Triangles.Add(11);
    Triangles.Add(7);

    Triangles.Add(7);
    Triangles.Add(11);
    Triangles.Add(4);

    Triangles.Add(11);
    Triangles.Add(8);
    Triangles.Add(4);

    // Other
    Triangles.Add(9);
    Triangles.Add(8);
    Triangles.Add(12);

    Triangles.Add(9);
    Triangles.Add(12);
    Triangles.Add(10);

    Triangles.Add(12);
    Triangles.Add(11);
    Triangles.Add(10);

    Triangles.Add(12);
    Triangles.Add(8);
    Triangles.Add(11);

}

bool URenderExtendBlueprintFunctions::IsASTCSupport()
{
	// r.Android.DisableASTCSupport
	static IConsoleVariable* DisableASTCSupportCvar = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_ANDROID_DISABLEASTCSUPPORT);
	
	if (DisableASTCSupportCvar != nullptr)
	{
		return DisableASTCSupportCvar->GetInt() < 1;
	}

	return true;
}

bool URenderExtendBlueprintFunctions::IsReachMinimumRequirements()
{
#if PLATFORM_IOS
	auto PlatformMemoryConstants = FPlatformMemory::GetConstants();
	return PlatformMemoryConstants.TotalPhysicalGB > 1;
#else
    return true;
#endif
}

FString URenderExtendBlueprintFunctions::GetDeviceModel()
{
#if PLATFORM_ANDROID
    return FAndroidMisc::FAndroidMisc::GetDeviceModel();
#elif PLATFORM_IOS
    return FIOSPlatformMisc::GetDefaultDeviceProfileName();
#elif PLATFORM_WINDOWS
    return FString(TEXT(""));
#else
    return FString(TEXT(""));
#endif
}

FString URenderExtendBlueprintFunctions::GetGPUFamily()
{
#if PLATFORM_ANDROID
    return FAndroidMisc::FAndroidMisc::GetGPUFamily();
#elif PLATFORM_IOS
    return FString(TEXT(""));
#else
    return FString(TEXT(""));
#endif
}

FString URenderExtendBlueprintFunctions::GetGLVersion()
{
#if PLATFORM_ANDROID
    return FAndroidMisc::FAndroidMisc::GetGLVersion();
#elif PLATFORM_IOS
    return FString(TEXT(""));
#else
    return FString(TEXT(""));
#endif
}

FString URenderExtendBlueprintFunctions::GetDeviceMake()
{
#if PLATFORM_ANDROID
    return FAndroidMisc::FAndroidMisc::GetDeviceMake();
#elif PLATFORM_IOS
    return FString(TEXT("Apple"));
#elif PLATFORM_WINDOWS
    return FString(TEXT("Windows"));
#else
    return FString(TEXT(""));
#endif
}

FString URenderExtendBlueprintFunctions::GetOSVersion()
{
#if PLATFORM_ANDROID
    return FAndroidMisc::FAndroidMisc::GetAndroidVersion();
#elif PLATFORM_IOS
    return FIOSPlatformMisc::GetOSVersion();
#elif PLATFORM_WINDOWS
    return FWindowsPlatformMisc::GetOSVersion();
#else
    return FString(TEXT(""));
#endif
}

float URenderExtendBlueprintFunctions::GetPhysicalMemory()
{
#if PLATFORM_ANDROID
    const FPlatformMemoryConstants& MemoryConstants = FPlatformMemory::GetConstants();
    return float(MemoryConstants.TotalPhysical / 1024.0 / 1024.0);
#elif PLATFORM_IOS
    const FPlatformMemoryConstants& MemoryConstants = FPlatformMemory::GetConstants();
    return float(MemoryConstants.TotalPhysical / 1024.0 / 1024.0 / 1024.0);
#else
    return 0.0f;
#endif
}

float URenderExtendBlueprintFunctions::GetPhysicalMemoryApprox()
{
    const FPlatformMemoryConstants& MemoryConstants = FPlatformMemory::GetConstants();
    return MemoryConstants.TotalPhysicalGB;
}

void URenderExtendBlueprintFunctions::ReleaseSkeletonMeshCPUResources(USkeletalMesh* SkeletalMesh)
{
    if (SkeletalMesh)
    {
        /*ENQUEUE_UNIQUE_RENDER_COMMAND_ONEPARAMETER(
            FreeSkelMeshCPUMem,
            USkeletalMesh*, InSkeletalMesh, SkeletalMesh,
            {
                InSkeletalMesh->ReleaseCPUResources();
            });*/
    }
}
// memory optimization, render target pool
void URenderExtendBlueprintFunctions::ReleaseUnusedRenderTargetPool()
{
    GEngine->Exec(NULL, TEXT("r.FreeUnusedRenderTargetPoolMemory"));
}

float URenderExtendBlueprintFunctions::GetScreenPercentageScale()
{
	auto lCVar = IConsoleManager::Get().FindTConsoleVariableDataFloat(TEXT("r.ScreenPercentage"));
	return lCVar->GetValueOnGameThread() > 0.f ? FMath::Clamp(lCVar->GetValueOnGameThread() / 100.f, 0.f, 1.f) : 1.f;
}

class UTexture2D* URenderExtendBlueprintFunctions::CreateTexture2DFromPngFile(const FString& FilePath)
{
#if WITH_EDITOR
	TArray<uint8> RawFileData;
	UTexture2D* Texture = NULL;
	if (FFileHelper::LoadFileToArray(RawFileData, *FilePath))
	{
		IImageWrapperModule& ImageWrapperModule = FModuleManager::LoadModuleChecked<IImageWrapperModule>(FName("ImageWrapper"));
		TSharedPtr<IImageWrapper> ImageWrapper = ImageWrapperModule.CreateImageWrapper(EImageFormat::PNG);
		if (ImageWrapper.IsValid() && ImageWrapper->SetCompressed(RawFileData.GetData(), RawFileData.Num()))
		{
			TArray64<uint8> UncompressedBGRA;
			if (ImageWrapper->GetRaw(ERGBFormat::BGRA, 8, UncompressedBGRA))
			{
				// Create UTexture
				Texture = UTexture2D::CreateTransient(ImageWrapper->GetWidth(), ImageWrapper->GetHeight(), PF_B8G8R8A8);

				// Fill in the source data from the file  
				void* TextureData = Texture->PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE);
				FMemory::Memcpy(TextureData, UncompressedBGRA.GetData(), UncompressedBGRA.Num());
				Texture->PlatformData->Mips[0].BulkData.Unlock();

				// Update the resource from data.  
				Texture->UpdateResource();
			}
		}
	}
	return Texture;
#endif
	return nullptr;
}

#if WITH_EDITOR
static TSharedPtr<IImageWrapper> GetImageWrapperByExtention(const FString InImagePath)
{
	IImageWrapperModule& ImageWrapperModule = FModuleManager::LoadModuleChecked<IImageWrapperModule>(FName("ImageWrapper"));
	if (InImagePath.EndsWith(".png"))
	{
		return ImageWrapperModule.CreateImageWrapper(EImageFormat::PNG);
	}
	else if (InImagePath.EndsWith(".jpg") || InImagePath.EndsWith(".jpeg"))
	{
		return ImageWrapperModule.CreateImageWrapper(EImageFormat::JPEG);
	}
	else if (InImagePath.EndsWith(".bmp"))
	{
		return ImageWrapperModule.CreateImageWrapper(EImageFormat::BMP);
	}
	else if (InImagePath.EndsWith(".ico"))
	{
		return ImageWrapperModule.CreateImageWrapper(EImageFormat::ICO);
	}
	else if (InImagePath.EndsWith(".exr"))
	{
		return ImageWrapperModule.CreateImageWrapper(EImageFormat::EXR);
	}
	else if (InImagePath.EndsWith(".icns"))
	{
		return ImageWrapperModule.CreateImageWrapper(EImageFormat::ICNS);
	}
	return nullptr;
}
#endif

UTexture2D* URenderExtendBlueprintFunctions::LoadTexture2DFromFile(const FString& ImagePath, int32& OutWidth, int32& OutHeight)
{
#if WITH_EDITOR
	UTexture2D* Texture = nullptr;
	// Not exists
	if (!FPlatformFileManager::Get().GetPlatformFile().FileExists(*ImagePath))
	{
		return nullptr;
	}

	// Load to array fail
	TArray<uint8> CompressedData;
	if (!FFileHelper::LoadFileToArray(CompressedData, *ImagePath))
	{
		return nullptr;
	}

	TSharedPtr<IImageWrapper> ImageWrapper = GetImageWrapperByExtention(ImagePath);
	if (ImageWrapper.IsValid() && ImageWrapper->SetCompressed(CompressedData.GetData(), CompressedData.Num()))
	{
		TArray64<uint8> UncompressedRGBA;
		if (ImageWrapper->GetRaw(ERGBFormat::RGBA, 8, UncompressedRGBA))
		{
			Texture = UTexture2D::CreateTransient(ImageWrapper->GetWidth(), ImageWrapper->GetHeight(), PF_R8G8B8A8);
			if (Texture != nullptr)
			{
				OutWidth = ImageWrapper->GetWidth();
				OutHeight = ImageWrapper->GetHeight();
				void* TextureData = Texture->PlatformData->Mips[0].BulkData.Lock(LOCK_READ_WRITE);
				FMemory::Memcpy(TextureData, UncompressedRGBA.GetData(), UncompressedRGBA.Num());
				Texture->PlatformData->Mips[0].BulkData.Unlock();
				Texture->UpdateResource();
			}
		}
	}
	return Texture;
#endif
	return nullptr;
}

bool URenderExtendBlueprintFunctions::SaveRenderTarget2DToPng(FString OutputDir, FString FileName, UTextureRenderTarget2D* TextureTarget)
{
#if WITH_EDITOR
	if (TextureTarget != NULL)
	{
		FString CaptureName = OutputDir + FileName + TEXT(".png");

		IImageWrapperModule& ImageWrapperModule = FModuleManager::LoadModuleChecked<IImageWrapperModule>(FName("ImageWrapper"));
		//Read Whole Capture Buffer
		TSharedPtr<IImageWrapper> ImageWrapper = ImageWrapperModule.CreateImageWrapper(EImageFormat::PNG);

		TArray<FColor> SurfaceDataWhole;
		SurfaceDataWhole.AddUninitialized(TextureTarget->GetSurfaceWidth() * TextureTarget->GetSurfaceHeight());
		// Read pixels
		FTextureRenderTargetResource* RenderTarget = TextureTarget->GameThread_GetRenderTargetResource();
		RenderTarget->ReadPixelsPtr(SurfaceDataWhole.GetData(), FReadSurfaceDataFlags());

		ImageWrapper->SetRaw(SurfaceDataWhole.GetData(), SurfaceDataWhole.GetAllocatedSize(), TextureTarget->GetSurfaceWidth(), TextureTarget->GetSurfaceHeight(), ERGBFormat::BGRA, 8);
		const TArray64<uint8>& PNGData = ImageWrapper->GetCompressed(100);

		FFileHelper::SaveArrayToFile(PNGData, *CaptureName);
		ImageWrapper.Reset();

		return true;
	}
#endif
	return false;
}

bool URenderExtendBlueprintFunctions::ImportFileToEdtior(FString FilFulleName, FString DestinationPath)
{
#if WITH_EDITOR
	FAssetToolsModule& AssetToolsModule = FModuleManager::Get().LoadModuleChecked<FAssetToolsModule>("AssetTools");
	TArray<TPair<FString, FString>> FilesAndDestinations;
	TArray<FString> FileNames;
	FileNames.Add(FilFulleName);
	FilesAndDestinations.Emplace(FilFulleName, DestinationPath);
	AssetToolsModule.Get().ImportAssets(FileNames, DestinationPath, nullptr, true, &FilesAndDestinations);
	return true;
#endif
	return false;

}

bool URenderExtendBlueprintFunctions::SaveDepthRenderTargetToPng(FString OutputDir, FString FileName,UTextureRenderTarget2D* TextureTarget, float Base, float Range)
{
#if WITH_EDITOR
	if (TextureTarget != NULL)
	{
		FString CaptureName = OutputDir + FileName + TEXT(".png");

		IImageWrapperModule& ImageWrapperModule = FModuleManager::LoadModuleChecked<IImageWrapperModule>(FName("ImageWrapper"));
		//Read Whole Capture Buffer
		TSharedPtr<IImageWrapper> ImageWrapper = ImageWrapperModule.CreateImageWrapper(EImageFormat::PNG);

		TArray<FFloat16Color> SurfaceDataWhole;
		SurfaceDataWhole.AddUninitialized(TextureTarget->GetSurfaceWidth() * TextureTarget->GetSurfaceHeight());
	
		// Read pixels
		FTextureRenderTargetResource* RenderTarget = TextureTarget->GameThread_GetRenderTargetResource();
		RenderTarget->ReadFloat16Pixels(SurfaceDataWhole);

		TArray<FColor> SurfaceDataWholeOut;
		SurfaceDataWholeOut.AddUninitialized(TextureTarget->GetSurfaceWidth() * TextureTarget->GetSurfaceHeight());

		for (int i = 0; i < SurfaceDataWhole.Num(); i++)
		{
			float R = SurfaceDataWhole[i].R.GetFloat();
			SurfaceDataWholeOut[i].A = FMath::Clamp((R - Base), 0.0f, Range) / Range * 255u;
		}

		ImageWrapper->SetRaw(SurfaceDataWholeOut.GetData(), SurfaceDataWholeOut.GetAllocatedSize(), TextureTarget->GetSurfaceWidth(), TextureTarget->GetSurfaceHeight(), ERGBFormat::BGRA, 8);
		const TArray64<uint8>& PNGData = ImageWrapper->GetCompressed(100);

		FFileHelper::SaveArrayToFile(PNGData, *CaptureName);
		ImageWrapper.Reset();

		return true;
	}
#endif
	return false;
}

bool URenderExtendBlueprintFunctions::SplitOceanRegionMapFromPngFile(const FString& FilePath, int32 Tiles)
{
#if WITH_EDITOR
	TArray<uint8> RawFileData;
	UTexture2D* Texture = NULL;
	if (FFileHelper::LoadFileToArray(RawFileData, *FilePath))
	{
		IImageWrapperModule& ImageWrapperModule = FModuleManager::LoadModuleChecked<IImageWrapperModule>(FName("ImageWrapper"));
		TSharedPtr<IImageWrapper> ImageWrapper = ImageWrapperModule.CreateImageWrapper(EImageFormat::PNG);
		if (ImageWrapper.IsValid() && ImageWrapper->SetCompressed(RawFileData.GetData(), RawFileData.Num()))
		{
			int32 SourceImageWidth = ImageWrapper->GetWidth();
			int32 SourceImageHeight = ImageWrapper->GetHeight();
			TArray64<uint8> UncompressedBGRA;
			if (ImageWrapper->GetRaw(ERGBFormat::BGRA, 8, UncompressedBGRA))
			{
				// Get file name prefix
				FString RegionMapPrefix, Name;
				FilePath.Split(FString("."), &RegionMapPrefix, &Name);

				int32 SubImageWidth = SourceImageWidth / (Tiles + 1) * 2;
				int32 SubImageHeight = SourceImageHeight / (Tiles + 1) * 2;

				for (int32 i = 0; i < Tiles; i++)
				{
					for (int32 j = 0; j < Tiles; j++)
					{
						TArray<FColor> SurfaceDataWholeOut;
						SurfaceDataWholeOut.AddUninitialized(SubImageWidth * SubImageHeight);

						for (int32 iSubImage = 0; iSubImage < SubImageWidth; iSubImage++)
						{
							for (int32 jSubImage = 0; jSubImage < SubImageHeight; jSubImage++)
							{
								int32 Index = (j * SubImageHeight * 0.5f + jSubImage ) * SourceImageWidth + i * SubImageWidth * 0.5f + iSubImage;

								FColor SubColor;
								SubColor.B = (UncompressedBGRA)[Index * 4 + 0];
								SubColor.G = (UncompressedBGRA)[Index * 4 + 1];
								SubColor.R = (UncompressedBGRA)[Index * 4 + 2];
								SubColor.A = (UncompressedBGRA)[Index * 4 + 3];

								SurfaceDataWholeOut[iSubImage + jSubImage * SubImageWidth] = SubColor;
							}
						}

						TSharedPtr<IImageWrapper> ImageWrapperSubImage = ImageWrapperModule.CreateImageWrapper(EImageFormat::PNG);

						ImageWrapperSubImage->SetRaw(SurfaceDataWholeOut.GetData(), SurfaceDataWholeOut.GetAllocatedSize(), SubImageWidth, SubImageHeight, ERGBFormat::BGRA, 8);
						const TArray64<uint8>& PNGData = ImageWrapperSubImage->GetCompressed(100);

						FString FilePathSubImage = RegionMapPrefix + FString::Printf(TEXT("_%02d_M.png"), j * Tiles + i + 1);
						FFileHelper::SaveArrayToFile(PNGData, *FilePathSubImage);
						ImageWrapperSubImage.Reset();
					}
				}
			}
		}
		ImageWrapper.Reset();

		return true;
	}
#endif
	return false;
}

bool URenderExtendBlueprintFunctions::ExecuteCommand(const FString& Cmd)
{
	check(GEngine != nullptr)
	return GEngine->Exec(NULL, *Cmd);
}

bool URenderExtendBlueprintFunctions::GetCVRIntValue(const FString& ConsoleVariableName, int32& OutValue)
{
	IConsoleVariable* ConsoleVariable = IConsoleManager::Get().FindConsoleVariable(*ConsoleVariableName);
	if (ConsoleVariable != nullptr)
	{
		OutValue = ConsoleVariable->GetInt();

		return true;
	}

	return false;
}

bool URenderExtendBlueprintFunctions::GetCVRFloatValue(const FString& ConsoleVariableName, float& OutValue)
{
	IConsoleVariable* ConsoleVariable = IConsoleManager::Get().FindConsoleVariable(*ConsoleVariableName);
	if (ConsoleVariable != nullptr)
	{
		OutValue = ConsoleVariable->GetFloat();

		return true;
	}

	return false;

}

bool URenderExtendBlueprintFunctions::SetCVRIntByDeviceProfile(const FString& ConsoleVariableName, int32 NewValue)
{
	IConsoleVariable* ConsoleVariable = IConsoleManager::Get().FindConsoleVariable(*ConsoleVariableName);
	if (ConsoleVariable != nullptr)
	{
		ConsoleVariable->Set(NewValue, ECVF_SetByDeviceProfile);

		UE_LOG(RenderExtendBlueprintLog, Log, TEXT("Set cvar by device profile %s to %d."), *ConsoleVariableName, NewValue);

		return true;
	}

	return false;
}

bool URenderExtendBlueprintFunctions::SetCVRFloatByDeviceProfile(const FString& ConsoleVariableName, float NewValue)
{
	IConsoleVariable* ConsoleVariable = IConsoleManager::Get().FindConsoleVariable(*ConsoleVariableName);
	if (ConsoleVariable != nullptr)
	{
		ConsoleVariable->Set(NewValue, ECVF_SetByDeviceProfile);

		UE_LOG(RenderExtendBlueprintLog, Log, TEXT("Set cvar by device profile %s to %f."), *ConsoleVariableName, NewValue);

		return true;
	}

	return false;
}

bool URenderExtendBlueprintFunctions::SetCVRIntByScalability(const FString& ConsoleVariableName, int32 NewValue)
{
	IConsoleVariable* ConsoleVariable = IConsoleManager::Get().FindConsoleVariable(*ConsoleVariableName);
	if (ConsoleVariable != nullptr)
	{
		ConsoleVariable->Set(NewValue, ECVF_SetByScalability);

		UE_LOG(RenderExtendBlueprintLog, Log, TEXT("Set cvar by scalability %s to %d."), *ConsoleVariableName, NewValue);

		return true;
	}

	return false;
}

bool URenderExtendBlueprintFunctions::SetCVRFloatByScalability(const FString& ConsoleVariableName, float NewValue)
{
	IConsoleVariable* ConsoleVariable = IConsoleManager::Get().FindConsoleVariable(*ConsoleVariableName);
	if (ConsoleVariable != nullptr)
	{
		ConsoleVariable->Set(NewValue, ECVF_SetByScalability);

		UE_LOG(RenderExtendBlueprintLog, Log, TEXT("Set cvar by scalability %s to %f."), *ConsoleVariableName, NewValue);

		return true;
	}

	return false;
}

float URenderExtendBlueprintFunctions::ConvertXFOVToYFOV(UObject* WorldContextObject, float XFOV, float AspectRatio)
{
	UWorld* World = nullptr;

	if (WorldContextObject != nullptr)
	{
		World = WorldContextObject->GetWorld();

		check(World != nullptr);
		UGameViewportClient* lViewportClient = World->GetGameViewport();
		if (lViewportClient->IsValidLowLevel() && (lViewportClient->Viewport != nullptr))
		{
			FIntPoint ViewSize = lViewportClient->Viewport->GetSizeXY();
			float VerticalFOV = FMath::RadiansToDegrees(2 * FMath::Atan(FMath::Tan(FMath::DegreesToRadians(XFOV) / 2) / AspectRatio));
			return FMath::RadiansToDegrees(2 * FMath::Atan(FMath::Tan(FMath::DegreesToRadians(VerticalFOV) / 2) * ViewSize.X / ViewSize.Y));
		}
	}

	return XFOV;
}

bool URenderExtendBlueprintFunctions::GetShadowCacheEnabled()
{
	IConsoleVariable* ConsoleVariable = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_SHADOWCACHE);
	if (ConsoleVariable != nullptr)
	{
        return ConsoleVariable->GetInt() > 0;
    }

	return false;
}

bool URenderExtendBlueprintFunctions::SetShadowCacheEnabled(bool bEnable)
{
	IConsoleVariable* ConsoleVariable = IConsoleManager::Get().FindConsoleVariable(CONSOLEVAR_SHADOWCACHE);
	if (ConsoleVariable != nullptr)
	{
		ConsoleVariable->Set(bEnable ? 1 : 0);

		return true;
	}

    return false;
}

