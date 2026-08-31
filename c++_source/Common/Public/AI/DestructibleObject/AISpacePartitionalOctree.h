#pragma once

#include "Math/GenericOctree.h"
#include "EngineUtils.h"


template<typename ElementType>
struct FAIOctreeElement
{
    FBoxSphereBounds Bounds;
    TSharedPtr<ElementType> Element;

    FAIOctreeElement(TSharedPtr<ElementType>& InElemnt)
        :Element(InElemnt)
    {
        Bounds = FBoxSphereBounds(&Element->GetLocation(), 1);
    }
    FORCEINLINE TSharedPtr<ElementType> GetElement()  { return Element; }
    FORCEINLINE const TSharedPtr<ElementType>& GetElement() const { return Element; }
};


template<typename ElementType>
struct FAIOctreeSemantics
{
    enum { MaxElementsPerLeaf = 16 };
    enum { MinInclusiveElementsPerNode = 7 };
    enum { MaxNodeDepth = 12 };

    /** Using the heap allocator instead of an inline allocator to trade off add/remove performance for memory. */
    /** Since we won't generate covers after init, should be ok. */
    typedef FDefaultAllocator ElementAllocator;

    FORCEINLINE static bool AreElementsEqual(const FAIOctreeElement<ElementType>& A, const FAIOctreeElement<ElementType>& B)
    {
        return *A.GetElement() == *B.GetElement();
    }

    static void SetElementId(const FAIOctreeElement<ElementType>& Element, FOctreeElementId Id)
    {
    }

    FORCEINLINE static const FBoxSphereBounds& GetBoundingBox(const FAIOctreeElement<ElementType>& Element)
    {
        return Element.Bounds;
    }
};



template<typename ElementType>
class AIOctreeSpacePartition
{
    typedef TOctree<FAIOctreeElement<ElementType>, FAIOctreeSemantics<ElementType>> FAIOctree;

public:
    AIOctreeSpacePartition():Octree(nullptr)
    {

    };
    virtual ~AIOctreeSpacePartition()
    {
        UE_LOG(LogTemp, Log, TEXT("destroy ai octree space partition"));
        Clear();
    }

    TArray<TSharedPtr<ElementType>> GetElement(const FBoxCenterAndExtent& Bounds)
    {
        check(Octree);
        //double StartRecordTime = FPlatformTime::Seconds();
        TArray<TSharedPtr<ElementType>> Elements;
        for (typename FAIOctree::template TConstElementBoxIterator<> OctreeIt(*Octree, Bounds); OctreeIt.HasPendingElements(); OctreeIt.Advance())
        {
            Elements.Add(OctreeIt.GetCurrentElement().GetElement());
        }
        //float fTime = (float)(FPlatformTime::Seconds() - StartRecordTime)*1000.0f;
        //UE_LOG(LogTemp, Log, TEXT("find element in octree with time: %f ms"), fTime);
        return Elements;
    }

    bool AddElement(TSharedPtr<ElementType>& Element)
    {
        check(Octree);
        Octree->AddElement(FAIOctreeElement<ElementType>(Element));
        return true;
    }

    void Serialize(FArchive& Ar)
    {
        if (Ar.IsLoading())
        {
            FVector Center, Extent;
            Ar << Center;
            Ar << Extent;
            UE_LOG(LogTemp, Log, TEXT("otctree: extent %s, center %s"), *Extent.ToString(), *Center.ToString());
            Octree = TUniquePtr<FAIOctree>(new FAIOctree(Center, Extent.GetAbsMax()));
        }
        else
        {
            FVector Extent = Octree->GetRootBounds().Extent;
            FVector Center = Octree->GetRootBounds().Center;
            Ar << Center;
            Ar << Extent;
        }
    }

    void Clear()
    {
        if (Octree)
        {
            Octree->Destroy();
            Octree = nullptr;
        }
    }

    void ShrinkElements()
    {
        check(Octree);
        Octree->ShrinkElements();
    }

    uint32 GetAllocatedSize() const
    {
        check(Octree);
        return Octree->GetSizeBytes() + sizeof(FBoxCenterAndExtent);
    }

    void DumpOctree()
    {
        check(Octree);
        Octree->DumpStats();
    }

protected:

    TUniquePtr<FAIOctree> Octree;
    FBoxCenterAndExtent BoundingBox;
};

