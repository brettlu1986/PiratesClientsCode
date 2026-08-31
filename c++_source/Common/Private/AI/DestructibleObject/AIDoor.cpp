#include "AI/DestructibleObject/AIDoor.h"

void FAIDoor::Serialize(FArchive& Ar)
{
    Ar << Location;
    Ar << TransformId;
    Ar << Scale;
    UE_LOG(LogTemp, Log, TEXT("door: location %s, scale %s, transformid %d"), *Location.ToString(), *Scale.ToString(), int32(TransformId));
}

