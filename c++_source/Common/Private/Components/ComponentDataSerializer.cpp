#include "Components/ComponentDataSerializer.h"
#include "Common.h"
#include "Util/ComponentInCDOCollector.h"
#include "Engine/SCS_Node.h"
#include "KMActor.h"
#include "KMPawn.h"
#include "KMCharacter.h"
#include "Engine/Blueprint.h"
#include "UObject/UObjectThreadContext.h"
#include "Game/GameCommon.h"
#include "Misc/GameLimitedTimeTaskManager.h"
#include "Engine/StreamableManager.h"
#include "Shell/EngineExtShell.h"

#include <type_traits>
#include <functional>

//#define ENABLE_DEBUG_LOG
#define CHILDREN_INHERIT_SAME_TAG TEXT("ChildrenInheritSameTag")
#define DO_NOT_INHERIT_PARENT_TAG TEXT("DonotInheritParentTag")

DEFINE_LOG_CATEGORY_STATIC(LogComponentDataSerializer, Log, All);

#define CALL_KMACTOR_FUNC(Actor, __code) { \
    if (auto KMActor = Cast<AKMActor>(Actor)) \
    { \
        KMActor->__code; \
    } \
    else if (auto KMPawn = Cast<AKMPawn>(Actor)) \
    { \
        KMPawn->__code; \
    } \
    else if (auto KMCharacter = Cast<AKMCharacter>(Actor)) \
    { \
        KMCharacter->__code; \
    } \
}

///////////////////////////////////////////////////////////////
class FComponentRawDataSerializer : public FArchiveUObject
{
public:
    FComponentRawDataSerializer(FGameComponentSavedData& InData, bool bLoad)
        : FArchiveUObject()
        , ComponentData(InData)
        , SeekPos(0)
    {
		SetIsLoading(bLoad);
		SetIsSaving(!bLoad);
        //ArCustomPropertyList = InstancedData.GetCachedPropertyListForSerialization();
        //ArUseCustomPropertyList = true;
    }

    virtual UObject* GetArchetypeFromLoader(const UObject* Obj) override
    {
        if (Obj)
        {
            return Obj->GetClass()->GetDefaultObject(false);
        }
        return nullptr;
    }

    virtual bool ShouldSkipProperty(const FProperty* InProperty) const override
    {
        return (InProperty->HasAnyPropertyFlags(CPF_Transient)
            || !InProperty->HasAnyPropertyFlags(CPF_Edit | CPF_Interp)
            || InProperty->IsEditorOnlyProperty());
    }

    virtual FArchive& operator<<(class FName& Value) override
    {
        int NameIndex = -1;
        auto& Names = ComponentData.Names;
        if (IsLoading())
        {
            *this << NameIndex;
            if (NameIndex >= 0 && NameIndex < Names.Num())
            {
                Value = Names[NameIndex];
            }
        }
        else
        {
            FName TempNameName(NAME_None);
            if (Value != TempNameName)
            {
                NameIndex = Names.Find(Value);
                if (NameIndex == INDEX_NONE)
                {
                    NameIndex = Names.Add(Value);
                }
            }
            *this << NameIndex;
        }
        return *this;
    }

    virtual FArchive& operator<<(class UObject*& Value) override
    {
        auto& Objects = ComponentData.Objects;
        int ObjectIndex = -1;
        if (IsLoading())
        {
            Value = nullptr;
            *this << ObjectIndex;
            if (ObjectIndex >= 0 && ObjectIndex < Objects.Num())
            {
                Value = Objects[ObjectIndex];
            }
        }
        else
        {
            if (Value != nullptr)
            {
                ObjectIndex = Objects.Find(Value);
                if (ObjectIndex == INDEX_NONE)
                {
                    ObjectIndex = Objects.Add(Value);
                }
            }
            *this << ObjectIndex;
        }
        return *this;
    }

    virtual void Serialize(void* Data, int64 Length) override
    {
        int OldPos = SeekPos;
        int NewPos = OldPos + Length;
        auto& RawData = ComponentData.RawData;

        if (IsLoading())
        {
            check(NewPos >= 0 && NewPos <= RawData.Num());
            FMemory::Memcpy(Data, &RawData[OldPos], Length);
        }
        else
        {
            int MemSize = RawData.Max();
            MemSize = MemSize == 0 ? 512 : MemSize;
            while (MemSize < NewPos)
            {
                MemSize *= 2;
            }
            RawData.Reserve(MemSize);

            if (NewPos >= RawData.Num())
            {
                RawData.AddUninitialized(NewPos - RawData.Num());
            }
            FMemory::Memcpy(&RawData[OldPos], Data, Length);
        }
        SeekPos = NewPos;
    }

    virtual int64 Tell() override
    {
        return SeekPos;
    }

    virtual int64 TotalSize() override
    {
        return ComponentData.RawData.Num();
    }

