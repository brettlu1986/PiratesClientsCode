// Fill out your copyright notice in the Description page of Project Settings.

#include "KMPlayerController.h"
#include "EngineExt.h"
#include "GameEngineExt.h"
#include "KMPawn.h"
#include "Game/Delegates/ActorDelegate.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Game/Delegates/PlayerDelegate.h"
//#include "ScriptActorComponent.h"
#include "Net/UnrealNetwork.h"

DEFINE_LOG_CATEGORY_STATIC(KMPlayerControllerLog, Log, All)

struct AKMPlayerController::FImplement
{
    AKMPlayerController *Owner;
	//FNetworkGUID NetworkGUID;
    //FString PawnScriptType;

    FImplement(AKMPlayerController *Parent)
        : Owner(Parent)
    {

    }
};

AKMPlayerController::AKMPlayerController(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , Impl(MakeShareable(new FImplement(this)))
    , LogicInstanceId(-1)
{
}

void AKMPlayerController::PostInitProperties()
{
    Super::PostInitProperties();
}

bool AKMPlayerController::CanRestartPlayer()
{
	return LevelLoadedOnClient && Super::CanRestartPlayer();
}

AActor* AKMPlayerController::GetPlayerPawn()
{
	return GetPawn();
}

void AKMPlayerController::ResetStartSpot()
{
	StartSpot = nullptr;
}

void AKMPlayerController::BeginPlay()
{
    SetVirtualJoystickVisibility(false);
    FPrintTimeHelper T(*FString::Printf(TEXT("AKMPlayerController::BeginPlay [%s]"), *GetName()));
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    UActorDelegate* ActorDelegate = Game ? Game->GetKMDelegateManager()->Actor : nullptr;
    if (ActorDelegate)
    {        
        ActorDelegate->OnControllerPreBeginPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
        T.Stamp(TEXT("PreBeginPlay"));
    }

    Super::BeginPlay();
    T.Stamp(TEXT("OrignalBeginPlay"));

    if (ActorDelegate)
    {
        ActorDelegate->OnControllerPostBeginPlay.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
        T.Stamp(TEXT("PostBeginPlay"));
    }
}

void AKMPlayerController::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    if (Game)
    {
        Game->GetKMDelegateManager()->Actor->OnControllerEndPlay.Broadcast(this, GetUniqueID(), GetLogicInstanceId());
    }

    Super::EndPlay(EndPlayReason);
}

//int32 AKMPlayerController::GetServerId()
//{
//	return UEngineExtActorShell::GetActorNetGuid(this);
//}

//int32 AKMPlayerController::GetNetworkGuid()
//{
//	if (!Impl->NetworkGUID.IsValid())
//	{
//		auto NetDriver = GetNetDriver();
//		if (NetDriver)
//		{
//			Impl->NetworkGUID = NetDriver->GuidCache->GetOrAssignNetGUID(this);
//		}
//		else
//		{
//			Impl->NetworkGUID = FNetworkGUID(6);
//		}
//	}
//	return Impl->NetworkGUID.Value;
//}

void AKMPlayerController::PreClientTravel(const FString& PendingURL, ETravelType TravelType, bool bIsSeamlessTravel)
{
	Super::PreClientTravel(PendingURL, TravelType, bIsSeamlessTravel);
	PreClientTravelEvent(PendingURL, TravelType, bIsSeamlessTravel);
}
//
//FString AKMPlayerController::GetServerNetworkAddress(bool AppendPort)
//{
//	UNetDriver* NetDriver = NULL;
//	if (GetWorld())
//	{
//		NetDriver = GetWorld()->GetNetDriver();
//	}
//
//	if (NetDriver && NetDriver->ServerConnection)
//	{
//		return NetDriver->ServerConnection->LowLevelGetRemoteAddress(AppendPort);
//	}
//
//	return TEXT("");
//}

void AKMPlayerController::InitPlayerState()
{
	Super::InitPlayerState();

	if (PlayerState != nullptr)
	{
		PlayerState->bAlwaysRelevant = false;
		PlayerState->bOnlyRelevantToOwner = true;
	}
}

