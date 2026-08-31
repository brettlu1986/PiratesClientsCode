
#include "Network/GameActorChannel.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Network/GameIpConnection.h"
#include "Network/GameIpNetDriver.h"
#include "Engine/StreamableManager.h"
#include "Engine/AssetManager.h"
#include "KMActor.h"
#include "KMCharacter.h"
#include "KMPawn.h"
#include "Shell/CommonActorShell.h"
#include "Delegates/GameDelegateManager.h"
#include "Delegates/PiratesGameNetDelegate.h"
#include "Shell/CommonShell.h"
#include "Game/Actor/KMScriptActorSpawnContext.h"
#include "Components/ComponentDataSerializer.h"
#include "Network/ProtobufMessageRef.h"

DEFINE_LOG_CATEGORY_STATIC(LogGameActorChannel, Log, All);

struct FBunchRestorer
{
    FBunchRestorer(TSharedPtr<FInBunch>& InBunch)
        : Marker(*InBunch.Get())
        , SavedBunch(InBunch)
    {
        NET_CHECKSUM(SavedBunch.Get());
    }
    ~FBunchRestorer()
    {
        Reset();
    }
    void Reset()
    {
        if (SavedBunch.IsValid())
        {
            Marker.Pop(*SavedBunch.Get());
        }        
    }
    FBitReaderMark Marker;
    TSharedPtr<FInBunch>& SavedBunch;
};

