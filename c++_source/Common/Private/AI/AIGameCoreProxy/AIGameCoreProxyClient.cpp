#include "AI/AIGameCoreProxy/AIGameCoreProxyClient.h"
#include "AI/AIGameCoreProxy/AIGameCoreProxyTCP.h"
#include "Shell/CommonShell.h"
#include "Game/GameEngineExt.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Game/Delegates/GameModeDelegate.h"
#include "Engine.h"

UAIGameCoreProxyClient::UAIGameCoreProxyClient(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer),
    GameCoreProxy(nullptr),
    bTrainingMode(false)
{

}


bool UAIGameCoreProxyClient::Init()
{
    if (!FParse::Value(FCommandLine::Get(), TEXT("-aiagent="), Endpoint) || Endpoint.IsEmpty())
    {
        FParse::Value(FCommandLine::Get(), TEXT("gameproxyip="), Endpoint);
    }
    if (!Endpoint.IsEmpty())
    {
        bTrainingMode = FParse::Param(FCommandLine::Get(), TEXT("train"));
        check(!GameCoreProxy);
        GameCoreProxy = NewObject<UAIGameCoreProxyTCP>();
        if (GameCoreProxy)
        {
            GameCoreProxy->Init();
            UE_LOG(LogTemp, Log, TEXT("UAIGameCoreProxyClient:gamecore proxy created"));
        }
    }
    return true;
}

bool UAIGameCoreProxyClient::Enabled() const
{
    return !Endpoint.IsEmpty();
}

bool UAIGameCoreProxyClient::TrainingMode() const
{
    return bTrainingMode;
}

bool UAIGameCoreProxyClient::Start()
{
    if (!Endpoint.IsEmpty() && GameCoreProxy)
    {
        GameCoreProxy->Start(Endpoint);
        UE_LOG(LogTemp, Log, TEXT("UAIGameCoreProxyClient:gamecore proxy start "));
        return true;
    }
    return false;
}

void UAIGameCoreProxyClient::Stop()
{
    if (GameCoreProxy)
    {
        GameCoreProxy->Stop();
    }
}

bool UAIGameCoreProxyClient::Uninit()
{
    if (GameCoreProxy)
    {
        GameCoreProxy->Uninit();
    }
    return true;
}

void UAIGameCoreProxyClient::Update(float DeltaTime)
{
    if (GameCoreProxy)
    {
        GameCoreProxy->Tick(DeltaTime);
    }
}