    virtual void Seek(int64 InPos) override
    {
        check(InPos >= 0 && InPos <= ComponentData.RawData.Num());
        SeekPos = InPos;
    }

private:
    FGameComponentSavedData& ComponentData;
    int64 SeekPos;
};

///////////////////////////////////////////////////////////////
struct FTempComponentInstancingDataUtils
{
#if WITH_EDITOR
    // Recursively gathers properties that differ from class/struct defaults, and fills out the cooked property list structure.
    static void RecursivePropertyGather(UStruct* InStruct, const uint8* DataPtr, const uint8* DefaultDataPtr, FBlueprintCookedComponentInstancingData& OutData)
    {
        for (FProperty* Property = InStruct->PropertyLink; Property; Property = Property->PropertyLinkNext)
        {
            // Skip editor-only properties since they won't be compiled in a non-editor configuration. Also skip transient and deprecated properties since they won't be serialized on save/duplicate.
            if (!Property->IsEditorOnlyProperty()
                && !Property->HasAnyPropertyFlags(CPF_Transient | CPF_DuplicateTransient | CPF_NonPIEDuplicateTransient | CPF_Deprecated))
            {
                for (int32 Idx = 0; Idx < Property->ArrayDim; Idx++)
                {
                    const uint8* PropertyValue = Property->ContainerPtrToValuePtr<uint8>(DataPtr, Idx);
                    const uint8* DefaultPropertyValue = Property->ContainerPtrToValuePtrForDefaults<uint8>(InStruct, DefaultDataPtr, Idx);

                    FBlueprintComponentChangedPropertyInfo ChangedPropertyInfo;
                    ChangedPropertyInfo.PropertyName = Property->GetFName();
                    ChangedPropertyInfo.ArrayIndex = Idx;
                    ChangedPropertyInfo.PropertyScope = InStruct;

                    if (FStructProperty* StructProperty = CastField<FStructProperty>(Property))
                    {
                        int32 NumChangedProperties = OutData.ChangedPropertyList.Num();

                        RecursivePropertyGather(StructProperty->Struct, PropertyValue, DefaultPropertyValue, OutData);

                        // Prepend the struct property only if there is at least one changed sub-property.
                        if (NumChangedProperties < OutData.ChangedPropertyList.Num())
                        {
                            OutData.ChangedPropertyList.Insert(ChangedPropertyInfo, NumChangedProperties);
                        }
                    }
                    else if (FArrayProperty* ArrayProperty = CastField<FArrayProperty>(Property))
                    {
                        FScriptArrayHelper ArrayValueHelper(ArrayProperty, PropertyValue);
                        FScriptArrayHelper DefaultArrayValueHelper(ArrayProperty, DefaultPropertyValue);

                        int32 NumChangedProperties = OutData.ChangedPropertyList.Num();
                        FBlueprintComponentChangedPropertyInfo ChangedArrayPropertyInfo = ChangedPropertyInfo;

                        for (int32 ArrayValueIndex = 0; ArrayValueIndex < ArrayValueHelper.Num(); ++ArrayValueIndex)
                        {
                            ChangedArrayPropertyInfo.ArrayIndex = ArrayValueIndex;
                            const uint8* ArrayPropertyValue = ArrayValueHelper.GetRawPtr(ArrayValueIndex);

                            if (ArrayValueIndex < DefaultArrayValueHelper.Num())
                            {
                                const uint8* DefaultArrayPropertyValue = DefaultArrayValueHelper.GetRawPtr(ArrayValueIndex);

                                if (FStructProperty* InnerStructProperty = CastField<FStructProperty>(ArrayProperty->Inner))
                                {
                                    int32 NumChangedArrayProperties = OutData.ChangedPropertyList.Num();

                                    RecursivePropertyGather(InnerStructProperty->Struct, ArrayPropertyValue, DefaultArrayPropertyValue, OutData);

                                    // Prepend the struct property only if there is at least one changed sub-property.
                                    if (NumChangedArrayProperties < OutData.ChangedPropertyList.Num())
                                    {
                                        OutData.ChangedPropertyList.Insert(ChangedArrayPropertyInfo, NumChangedArrayProperties);
                                    }
                                }
                                else if (!ArrayProperty->Inner->Identical(ArrayPropertyValue, DefaultArrayPropertyValue, PPF_None))
                                {
                                    // Emit the index of the individual array value that differs from the default value
                                    OutData.ChangedPropertyList.Add(ChangedArrayPropertyInfo);
                                }
                            }
                            else
                            {
                                // Emit the "end" of differences with the default value (signals that remaining values should be copied in full)
                                ChangedArrayPropertyInfo.PropertyName = NAME_None;
                                OutData.ChangedPropertyList.Add(ChangedArrayPropertyInfo);

                                // Don't need to record anything else.
                                break;
                            }
                        }

                        // Prepend the array property as changed only if the sizes differ and/or if we also wrote out any of the inner value as changed.
                        if (ArrayValueHelper.Num() != DefaultArrayValueHelper.Num() || NumChangedProperties < OutData.ChangedPropertyList.Num())
                        {
                            OutData.ChangedPropertyList.Insert(ChangedPropertyInfo, NumChangedProperties);
                        }
                    }
                    else if (!Property->Identical(PropertyValue, DefaultPropertyValue, PPF_None))
                    {
                        OutData.ChangedPropertyList.Add(ChangedPropertyInfo);
                    }
                }
            }
        }
    }

