#pragma once

#include "CoreMinimal.h"
#include "Game/GameCommon.h"
#include "GPerfReporter.h"


// 与GPerf中dashboard的配置需保持一致
#if UE_SERVER
    const static int32 EXTENSION_LUA_MEMORY = 0;
    const static int32 EXTENSION_UE4_GC_STATE = 1;
    const static int32 EXTENSION_SPAWN_ACTOR_STATE = 2;
#else
    const static int32 EXTENSION_LUA_MEMORY = 0;
    const static int32 EXTENSION_PING = 1;
    const static int32 EXTENSION_UE4_GC_STATE = 2;
    const static int32 EXTENSION_NUM_PRIMITIVES_GRASS = 3;
    const static int32 EXTENSION_NUM_PRIMITIVES_FOLIAGE = 4;
    const static int32 EXTENSION_NUM_PRIMITIVES_LANDSCAPE = 5;
    const static int32 EXTENSION_NUM_PRIMITIVES_SHADOW = 6;
    const static int32 EXTENSION_NUM_PRIMITIVES_DRAWN_RHI_STATIC = 7;
    const static int32 EXTENSION_NUM_PRIMITIVES_DRAWN_RHI_MASK_Z = 8;
    const static int32 EXTENSION_NUM_PRIMITIVES_DRAWN_RHI_SKM = 9;
    const static int32 EXTENSION_NUM_DRAW_CALLS_GRASS = 10;
    const static int32 EXTENSION_NUM_DRAW_CALLS_FOLIAGE = 11;
    const static int32 EXTENSION_NUM_DRAW_CALLS_LANDSCAPE = 12;
    const static int32 EXTENSION_NUM_DRAW_CALLS_SHADOW = 13;
    const static int32 EXTENSION_NUM_DRAW_CALLS_STATIC = 14;
    const static int32 EXTENSION_NUM_DRAW_CALLS_MASK_Z = 15;
    const static int32 EXTENSION_NUM_DRAW_CALLS_SKM = 16;
    const static int32 EXTENSION_NUM_DRAW_CALLS_PARTICLE = 17;
    const static int32 EXTENSION_NUM_DRAW_CALLS_SLATE = 18;
    const static int32 EXTENSION_RENDER_QUALITY = 19;
    const static int32 EXTENSION_NUM_PRIMITIVES_COUNTER_0 = 20;
    const static int32 EXTENSION_SPAWN_ACTOR_STATE = 21;
#endif

template<typename TLuaRootType>
class TLuaMemoryReporter : public FGPerfReporter
{
public:
    TLuaMemoryReporter(TLuaRootType* InLuaRoot) : LuaRoot(InLuaRoot) {}
    const int32 GetExtIdx() override { return EXTENSION_LUA_MEMORY; }
    const float GetReportInterval() override { return 30.0f; }
    const float GetData() override 
    { 
        float Result = 0.0f;
        if (LuaRoot.IsValid())
        {
            //UE_LOG(LogTemp, Log, TEXT("LuaRoot.IsValid"));
            Result = LuaRoot->GetMemoryUsage();
        }
        else
        {
            //UE_LOG(LogTemp, Log, TEXT("LuaRoot.NOTValid"));
            Result = .0f;
        }
        return  Result; 
    }
private:
    TWeakObjectPtr<TLuaRootType> LuaRoot;
};

class FGarbageColletctionStateReporter : public FGPerfReporter
{
public:
    const int32 GetExtIdx() override { return EXTENSION_UE4_GC_STATE; }
    const float GetData() override 
    { 
#if !WITH_EDITOR
        extern double GCFrameTime;
        extern double GCFramePurgeTime;

        float GCTotalTime = GCFrameTime > GCFramePurgeTime ? GCFrameTime : GCFramePurgeTime;
        //UE_LOG(LogTemp, Display, TEXT("FGarbageColletctionStateReporter %f"), GCTotalTime);

        GCFrameTime = 0.0f;
        GCFramePurgeTime = 0.0;
        return GCTotalTime;
#endif
        return 0.f;
    }
    const bool IsRelatedToStatUnit() override { return true; }
};


class FSpawnActorReporter : public FGPerfReporter
{
public:
    FSpawnActorReporter(UGameCommon* InGameCommon) : GameCommon(InGameCommon) {}
    const int32 GetExtIdx() override { return EXTENSION_SPAWN_ACTOR_STATE; }
    const float GetData() override
    {
        if (GameCommon.IsValid())
        {
            auto LastSpawnFrameCounter = GameCommon->GetLastSpawnActorFrameCounter();
            return (LastSpawnFrameCounter == GFrameCounter - 1) ? 1.f : 0.f;   // 根据当前的写法，本函数的调用是在tick末，GFrameCounter已经经历过+1，故-1
        }
        return 0.f;
    }
    const bool IsRelatedToStatUnit() override { return true; }
private:
    TWeakObjectPtr<UGameCommon> GameCommon;
};


