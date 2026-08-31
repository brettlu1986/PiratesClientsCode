#include "PiratesPlayerStart.h"
#include "Common.h"


APiratesPlayerStart::APiratesPlayerStart(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
{
    GroupIndex = -1;// -1 means for all teams
    bCanRespawn = true;
    bActive = true;
    Priority = 0;
    UsedTimes = 0;
}