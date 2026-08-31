#include "Game/Battle/PiratesGameGroupPrivateInfo.h"
#include "Common.h"
#include "PiratesGameState.h"
#include "PiratesPlayerController.h"
//
//
//APiratesGameGroupPrivateInfo::APiratesGameGroupPrivateInfo(const FObjectInitializer& ObjectInitializer)
//    : Super(ObjectInitializer)
//{
//    bReplicates = true;
//    PrimaryActorTick.bCanEverTick = false;
//    PrimaryActorTick.bStartWithTickEnabled = false;
//
//    GroupIndex = -1;
//    SurrenderState = EPiratesSurrenderState::Disabled;
//}
//
//bool APiratesGameGroupPrivateInfo::IsNetRelevantFor(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const
//{
//    const APiratesPlayerController* PC = Cast<APiratesPlayerController>(RealViewer);
//    if (PC == nullptr)
//        return false;
//
//    return (GroupIndex == PC->GroupIndex);
//}
//
//void APiratesGameGroupPrivateInfo::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
//{
//    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
//
//    DOREPLIFETIME(APiratesGameGroupPrivateInfo, GroupIndex);
//    DOREPLIFETIME(APiratesGameGroupPrivateInfo, SurrenderState);
//}
//
//void APiratesGameGroupPrivateInfo::Init(int32 InGroupIndex)
//{
//    check(InGroupIndex > -1);
//    GroupIndex = InGroupIndex;
//}
//
//void APiratesGameGroupPrivateInfo::AddPlayerController(APiratesPlayerController * PC)
//{
//    Controllers.AddUnique(PC);
//}
//
//void APiratesGameGroupPrivateInfo::RemovePlayerController(APiratesPlayerController * PC)
//{
//    Controllers.Remove(PC);
//}
//
//void APiratesGameGroupPrivateInfo::FailToVoteForSurrender(int32 PlayerId)
//{
//    for (auto& PC : Controllers)
//    {
//        if (PC->GlobalPlayerId == PlayerId)
//        {
//            PC->ClientFailToVoteForSurrender();
//            break;
//        }
//    }
//}
//
//void APiratesGameGroupPrivateInfo::StartVotingForSurrender(int32 PlayerId)
//{
//    SurrenderState = EPiratesSurrenderState::Voting;
//
//    for (auto& PC : Controllers)
//    {
//        PC->ClientStartVotingForSurrender(PlayerId);
//    }
//}
//
//void APiratesGameGroupPrivateInfo::UpdateVotingStateForSurrender(int32 PlayerId, bool Agreed)
//{
//    for (auto& PC : Controllers)
//    {
//        PC->ClientVoteForSurrender(PlayerId, Agreed);
//    }
//}
//
//void APiratesGameGroupPrivateInfo::EndVotingForSurrender(bool Approved, float CoolDownTime)
//{
//    if (Approved)
//    {
//        SurrenderState = EPiratesSurrenderState::Approved;
//    }
//    else
//    {
//        SurrenderState = EPiratesSurrenderState::CoolDown;
//    }
//    
//    for (auto& PC : Controllers)
//    {
//        PC->ClientEndVotingForSurrender(Approved, CoolDownTime);
//    }
//}
//
//void APiratesGameGroupPrivateInfo::EndCoolDownForSurrender()
//{
//    SurrenderState = EPiratesSurrenderState::Free;
//}
//
//void APiratesGameGroupPrivateInfo::OnRep_SurrenderState()
//{
//    APiratesGameState* GameState = GetWorld()->GetGameState<APiratesGameState>();
//    if (GameState != nullptr)
//    {
//        if (SurrenderState == EPiratesSurrenderState::Free)
//        {
//            GameState->HandleEnableSurrender(GroupIndex);
//        }
//    }
//}
//
//
