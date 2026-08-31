#include "AI/DestructibleObject/AIDestructibleObjectManagerRoot.h"

UAIDestructibleObjectManagerRoot::UAIDestructibleObjectManagerRoot(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer),DoorManager(nullptr)
{

}


bool UAIDestructibleObjectManagerRoot::Init()
{
    DoorManager = TUniquePtr<AIDoorManager>(new AIDoorManager());
    if (DoorManager)
    {
        DoorManager->Init();
        return true;
    }
    return false;
}

bool UAIDestructibleObjectManagerRoot::Uninit()
{
    if (DoorManager)
    {
        DoorManager->Uninit();
        DoorManager = nullptr;
    }
    return true;
}

void UAIDestructibleObjectManagerRoot::Clear()
{
    Uninit();
}

bool UAIDestructibleObjectManagerRoot::GetDoors(const FVector& Location, float Extent, TArray<int32>& OutDoorInstanceIds)
{
    if (DoorManager)
    {
        //double StartRecordTime = FPlatformTime::Seconds();
        FBoxCenterAndExtent Bound(Location, FVector(Extent));
        TArray<TSharedPtr<FAIDoor>> Doors = DoorManager->GetElement(Bound);
        for (auto Door : Doors)
        {
            OutDoorInstanceIds.Emplace(Door->InstanceId);
        }
        //float fTime = (float)(FPlatformTime::Seconds() - StartRecordTime)*1000.0f;
        //UE_LOG(LogTemp, Log, TEXT("get doors with time: %f ms"), fTime);
        return OutDoorInstanceIds.Num() > 0;
    }
    return false;
}

int32 UAIDestructibleObjectManagerRoot::GetNearestDoor(const FVector& Location, float Extent)
{
    if (DoorManager)
    {
        //double StartRecordTime = FPlatformTime::Seconds();
        FBoxCenterAndExtent Bound(Location, FVector(Extent));
        TArray<TSharedPtr<FAIDoor>> Doors = DoorManager->GetElement(Bound);
        int32 nRet = -1;
        float NearestDistSquared = -1;
        for (auto Door : Doors)
        {
            float CurDistSquared = FVector::DistSquared(Location, Door->Location);
            if (CurDistSquared < NearestDistSquared || NearestDistSquared < 0)
            {
                nRet = Door->InstanceId;
                NearestDistSquared = CurDistSquared;
            }
        }
        //float fTime = (float)(FPlatformTime::Seconds() - StartRecordTime)*1000.0f;
        //UE_LOG(LogTemp, Log, TEXT("get nearest door with time: %f ms"), fTime);
        return nRet;
    }
    return -1;
}

void UAIDestructibleObjectManagerRoot::SetDoorInstanceId(int32 TransformId, int32 InstanceId)
{
    if (DoorManager)
    {
        DoorManager->SetInstanceId(TransformId, InstanceId);
    }
}

void UAIDestructibleObjectManagerRoot::DumpStat()
{
    if (DoorManager)
    {
        DoorManager->DumpStat();
    }
}
