#ifdef WITH_GPERF
#include "GPerfReporters/GPerfReporterManager.h"
#include "Client.h"
#include "GPerf.h"
#include "GPerfReporter.h"
#include "GameClient.h"
#include "RHI.h"
#include "ExtendBlueprintFunctions.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "Kismet/GameplayStatics.h"
#include "GPerf/GPerfReporterCommon.h"
#if ENABLE_U4LUA
#include "GameLuaRoot.h"
#else
#include "GameLuaManager.h"
#endif
#include "RenderSettingsManager.h"

extern RHI_API int32 GNumPrimitivesGrassDrawRHI;
extern RHI_API int32 GNumPrimitivesFoliageDrawRHI;
extern RHI_API int32 GNumPrimitivesLandscapeDrawRHI;
extern RHI_API int32 GNumPrimitivesShadow;
extern RHI_API int32 GNumPrimitivesDrawnRHIStatic;
extern RHI_API int32 GNumPrimitivesDrawnRHIMaskZ;
extern RHI_API int32 GNumPrimitivesDrawnRHISKM;
extern RHI_API int32 GNumDrawCallsGrass;
extern RHI_API int32 GNumDrawCallsFoliage;
extern RHI_API int32 GNumDrawCallsLandscape;
extern RHI_API int32 GNumDrawCallsShadow;
extern RHI_API int32 GNumDrawCallsStatic;
extern RHI_API int32 GNumDrawCallsMaskZ;
extern RHI_API int32 GNumDrawCallsSKM;
extern RHI_API int32 GNumDrawCallsParticle;
extern RHI_API int32 GNumDrawCallsSlate;
extern RHI_API int32 GNumPrimitivesCounter0;




const static FString UNKNOW_LAND_NAME = TEXT("unknow_land_name");
const static TMap<EPiratesGridRegionType, FString> REGEION_NAME = {
    { EPiratesGridRegionType::Unknown, TEXT("Unknown") },
    { EPiratesGridRegionType::Land   , TEXT("Land")    },
    { EPiratesGridRegionType::Ocean  , TEXT("Ocean")   },
    { EPiratesGridRegionType::Shore  , TEXT("Shore")   },
    { EPiratesGridRegionType::Port   , TEXT("Port")    },
    { EPiratesGridRegionType::Rock   , TEXT("Rock")    },
    { EPiratesGridRegionType::Lake   , TEXT("Lake")    }
};



class FPingReporter : public FGPerfReporter
{
public:
    const int32 GetExtIdx() override { return EXTENSION_PING; }
    const float GetData() override
    {
#if PLATFORM_IOS || PLATFORM_ANDROID
        return UExtendBlueprintFunctions::GetPing(GWorld);
#else
        return 0;
#endif
    }
};



class FRHIDataReporter : public FGPerfReporter
{
public:
    FRHIDataReporter(int32 InExtIdx, int32* InDataPtr)
        : ExtIdx(InExtIdx)
        , DataPtr(InDataPtr)
    {}
    const int32 GetExtIdx() override { return ExtIdx; }
    const float GetData() override { return *DataPtr; }
    const bool IsRelatedToStatUnit() override {
        return true;
    }
private:
    int32 ExtIdx;
    int32* DataPtr;
};

class FRenderQualityReporter : public FGPerfReporter
{
public:    
    FRenderQualityReporter(UGameClient* InGameClient) : GameClient(InGameClient)
    {

    }
    const int32 GetExtIdx() override { return EXTENSION_RENDER_QUALITY; }
    const float GetData() override
    {
        if (GameClient.IsValid() && GameClient->GetRenderSettingsManager() != nullptr)
        {
            return GameClient->GetRenderSettingsManager()->GetInnerQuality();
        }
        return 0.f;
    }

    const bool IsRelatedToStatUnit() override {
        return true;
    }
private:
    TWeakObjectPtr<UGameClient> GameClient;
};

class FCustomTransformReporter : public FGPerfTransformReporter
{
public:
    FCustomTransformReporter(UGameClient* InGameClient) : GameClient(InGameClient) {}

