// Fill out your copyright notice in the Description page of Project Settings.
#include "Server.h"
#include "GameServer.h"
#include "ServerShell.h"

IMPLEMENT_GAME_MODULE(FServerModule, Server);

void FServerModule::StartupModule()
{
}

void FServerModule::ShutdownModule()
{
}

void FServerModule::OnGameInstanceInit(UGameInstance* GameInstance)
{
    check(GameInstance);
    if (nullptr != GameInstance)
    {
        auto GameServer = NewObject<UGameServer>(GameInstance);
        GameServer->Init();
        auto ServerShell = NewObject<UServerShell>(GameInstance);
        ServerShell->Init();
        GameServer->PostInit();
    }
}

void FServerModule::OnGameInstanceStart(UGameInstance* GameInstance)
{
    UGameServer::Get(GameInstance)->Start();
    UServerShell::GetServer(GameInstance)->Start();
}

void FServerModule::OnGameInstanceShutdown(UGameInstance* GameInstance)
{
    UServerShell::GetServer(GameInstance)->Shutdown();
    UGameServer::Get(GameInstance)->Shutdown();    
}

void FServerModule::OnGameInstancePostShutdown(UGameInstance* GameInstance)
{
    UServerShell::GetServer(GameInstance)->Uninit();
    UGameServer::Get(GameInstance)->Uninit();
}

bool FServerModule::Exec(class UWorld* InWorld, const TCHAR* Cmd, FOutputDevice& Ar)
{
    return false;
}
