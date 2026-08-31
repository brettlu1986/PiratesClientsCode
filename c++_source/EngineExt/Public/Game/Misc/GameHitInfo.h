#pragma once
#include "GameHitInfo.generated.h"

class AActor;

USTRUCT(Blueprintable)
struct FGameHitInfo
{
    GENERATED_USTRUCT_BODY()

    /** The amount of damage actually applied */
    UPROPERTY()
    float ActualDamage;

    /** Who hit us */
    UPROPERTY()
    TWeakObjectPtr<AActor> Instigator;

    /** Who actually caused the damage */
    UPROPERTY()
    TWeakObjectPtr<AActor> DamageCauser;

    UPROPERTY()
    UClass* DamageTypeClass;

private:

    /** A rolling counter used to ensure the struct is dirty and will replicate. */
    UPROPERTY()
    uint8 EnsureReplicationByte;

public:
    FGameHitInfo();
    void EnsureReplication();
};