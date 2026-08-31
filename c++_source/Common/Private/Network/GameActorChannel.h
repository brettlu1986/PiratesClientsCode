// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Engine/ActorChannel.h"
#include "Serialization/BitReader.h"
#include "GameActorChannel.generated.h"


UCLASS(transient)
class COMMON_API UGameActorChannel : public UActorChannel
{
    GENERATED_UCLASS_BODY()

private:
    enum EProcessState
    {
        None = 0,
        WaitPendingGuids,
        SerializeActor,
        SerializeArchetype,
        SerializeActorLevel,
        SpawnNetActor,
        WaitComponentAllReady,
        ProcessActorCreateBunch,
        LoadActorResources,
        WaitLogicResourcesLoaded,
        ActorPostNetInit,
        Finished,
        Error,
    };

public:
    virtual void ReceivedBunch(FInBunch& Bunch) override;
    virtual void Tick() override;
    virtual bool CleanUp(const bool bForDestroy, EChannelCloseReason CloseReason) override;
    virtual bool CanStopTicking() const override;

public:
    UFUNCTION()
    void SetActorResourcesLoaded(const TArray<UObject*>& HoldedResources);

    UFUNCTION()
    void UseComponentDataSerializer(const TArray<FName>& InAsyncComponentTags);

public:
    FORCEINLINE const bool IsComponentDataSerializerUsed() const { return AsyncComponentTags.Num() > 0; }

private:
    void ChangeState(EProcessState State, FInBunch& Bunch, bool Immediately=true, bool ConsumeDriverTimeLimit=true);
    void Process(FInBunch& Bunch, bool ConsumeDriverTimeLimit);
    bool ProcessImp(FInBunch& Bunch, EProcessState& OutNewState, bool& OutChangeImmediately);
    void ProcessUntilFinish();

    bool WaitPendingGUIResolves();
    bool SerializeObject(FInBunch& Bunch, UClass* Class, UObject* &Out);
    bool LoadActorResourcesImp(FInBunch& Bunch);
    bool SpawnActor(FInBunch& Bunch);
    bool ProcessCreateBunch();
    
private:
    void CollectResources(FInBunch& Bunch, TSet<FString>* OutPaths, TSet<FNetworkGUID>* OutGUIDs);
    bool AsyncLoadSerializedObjectResources(FInBunch& Bunch);    
    void ClearSerializeInfo();
    void SetError(const TCHAR* Info);
    void SkipMappedGuids(FInBunch& Bunch);
    //void SkipSerializeTransform(FInBunch& Bunch);
    
    //void CollectPendingNetGuids(FInBunch& Bunch);
    //void VerifyPendingNetGuids();
    //FORCEINLINE const bool NeedVerifyPendingNetGuids() const { return PendingNetGUIDs.Num() > 0; }
    
    FORCEINLINE void SaveBunchPos(FInBunch& Bunch) { CurrentBunchPos = MakeShareable(new FBitReaderMark(Bunch)); }
    FORCEINLINE void ResetBunchPos(FInBunch& Bunch) { if(CurrentBunchPos.IsValid()) CurrentBunchPos->Pop(Bunch); }

private:
    EProcessState ProcessState;
    bool CurrentStateResourceLoaded;
    bool LoadActorResourcesAsync;
    //TSet<FNetworkGUID> PendingNetGUIDs;

    TArray<FName> AsyncComponentTags;
   
    TSharedPtr<FInBunch> ActorCreateBunch;
    TSharedPtr<FBitReaderMark> CurrentBunchPos;
    TSharedPtr<FStreamableHandle> AsyncResourceHandle;

private:
    UPROPERTY()
    TSet<UObject*> HoldedObjects;
};
