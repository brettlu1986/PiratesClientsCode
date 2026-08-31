#include "Game/Misc/GameHitInfo.h"
#include "EngineExt.h"


FGameHitInfo::FGameHitInfo()
    : ActualDamage(0.0f)
    , DamageTypeClass(nullptr)
    , EnsureReplicationByte(0)
{

}

void FGameHitInfo::EnsureReplication()
{
    ++EnsureReplicationByte;
}
