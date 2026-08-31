#pragma once

#include "CoreMinimal.h"
#include "Math/GenericOctree.h"
#include "Shell/CommonShell.h"
#include "Battle/PiratesGridTypeManager.h"

template<typename SpacePartitionContainer, typename Element>
class AISpacePartitionalManager
{
    
    typedef TMap<int32, TSharedPtr<SpacePartitionContainer>> SPCMap;
    typedef TArray<TSharedPtr<Element>> ElementArray;
public:
    AISpacePartitionalManager():bLoaded(false)
    {

    }

    virtual ~AISpacePartitionalManager()
    {
        UnLoad();
    }

public:
    virtual bool Init()
    {
        OnPostLoadMapHandle = FCoreUObjectDelegates::PostLoadMapWithWorld.AddRaw(this, &AISpacePartitionalManager::OnPostLoadMap);
        OnWorldCleanUpHandle = FWorldDelegates::OnWorldCleanup.AddRaw(this, &AISpacePartitionalManager::OnWorldCleanUp);
        return true;
    }

    virtual bool Uninit()
    {
        FCoreUObjectDelegates::PostLoadMapWithWorld.Remove(OnPostLoadMapHandle);
        FWorldDelegates::OnWorldCleanup.Remove(OnWorldCleanUpHandle);
        return true;
    }

    virtual void OnElementAdded(TSharedPtr<Element>& InElement)
    {

    }

    virtual void OnRegionAdded(TSharedPtr<SpacePartitionContainer>& SPC)
    {

    }

    virtual bool Load(const FString& WorldName)
    {
        UnLoad();
        FString FilePath = GetConfigPath(WorldName);
        UE_LOG(LogTemp, Log, TEXT("aisp:load data in path: %s"), *FilePath);
        IFileManager& FileManager = IFileManager::Get();
        FArchive* FileReader = FileManager.CreateFileReader(*FilePath);
        if (FileReader)
        {
            uint16 Version = 0;
            uint8 NumIsland = 0;
            (*FileReader) << Version;
            (*FileReader) << NumIsland;
            UE_LOG(LogTemp, Log, TEXT("aisp: version %d, num island %d"), int32(Version), int32(NumIsland));
            for (uint8 i = 0; i < NumIsland; i++)
            {
                uint32 nLandId = 0;
                (*FileReader) << nLandId;
                UE_LOG(LogTemp, Log, TEXT("aisp: parse land %d"), int32(nLandId));
                TSharedPtr<SpacePartitionContainer> Spc = TSharedPtr<SpacePartitionContainer>(new SpacePartitionContainer());
                Spc->Serialize(*FileReader);

                uint32 NumElement = 0;
                (*FileReader) << NumElement;
                UE_LOG(LogTemp, Log, TEXT("aisp: door num %d"), int32(NumElement));
                for (uint32 n = 0; n < NumElement; n++)
                {
                    TSharedPtr<Element> Ele = TSharedPtr<Element>(new Element());
                    Ele->Serialize(*FileReader);
                    Spc->AddElement(Ele);
                    Elements.Emplace(Ele);
                    OnElementAdded(Ele);
                }

                Spcs.Emplace(nLandId, Spc);
                OnRegionAdded(Spc);
            }
            delete FileReader;
            bLoaded = true;
        }
        else
        {
            UE_LOG(LogTemp, Log, TEXT("aisp:file bot found: %s"), *FilePath);
        }

        return bLoaded;
    }

    virtual bool UnLoad()
    {
        for (auto Iter = Spcs.CreateIterator(); Iter; ++Iter)
        {
            (Iter).Value()->Clear();
        }
        Spcs.Empty();
        Elements.Empty();
        bLoaded = false;
        return true;
    }

    virtual TArray<TSharedPtr<Element>> GetElement(const FBoxCenterAndExtent& Bounds)
    {
        UPiratesGridTypeManager* GridTypeManager = UCommonShell::GetCommon(GWorld)->GetGridTypeManager();
        uint8 nLandId = GridTypeManager->GetLandID(Bounds.Center.X, Bounds.Center.Y);
        auto Spc = Spcs.Find(nLandId);
        if (Spc)
        {
            return (*Spc)->GetElement(Bounds);
        }
        return TArray<TSharedPtr<Element>>();
    }

    virtual bool AddElement(TSharedPtr<Element>& NewElement)
    {
        if (NewElement)
        {
            UPiratesGridTypeManager* GridTypeManager = UCommonShell::GetCommon(GWorld)->GetGridTypeManager();
            const FVector& Location = NewElement->GetLocation();
            uint8 nLandId = GridTypeManager->GetLandID(Location.X, Location.Y);
            auto Spc = Spcs.Find(nLandId);
            if (Spc)
            {
                return (*Spc)->AddElement(NewElement);
            }
            else
            {
                UE_LOG(LogTemp, Error, TEXT("add element to a invalid spc, nlandid %d"), (int32)nLandId);
            }
        }

        return false;
    }

    virtual FString GetConfigPath(const FString& WorldName) const
    {
        return TEXT("");
    }

    uint32 GetAllocatedMemorySize() const
    {
        uint32 MemorySize = sizeof(Element) * Elements.Num();
        for (auto Iter = Spcs.CreateConstIterator(); Iter; ++Iter)
        {
            MemorySize += (Iter).Value()->GetAllocatedSize();
        }
        return MemorySize;
    }

    virtual void DumpStat()
    {
        UE_LOG(LogTemp, Log, TEXT("====================================================================================================="));
        uint32 MemorySize = GetAllocatedMemorySize();
        UE_LOG(LogTemp, Log, TEXT("ai space partition allocated memeory size %.2f kb"), (float)MemorySize / 1024.0f);
        for (auto Iter = Spcs.CreateIterator(); Iter; ++Iter)
        {
            (Iter).Value()->DumpOctree(); 
        }
        UE_LOG(LogTemp, Log, TEXT("====================================================================================================="));
    }

protected:
    void OnPostLoadMap (UWorld* CurrentWorld)
    {
        if (CurrentWorld->IsServer())
        {
            FString WorldName = CurrentWorld->GetName();
            Load(WorldName);
        }
    }

    void OnWorldCleanUp(UWorld* CurrentWorld, bool bSessionEnded, bool bCleanupResources)
    {
        UnLoad();
    }
    
    FDelegateHandle OnPostLoadMapHandle;
    FDelegateHandle OnWorldCleanUpHandle;
    bool bLoaded;
    SPCMap  Spcs;
    ElementArray Elements;
};