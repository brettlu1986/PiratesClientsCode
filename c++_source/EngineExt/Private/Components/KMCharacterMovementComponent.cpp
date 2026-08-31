// Fill out your copyright notice in the Description page of Project Settings.

#include "KMCharacterMovementComponent.h"
#include "EngineExt.h"
#include "KMCharacter.h"
#include "Engine/GameInstance.h"
#include "GameFramework/GameNetworkManager.h"

UKMCharacterMovementComponent::UKMCharacterMovementComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , EnableMovementSyncLocal(true)
{
}

void UKMCharacterMovementComponent::DiscardPendingMove()
{
    FNetworkPredictionData_Client_Character* ClientData = GetPredictionData_Client_Character();
    if (ClientData && ClientData->PendingMove.IsValid())
    {
        if (CharacterOwner->IsReplicatingMovement())
        {
            UE_LOG(LogNetPlayerMovement, Verbose, TEXT("Ignore Pending move"));
            // Remove pending move from move list. It would have to be the last move on the list.
            if (ClientData->SavedMoves.Num() > 0 && ClientData->SavedMoves.Last() == ClientData->PendingMove)
            {
                ClientData->SavedMoves.Pop();
            }
            ClientData->FreeMove(ClientData->PendingMove);
            ClientData->PendingMove = NULL;
        }
        else
        {
            ClientData->PendingMove = NULL;
        }
    }
}

void UKMCharacterMovementComponent::ServerMove_Implementation(float TimeStamp, FVector_NetQuantize10 InAccel, FVector_NetQuantize100 ClientLoc, uint8 CompressedMoveFlags, uint8 ClientRoll, uint32 View, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode)
{
    if (!EnableMovementSyncLocal)
    {
        return;
    }

    Super::ServerMove_Implementation(TimeStamp, InAccel, ClientLoc, CompressedMoveFlags, ClientRoll, View, ClientMovementBase, ClientBaseBoneName, ClientMovementMode);
}

void UKMCharacterMovementComponent::ServerMoveDual_Implementation(float TimeStamp0, FVector_NetQuantize10 InAccel0, uint8 PendingFlags, uint32 View0, float TimeStamp, FVector_NetQuantize10 InAccel, FVector_NetQuantize100 ClientLoc, uint8 NewFlags, uint8 ClientRoll, uint32 View, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode)
{
    if (!EnableMovementSyncLocal)
    {
        return;
    }

    Super::ServerMoveDual_Implementation(TimeStamp0, InAccel0, PendingFlags, View0, TimeStamp, InAccel, ClientLoc, NewFlags, ClientRoll, View, ClientMovementBase, ClientBaseBoneName, ClientMovementMode);
}

void UKMCharacterMovementComponent::ServerMoveDualHybridRootMotion_Implementation(float TimeStamp0, FVector_NetQuantize10 InAccel0, uint8 PendingFlags, uint32 View0, float TimeStamp, FVector_NetQuantize10 InAccel, FVector_NetQuantize100 ClientLoc, uint8 NewFlags, uint8 ClientRoll, uint32 View, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode)
{
    if (!EnableMovementSyncLocal)
    {
        return;
    }

    Super::ServerMoveDualHybridRootMotion_Implementation(TimeStamp0, InAccel0, PendingFlags, View0, TimeStamp, InAccel, ClientLoc, NewFlags, ClientRoll, View, ClientMovementBase, ClientBaseBoneName, ClientMovementMode);
}

void UKMCharacterMovementComponent::ServerMoveOld_Implementation(float OldTimeStamp, FVector_NetQuantize10 OldAccel, uint8 OldMoveFlags)
{
    if (!EnableMovementSyncLocal)
    {
        return;
    }

    Super::ServerMoveOld_Implementation(OldTimeStamp, OldAccel, OldMoveFlags);
}

void UKMCharacterMovementComponent::CallServerMove(const class FSavedMove_Character* NewMove, const class FSavedMove_Character* OldMove)
{
    if (!EnableMovementSyncLocal)
    {
        return;
    }

    Super::CallServerMove(NewMove, OldMove);
}

void UKMCharacterMovementComponent::ClientAckGoodMove(float TimeStamp)
{
    // 这个感觉不屏蔽也没什么事
    //if (!EnableMovementSyncLocal)
    //{
    //    return;
    //}

    Super::ClientAckGoodMove(TimeStamp);
}