    static void FillData(int TagFlag, const FComponentTreeNodeInCDO* Node, const FName& ParentComponentName,
        FGameComponentSavedData& OutData)
    {
        UActorComponent* Component = Node->Component;
        OutData.TagFlag = TagFlag;
        OutData.Class = Component->GetClass();
        check(OutData.Class);
        //OutData.ClassPathName = Component->GetClass()->GetPathName();
        //OutData.TemplateFlags = (int)Component->GetFlags();
        OutData.VariableName = Node->VariableName;
        OutData.ParentComponentName = ParentComponentName;
        OutData.AttachToName = Node->SCSNode->AttachToName;

        RecursivePropertyGather(
            OutData.Class,
            (uint8*)Component,
            (uint8*)OutData.Class->GetDefaultObject(false),
            OutData.InstancedData);

        if (Component->HasAnyFlags(RF_NeedLoad))
        {
            if (FLinkerLoad* Linker = Component->GetLinker())
            {
                Linker->Preload(Component);
            }
        }

        FComponentRawDataSerializer Writer(OutData, false);
        Component->Serialize(Writer);
    }
#endif

    static UActorComponent* NewComponent(AActor* Actor, FGameComponentSavedData& Data)
    {
        UActorComponent* NewActorComp = nullptr;
        if (Data.Class != nullptr)	// some components (e.g. UTextRenderComponent) are not loaded on a server (or client). Handle that gracefully, but we ideally shouldn't even get here (see UEBP-175).
        {
            auto& InstancedData = Data.InstancedData;
            if (!InstancedData.bHasValidCookedData)
            {
                // Note we aren't copying the the RF_ArchetypeObject flag. Also note the result is non-transactional by default.
                NewActorComp = NewObject<UActorComponent>(
                    Actor,
                    Data.Class,
                    Data.VariableName,
                    //EObjectFlags(Data.TemplateFlags) & ~(RF_ArchetypeObject | RF_Transactional | RF_WasLoaded | RF_Public | RF_InheritableComponentTemplate)
                    RF_LoadCompleted
                    );

                // Set these flags to match what SDO would otherwise do before serialization to enable post-duplication logic on the destination object.
                NewActorComp->SetFlags(RF_NeedPostLoad | RF_NeedPostLoadSubobjects);

                // Load cached data into the new instance.
                FComponentRawDataSerializer Reader(Data, true);
                NewActorComp->Serialize(Reader);

                {
                    TGuardValue<bool> GuardIsRoutingPostLoad(FUObjectThreadContext::Get().IsRoutingPostLoad, true);
                    NewActorComp->ConditionalPostLoad();
                }

#if !WITH_EDITORONLY_DATA && !WITH_EDITOR
                InstancedData.bHasValidCookedData = true;
                InstancedData.BuildCachedPropertyDataFromTemplate(NewActorComp);
                // 必须重新命名，否则在CreateComponentFromTemplateData里会check失败
                InstancedData.ComponentTemplateName = MakeUniqueObjectName(
                    Actor->GetClass()->GetDefaultObject(),
                    Data.Class, Data.VariableName);
#endif
            }
            else
            {
                NewActorComp = Actor->CreateComponentFromTemplateData(&InstancedData, Data.VariableName);
                NewActorComp->CreationMethod = EComponentCreationMethod::SimpleConstructionScript;
                Actor->BlueprintCreatedComponents.Remove(NewActorComp);
            }
        }
        return NewActorComp;
    }
};

