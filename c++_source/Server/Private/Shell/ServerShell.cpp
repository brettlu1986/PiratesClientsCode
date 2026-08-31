// Fill out your copyright notice in the Description page of Project Settings.

#include "Shell/ServerShell.h"
#include "Server.h"
#include "Game/GameServer.h"
#include "Game/HistoryService.h"

#include "Shell/DungeonShell.h"
#include "AI/AIGameCoreProxy/AIGameCoreProxyClient.h"

UServerShell::UServerShell(const FObjectInitializer& ObjectInitializer)
: Super(ObjectInitializer)
, DungeonShell(nullptr)
{
}

UServerShell* UServerShell::GetServer(UObject* WorldContextObject)
{
    return Cast<UServerShell>(GetShell(WorldContextObject));
}

void UServerShell::Init()
{
    Super::Init();

    DungeonShell = NewObject<UDungeonShell>(this);
}

void UServerShell::CancelPendingNetGame(UObject* WorldContextObject)
{
    if (UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull))
    {
        GEngine->CancelPending(World);
    }
}

USocketNetworkManager* UServerShell::GetDungeonNetManager()
{
    return UGameServer::Get(this)->GetDungeonNetManager();
}

bool UServerShell::IsDungeonWithHub()
{
    return UGameServer::Get(this)->IsDungeonWithHub();
}

bool UServerShell::ShouldTriggerCrashDueToLuaError()
{
    return UGameServer::Get(this)->ShouldTriggerCrashDueToLuaError();
}

bool UServerShell::SetDumpPolicy(bool bCore)
{
    return UGameServer::Get(this)->SetDumpPolicy(bCore);
}

UDungeonShell* UServerShell::GetDungeonShell()
{
    return DungeonShell;
}

bool UServerShell::KickPlayer(APlayerController *PlayerController)
{
    return UGameServer::Get(this)->KickPlayer(PlayerController);
}

int32 UServerShell::KickAllPlayers()
{
    return UGameServer::Get(this)->KickAllPlayers();
}

FString UServerShell::GetDungeonInitData()
{
    return UGameServer::Get(this)->GetDungeonInitData();
}

FString UServerShell::GetHistoryServiceSavePlayerStatsUrl()
{
    UHistoryService* HistoryService = UGameServer::Get(this)->GetHistoryService();
    if (HistoryService) 
    {
        return HistoryService->GetSavePlayerStatsUrl();
    }
    return TEXT("");
}

FString UServerShell::GetHistoryServiceSaveTeamRankUrl()
{
    UHistoryService* HistoryService = UGameServer::Get(this)->GetHistoryService();
    if (HistoryService)
    {
        return HistoryService->GetSaveTeamRankUrl();
    }
    return TEXT("");
}

bool UServerShell::IsStressTest()
{
    return UGameServer::Get(this)->IsStressTest();
}

UAIGameCoreProxyClient* UServerShell::GetAIGameCoreProxy() const
{
    return UGameServer::Get(this)->GetAIGameCoreProxy();
}

void UServerShell::RedirectLogBySession(const FString& SessionId)
{
    UGameServer::Get(this)->RedirectLogBySession(SessionId);
}