void AKMPlayerController::OnPossess(APawn* InPawn)
{
	Super::OnPossess(InPawn);

    auto DelegateMgr = UGameEngineExt::Get(this)->GetKMDelegateManager();
    if (IsValid(DelegateMgr))
    {
        DelegateMgr->Player->OnPossess.ExecuteIfBound(GetUniqueID(), IsValid(InPawn) ? InPawn->GetUniqueID() : INDEX_NONE);
    }

	auto KMPawn = Cast<AKMPawn>(InPawn);
    if (KMPawn)
    {
        KMPawn->OnPostPossessed();
    }
}

void AKMPlayerController::OnUnPossess()
{
    Super::OnUnPossess();

    UGameEngineExt* EngineExt = UGameEngineExt::Get(this);
    if (EngineExt != nullptr)
    {
        auto DelegateMgr = EngineExt->GetKMDelegateManager();
        if (IsValid(DelegateMgr))
        {
            DelegateMgr->Player->OnUnPossess.ExecuteIfBound(GetUniqueID());
        }
    }
    
}

void AKMPlayerController::ClientWasKicked_Implementation(FText const& KickReason)
{
    Super::ClientWasKicked_Implementation(KickReason);
    UGameEngineExt* EngineExt = UGameEngineExt::Get(this);
    if (EngineExt != nullptr)
    {
        auto DelegateMgr = EngineExt->GetKMDelegateManager();
        if (IsValid(DelegateMgr))
        {
            DelegateMgr->Player->OnClientWasKicked.ExecuteIfBound(KickReason);
        }
    }
}

//bool AKMPlayerController::InitialFromDataset(FKMNodeDataset* DS)
//{
//	return true;
//}

//void AKMPlayerController::SetPawnScriptType(const FString& ScriptType)
//{
//    Impl->PawnScriptType = ScriptType;
//}
//
//const FString& AKMPlayerController::GetPawnScriptType()
//{
//    return Impl->PawnScriptType;
//}

void AKMPlayerController::CleanupPlayerState()
{
    auto const GameMode = GetWorld()->GetAuthGameMode<AGameMode>();
    auto NetMode = GEngine->GetNetMode(GetWorld());
    if (GameMode && NetMode != NM_Standalone && NetMode != NM_Client)
    {
        // Implement as APlayerController
        GameMode->AddInactivePlayer(PlayerState, this);
    }
    else
    {
        // Implement as AController
        PlayerState->Destroy(true);
    }

    PlayerState = NULL;
}


void AKMPlayerController::BeginSpectatingState()
{
    Super::BeginSpectatingState();

    auto GameExt = UGameEngineExt::Get(this);
    if (IsLocalController() && GameExt)
    {
        auto DelegateMgr = GameExt->GetKMDelegateManager();
        if (IsValid(DelegateMgr))
        {
            DelegateMgr->Player->OnBeginSpectating.ExecuteIfBound(GetUniqueID());
        }
    }
}

void AKMPlayerController::EndSpectatingState()
{
    Super::EndSpectatingState();

    auto GameExt = UGameEngineExt::Get(this);
    if (IsLocalController() && GameExt)
    {
        auto DelegateMgr = GameExt->GetKMDelegateManager();
        if (IsValid(DelegateMgr))
        {
            DelegateMgr->Player->OnEndSpectating.ExecuteIfBound(GetUniqueID());
        }
    }
}

void AKMPlayerController::ServerExecGMCommand_Implementation(const FString& Param)
{
    auto DelegateMgr = UGameEngineExt::Get(this)->GetKMDelegateManager();
    if (IsValid(DelegateMgr))
    {
        auto& Func = DelegateMgr->Player->OnServerExecGM;
        if (Func.IsBound())
        {
            Func.Execute(this, Param);
        }
    }
}

bool AKMPlayerController::ServerExecGMCommand_Validate(const FString& Param)
{
    return true;
}

void AKMPlayerController::GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME_CONDITION(AKMPlayerController, InitProtoData, COND_InitialOnly);
    DOREPLIFETIME_CONDITION(AKMPlayerController, LogicInstanceId, COND_InitialOnly);
}
