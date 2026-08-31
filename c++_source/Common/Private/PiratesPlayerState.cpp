#include "PiratesPlayerState.h"
#include "Common.h"
#include "Net/UnrealNetwork.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Network/ReplicatedProtoPropertyComponent.h"
#include "Game/Delegates/PiratesPlayerStateDelegate.h"


APiratesPlayerState::APiratesPlayerState(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
	, PiratePlayerId(-1)
{
    static FName DefaultRPCPropertyCompName = FName("ReplicatedProtoPropertyComponent");
    auto PropertyComponent = CreateOptionalDefaultSubobject<UReplicatedProtoPropertyComponent>(DefaultRPCPropertyCompName);
    if (!HasAnyFlags(RF_ClassDefaultObject))
    {
        PropertyComponent->SetClientRecvType(true);
        if (UKismetSystemLibrary::IsDedicatedServer(this))
        {
            PropertyComponent->EnableReplicateToClient(false);
        }
    }
    
}
void APiratesPlayerState::BeginPlay()
{
    Super::BeginPlay();

    auto Delegate = UGameCommon::Get(this)->GetGameDelegateManager()->PlayerState;
    check(IsValid(Delegate));

    Delegate->OnPlayerStateBeginPlay.ExecuteIfBound(this);
}

void APiratesPlayerState::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    auto Delegate = UGameCommon::Get(this)->GetGameDelegateManager()->PlayerState;
    Delegate->OnPlayerStateEndPlay.ExecuteIfBound(this);

    Super::EndPlay(EndPlayReason);
}

void APiratesPlayerState::OnSerializeNewActor(FOutBunch& OutBunch)
{
    TArray<uint8> ReplicatedRawData;
    auto Component = FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component)
    {
        Component->ConstructRawData(ReplicatedRawData);
        Component->EnableReplicateToClient(true);
    }

    OutBunch << ReplicatedRawData;
    Super::OnSerializeNewActor(OutBunch);
}

void APiratesPlayerState::OnActorChannelOpen(FInBunch& InBunch, UNetConnection* Connection)
{
    if (InBunch.bClose || InBunch.AtEnd())
    {
        Super::OnActorChannelOpen(InBunch, Connection);
        return;
    }

    auto GameCommon = UGameCommon::Get(this);
    if (GameCommon)
    {
        auto Delegate = GameCommon->GetGameDelegateManager()->PlayerState;
        Delegate->OnPlayerStateActorChannelOpen.ExecuteIfBound(this);
    }
    TArray<uint8> ReplicatedRawData;
    InBunch << ReplicatedRawData;
    auto Component = FindComponentByClass<UReplicatedProtoPropertyComponent>();
    if (Component && ReplicatedRawData.Num())
    {
        Component->ProcessRecvData(ReplicatedRawData);
    }
    Super::OnActorChannelOpen(InBunch, Connection);
}

void APiratesPlayerState::PostNetInit()
{
	Super::PostNetInit();

	// 第一次属性同步下来
	auto GameCommon = UGameCommon::Get(this);
	if (GameCommon)
	{
		auto Delegate = GameCommon->GetGameDelegateManager()->PlayerState;
		Delegate->OnPostNetInit.ExecuteIfBound(this);
	}
}

void APiratesPlayerState::RecalculateAvgPing()
{
	Super::RecalculateAvgPing();
	// player states are always relevant by default, bShouldUpdateReplicatedPing=true
	uint8 NewPing = FMath::Min(255, (int32)(ExactPing * 0.5f));
    SetPing(NewPing);
}

void APiratesPlayerState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	DOREPLIFETIME_CONDITION(APiratesPlayerState, PiratePlayerId, COND_InitialOnly);
}