UGameActorChannel::UGameActorChannel(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , ProcessState(EProcessState::None)
    , CurrentStateResourceLoaded(false)
    , LoadActorResourcesAsync(true)
{
}

/*
当收到actor create的包时通过NetDriver的ShouldQueueBunchesForActorGUID来屏蔽掉此包，
然后解析包中的数据，将所有资源serialize完再处理所有的包
*/
void UGameActorChannel::ReceivedBunch(FInBunch& Bunch)
{
    if (Connection->GetDriver()->IsServer())
    {
        Super::ReceivedBunch(Bunch);
    }
    else
    {
        bool NeedStartState = false;
        if (Actor == nullptr)
        {
            if (Bunch.bOpen && !Bunch.bClose && !Bunch.AtEnd())
            {
                auto Dirver = Cast<UGameIpNetDriver>(Connection->GetDriver());
                if (Dirver && Dirver->IsActorAsyncCreatingEnabled() && UGameCommon::Get(Dirver->GetWorld()))
                {
                    if (Broken || bTornOff)
                    {
                        return;
                    }

                    ActorCreateBunch = MakeShareable(new FInBunch(Bunch));
                    FInBunch& SavedBunch = *ActorCreateBunch.Get();
                    SkipMappedGuids(SavedBunch);

                    {
                        FBunchRestorer R(ActorCreateBunch);
                        SavedBunch << ActorNetGUID;
                    }

                    // 避免在connection::tick中将已经重新打开的Actor删除，在收到open数据包的时候检查KeepProcessingActorChannelBunchesMap。
                    if (Connection->KeepProcessingActorChannelBunchesMap.Contains(ActorNetGUID))
                    {
                        UE_LOG(LogGameActorChannel, Log, TEXT("Channel [%p], Bunch Open ClearSerializeInfo, ActorNetGuid: %d."), this, ActorNetGUID.Value);
                        ClearSerializeInfo();
                    }
                    else
                    {
                        check(ProcessState == EProcessState::None);
                        Dirver->AddActorGUIDForQueueBunches(ActorNetGUID);   // 往queueBunch里加，阻止ProcessBunch
                        NeedStartState = true;
                    }
                }
            }
            else if (!Bunch.bOpen && Bunch.bClose && ProcessState != EProcessState::Finished)
            {
                // 要close channel了，这会先强制处理下
                //ProcessUntilFinish();
                UE_LOG(LogGameActorChannel, Error, TEXT("Channel [%p], ProcessUntilFinish ActorNetGuid: %d, ChangeState: %d."), this, ActorNetGUID.Value, ProcessState);
            }
        }
        //else if (!ActorCreateBunch.IsValid() && ActorNetGUID.IsValid())
        //{
        //    CollectPendingNetGuids(Bunch);
        //    VerifyPendingNetGuids();
        //    if (NeedVerifyPendingNetGuids())
        //    {
        //        // 有pending的资源，queue了
        //        auto NetDirver = Cast<UGameIpNetDriver>(Connection->GetDriver());
        //        NetDirver->AddActorGUIDForQueueBunches(ActorNetGUID);   // 往queueBunch里加，阻止ProcessBunch
        //    }
        //}

        Super::ReceivedBunch(Bunch);

        if (NeedStartState)
        {            
            ChangeState(EProcessState::WaitPendingGuids, *ActorCreateBunch.Get());
        }
    }
}

void UGameActorChannel::Tick()
{
    if (Connection->GetDriver()->IsServer())
    {
        Super::Tick();
    }
    else
    {
        if(ActorCreateBunch.IsValid())
        {
            Process(*ActorCreateBunch.Get(), true);

            if (ProcessState == EProcessState::Error || ProcessState == EProcessState::Finished)
            {
                ClearSerializeInfo();
            }
        }
        //if (NeedVerifyPendingNetGuids())
        //{
        //    VerifyPendingNetGuids();
        //}

        Super::Tick();
    }
}

bool UGameActorChannel::CleanUp(const bool bForDestroy, EChannelCloseReason CloseReason)
{
    bool Ret = Super::CleanUp(bForDestroy, CloseReason);
    if(Ret)
    {
        ProcessState = EProcessState::None;
        ClearSerializeInfo();
    }
    return Ret;
}

void UGameActorChannel::ProcessUntilFinish()
{
    if (ActorCreateBunch.IsValid())
    {
        UE_LOG(LogGameActorChannel, Verbose, TEXT("Channel [%p], ProcessUntilFinish ActorNetGuid: %d, ChangeState: %d"), this, ActorNetGUID.Value, ProcessState);
        if (ProcessState == EProcessState::WaitPendingGuids)
        {
            // pending状态直接不处理了
            ClearSerializeInfo();
        }
        else
        {
            LoadActorResourcesAsync = false;
            while (ActorCreateBunch.IsValid())
            {
                Process(*ActorCreateBunch.Get(), false);

                if (ProcessState == EProcessState::Error || ProcessState == EProcessState::Finished)
                {
                    ClearSerializeInfo();
                }
            }
            LoadActorResourcesAsync = true;
        }
    }    
}

bool UGameActorChannel::CanStopTicking() const
{
    if (ActorCreateBunch.IsValid())
    {
        // 当处于未完成状态不能停tick
        return false;
    }

    return Super::CanStopTicking();
}

void UGameActorChannel::SetActorResourcesLoaded(const TArray<UObject*>& HoldedResources)
{
    CurrentStateResourceLoaded = true;
    for (auto& Object : HoldedResources)
    {
        HoldedObjects.Emplace(Object);
    }
}

void UGameActorChannel::UseComponentDataSerializer(const TArray<FName>& InAsyncComponentTags)
{
    AsyncComponentTags = InAsyncComponentTags;
}

void UGameActorChannel::ChangeState(EProcessState State, FInBunch& Bunch, bool Immediately, bool ConsumeDriverTimeLimit)
{
    UE_LOG(LogGameActorChannel, Verbose, TEXT("Channel [%p], ActorNetGuid: %d, ChangeState: %d"), this, ActorNetGUID.Value, State);
    SaveBunchPos(Bunch);

    CurrentStateResourceLoaded = false;
    ProcessState = State;    
    AsyncResourceHandle.Reset();

    if (ProcessState == EProcessState::Error || ProcessState == EProcessState::Finished)
    {
        ClearSerializeInfo();
    }
    else if (Immediately)
    {
        Process(Bunch, ConsumeDriverTimeLimit);
    }    
}

void UGameActorChannel::Process(FInBunch& Bunch, bool ConsumeDriverTimeLimit)
{
    auto Driver = Cast<UGameIpNetDriver>(Connection->GetDriver());
    if (ConsumeDriverTimeLimit && Driver->GetActorAsyncCreatingRemainTime() <= 0.0f)
    {
        UE_LOG(LogGameActorChannel, Verbose, TEXT("GetActorAsyncCreatingRemainTime <= 0.0f, this; %p"), this);
        return;
    }

    double NowTime = FPlatformTime::Seconds();
    EProcessState NewState = EProcessState::None;
    bool ChangeImmediately = false;
    bool NeedChangeState = ProcessImp(Bunch, NewState, ChangeImmediately);

    if (ConsumeDriverTimeLimit)
    {
        Driver->ConsumeActorAsyncCreatingTime((float)(FPlatformTime::Seconds() - NowTime));
    }    

    if (NeedChangeState)
    {
        ChangeState(NewState, Bunch, ChangeImmediately, ConsumeDriverTimeLimit);
    }
}

bool UGameActorChannel::ProcessImp(FInBunch& Bunch, EProcessState& OutNewState, bool& OutChangeImmediately)
{
    UE_LOG(LogGameActorChannel, Verbose, TEXT("Channel [%p], ActorNetGuid: %d, Process: %d"), this, ActorNetGUID.Value, ProcessState);
    ResetBunchPos(Bunch);

    auto SetOutParams = [&](EProcessState NewState, bool ChangeImmediately = true)->bool {
        OutNewState = NewState;
        OutChangeImmediately = ChangeImmediately;
        return true;
    };

    switch (ProcessState)
    {
    case EProcessState::WaitPendingGuids:
    {
        if (WaitPendingGUIResolves())
        {
            return SetOutParams(EProcessState::SerializeActor);
        }
        break;
    }
    case EProcessState::SerializeActor:
    {
        UObject* Out = nullptr;
        if (SerializeObject(Bunch, AActor::StaticClass(), Out))
        {
            if (Cast<AActor>(Out) == nullptr && ActorNetGUID.IsDynamic() && !Bunch.AtEnd())
            {
                auto& GuidCache = Connection->GetDriver()->GuidCache;
                if (GuidCache.IsValid())
                {
                    GuidCache->ImportedNetGuids.Add(ActorNetGUID);
                }
                return SetOutParams(EProcessState::SerializeArchetype);
            }
            else
            {
                return SetOutParams(EProcessState::Finished);
            }
        }
        break;
    }        
    case EProcessState::SerializeArchetype:
    {
        UObject* Archetype = nullptr;
        if (SerializeObject(Bunch, UObject::StaticClass(), Archetype))
        {
            if (Archetype)
            {
                HoldedObjects.Emplace(Archetype);
                return SetOutParams(EProcessState::SerializeActorLevel);
            }         
        }
        break;
    }
    case EProcessState::SerializeActorLevel:
    {
        UObject* ActorLevel = nullptr;
        if (SerializeObject(Bunch, ULevel::StaticClass(), ActorLevel))
        {
            return SetOutParams(EProcessState::SpawnNetActor, false);
        }
        break;
    }
    case EProcessState::SpawnNetActor:
    {
        if (SpawnActor(Bunch))
        {
            return SetOutParams(EProcessState::WaitComponentAllReady);
        }
        break;
    }
    case EProcessState::WaitComponentAllReady:
    {
        // TODO：这里留个口子给ComponentDataSerializer，如果spawn本身太慢就启用ComponentDataSerializer
        return SetOutParams(EProcessState::ProcessActorCreateBunch, false);
    }
    case EProcessState::ProcessActorCreateBunch:
    {
        if (ProcessCreateBunch())
        {
            if (Actor)
            {
                return SetOutParams(EProcessState::LoadActorResources);
            }
            else
            {
                SetError(TEXT("Process actor create bunch failed."));
            }
        }      
        break;
    }
    case EProcessState::LoadActorResources:
    {
        if (LoadActorResourcesImp(Bunch))
        {
            if (CurrentStateResourceLoaded)
            {
                return SetOutParams(EProcessState::ActorPostNetInit);
            }
            else
            {
                return SetOutParams(EProcessState::WaitLogicResourcesLoaded);
            }            
        }
        break;
    }
    case EProcessState::WaitLogicResourcesLoaded:
    {
        if (CurrentStateResourceLoaded)
        {
            return SetOutParams(EProcessState::ActorPostNetInit);
        }
        break;
    }
    case EProcessState::ActorPostNetInit:
    {
        check(Actor);
        Actor->PostNetInit();   // 这里会执行beginplay，触发lua gameobject创建等流程
        return SetOutParams(EProcessState::Finished);        
    }
    default:
        break;
    };

    return false;
}

bool UGameActorChannel::WaitPendingGUIResolves()
{
    if (PendingGuidResolves.Num() > 0)
    {
        for (auto It = PendingGuidResolves.CreateIterator(); It; ++It)
        {
            if (Connection->Driver->GuidCache->GetObjectFromNetGUID(*It, true) != NULL)
            {
                // This guid is now resolved, we can remove it from the pending guid list
                It.RemoveCurrent();
                continue;
            }

            if (Connection->Driver->GuidCache->IsGUIDBroken(*It, true))
            {
                // This guid is broken, remove it, and warn
                UE_LOG(LogGameActorChannel, Warning, TEXT("WaitPendingGUIResolves Guid is broken. NetGUID: %s, ChIndex: %i, Actor: %s"), *It->ToString(), ChIndex, Actor != NULL ? *Actor->GetPathName() : TEXT("NULL"));
                It.RemoveCurrent();
                continue;
            }

            return false;
        }
    }
    return true;
}

bool UGameActorChannel::SerializeObject(FInBunch& Bunch, UClass* Class, UObject* &Object)
{
    if (!AsyncLoadSerializedObjectResources(Bunch))
    {
        return false;
    }

    FNetworkGUID GUID;
    Connection->PackageMap->SerializeObject(Bunch, Class, Object, &GUID);    

    if (Bunch.IsError())
    {
        SetError(TEXT("SerializeObject failed"));
        return false;
    }
    else if (Connection->GetDriver()->GuidCache->IsGUIDBroken(GUID, false))
    {
        SetError(TEXT("GUID is broken"));
        return false;
    }

    UE_LOG(LogGameActorChannel, Verbose, TEXT("Channel [%p], ActorNetGuid: %d, SerializeObject: Object: %s, GUID: %d"),
        this, ActorNetGUID.Value, Object ? *Object->GetFullName() : TEXT("null"), *GUID.ToString());
    return true;
}

bool UGameActorChannel::LoadActorResourcesImp(FInBunch& Bunch)
{
    check(Actor);    
    int LogicInstanceId = -1;
    const TArray<uint8>* pInitData = nullptr;

#define TRY_GET_INFO(__class) \
    if(auto TempActor = Cast<__class>(Actor)) \
    { \
        LogicInstanceId = TempActor->GetLogicInstanceId(); \
        pInitData = &TempActor->GetInitProtoData(); \
    }

    TRY_GET_INFO(AKMActor);
    TRY_GET_INFO(AKMCharacter);
    TRY_GET_INFO(AKMPawn);

#undef TRY_GET_INFO

    CurrentStateResourceLoaded = true;
    if(pInitData && pInitData->Num() > 0)
    {
        auto CommonShell = UCommonShell::GetCommon(Connection->GetDriver()->GetWorld());
        auto ProtobufMessageRef = CommonShell->GetCommonActorShell()->RawDataToMessageRef(*pInitData);
        if (ProtobufMessageRef)
        {
            CurrentStateResourceLoaded = false;
            CommonShell->GetGameDelegateManager()->GameNet->OnRecvActorInfoBeforeNetInit.Execute(
                this, Actor, LogicInstanceId, ProtobufMessageRef, ActorNetGUID.Value, LoadActorResourcesAsync);
        }
    }
    return true;
}

//void UGameActorChannel::SkipSerializeTransform(FInBunch& Ar)
//{
//    // 参考 UPackageMapClient::SerializeNewActor
//    FVector_NetQuantize10 Location;
//    FVector_NetQuantize10 Scale;
//    FVector_NetQuantize10 Velocity;
//    FRotator Rotation;
//    bool SerSuccess = false;
//    auto PackageMap = Connection->PackageMap;
//
//    bool bSerializeLocation = false;
//    bool bSerializeRotation = false;
//    bool bSerializeScale = false;
//    bool bSerializeVelocity = false;
//
//    Ar.SerializeBits(&bSerializeLocation, 1);
//    if (bSerializeLocation)
//    {
//        Location.NetSerialize(Ar, PackageMap, SerSuccess);
//    }
//
//    Ar.SerializeBits(&bSerializeRotation, 1);
//    if (bSerializeRotation)
//    {
//        Rotation.NetSerialize(Ar, PackageMap, SerSuccess);
//    }
//
//    Ar.SerializeBits(&bSerializeScale, 1);
//    if (bSerializeScale)
//    {
//        Scale.NetSerialize(Ar, PackageMap, SerSuccess);
//    }
//
//    Ar.SerializeBits(&bSerializeVelocity, 1);
//    if (bSerializeVelocity)
//    {
//        Velocity.NetSerialize(Ar, PackageMap, SerSuccess);
//    }
//}

bool UGameActorChannel::SpawnActor(FInBunch& Bunch)
{
    FBitReaderMark Marker;
    Marker.Pop(Bunch);     // seek pos 0
    SkipMappedGuids(Bunch);
    
    const float PRINT_MAX_TIME = 1.0f;
    double StartTime = FPlatformTime::Seconds();
    AActor* ActorSpawned = nullptr;
    Connection->PackageMap->SerializeNewActor(Bunch, this, ActorSpawned);
    check(ActorSpawned);
    double DeltaTime = (FPlatformTime::Seconds() - StartTime)*1000.0f;
    if (DeltaTime >= PRINT_MAX_TIME && ActorSpawned)
    {
        UE_LOG(LogGameActorChannel, Log, TEXT("SerializeNewActor time %f ms, path name: %s"), (float)DeltaTime, *ActorSpawned->GetName());
    }

    if (IsComponentDataSerializerUsed() && ActorSpawned)
    {
        // 这里使用UComponentDataSerializer的异步load
        auto ComponentDataSerializer = ActorSpawned->FindComponentByClass<UComponentDataSerializer>();
        if (ComponentDataSerializer)
        {
            ComponentDataSerializer->LoadAsyn(AsyncComponentTags, 0, false, false);
        }
        else
        {
            ActorSpawned = nullptr; // 强制finish
        }
    }
    return true;
}

bool UGameActorChannel::ProcessCreateBunch()
{
    check(QueuedBunches.Num() > 0);
    auto Driver = Cast<UGameIpNetDriver>(Connection->GetDriver());
    //if (Driver->GuidCache->PendingAsyncPackages.Num() > 0)
    //{
    //    return false;
    //}

    // ProcessQueuedBunches时只处理第一个ActorCreateBunch，其他的下针在处理
    FBitReaderMark Reseter(*QueuedBunches[0]);
    TArray<FInBunch*> Backup;
    if (QueuedBunches.Num() > 1)
    {
        Backup.Append(&QueuedBunches[1], QueuedBunches.Num() - 1);
        QueuedBunches.RemoveAt(1, QueuedBunches.Num() - 1);
    }
    Driver->RemoveActorGUIDForQueueBunches(ActorNetGUID);

    TArray<UActorChannel*> BackupChannels;
    bool HasKeepProcessingActorChannel = Connection->KeepProcessingActorChannelBunchesMap.RemoveAndCopyValue(ActorNetGUID, BackupChannels);

    // 这里会触发actorchannel open，因为上面已经spawn了actor，所以在处理包时不会触发postNetInit，具体参考UActorChannel::ProcessBunch中的bSpawnedNewActor        
    bool Ret = ProcessQueuedBunches();

    Driver->AddActorGUIDForQueueBunches(ActorNetGUID);
    if (HasKeepProcessingActorChannel)
    {
        Connection->KeepProcessingActorChannelBunchesMap.Emplace(ActorNetGUID, BackupChannels);
    }

    if (Actor)
    {
        check(Ret);
        QueuedBunches.Append(Backup);
        return true;
    }
    else
    {
        // actor未spawn说明没处理，那么恢复queuebunch，下针继续尝试
        check(QueuedBunches.Num() > 0);
        Reseter.Pop(*QueuedBunches[0]);
        QueuedBunches.Append(Backup);
        return false;
    }
}

// 基本抄了一遍UPackageMapClient::InternalLoadObject
void UGameActorChannel::CollectResources(FInBunch& Ar, TSet<FString>* OutPaths, TSet<FNetworkGUID>* OutGUIDs)
{
    if (Ar.IsError())
    {
        SetError(TEXT("CollectResources failed, ar has error"));
        return;        
    }

    auto& GuidCache = Connection->GetDriver()->GuidCache;

    FNetworkGUID NetGUID;
    Ar << NetGUID;
    if (OutGUIDs)
    {
        OutGUIDs->Emplace(NetGUID);
    }

    // ----------------	
    // Read the full if its there
    // ----------------	
    struct FExportFlags
    {
        union
        {
            struct
            {
                uint8 bHasPath : 1;
                uint8 bNoLoad : 1;
                uint8 bHasNetworkChecksum : 1;
            };

            uint8	Value;
        };

        FExportFlags()
        {
            Value = 0;
        }
    };
    FExportFlags ExportFlags;

    if (NetGUID.IsDefault() || GuidCache->IsExportingNetGUIDBunch)
    {
        Ar << ExportFlags.Value;

        if (Ar.IsError())
        {
            SetError(TEXT("CollectResources failed, ExportFlags read failed."));
            return;
        }
    }

    if (ExportFlags.bHasPath)
    {
        CollectResources(Ar, OutPaths, OutGUIDs);

        FString PathName;
        uint32	NetworkChecksum = 0;

        Ar << PathName;

        if (ExportFlags.bHasNetworkChecksum)
        {
            Ar << NetworkChecksum;
        }

        if (Ar.IsError())
        {
            SetError(TEXT("CollectResources failed, Failed to load path name"));
            return;
        }

        if (OutPaths && NetGUID.IsDefault())
        {
            OutPaths->Emplace(PathName);
            UE_LOG(LogGameActorChannel, Verbose, TEXT("ActorNetGuid: %d, CollectResources: %s"), ActorNetGUID.Value, *PathName);
        }
    }
}

bool UGameActorChannel::AsyncLoadSerializedObjectResources(FInBunch& Bunch)
{
    if (CurrentStateResourceLoaded)
    {
        return true;
    }
    else if (!AsyncResourceHandle.IsValid())
    {
        // 参考UPackageMapClient::SerializeNewActor里SerializeObject的调用步骤
        FBunchRestorer R(ActorCreateBunch);
        TSet<FString> Paths;
        CollectResources(Bunch, &Paths, nullptr);

        if (Bunch.IsError())
        {
            SetError(TEXT("CollectResources failed"));
            return false;
        }

        if (Paths.Num() == 0)
        {
            AsyncResourceHandle.Reset();
            CurrentStateResourceLoaded = true;
            return true;
        }

        TArray<FSoftObjectPath> PendingResources;
        for (auto Iter = Paths.CreateIterator(); Iter; ++Iter)
        {
            PendingResources.Emplace(*Iter);
        }

        CurrentStateResourceLoaded = false;
        AsyncResourceHandle = UAssetManager::GetStreamableManager().RequestAsyncLoad(PendingResources,
            FStreamableDelegate(), FStreamableManager::AsyncLoadHighPriority);
        return true;
    }
    else if (AsyncResourceHandle->HasLoadCompleted())
    {
        TArray<UObject*> Objects;
        AsyncResourceHandle->GetLoadedAssets(Objects);
        for (auto Object : Objects)
        {
            HoldedObjects.Emplace(Object);
        }
        AsyncResourceHandle.Reset();
        CurrentStateResourceLoaded = true;
        return true;
    }
    else if (!AsyncResourceHandle->IsActive())
    {
        SetError(TEXT("Async load failed"));
        return false;
    }

    return false;
}

void UGameActorChannel::ClearSerializeInfo()
{
    if (Connection && Connection->GetDriver())
    {
        Cast<UGameIpNetDriver>(Connection->GetDriver())->RemoveActorGUIDForQueueBunches(ActorNetGUID);
    }

    CurrentStateResourceLoaded = false;

    ActorCreateBunch.Reset();
    CurrentBunchPos.Reset();
    AsyncResourceHandle.Reset();
        
    HoldedObjects.Empty();   
}

void UGameActorChannel::SetError(const TCHAR* Info)
{    
    UE_LOG(LogGameActorChannel, Error, TEXT("ActorNetGuid: %d, State: %d, info: %s"), ActorNetGUID.Value, ProcessState, Info);
    ProcessState = EProcessState::Error;
}

void UGameActorChannel::SkipMappedGuids(FInBunch& Bunch)
{
    if (Bunch.bHasMustBeMappedGUIDs)
    {
        FNetworkGUID TempNetGUID;
        uint16 NumMustBeMappedGUIDs = 0;
        Bunch << NumMustBeMappedGUIDs;
        for (int32 i = 0; i < NumMustBeMappedGUIDs; i++)
        {
            Bunch << TempNetGUID;
        }
    }
}

// 参考UPackageMapClient::ReceiveNetGUIDBunch
//void UGameActorChannel::CollectPendingNetGuids(FInBunch& Bunch)
//{    
//    if (!Bunch.bHasPackageMapExports)
//    {
//        return;
//    }
//
//    FBitReaderMark Marker(Bunch);
//    const bool bHasRepLayoutExport = Bunch.ReadBit() == 1 ? true : false;
//    if (bHasRepLayoutExport)
//    {
//        Marker.Pop(Bunch);
//        return;
//    }
//    
//    TGuardValue<bool> IsExportingGuard(Connection->GetDriver()->GuidCache->IsExportingNetGUIDBunch, true);
//
//    int32 NumGUIDsInBunch = 0;
//    Bunch << NumGUIDsInBunch;
//
//    const int32 MAX_GUID_COUNT = 2048;
//    if (NumGUIDsInBunch < MAX_GUID_COUNT)
//    {
//        NET_CHECKSUM(Bunch);
//
//        int32 NumGUIDsRead = 0;
//        while (NumGUIDsRead < NumGUIDsInBunch)
//        {
//            CollectResources(Bunch, nullptr, &PendingNetGUIDs);
//
//            if (Bunch.IsError())
//            {
//                UE_LOG(LogGameActorChannel, Error, TEXT("CollectPendingNetGuids failed."));
//                break;
//            }
//            NumGUIDsRead++;
//        }        
//    }
//
//    Marker.Pop(Bunch);
//}

//void UGameActorChannel::VerifyPendingNetGuids()
//{
//    auto& GuidCache = Connection->GetDriver()->GuidCache;
//    for (auto Iter = PendingNetGUIDs.CreateIterator(); Iter; ++Iter)
//    {
//        if (!GuidCache->IsGUIDPending(*Iter))
//        {
//            Iter.RemoveCurrent();
//        }
//    }
//
//    if (PendingNetGUIDs.Num() == 0)
//    {
//        auto NetDirver = Cast<UGameIpNetDriver>(Connection->GetDriver());
//        NetDirver->RemoveActorGUIDForQueueBunches(ActorNetGUID);
//    }
//}