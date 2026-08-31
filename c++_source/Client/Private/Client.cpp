// Fill out your copyright notice in the Description page of Project Settings.
//#include "ClientPrivatePCH.h"
#include "Client.h"
#include "GameClient.h"
#include "ClientShell.h"

IMPLEMENT_GAME_MODULE(FClientModule, Client);

DEFINE_LOG_CATEGORY_STATIC(ClientModuleLog, Log, All)

void FClientModule::StartupModule()
{
}

void FClientModule::ShutdownModule()
{

}

void FClientModule::OnGameInstanceInit(UGameInstance* GameInstance)
{
    check(GameInstance);
    if (nullptr != GameInstance)
    {
        auto GameClient = NewObject<UGameClient>(GameInstance);
        UE_LOG(ClientModuleLog, Log, TEXT("GameClient Init"));
        GameClient->Init();
        UE_LOG(ClientModuleLog, Log, TEXT("ClientShell Init"));
        auto ClientShell = NewObject<UClientShell>(GameInstance);
        ClientShell->Init();
        UE_LOG(ClientModuleLog, Log, TEXT("GameClient PostInit"));
        GameClient->PostInit();
    }
}

void FClientModule::OnGameInstanceStart(UGameInstance* GameInstance)
{
    UE_LOG(ClientModuleLog, Log, TEXT("GameClient Start"));
    UGameClient::Get(GameInstance)->Start();
    UE_LOG(ClientModuleLog, Log, TEXT("UClientShell Start"));
    UClientShell::Get(GameInstance)->Start();
}

void FClientModule::OnGameInstanceShutdown(UGameInstance* GameInstance)
{
    UClientShell::Get(GameInstance)->Shutdown();
    UGameClient::Get(GameInstance)->Shutdown();
}

void FClientModule::OnGameInstancePostShutdown(UGameInstance* GameInstance)
{
    // 客户端结束前强制吧所有gamethread的task执行完，防止残留task导致崩溃
    FTaskGraphInterface::Get().ProcessThreadUntilIdle(ENamedThreads::GameThread);

    UClientShell::Get(GameInstance)->Uninit();
    UGameClient::Get(GameInstance)->Uninit();
}

bool FClientModule::Exec(class UWorld* InWorld, const TCHAR* Cmd, FOutputDevice& Ar)
{
    bool Ret = false;
    if (InWorld)
    {
        auto GameClient = UGameClient::Get(InWorld);
        if (GameClient)
        {
            Ret = GameClient->Exec(Cmd, Ar);
        }
    }
    return Ret;
}
