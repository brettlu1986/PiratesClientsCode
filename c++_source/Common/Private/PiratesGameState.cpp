#include "PiratesGameState.h"
#include "Common.h"
#include "PiratesPlayerState.h"
#include "PiratesPlayerController.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameStateDelegate.h"
#include "Game/Battle/PiratesGameGroupPrivateInfo.h"
#include "Network/ReplicatedProtoPropertyComponent.h"
#include "Network/ReplicatedProtoCallComponent.h"
#include "CustomReplicationComponent.h"
#include "TimerManager.h"
#include "Engine/NetConnection.h"
#include "Components/CampRelationComponent.h"


APiratesGameState::APiratesGameState(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    static FName DefaultRPCCompName = FName("ReplicatedProtoCallComponent");
    CreateOptionalDefaultSubobject<UReplicatedProtoCallComponent>(DefaultRPCCompName);
    CampRelationComponent = CreateDefaultSubobject<UCampRelationComponent>(TEXT("CampRelationComponent"));
	
    static FName DefaultRPCPropertyCompName = FName("ReplicatedProtoPropertyComponent");
    auto PropertyComponent = CreateOptionalDefaultSubobject<UReplicatedProtoPropertyComponent>(DefaultRPCPropertyCompName);
    PropertyComponent->SetClientRecvType(true);

    static FName DefaultCustomPropertyCompName = FName("CustomPropertyReplicationComponent");
    CustomReplication = CreateOptionalDefaultSubobject<UCustomReplicationComponent>(DefaultCustomPropertyCompName);
    CustomReplication->DefineInfoName = "GameStateLuaRepComponent";
    CustomReplication->SetIsReplicated(true);
}

void APiratesGameState::BeginPlay()
{
    Super::BeginPlay();

    auto Delegate = UGameCommon::Get(this)->GetGameDelegateManager()->GameState;
    check(IsValid(Delegate));

    Delegate->OnGameStateBeginPlay.ExecuteIfBound(this);
}

void APiratesGameState::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    auto Delegate = UGameCommon::Get(this)->GetGameDelegateManager()->GameState;
    Delegate->OnGameStateEndPlay.ExecuteIfBound(this);

    Super::EndPlay(EndPlayReason);
}

void APiratesGameState::Clear()
{
    FTimerManager& TimerManager = GetWorldTimerManager();
    TimerManager.ClearTimer(TimerHandle_DefaultTimer);
}

void APiratesGameState::HandleMatchHasEnded()
{
    auto Delegate = UGameCommon::Get(this)->GetGameDelegateManager()->GameState;
    Delegate->OnMatchHasEnded.ExecuteIfBound();

    Super::HandleMatchHasEnded();
}

void APiratesGameState::DefaultTimer()
{
    Super::DefaultTimer();
}

void APiratesGameState::OnSerializeNewActor(FOutBunch& OutBunch)
{
    auto Delegate = UGameCommon::Get(this)->GetGameDelegateManager()->GameState;
    Delegate->OnGameStateSerializeNewActor.ExecuteIfBound();

    TArray<uint8> ReplicatedRawData;
    auto Component = FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {           
        Component->ConstructRawData(ReplicatedRawData);
    }
    
    OutBunch << ReplicatedRawData;
    Super::OnSerializeNewActor(OutBunch);
}

void APiratesGameState::OnActorChannelOpen(FInBunch& InBunch, UNetConnection* Connection)
{
    if (InBunch.bClose || InBunch.AtEnd())
    {
        Super::OnActorChannelOpen(InBunch, Connection);
        return;
    }

    auto Delegate = UGameCommon::Get(this)->GetGameDelegateManager()->GameState;
    Delegate->OnGameStateActorChannelOpen.ExecuteIfBound(this);

    TArray<uint8> ReplicatedRawData;
    InBunch << ReplicatedRawData;
    auto Component = FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component && ReplicatedRawData.Num())
    {
        Component->ProcessRecvData(ReplicatedRawData);
    }
    Super::OnActorChannelOpen(InBunch, Connection);
}

void APiratesGameState::SetCampRelationMatrix(int32 CampCount, const TArray<bool>& RelationMatrix)
{
    if (CampRelationComponent)
    {
        CampRelationComponent->SetCampRelationMatrix(CampCount, RelationMatrix);
        if (OnCampRelationMatrixChanged.IsBound())
        {
            OnCampRelationMatrixChanged.Broadcast();
        }
    }
}

bool APiratesGameState::IsFriendCampRelation(int32 CampA, int32 CampB) const
{
    return CampRelationComponent ? CampRelationComponent->IsFriendCampRelation(CampA, CampB) : false;
}