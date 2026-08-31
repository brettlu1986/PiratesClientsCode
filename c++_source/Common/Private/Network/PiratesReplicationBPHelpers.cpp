// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/PiratesReplicationBPHelpers.h"
#include "Common.h"
#include "PiratesReplicationGraph.h"

void UPiratesReplicationBPHelpers::SetTeamForPlayerController(APlayerController* Player, int32 TeamId)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(Player))
    {
        PiratesGraph->SetTeamForPlayerController(Player, TeamId);
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("SetTeamForPlayerController PiratesReplicationGraph not found"));
}

void UPiratesReplicationBPHelpers::ClearTeamReplicateById(AActor* Actor, int32 TeamId)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(Actor))
    {
        PiratesGraph->ClearTeamReplicateById(TeamId);
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("ClearTeamReplicateById PiratesReplicationGraph not found"));
}

void UPiratesReplicationBPHelpers::AddDependentActor(AActor* ReplicatorActor, AActor* DependentActor)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(ReplicatorActor))
    {
        PiratesGraph->AddDependentActor(ReplicatorActor, DependentActor);
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("AddDependentActor PiratesReplicationGraph not found"));
}

void UPiratesReplicationBPHelpers::RemoveDependentActor(AActor* ReplicatorActor, AActor* DependentActor)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(ReplicatorActor))
    {
        PiratesGraph->RemoveDependentActor(ReplicatorActor, DependentActor);
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("RemoveDependentActor PiratesReplicationGraph not found"));
}

void UPiratesReplicationBPHelpers::ChangeOwnerAndRefreshReplication(AActor* ActorToChange, AActor* NewOwner)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(ActorToChange))
    {
        PiratesGraph->ChangeOwnerOfAnActor(ActorToChange, NewOwner);
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("ChangeOwnerAndRefreshReplication PiratesReplicationGraph not found"));
}

void UPiratesReplicationBPHelpers::ChangeActorCullDistanceSquared(AActor* ActorToChange, float CullDistance)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(ActorToChange))
    {
        PiratesGraph->ChangeActorCullDistanceSquared(ActorToChange, CullDistance);      
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("ChangeActorCullDistanceSquared PiratesReplicationGraph not found"));
}

float UPiratesReplicationBPHelpers::GetActorCullDistanceSquared(AActor* Actor)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(Actor))
    {
        return PiratesGraph->GetActorCullDistanceSquared(Actor);
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("GetActorCullDistanceSquared PiratesReplicationGraph not found"));
    return 0.f;
}

void UPiratesReplicationBPHelpers::SetActorReplicateToController(APlayerController* PlayerController, AActor* Actor, bool bReplicate)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(PlayerController))
    {
        PiratesGraph->SetActorReplicateToController(PlayerController, Actor, bReplicate);
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("SetActorReplicateToController PiratesReplicationGraph not found"));
}

void UPiratesReplicationBPHelpers::SetReplicatePlayerMaxNum(APlayerController* Controller, int32 Num)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(Controller))
    {
        if (Num >= 0)
        {
            PiratesGraph->ReplicatePlayerMaxNum = Num;
        }
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("SetReplicatePlayerMaxNum PiratesReplicationGraph not found"));
}

void UPiratesReplicationBPHelpers::SetEnableLimitPlayerNum(UObject* Actor, bool bLimit)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(Actor))
    {
        PiratesGraph->bLimitPlayerNum = bLimit;
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("SetEnableLimitPlayerNum PiratesReplicationGraph not found"));
}

void UPiratesReplicationBPHelpers::SetActorDormantForConnection(AActor* DormantActor, AActor* OtherActor, uint8 bDormant)
{
    if (UPiratesReplicationGraph* PiratesGraph = FindReplicationGraph(DormantActor))
    {
        PiratesGraph->SetActorDormantForConnection(DormantActor, OtherActor, bDormant);
        return;
    }

    UE_LOG(LogPiratesReplicationGraph, Log, TEXT("SetActorDormantForConnection PiratesReplicationGraph not found"));
}

class UPiratesReplicationGraph* UPiratesReplicationBPHelpers::FindReplicationGraph(const UObject* WorldContextObject)
{
    if (WorldContextObject)
    {
        if (UWorld* World = WorldContextObject->GetWorld())
        {
            if (UNetDriver* NetworkDriver = World->GetNetDriver())
            {
                if (UPiratesReplicationGraph* PiratesGraph = NetworkDriver->GetReplicationDriver<UPiratesReplicationGraph>())
                {
                    return PiratesGraph;
                }
            }
        }
    }

    return nullptr;
}