void UKMCharacterMovementComponent::ClientAdjustPosition(float TimeStamp, FVector NewLoc, FVector NewVel, UPrimitiveComponent* NewBase, FName NewBaseBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode)
{
    if (!EnableMovementSyncLocal)
    {
        if (AdjustPositionInfo.IsValid())
        {
            AdjustPositionInfo->Set(TimeStamp, NewLoc, NewVel, NewBase, NewBaseBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode);
        }
        return;
    }

    Super::ClientAdjustPosition(TimeStamp, NewLoc, NewVel, NewBase, NewBaseBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode);
}

void UKMCharacterMovementComponent::ClientVeryShortAdjustPosition(float TimeStamp, FVector NewLoc, UPrimitiveComponent* NewBase, FName NewBaseBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode)
{
    if (!EnableMovementSyncLocal)
    {
        if (AdjustPositionInfo.IsValid())
        {
            AdjustPositionInfo->Set(TimeStamp, NewLoc, NewBase, NewBaseBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode);
        }
        return;
    }

    Super::ClientVeryShortAdjustPosition(TimeStamp, NewLoc, NewBase, NewBaseBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode);
}

void UKMCharacterMovementComponent::ClientAdjustRootMotionPosition(float TimeStamp, float ServerMontageTrackPosition, FVector ServerLoc, FVector_NetQuantizeNormal ServerRotation, float ServerVelZ, UPrimitiveComponent* ServerBase, FName ServerBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode)
{
    if (!EnableMovementSyncLocal)
    {
        // 这里如果有需要在记录Info
        return;
    }

    Super::ClientAdjustRootMotionPosition(TimeStamp, ServerMontageTrackPosition, ServerLoc, ServerRotation, ServerVelZ, ServerBase, ServerBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode);
}

void UKMCharacterMovementComponent::ClientAdjustRootMotionSourcePosition(float TimeStamp, FRootMotionSourceGroup ServerRootMotion, bool bHasAnimRootMotion, float ServerMontageTrackPosition, FVector ServerLoc, FVector_NetQuantizeNormal ServerRotation, float ServerVelZ, UPrimitiveComponent* ServerBase, FName ServerBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode)
{
    if (!EnableMovementSyncLocal)
    {
        // 这里如果有需要在记录Info
        return;
    }

    Super::ClientAdjustRootMotionSourcePosition(TimeStamp, ServerRootMotion, bHasAnimRootMotion, ServerMontageTrackPosition, ServerLoc, ServerRotation, ServerVelZ, ServerBase, ServerBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode);
}

void UKMCharacterMovementComponent::SetMovementSyncEnabled(bool Enabled)
{
    if (Enabled != EnableMovementSyncLocal)
    {
        EnableMovementSyncLocal = Enabled;
        if (!GetWorld()->GetGameInstance()->IsDedicatedServerInstance())
        {
            OnLocalSyncChangedInClient();
        }
    }
}

void UKMCharacterMovementComponent::OnLocalSyncChangedInClient()
{
    if (EnableMovementSyncLocal)
    {
        if (AdjustPositionInfo.IsValid())
        {
            auto& Info = *AdjustPositionInfo.Get();
            if (Info.IsDirty && HasValidData() && IsActive())
            {
                if (Info.IsShortAdjust)
                {
                    ClientVeryShortAdjustPosition(
                        Info.TimeStamp,
                        Info.NewLoc,
                        Info.NewBase.Get(),
                        Info.NewBaseBoneName,
                        Info.bHasBase,
                        Info.bBaseRelativePosition,
                        Info.ServerMovementMode);
                }
                else
                {
                    ClientAdjustPosition(
                        Info.TimeStamp,
                        Info.NewLoc,
                        Info.NewVel,
                        Info.NewBase.Get(),
                        Info.NewBaseBoneName,
                        Info.bHasBase,
                        Info.bBaseRelativePosition,
                        Info.ServerMovementMode);
                }
            }
            AdjustPositionInfo.Reset();
        }

        FlushServerMoves();
    }
    else
    {
        AdjustPositionInfo.Reset(new FAdjustPositionInfo());
    }
}