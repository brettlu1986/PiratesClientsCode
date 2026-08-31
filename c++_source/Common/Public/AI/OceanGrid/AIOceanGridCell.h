#pragma once

#include "CoreMinimal.h"

class FAIItemBase : public TIntrusiveLinkedList<FAIItemBase>
{
public:
    int32       Id;
    FVector     Location;

public:

    FAIItemBase(int32 InId = INDEX_NONE, const FVector& InLocation = FVector::ZeroVector) :
        Id(InId), Location(InLocation)
    {

    }

    virtual uint32 GetAllocatedSize() const
    {
        return sizeof(FAIItemBase);
    }

    friend FArchive& operator<<(FArchive& Ar, FAIItemBase& V)
    {
        return Ar << V.Id << V.Location;
    }
};

template<typename T>
class FAIOceanItem : public FAIItemBase
{
public:
    T ItemData;

public:
    FAIOceanItem(int32 InId = INDEX_NONE, const FVector& InLocation = FVector::ZeroVector) :
    FAIItemBase(InId, InLocation)
    { }

    FAIOceanItem(int32 InId , const FVector& InLocation, const T& InData) : FAIItemBase(InId, InLocation), ItemData(InData) { }

    virtual uint32 GetAllocatedSize() const override
    {
        return sizeof(FAIItemBase) + sizeof(ItemData);
    }
};

struct FAIOceanGridCellCell
{
    typedef TMap<int32, TSharedPtr<FAIItemBase>> ItemHeadMap;

    ItemHeadMap ItemHeads;

public:

    FAIOceanGridCellCell() { }

    FAIOceanGridCellCell(int InvalidCellValue) { }

    ~FAIOceanGridCellCell()
    {
        ItemHeads.Empty();
    }

    template<typename T>
    void Add(FAIOceanItem<T>* ItemToAdd)
    {
        if (ItemToAdd)
        {
            ItemToAdd->Unlink();
            int32 ItemKind = T::GetItemId();
            auto ItemHead = ItemHeads.Find(ItemKind);
            if (ItemHead && (*ItemHead).IsValid())
            {
                ItemToAdd->LinkAfter((*ItemHead).Get());
            }
            else
            {
                TSharedPtr<FAIOceanItem<T>> NewItemHead = MakeShared<FAIOceanItem<T>>();
                ItemToAdd->LinkAfter(NewItemHead.Get());
                ItemHeads.Emplace(ItemKind, NewItemHead);
            }
        }
    }

    template<typename T>
    const FAIItemBase* GetHead() const
    {
        int32 ItemKind = T::GetItemId();
        auto ItemHead = ItemHeads.Find(ItemKind);
        if (ItemHead)
        {
            return (*ItemHead).Get();
        }
        return nullptr;
    }

    friend FArchive& operator<<(FArchive& Ar, FAIOceanGridCellCell& V)
    {
        for (auto& Head : V.ItemHeads)
        {
            auto HeadItem = Head.Value;
            for (FAIItemBase::TIterator It(HeadItem->GetNextLink()); It; It.Next())
            {
                Ar << (*It);
            }
        }
        
        return Ar;
    }
};