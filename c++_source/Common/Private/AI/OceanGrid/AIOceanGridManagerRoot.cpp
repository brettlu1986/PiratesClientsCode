#include "AI/OceanGrid/AIOceanGridManagerRoot.h"
#include "Shell/CommonShell.h"
#include "Engine/World.h"


UAIOceanGridManagerRoot::UAIOceanGridManagerRoot(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer), OceanGridManager(new AIOceanGridManager())
{

}

bool UAIOceanGridManagerRoot::Init()
{
    if (OceanGridManager)
    {
        return true;
    }
    return false;
}

void UAIOceanGridManagerRoot::InitCells(float Width, float Height, float CenterX, float CenterY, float CellSize)
{
    if (OceanGridManager)
    {
        float HalfWidth  = Width * 0.5;
        float HalfHeight = Height * 0.5;
        FBox Bounds(FVector(CenterX - HalfWidth, CenterY - HalfHeight, 0), 
            FVector(CenterX + HalfWidth, CenterY + HalfHeight, 0));
        OceanGridManager->Clear();
        OceanGridManager->Init(CellSize, Bounds);
    }
}

bool UAIOceanGridManagerRoot::Uninit()
{
    if (OceanGridManager)
    {
        OceanGridManager->Clear();
    }
    return true;
}

bool UAIOceanGridManagerRoot::AddTorpedo(AActor* TorpedoActor)
{
    if (OceanGridManager && TorpedoActor)
    {
        return OceanGridManager->AddItem<FAITorpedo>(TorpedoActor->GetUniqueID(), TorpedoActor->GetActorLocation(), TorpedoActor);
    }
    return false;
}

bool UAIOceanGridManagerRoot::RemoveTorpedo(int32 UniqueId)
{
    if (OceanGridManager)
    {
        return OceanGridManager->RemoveItem<FAITorpedo>(UniqueId);
    }
    return false;
}

void UAIOceanGridManagerRoot::FindTorpedo(APawn* Pawn, float SightDist, float SightFOV, UWorld* World, TArray<int32>& OutIds)
{
    if (OceanGridManager)
    {
        return OceanGridManager->FindItem<FAITorpedo>(Pawn, SightDist, SightFOV, World, OutIds);
    }
}

void UAIOceanGridManagerRoot::Dump()
{
    if (OceanGridManager)
    {
        int32 CellCount = OceanGridManager->GetCellsCount();
        int32 MemorySize = OceanGridManager->GetTotalMemorySize();
        int32 ItemCount = OceanGridManager->GetItemCount();
        float CellSize = OceanGridManager->GridCellSize;
        const FBox& WorldBounds = OceanGridManager->WorldBounds;
        UE_LOG(LogTemp, Display, TEXT("AIOceanGridManager: MemorySize: %.2f kb, CellCount: %d, GridSize: %.2f, WorldBounds: %s, Item Count: %d"), MemorySize / 1024.0f, CellCount, CellSize, *WorldBounds.ToString(), ItemCount);
    }
}

const FAIOceanItem<FAITorpedo>* UAIOceanGridManagerRoot::GetTorpedo(int32 UniqueId) const
{
    if (OceanGridManager)
    {
        return OceanGridManager->GetItem<FAITorpedo>(UniqueId);
    }
    return nullptr;
}