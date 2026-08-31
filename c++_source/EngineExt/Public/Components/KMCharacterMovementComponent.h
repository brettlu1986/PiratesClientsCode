// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/CharacterMovementComponent.h"
#include "KMCharacterMovementComponent.generated.h"

UCLASS()
class ENGINEEXT_API UKMCharacterMovementComponent : public UCharacterMovementComponent
{
    GENERATED_UCLASS_BODY()

public:
    /** 当存在PendingMove时，丢弃掉 */
    UFUNCTION()
    void DiscardPendingMove();

public:
    void SetMovementSyncEnabled(bool Enabled);

protected:
    // 各种屏蔽收发包操作
    // 之所以写俩是因为客户端上行时用validate屏蔽发包，server收到时用Implementation屏蔽收包
    virtual void ServerMove_Implementation(float TimeStamp, FVector_NetQuantize10 InAccel, FVector_NetQuantize100 ClientLoc, uint8 CompressedMoveFlags, uint8 ClientRoll, uint32 View, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode) override;    
    virtual void ServerMoveDual_Implementation(float TimeStamp0, FVector_NetQuantize10 InAccel0, uint8 PendingFlags, uint32 View0, float TimeStamp, FVector_NetQuantize10 InAccel, FVector_NetQuantize100 ClientLoc, uint8 NewFlags, uint8 ClientRoll, uint32 View, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode) override;    
    virtual void ServerMoveDualHybridRootMotion_Implementation(float TimeStamp0, FVector_NetQuantize10 InAccel0, uint8 PendingFlags, uint32 View0, float TimeStamp, FVector_NetQuantize10 InAccel, FVector_NetQuantize100 ClientLoc, uint8 NewFlags, uint8 ClientRoll, uint32 View, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode) override;
    virtual void ServerMoveOld_Implementation(float OldTimeStamp, FVector_NetQuantize10 OldAccel, uint8 OldMoveFlags) override;    

    virtual void CallServerMove(const class FSavedMove_Character* NewMove, const class FSavedMove_Character* OldMove) override;
    virtual void ClientAckGoodMove(float TimeStamp) override;
    virtual void ClientAdjustPosition(float TimeStamp, FVector NewLoc, FVector NewVel, UPrimitiveComponent* NewBase, FName NewBaseBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode) override;
    virtual void ClientVeryShortAdjustPosition(float TimeStamp, FVector NewLoc, UPrimitiveComponent* NewBase, FName NewBaseBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode) override;
    virtual void ClientAdjustRootMotionPosition(float TimeStamp, float ServerMontageTrackPosition, FVector ServerLoc, FVector_NetQuantizeNormal ServerRotation, float ServerVelZ, UPrimitiveComponent* ServerBase, FName ServerBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode) override;
    virtual void ClientAdjustRootMotionSourcePosition(float TimeStamp, FRootMotionSourceGroup ServerRootMotion, bool bHasAnimRootMotion, float ServerMontageTrackPosition, FVector ServerLoc, FVector_NetQuantizeNormal ServerRotation, float ServerVelZ, UPrimitiveComponent* ServerBase, FName ServerBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode) override;    

protected:    
    virtual void OnLocalSyncChangedInClient();    

protected:
    struct FAdjustPositionInfo
    {
        float TimeStamp;
        FVector NewLoc;
        FVector NewVel;
        TWeakObjectPtr<UPrimitiveComponent> NewBase;
        FName NewBaseBoneName;
        bool bHasBase;
        bool bBaseRelativePosition;
        uint8 ServerMovementMode;
        bool IsShortAdjust;
        bool IsDirty;

        FAdjustPositionInfo()
        {
            FMemory::Memzero(this, sizeof(FAdjustPositionInfo));
        }

        void Set(float InTimeStamp, 
            const FVector& InNewLoc, 
            const FVector& InNewVel, 
            UPrimitiveComponent* InNewBase, 
            const FName& InNewBaseBoneName, 
            bool bInHasBase, 
            bool bInBaseRelativePosition, 
            uint8 InServerMovementMode)
        {
            TimeStamp = InTimeStamp;
            NewLoc = InNewLoc;
            NewVel = InNewVel;
            NewBase = InNewBase;
            NewBaseBoneName = InNewBaseBoneName;
            bHasBase = bInHasBase;
            bBaseRelativePosition = bInBaseRelativePosition;
            ServerMovementMode = InServerMovementMode;
            IsShortAdjust = false;
            IsDirty = true;
        }

        void Set(float InTimeStamp,
            const FVector& InNewLoc,
            UPrimitiveComponent* InNewBase,
            const FName& InNewBaseBoneName,
            bool bInHasBase,
            bool bInBaseRelativePosition,
            uint8 InServerMovementMode)
        {
            TimeStamp = InTimeStamp;
            NewLoc = InNewLoc;
            NewVel = FVector(0.0f, 0.0f, 0.0f);
            NewBase = InNewBase;
            NewBaseBoneName = InNewBaseBoneName;
            bHasBase = bInHasBase;
            bBaseRelativePosition = bInBaseRelativePosition;
            ServerMovementMode = InServerMovementMode;
            IsShortAdjust = true;
            IsDirty = true;
        }

        void Reset()
        {
            IsDirty = false;
        }
    };

protected:
    TUniquePtr<FAdjustPositionInfo> AdjustPositionInfo;
    bool EnableMovementSyncLocal;
};
