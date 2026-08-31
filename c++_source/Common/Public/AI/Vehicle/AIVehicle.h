#pragma once

#include "CoreMinimal.h"

struct FAIVehicle : public TIntrusiveLinkedList<FAIVehicle>
{
    int32       InstanceId;
    FVector     Location;

public:
    FAIVehicle(FAIVehicle& Other) : InstanceId(Other.InstanceId), Location(Other.Location) {}
    FAIVehicle() : InstanceId(-1), Location(FVector::ZeroVector) {}
    FAIVehicle(int32 InInstanceId, const FVector& InLocation) :
        InstanceId(InInstanceId), Location(InLocation)
    {

    }

    bool operator==(const FAIVehicle & Other) const
    {
        return InstanceId == Other.InstanceId;
    }

    friend FArchive& operator<<(FArchive& Ar, FAIVehicle& V)
    {
        return Ar << V.InstanceId << V.Location;
    }
};

struct FAIVehicleCell
{

    FAIVehicle VehicleHead;

public:

    FAIVehicleCell() 
    {

    }

    FAIVehicleCell(int InvalidCellValue) 
    {

    }

    void Add(FAIVehicle* Vehicle);
    const FAIVehicle& GetHead() const
    {
        return VehicleHead;
    }

    friend FArchive& operator<<(FArchive& Ar, FAIVehicleCell& V)
    {

        for (FAIVehicle::TIterator It(V.VehicleHead.GetNextLink()); It; It.Next())
        {
            Ar << (*It);
        }
        
        return Ar;
    }
};