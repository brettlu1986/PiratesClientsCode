#pragma once

#include "CoreMinimal.h"
#include "AIModule/Public/SimpleCellGrid.h"
#include "AIOceanGridCell.h"

class AIOceanGridManager : public TSimpleCellGrid<FAIOceanGridCellCell>
{
public:
    template<typename T>
    bool SetItemLocation(int32 Id, const FVector& Location)
    {
        int32 CellIndex = GetCellIndex(Location);
        if (CellIndex != INDEX_NONE)
        {
            TSharedPtr<FAIItemBase>* ItemPtr = Items.Find(Id);
            if (ItemPtr)
            {
                TSharedPtr<FAIItemBase>& Item = (*ItemPtr);
                if (Item.IsValid())
                {
                    Item->Location = Location;
                    FAIOceanGridCellCell& Cell = GetCellAtIndexUnsafe(CellIndex);
                    Cell.Add<T>(static_cast<FAIOceanItem<T>*>(Item.Get()));
                    UE_LOG(LogTemp, Log, TEXT("set item location %d, %s"), Id, *Location.ToString());
                    return true;
                }
            }
        }
        return false;
    }

    template<typename T, typename... InArgTypes>
    bool AddItem(int32 Id, const FVector& Location, InArgTypes&&... Args)
    {
        if (!Items.Contains(Id))
        {
            int32 CellIndex = GetCellIndex(Location);
            if (CellIndex != INDEX_NONE)
            {
                TSharedPtr<FAIOceanItem<T>> NewItem = MakeShared<FAIOceanItem<T>>(Id
                    , Location, T(Forward<InArgTypes>(Args)...));
                Items.Emplace(Id, NewItem);
                NewItem->Location = Location;
                NewItem->Id = Id;
                FAIOceanGridCellCell& Cell = GetCellAtIndexUnsafe(CellIndex);
                Cell.Add<T>(NewItem.Get());
                UE_LOG(LogTemp, Log, TEXT("set item location %d, %s at cell %d"), Id, *Location.ToString(), CellIndex);
                return true;
            }
        }
        return false;
    }

    template<typename T>
    bool RemoveItem(int32 Id)
    {
        auto ItemPtr = Items.Find(Id);;
        if (ItemPtr)
        {
            UE_LOG(LogTemp, Log, TEXT("removed item %d"), Id);
            (*ItemPtr)->Unlink();
            Items.Remove(Id);
            return true;
        }
        return false;
    }

    template<typename T>
    const FAIOceanItem<T>* GetItem(int32 Id) const
    {
        auto ItemPtr = Items.Find(Id);;
        if (ItemPtr)
        {
            return static_cast<FAIOceanItem<T>*>((*ItemPtr).Get());
        }
        return nullptr;
    }


    template<typename T>
    void FindItem(APawn* Pawn, float SightDist, float SightFOV, UWorld* World, TArray<int32>& OutIds)
    {
        if (!Pawn || Pawn->IsPendingKill() || !World)
        {
            return;
        }
        /*    double StartTime = FPlatformTime::Seconds();*/
        FVector Location = Pawn->GetActorLocation();

        FIntVector CellCoords = GetCellCoordsUnsafe(Location);
        TArray<FIntVector> CellCoordsList;
        CellCoordsList.Emplace(CellCoords);
        CellCoordsList.Emplace(CellCoords + FIntVector(1, -1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(1, 0, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(1, 1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(0, -1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(0, 1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(-1, -1, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(-1, 0, 0));
        CellCoordsList.Emplace(CellCoords + FIntVector(-1, 1, 0));

        float LimitDistanceSquared = SightDist * SightDist;

        FVector  EyePosition;
        FRotator EyeRotator;
        Pawn->GetActorEyesViewPoint(EyePosition, EyeRotator);
        const FVector OwnerFowardDir = EyeRotator.Vector().GetSafeNormal2D();
        const float LimitDot = FMath::Cos(SightFOV * 0.5f * PI / (180.f));

        for (const FIntVector& Coords : CellCoordsList)
        {
            int32 CellIndex = GetCellIndex(Coords.X, Coords.Y);
            if (CellIndex != INDEX_NONE)
            {
                FAIOceanGridCellCell& Cell = GetCellAtIndexUnsafe(CellIndex);
                const FAIItemBase* Head = Cell.GetHead<T>();
                if (Head)
                {
                    for (FAIItemBase::TConstIterator It(Head->GetNextLink()); It; It.Next())
                    {
                        FVector TraceEnd = (*It).Location;
                        FVector TraceStart = EyePosition;

                        float SquaredDistance = FVector::DistSquaredXY(TraceStart, TraceEnd);
                        float Dot = FVector::DotProduct(OwnerFowardDir, (TraceEnd - TraceStart).GetSafeNormal2D());
                        if (SquaredDistance <= LimitDistanceSquared && Dot >= LimitDot)
                        {
                            OutIds.Emplace((*It).Id);

                        }
                    }
                }
            }
        }
    }

    uint32 GetTotalMemorySize() const
    {
        uint32 MemorySize = GetAllocatedSize();
        for (auto Item : Items)
        {
            MemorySize += (*Item.Value).GetAllocatedSize();
        }
        MemorySize += Items.GetAllocatedSize();
        return MemorySize;
    }

    int32 GetItemCount() const
    {
        return Items.Num();
    }

    void Clear()
    {
        UE_LOG(LogTemp, Log, TEXT("Ocean Grid Manager Clear"));
        Zero();
        Items.Empty(0);
    }

protected:

    typedef TMap<int32, TSharedPtr<FAIItemBase>> ItemMap;
    ItemMap Items;

};