    const void GetTransformInfo(FVector& Location, FRotator& Rotation, FString& LocationName) override
    {
        ReturnIfFalse(GameClient.IsValid());

        APawn* Pawn = UGameplayStatics::GetPlayerPawn(GameClient.Get(), 0);
        ReturnIfNullptr(Pawn);
        Location = Pawn->GetActorLocation();
        Rotation = Pawn->GetActorRotation();

        UPiratesGridTypeManager* PiratesGridTypeManager = GameClient->GetGridTypeManager();
        ReturnIfNullptr(PiratesGridTypeManager);
        LocationName = PiratesGridTypeManager->GetRegionName(Location.X, Location.Y);
        ReturnIfFalse(LocationName.Equals(UNKNOW_LAND_NAME));
        EPiratesGridRegionType Type = PiratesGridTypeManager->GetRegionType(Location.X, Location.Y);
        const FString* RegionNamePtr = REGEION_NAME.Find(Type);
        ReturnIfNullptr(RegionNamePtr);
        LocationName = *RegionNamePtr;
    }
private:
    TWeakObjectPtr<UGameClient> GameClient;
};

void UGPerfReporterManager::Init(UGameClient* GameClient)
{
    InitReporters(GameClient);
    FGPerfModule& GPerfModule = FModuleManager::GetModuleChecked<FGPerfModule>("GPerf");
    for (auto Reporter : Reporters)
    {
        GPerfModule.AddGPerfReporter(Reporter);
    }
    TransformReporter = MakeShareable(new FCustomTransformReporter(GameClient));
    GPerfModule.SetGPerfTransformReporter(TransformReporter);
}

void UGPerfReporterManager::Uninit()
{
    FGPerfModule& GPerfModule = FModuleManager::GetModuleChecked<FGPerfModule>("GPerf");
    for (auto Reporter : Reporters)
    {
        GPerfModule.RemoveGPerfReporter(Reporter);
        Reporter.Reset();
    }
    Reporters.Empty();
    GPerfModule.ClearGPerfTransformReporter();
    TransformReporter.Reset();
}

void UGPerfReporterManager::InitReporters(UGameClient* GameClient)
{
    Reporters.Add(MakeShareable(new FPingReporter()));
    Reporters.Add(MakeShareable(new FGarbageColletctionStateReporter()));
#ifdef ENABLE_U4LUA
    Reporters.Add(MakeShareable(new TLuaMemoryReporter<UGameLuaRoot>(GameClient->GetLuaRoot())));
#else
    Reporters.Add(MakeShareable(new TLuaMemoryReporter<UGameLuaManager>(GameClient->GetGameLuaManager())));
#endif
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_PRIMITIVES_GRASS             , &GNumPrimitivesGrassDrawRHI)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_PRIMITIVES_FOLIAGE           , &GNumPrimitivesFoliageDrawRHI)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_PRIMITIVES_LANDSCAPE         , &GNumPrimitivesLandscapeDrawRHI)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_PRIMITIVES_SHADOW            , &GNumPrimitivesShadow)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_PRIMITIVES_DRAWN_RHI_STATIC  , &GNumPrimitivesDrawnRHIStatic)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_PRIMITIVES_DRAWN_RHI_MASK_Z  , &GNumPrimitivesDrawnRHIMaskZ)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_PRIMITIVES_DRAWN_RHI_SKM     , &GNumPrimitivesDrawnRHISKM)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_GRASS             , &GNumDrawCallsGrass)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_FOLIAGE           , &GNumDrawCallsFoliage)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_LANDSCAPE         , &GNumDrawCallsLandscape)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_SHADOW            , &GNumDrawCallsShadow)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_STATIC            , &GNumDrawCallsStatic)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_MASK_Z            , &GNumDrawCallsMaskZ)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_SKM               , &GNumDrawCallsSKM)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_PARTICLE          , &GNumDrawCallsParticle)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_DRAW_CALLS_SLATE             , &GNumDrawCallsSlate)));
    Reporters.Add(MakeShareable(new FRenderQualityReporter(GameClient)));
    Reporters.Add(MakeShareable(new FRHIDataReporter(EXTENSION_NUM_PRIMITIVES_COUNTER_0         , &GNumPrimitivesCounter0)));
    Reporters.Add(MakeShareable(new FSpawnActorReporter(GameClient)));
}

#endif
