#pragma once

#include "CoreMinimal.h"

struct FAIDoor
{

    int32       InstanceId;
    int32       TransformId;
    FVector     Scale;
    FVector     Location;

public:

    FAIDoor(int32 InTransformId = 0, const FVector& InLocation = FVector::ZeroVector, const FVector& InScale = FVector(1, 1, 1)) :
        InstanceId(-1), TransformId(InTransformId), Scale(InScale), Location(InLocation)
    {

    }

    ~FAIDoor()
    {
        //UE_LOG(LogTemp, Log, TEXT("destroy ai door"));
    }

    FORCEINLINE const FVector& GetLocation() const
    {
        return Location;
    }

    bool operator==(const FAIDoor & Other) const
    {
        return InstanceId == Other.InstanceId;
    }

    void Serialize(FArchive& Ar);
};