///////////////////////////////////////////////////////////////
UComponentDataSerializer::UComponentDataSerializer(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , bFinished(false)
{
}

bool UComponentDataSerializer::Save(UClass* ActorClass)
{
#if WITH_EDITOR
    check(SavedTags.Num() < 32);

    UBlueprintGeneratedClass* ActualBPGC = Cast<UBlueprintGeneratedClass>(ActorClass);
    if (!ActualBPGC)
    {
        return false;
    }

    auto& AllDatas = ComponentDatas;
    if (SavedTags.Num() == 0)
    {
        AllDatas.Empty();
        return false;
    }

    std::function<void(FComponentInCDOCollector&, const FComponentTreeNodeInCDO*, const FName&, int, bool, int)> CollectFunc;
    CollectFunc = [&](FComponentInCDOCollector& InCollector, const FComponentTreeNodeInCDO* Node,
        const FName& ParentComponentName, int ParentTagFlag, bool bParentEditorOnly,
        int InheritParentStack)->void {

        UActorComponent* Component = Node->Component;
        if (Component
            && (bParentEditorOnly || Component->IsEditorOnly())
            && Component == Node->SCSNode->GetActualComponentTemplate(ActualBPGC))
        {
            int TagFlag = GetComponentExportedTag(Component);
            if (Component->ComponentTags.Find(DO_NOT_INHERIT_PARENT_TAG) != INDEX_NONE)
            {
                ParentTagFlag = 0;
                InheritParentStack = 0;
            }
            else
            {
                TagFlag |= ParentTagFlag;
            }

            if (TagFlag != 0)
            {
                auto& Data = AllDatas[AllDatas.AddDefaulted()];
                Component->bIsEditorOnly = 0;
                FTempComponentInstancingDataUtils::FillData(TagFlag, Node, ParentComponentName, Data);
                Component->bIsEditorOnly = 1;

                int KeyWordLen = FCString::Strlen(CHILDREN_INHERIT_SAME_TAG);
                for (auto& ComponentTag : Component->ComponentTags)
                {
                    FString Temp(ComponentTag.ToString());
                    int FindedIndex = Temp.Find(CHILDREN_INHERIT_SAME_TAG);
                    if (FindedIndex != INDEX_NONE)
                    {
                        ParentTagFlag = TagFlag;
                        InheritParentStack = MAX_int32;

                        if (Temp.Len() > KeyWordLen)
                        {
                            int Stack = FCString::Atoi(&Temp[0] + KeyWordLen);
                            if (Stack > 0)
                            {
                                InheritParentStack = Stack;
                            }
                        }
                        break;
                    }
                }
            }
            bParentEditorOnly = true;
        }

        if (InheritParentStack <= 0)
        {
            ParentTagFlag = 0;
        }

        for (int ii = 0; ii < Node->ChildIndices.Num(); ii++)
        {
            CollectFunc(InCollector, &InCollector.GetNode(Node->ChildIndices[ii]),
                Node->VariableName, ParentTagFlag, bParentEditorOnly, InheritParentStack-1);
        }
    };

    FComponentInCDOCollector Collector(ActorClass);
    int DataCount = Collector.GetNodeCount() - 1;  // root has no component, so we remove it
    AllDatas.Empty(DataCount);
    auto& ChildNodes = Collector.GetRoot().ChildIndices;
    for (int ii = 0; ii < ChildNodes.Num(); ii++)
    {
        CollectFunc(Collector, &Collector.GetNode(ChildNodes[ii]), NAME_None, 0, false, 0);
    }
    AllDatas.Shrink();

    int TotalMemorySize = AllDatas.GetAllocatedSize();
    for (auto& Data : AllDatas)
    {
        TotalMemorySize += Data.GetAdditionalMemorySize();
    }
    UE_LOG(LogComponentDataSerializer, Log, TEXT("Class [%s], saved %d data, total size: %.2f KB"),
        *ActorClass->GetName(), AllDatas.Num(), TotalMemorySize/1000.0f);
    return true;
#else
    return false;
#endif
}

bool UComponentDataSerializer::LoadSyn(const TArray<FName>& Tags, bool bBeginPlay)
{
    if (bFinished)
    {
        return true;
    }

    bFinished = true;
    auto Archetype = Cast<UComponentDataSerializer>(GetArchetype());
    auto& AllDatas = Archetype->ComponentDatas;
    int* DataIndices = (int*)FMemory_Alloca(sizeof(int*)*AllDatas.Num());
    int DataNum = CollectDataIndicesByTag(AllDatas, Tags, DataIndices);
    if (DataNum == 0)
    {
        return true;
    }

    AActor* Actor = GetOwner();
    UClass* ActorClass = Actor->GetClass();
    UWorld* World = Actor->GetWorld();
    if (TaskHandles.Num() > 0)
    {
        FlushAsynRequests();
        return true;
    }

#if WITH_EDITOR
    DestroyOldEditorComponents();
#endif

    UActorComponent** TempComponents = (UActorComponent**)FMemory_Alloca(sizeof(UActorComponent*)*DataNum);
    for (int ii = 0; ii < DataNum; ii++)
    {
        auto& Data = AllDatas[DataIndices[ii]];
        TempComponents[ii] = CreateComponent(Data);
    }

    for (int ii = 0; ii < DataNum; ii++)
    {
        auto Component = TempComponents[ii];
        if (Component)
        {
            Component->RegisterComponentWithWorld(World);
            Actor->AddOwnedComponent(Component);
        }
    }

    UBlueprintGeneratedClass::BindDynamicDelegates(Actor->GetClass(), Actor);

    if (bBeginPlay)
    {
        TryActorBeginPlayManually();
    }
    return true;
}

bool UComponentDataSerializer::LoadAsyn(const TArray<FName>& Tags, int Priority, bool ManualBeginPlay, bool SeparateBeginPlay)
{
    if (bFinished || TaskHandles.Num() > 0)
    {
        return true;
    }

    auto Archetype = Cast<UComponentDataSerializer>(GetArchetype());
    auto& AllDatas = Archetype->ComponentDatas;
    int* DataIndices = (int*)FMemory_Alloca(sizeof(int*)*AllDatas.Num());
    int DataNum = CollectDataIndicesByTag(AllDatas, Tags, DataIndices);
    if (DataNum == 0)
    {
        return true;
    }

    AActor* Actor = GetOwner();
    UClass* ActorClass = Actor->GetClass();
    UWorld* World = Actor->GetWorld();
    if (TempInstancedComponents.Num() != 0 || TaskHandles.Num() != 0)
    {
        return false;
    }

#if WITH_EDITOR
    DestroyOldEditorComponents();
#endif

    //class FVerifyClassTask : public FGameLimitedTimeTask
    //{
    //public:
    //    FVerifyClassTask(UComponentDataSerializer* InOwner)
    //        : OwnerComponent(InOwner)
    //        , bInited(false)
    //    {
    //    }
    //    virtual ~FVerifyClassTask()
    //    {
    //        Cancel();
    //    }
    //    virtual void Process() override
    //    {
    //        if (!OwnerComponent.IsValid())
    //        {
    //            return;
    //        }

    //        auto Archetype = Cast<UComponentDataSerializer>(OwnerComponent->GetArchetype());
    //        auto& AllDatas = Archetype->ComponentDatas;
    //        if (!bInited)
    //        {
    //            bInited = true;
    //            for(int ii=0; ii<AllDatas.Num(); ii++)
    //            {
    //                auto& Data = AllDatas[ii];
    //                if (!Data.Class)
    //                {
    //                    Data.Class = Cast<UClass>(StaticFindObject(UClass::StaticClass(), nullptr, *Data.ClassPathName));
    //                }
    //                if (Data.Class)
    //                {
    //                    continue;
    //                }
    //                IndexToHandles.Emplace(ii) = AssetLoader.RequestAsyncLoad(
    //                    FStringAssetReference(Data.ClassPathName),
    //                    FStreamableDelegate(),
    //                    MAX_int32);
    //            }
    //        }
    //        else
    //        {
    //            for (auto Iter=IndexToHandles.CreateIterator(); Iter; ++Iter)
    //            {
    //                auto Index = Iter->Key;
    //                auto Handle = Iter->Value;
    //                if (Handle->HasLoadCompleted())
    //                {
    //                    AllDatas[Index].Class = Cast<UClass>(Handle->GetLoadedAsset());
    //                    Iter.RemoveCurrent();
    //                }
    //            }
    //        }
    //    }
    //    virtual void Cancel() override
    //    {
    //        if (IndexToHandles.Num())
    //        {
    //            for (auto Iter = IndexToHandles.CreateIterator(); Iter; ++Iter)
    //            {
    //                auto Handle = Iter->Value;
    //                Handle->CancelHandle();
    //            }
    //            IndexToHandles.Empty();
    //        }
    //    }
    //private:
    //    bool bInited;
    //    FStreamableManager AssetLoader;
    //    TMap<int, TSharedPtr<FStreamableHandle> > IndexToHandles;
    //    TWeakObjectPtr<UComponentDataSerializer> OwnerComponent;
    //};

    class FCreateTask : public FGameLimitedTimeTask
    {
    public:
        FCreateTask(UComponentDataSerializer* InOwner, int InDataIndex)
            : OwnerComponent(InOwner)
            , DataIndex(InDataIndex)
        {
        }

        virtual void Process() override
        {
            if (!OwnerComponent.IsValid())
            {
                return;
            }

            auto RawOwnerComponent = OwnerComponent.Get();
            auto TempArchetype = Cast<UComponentDataSerializer>(RawOwnerComponent->GetArchetype());
            check(DataIndex >= 0 && DataIndex < TempArchetype->ComponentDatas.Num());
            auto& Data = TempArchetype->ComponentDatas[DataIndex];
            auto TempComponent = RawOwnerComponent->CreateComponent(Data);
            RawOwnerComponent->TempInstancedComponents.Add(TempComponent);

#ifdef ENABLE_DEBUG_LOG
            if (TempComponent)
            {
                UE_LOG(LogComponentDataSerializer, Display, TEXT("Process CreateTask, OwnerActor[%s], VariableName[%s]"),
                    *RawOwnerComponent->GetOwner()->GetName(), *Data.VariableName.ToString());
            }
#endif
        }

        virtual const FString GetInfo() const override
        {
            if (!OwnerComponent.IsValid())
            {
                return FString(TEXT("ComponentCreateTask invalid owner"));
            }

            auto TempArchetype = Cast<UComponentDataSerializer>(OwnerComponent->GetArchetype());
            check(DataIndex >= 0 && DataIndex < TempArchetype->ComponentDatas.Num());
            auto& Data = TempArchetype->ComponentDatas[DataIndex];
            return FString::Printf(TEXT("ComponentCreateTask: actor: %s, %s"),
                *OwnerComponent->GetOwner()->GetName(),
                *Data.GetInfo());
        }
    private:
        TWeakObjectPtr<UComponentDataSerializer> OwnerComponent;
        int DataIndex;
    };

    class FRegisterTask : public FGameLimitedTimeTask
    {
    public:
        FRegisterTask(UComponentDataSerializer* InOwner, int InDataIndex)
            : OwnerComponent(InOwner)
            , DataIndex(InDataIndex)
        {
        }

        virtual void Process() override
        {
            if (!OwnerComponent.IsValid())
            {
                return;
            }

            auto RawOwnerComponent = OwnerComponent.Get();
            if (DataIndex >= RawOwnerComponent->TempInstancedComponents.Num())
            {
                return;
            }

            auto TempComponent = RawOwnerComponent->TempInstancedComponents[DataIndex];
            if (TempComponent)
            {
                TempComponent->RegisterComponentWithWorld(RawOwnerComponent->GetWorld());
                RawOwnerComponent->GetOwner()->AddOwnedComponent(TempComponent);

#ifdef ENABLE_DEBUG_LOG
                auto TempArchetype = Cast<UComponentDataSerializer>(RawOwnerComponent->GetArchetype());
                check(DataIndex >= 0 && DataIndex < TempArchetype->ComponentDatas.Num());
                auto& Data = TempArchetype->ComponentDatas[DataIndex];
                UE_LOG(LogComponentDataSerializer, Display, TEXT("Process RegisterTask, OwnerActor[%s], VariableName[%s]"),
                    *RawOwnerComponent->GetOwner()->GetName(), *Data.VariableName.ToString());
#endif
            }
        }

        virtual const FString GetInfo() const override
        {
            if (!OwnerComponent.IsValid())
            {
                return FString(TEXT("ComponentRegisterTask invalid owner"));
            }

            auto TempComponent = OwnerComponent->TempInstancedComponents[DataIndex];
            return FString::Printf(TEXT("ComponentRegisterTask: actor: %s, component: %s"),
                *OwnerComponent->GetOwner()->GetName(),
                TempComponent ? *TempComponent->GetName() : TEXT("null"));
        }
    private:
        TWeakObjectPtr<UComponentDataSerializer> OwnerComponent;
        int DataIndex;
    };

    class FBeginPlayTask : public FGameLimitedTimeTask
    {
    public:
        enum EBeginPlayState
        {
            Pre = 0,
            Orignal,
            Post,
            Full,
        };
    public:
        FBeginPlayTask(UComponentDataSerializer* InOwnerComponent, int InDataCount, EBeginPlayState InBeginPlayState)
            : OwnerComponent(InOwnerComponent)
            , DataCount(InDataCount)
            , BeginPlayState(InBeginPlayState)
        {
        }
        virtual ~FBeginPlayTask()
        {
        }
        void Clear()
        {
            auto RawOwnerComponent = OwnerComponent.Get();
            if (RawOwnerComponent)
            {
                RawOwnerComponent->TempInstancedComponents.Empty();
                RawOwnerComponent->TaskHandles.Empty();
                auto& RawMemory = RawOwnerComponent->TaskRawMemory;
                if (RawMemory.Num() > 0)
                {
                    int Offset = 0;
                    for (int ii = 0; ii < DataCount; ii++)
                    {
                        ((FCreateTask*)&RawMemory[Offset])->~FCreateTask();
                        Offset += sizeof(FCreateTask);
                    }
                    for (int ii = 0; ii < DataCount; ii++)
                    {
                        ((FRegisterTask*)&RawMemory[Offset])->~FRegisterTask();
                        Offset += sizeof(FRegisterTask);
                    }
                    check(Offset == RawMemory.Num());
                    RawMemory.Empty();
                }
            }
        }
        virtual void Process() override
        {
            if (!OwnerComponent.IsValid())
            {
                return;
            }

            AActor* TempActor = OwnerComponent->GetOwner();
            check(TempActor);

            switch (BeginPlayState)
            {
            case FBeginPlayTask::Pre:
                UBlueprintGeneratedClass::BindDynamicDelegates(TempActor->GetClass(), TempActor);
                CALL_KMACTOR_FUNC(TempActor, PreBeginPlay());
                break;
            case FBeginPlayTask::Orignal:
                CALL_KMACTOR_FUNC(TempActor, OrignalBeginPlay());
                break;
            case FBeginPlayTask::Post:
                Clear();
                OwnerComponent->bFinished = true;
                CALL_KMACTOR_FUNC(TempActor, PostBeginPlay());
                break;
            case FBeginPlayTask::Full:
                Clear();
                OwnerComponent->bFinished = true;
                UBlueprintGeneratedClass::BindDynamicDelegates(TempActor->GetClass(), TempActor);
                OwnerComponent->TryActorBeginPlayManually();
                break;
            }
#ifdef ENABLE_DEBUG_LOG
            UE_LOG(LogComponentDataSerializer, Display, TEXT("Process Beginplay, OwnerActor[%s]"),
                *OwnerComponent->GetOwner()->GetName());
#endif
        }

        virtual const FString GetInfo() const override
        {
            if (!OwnerComponent.IsValid())
            {
                return FString(TEXT("ComponentBeginPlayTask invalid owner"));
            }

            return FString::Printf(TEXT("ComponentBeginPlayTask: actor: %s, state: %d"),
                *OwnerComponent->GetOwner()->GetName(),
                (int)BeginPlayState);
        }
    private:
        TWeakObjectPtr<UComponentDataSerializer> OwnerComponent;
        int DataCount;
        EBeginPlayState BeginPlayState;
    };

    auto TaskManager = UGameCommon::Get(this)->GetTaskManager();
    TaskRawMemory.AddUninitialized(sizeof(FCreateTask)*DataNum + sizeof(FRegisterTask)*DataNum);
    TaskHandles.Reserve(DataNum*2 + 1);

    //TaskHandles.Add(TaskManager->AddTask(new FVerifyClassTask(this), Priority, true));

    int Offset = 0;
    FGameLimitedTimeTask* Task = nullptr;
    for (int ii = 0; ii < DataNum; ii++)
    {
        Task = new (&TaskRawMemory[Offset]) FCreateTask(this, DataIndices[ii]);
        Offset += sizeof(FCreateTask);
        TaskHandles.Add(TaskManager->AddTask(Task, Priority, false));
    }
    for (int ii = 0; ii < DataNum; ii++)
    {
        Task = new (&TaskRawMemory[Offset]) FRegisterTask(this, ii);
        Offset += sizeof(FRegisterTask);
        TaskHandles.Add(TaskManager->AddTask(Task, Priority, false));
    }
    check(Offset == TaskRawMemory.Num());
    if (ManualBeginPlay)
    {
        if (SeparateBeginPlay)
        {
            TaskHandles.Add(TaskManager->AddTask(new FBeginPlayTask(this, DataNum, FBeginPlayTask::Pre), Priority, true));
            TaskHandles.Add(TaskManager->AddTask(new FBeginPlayTask(this, DataNum, FBeginPlayTask::Orignal), Priority, true));
            TaskHandles.Add(TaskManager->AddTask(new FBeginPlayTask(this, DataNum, FBeginPlayTask::Post), Priority, true));
        }
        else
        {
            TaskHandles.Add(TaskManager->AddTask(new FBeginPlayTask(this, DataNum, FBeginPlayTask::Full), Priority, true));
        }
    }

    return true;
}

void UComponentDataSerializer::FlushAsynRequests()
{
    if (TaskHandles.Num())
    {
        auto SavedHandles = TaskHandles;
        TaskHandles.Empty();

        auto TaskManager = UGameCommon::Get(this)->GetTaskManager();
        for (int ii = 0; ii < SavedHandles.Num(); ii++)
        {
            auto Handle = SavedHandles[ii];
            TaskManager->FlushTask(Handle);
        }
        TaskRawMemory.Empty();
    }
}

void UComponentDataSerializer::CancelAsynRequests()
{
    auto GameCommon = UGameCommon::Get(this);
    if (TaskHandles.Num() && GameCommon)
    {
        auto TaskManager = GameCommon->GetTaskManager();
        if (TaskManager)
        {
            for (int ii = 0; ii < TaskHandles.Num(); ii++)
            {
                TaskManager->RemoveTask(TaskHandles[ii]);
            }
        }
        TaskHandles.Empty();
    }
    TaskRawMemory.Empty();
}

int UComponentDataSerializer::GetTagFlag(const FName& Tag)
{
    for (int ii=0; ii<SavedTags.Num(); ii++)
    {
        if (SavedTags[ii] == Tag)
        {
            return GetTagFlag(ii);
        }
    }

    return 0;
}

int UComponentDataSerializer::GetTagFlag(int SavedTagIndex)
{
    return 1 << SavedTagIndex;
}

void UComponentDataSerializer::TryActorBeginPlayManually()
{
    AActor* Actor = GetOwner();
    CALL_KMACTOR_FUNC(Actor, BeginPlayManually());
}

int UComponentDataSerializer::GetComponentExportedTag(UActorComponent* Component)
{
    int TagFlag = 0;
    auto& Tags = Component->ComponentTags;
    if (Tags.Num())
    {
        for (int jj = 0; jj < SavedTags.Num(); jj++)
        {
            FName& SavedTag = SavedTags[jj];
            if (Tags.Find(SavedTag) != INDEX_NONE)
            {
                TagFlag |= GetTagFlag(jj);
            }
        }
    }
    return TagFlag;
}

UActorComponent* UComponentDataSerializer::CreateComponent(FGameComponentSavedData& Data)
{
    if (!Data.Class)
    {
        return nullptr;
    }

    AActor* Actor = GetOwner();
    FObjectPropertyBase* Prop = CastField<FObjectPropertyBase>(Actor->GetClass()->FindPropertyByName(Data.VariableName));
    if (!Prop)
    {
        return nullptr;
    }

    auto OldComponent = Cast<UActorComponent>(Prop->GetObjectPropertyValue_InContainer(Actor));
    if (OldComponent)
    {
        return nullptr;
    }

    auto NewActorComp = FTempComponentInstancingDataUtils::NewComponent(Actor, Data);
    if (!NewActorComp)
    {
        return nullptr;
    }

    NewActorComp->SetNetAddressable();

    // Special handling for scene components
    USceneComponent* NewSceneComp = Cast<USceneComponent>(NewActorComp);
    if (NewSceneComp != nullptr && Data.ParentComponentName != NAME_None)
    {
        FObjectPropertyBase* ParentProperty = CastField<FObjectPropertyBase>(Actor->GetClass()->FindPropertyByName(Data.ParentComponentName));
        if (ParentProperty)
        {
            auto ParentComponent = Cast<USceneComponent>(ParentProperty->GetObjectPropertyValue_InContainer(Actor));
            if (ParentComponent)
            {
                NewSceneComp->SetupAttachment(ParentComponent, Data.AttachToName);
            }
        }
    }

    Prop->SetObjectPropertyValue_InContainer(Actor, NewActorComp);
    return NewActorComp;
}

#if WITH_EDITOR
void UComponentDataSerializer::DestroyOldEditorComponents()
{
    AActor* Actor = GetOwner();
    TInlineComponentArray<UActorComponent*> OldComponents;
    Actor->GetComponents(OldComponents);
    for (int ii = OldComponents.Num() - 1; ii >= 0; ii--)
    {
        auto OldComponent = OldComponents[ii];
        if (OldComponent->IsEditorOnly())
        {
            FObjectPropertyBase* Prop = CastField<FObjectPropertyBase>(Actor->GetClass()->FindPropertyByName(OldComponent->GetFName()));
            if (Prop)
            {
                Prop->SetObjectPropertyValue_InContainer(Actor, nullptr);
            }
            FString TempNewName = OldComponent->GetName();
            TempNewName.Append("_PendingDelete");
            OldComponent->Rename(*TempNewName, Actor);
            OldComponent->DestroyComponent();
        }
    }
}
#endif

int UComponentDataSerializer::CollectDataIndicesByTag(const TArray<FGameComponentSavedData>& AllDatas,
    const TArray<FName>& Tags, int* OutDataIndices)
{
    check(OutDataIndices);
    int TagFlag = 0;
    for (auto& Tag : Tags)
    {
        TagFlag |= GetTagFlag(Tag);
    }

    int DataNum = 0;
    for (int ii=0; ii<AllDatas.Num(); ii++)
    {
        if (AllDatas[ii].TagFlag & TagFlag)
        {
            OutDataIndices[DataNum++] = ii;
        }
    }
    return DataNum;
}

void UComponentDataSerializer::OnComponentDestroyed(bool bDestroyingHierarchy)
{
    CancelAsynRequests();
    Super::OnComponentDestroyed(bDestroyingHierarchy);
}

void UComponentDataSerializer::Serialize(FArchive& Ar)
{
    struct FIgnoreProperty
    {
        FIgnoreProperty()
            : IgnoreProperty(nullptr)
            , bOldSkipFlag(false)
        {
        }
        void Edit(UClass* Class, const TCHAR* Name)
        {
            bOldSkipFlag = false;
            IgnoreProperty = Class->FindPropertyByName(Name);
            if (IgnoreProperty)
            {
                bOldSkipFlag = IgnoreProperty->HasAnyPropertyFlags(CPF_SkipSerialization);
                IgnoreProperty->SetPropertyFlags(CPF_SkipSerialization);
            }
        }
        void Revert()
        {
            if (IgnoreProperty && !bOldSkipFlag)
            {
                IgnoreProperty->ClearPropertyFlags(CPF_SkipSerialization);
            }
        }
        FProperty* IgnoreProperty;
        bool bOldSkipFlag;
    } IgnoreHelper;

    if (!HasAnyFlags(RF_ClassDefaultObject | RF_ArchetypeObject | RF_DefaultSubObject)
        || HasAnyFlags(RF_Transient))
    {
        IgnoreHelper.Edit(GetClass(), TEXT("ComponentDatas"));
    }

    Super::Serialize(Ar);

    IgnoreHelper.Revert();
}

#undef CALL_KMACTOR_FUNC