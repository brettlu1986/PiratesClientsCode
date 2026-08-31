//#ifdef WITH_GPERF
#include "GPerf/GPerfReporterManagerServer.h"
#include "GPerf.h"
#include "GPerf/GPerfReporterCommon.h"
#include "Game/GameServer.h"

#if ENABLE_U4LUA
#include "GameLuaRoot.h"
#else
#include "GameLuaManager.h"
#endif

void UGPerfReporterManagerServer::Init(UGameServer* GameServer)
{
    UE_LOG(LogTemp, Log, TEXT("UGPerfReporterManagerServer::Init"));
    InitReporters(GameServer);
    FGPerfModule& GPerfModule = FModuleManager::GetModuleChecked<FGPerfModule>("GPerf");
    for (auto Reporter : Reporters)
    {
        GPerfModule.AddGPerfReporter(Reporter);
    }
}

void UGPerfReporterManagerServer::Uninit()
{
    FGPerfModule& GPerfModule = FModuleManager::GetModuleChecked<FGPerfModule>("GPerf");
    for (auto Reporter : Reporters)
    {
        GPerfModule.RemoveGPerfReporter(Reporter);
        Reporter.Reset();
    }
    Reporters.Empty();
}

void UGPerfReporterManagerServer::InitReporters(UGameServer* GameServer)
{
    Reporters.Add(MakeShareable(new FGarbageColletctionStateReporter()));
#ifdef ENABLE_U4LUA
    Reporters.Add(MakeShareable(new TLuaMemoryReporter<UGameLuaRoot>(GameServer->GetLuaRoot())));
#else
    Reporters.Add(MakeShareable(new TLuaMemoryReporter<UGameLuaManager>(GameServer->GetGameLuaManager())));
#endif
    Reporters.Add(MakeShareable(new FSpawnActorReporter(GameServer)));
}

