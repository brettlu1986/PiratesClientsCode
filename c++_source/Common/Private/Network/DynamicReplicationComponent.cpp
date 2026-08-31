#include "Network/DynamicReplicationComponent.h"
#include "Common.h"
#include "Util/LuaTableRef.h"
#include "ProtobufCodec.h"
#include "Util/MessageLuaUtil.h"
#include "Game/GameCommon.h"
#include "Network/RPCNetworkManager.h"
#include "Net/UnrealNetwork.h"

#define WITH_PROTO_CHECK 1
#if WITH_PROTO_CHECK
#include "Misc/SecureHash.h"
#endif

#define REPNOTIFY_FUNCTION_PREFIX TEXT("OnRep_")

DEFINE_LOG_CATEGORY_STATIC(DynamicReplicationComponentLog, Log, All)

static FString GetRepNotifyFunctionName(const FDynamicReplicationPropertyDefine& Info)
{
    return FString(REPNOTIFY_FUNCTION_PREFIX) + Info.PropertyName.ToString();
}

UFunction* UDynamicReplicationGeneratedClass::CreateRepFunction(UDynamicReplicationGeneratedClass* Class, const FDynamicReplicationPropertyDefine& Info)
{
    FName FunctionName = *GetRepNotifyFunctionName(Info);
    UFunction* NewFunction = NewObject<UFunction>(Class, FunctionName, RF_Public);
    NewFunction->FunctionFlags |= (FUNC_Public | FUNC_Native);
    Class->AddNativeFunction(*FunctionName.ToString(), &UDynamicReplicationGeneratedClass::OnRepNotify);
    Class->AddFunctionToFunctionMap(NewFunction, FunctionName);
    NewFunction->Bind();
    NewFunction->StaticLink(true);

    return NewFunction;
}

FProperty* UDynamicReplicationGeneratedClass::CreateRepProperty(UDynamicReplicationGeneratedClass* Class, const FDynamicReplicationPropertyDefine& Info)
{
    auto CreateSingleProperty = [&](UObject* PropertyOuter, const FName& Name, EDynamicReplicationPropertyType Type)->FProperty* {
        const EObjectFlags ObjectFlags = RF_Public;
        FProperty* Ret = nullptr;

        switch (Type)
        {
        case EDynamicReplicationPropertyType::Bool:
        {
            auto BoolProperty = new FBoolProperty(PropertyOuter, Name, ObjectFlags);
            BoolProperty->SetBoolSize(sizeof(bool), true);
            Ret = BoolProperty;
            break;
        }
        case EDynamicReplicationPropertyType::Int:
        {
            Ret = new FIntProperty(PropertyOuter, Name, ObjectFlags);
            Ret->SetPropertyFlags(CPF_HasGetValueTypeHash);
            break;
        }
        case EDynamicReplicationPropertyType::Float:
        {
            Ret = new FFloatProperty(PropertyOuter, Name, ObjectFlags);
            Ret->SetPropertyFlags(CPF_HasGetValueTypeHash);
            break;
        }
        case EDynamicReplicationPropertyType::String:
        {
            Ret = new FStrProperty(PropertyOuter, Name, ObjectFlags);
            Ret->SetPropertyFlags(CPF_HasGetValueTypeHash);
            break;
        }
        case EDynamicReplicationPropertyType::Proto:
        {
#ifdef USE_TEMP_PROTO_SOLUTION
            Class->ProtoItemIndexToPropertyId.Add(Class->ProtoItemIndex, Info.PropertyId);
            Class->PropertyIdToProtoItemIndex.Add(Info.PropertyId, Class->ProtoItemIndex);
            Class->PropertyIdToRepType.Add(Info.PropertyId, Info.RepType);
            Class->PropertyIdToPropertyName.Add(Info.PropertyId, Name);
            ++Class->ProtoItemIndex;
#else
            auto ArrayProperty = new FArrayProperty(PropertyOuter, Name, ObjectFlags);
            ArrayProperty->Inner = new FByteProperty(ArrayProperty, Name, ObjectFlags);
            ArrayProperty->Inner->SetPropertyFlags(CPF_HasGetValueTypeHash | CPF_IsPlainOldData);
            Ret = ArrayProperty;
#endif
            break;
        }
        }

        return Ret;
    };

    FProperty* Property = nullptr;
    //if (Info.IsArray)
    //{
    //    auto ArrayProperty = NewObject<FArrayProperty>(Class, Info.PropertyName);
    //    ArrayProperty->Inner = CreateSingleProperty(ArrayProperty, Info.PropertyName, Info.PropertyType);
    //    ArrayProperty->Inner->SetPropertyFlags(CPF_HasGetValueTypeHash | CPF_IsPlainOldData);
    //    Property = ArrayProperty;
    //}
    //else
    {
        Property = CreateSingleProperty(Class, Info.PropertyName, Info.PropertyType);
    }

#ifdef USE_TEMP_PROTO_SOLUTION
    if (!Property)
    {
        return nullptr;
    }
#endif

    Property->SetBlueprintReplicationCondition(Info.RepType);
    Property->SetPropertyFlags(CPF_Net | CPF_RepNotify | CPF_Transient | CPF_Edit);
    Property->RepNotifyFunc = *GetRepNotifyFunctionName(Info);
    Property->SetFlags(RF_LoadCompleted);
    Class->AddCppProperty(Property);
    Class->NumReplicatedProperties++;

    return Property;
}

bool UDynamicReplicationGeneratedClass::CheckSameClass(UDynamicReplicationGeneratedClass* Class, const TArray<FDynamicReplicationPropertyDefine>& Defines)
{
#ifdef USE_TEMP_PROTO_SOLUTION
    int nProtoIndex = 0;
#else
    if (Class->IdToProperties.Num() != Defines.Num())
    {
        return false;
    }
#endif

    for (auto& DefineInfo : Defines)
    {
        FProperty* Property = Class->FindPropertyByName(DefineInfo.PropertyName);
        if (Property)
        {
            if (Property->GetBlueprintReplicationCondition() != DefineInfo.RepType)
            {
                return false;
            }

            auto* FindedProperty = Class->IdToProperties.Find(DefineInfo.PropertyId);
            if (FindedProperty == nullptr || *FindedProperty != Property)
            {
                return false;
            }

            bool bSame = false;
            switch (DefineInfo.PropertyType)
            {
            case EDynamicReplicationPropertyType::Bool:
            {
                bSame = CastField<FBoolProperty>(Property) != nullptr;
                break;
            }
            case EDynamicReplicationPropertyType::Int:
            {
                bSame = CastField<FIntProperty>(Property) != nullptr;
                break;
            }
            case EDynamicReplicationPropertyType::Float:
            {
                bSame = CastField<FFloatProperty>(Property) != nullptr;
                break;
            }
            case EDynamicReplicationPropertyType::String:
            {
                bSame = CastField<FStrProperty>(Property) != nullptr;
                break;
            }
            case EDynamicReplicationPropertyType::Proto:
            {
                auto ArrayProperty = CastField<FArrayProperty>(Property);
                if (ArrayProperty)
                {
                    bSame = CastField<FByteProperty>(ArrayProperty->Inner) != nullptr;
                }
                break;
            }
            default:
                return false;
            }

            if (!bSame)
            {
                return false;
            }
        }
        else
        {
#ifdef USE_TEMP_PROTO_SOLUTION
            if (DefineInfo.PropertyType != EDynamicReplicationPropertyType::Proto)
            {
                return false;
            }

            auto* FindedRepType = Class->PropertyIdToRepType.Find(DefineInfo.PropertyId);
            if (!FindedRepType || *FindedRepType != DefineInfo.RepType)
            {
                return false;
            }
            auto* FindedProtoIndex = Class->PropertyIdToProtoItemIndex.Find(DefineInfo.PropertyId);
            if (!FindedProtoIndex || *FindedProtoIndex != nProtoIndex)
            {
                return false;
            }
            auto* FindedName = Class->PropertyIdToPropertyName.Find(DefineInfo.PropertyId);
            if (!FindedName || *FindedName != DefineInfo.PropertyName)
            {
                return false;
            }
#else
            return false;
#endif
        }

#ifdef USE_TEMP_PROTO_SOLUTION
        if (DefineInfo.PropertyType == EDynamicReplicationPropertyType::Proto)
        {
            ++nProtoIndex;
        }
#endif
    }

#ifdef USE_TEMP_PROTO_SOLUTION
    if (nProtoIndex != Class->ProtoItemIndex)
    {
        return false;
    }
#endif

    return true;
}

UBlueprintGeneratedClass* UDynamicReplicationGeneratedClass::Generate(const FString& ClassName,
    const TArray<FDynamicReplicationPropertyDefine>& Defines)
{
    auto Outer = GetTransientPackage();
    auto ParentClass = UDynamicReplicationComponent::StaticClass();
    UDynamicReplicationGeneratedClass* Class = nullptr;

#if WITH_EDITOR
    Class = Cast<UDynamicReplicationGeneratedClass>(StaticFindObject(UClass::StaticClass(), Outer, *ClassName));
    if (Class && !Class->IsPendingKill() && CheckSameClass(Class, Defines))
    {
        return Class;
    }
#endif

    Class = NewObject<UDynamicReplicationGeneratedClass>(Outer, *ClassName, RF_Public);
    Class->ClassFlags |= (ParentClass->ClassFlags & (CLASS_Inherit | CLASS_ScriptInherit | CLASS_CompiledFromBlueprint));
    Class->ClassConstructor = ParentClass->ClassConstructor;
    Class->ClassGeneratedBy = nullptr;
    Class->ClassAddReferencedObjects = ParentClass->ClassAddReferencedObjects;
    Class->PropertyLink = ParentClass->PropertyLink;
    Class->ClassWithin = ParentClass->ClassWithin;
    Class->ClassConfigName = ParentClass->ClassConfigName;
    Class->SetSuperStruct(ParentClass);
    Class->ClassCastFlags |= ParentClass->ClassCastFlags;

#ifdef USE_TEMP_PROTO_SOLUTION
    Class->ProtoItemIndex = 0;
#endif

    for (auto& Info : Defines)
    {
        FProperty* Property = CreateRepProperty(Class, Info);
#ifdef USE_TEMP_PROTO_SOLUTION
        if (!Property)
        {
            continue;
        }
#endif

        check(Property);
        Class->IdToProperties.Add(Info.PropertyId, Property);

        UFunction* Function = CreateRepFunction(Class, Info);
        check(Function);
        Class->FunctionToIds.Add(Function, Info.PropertyId);
    }

    Class->Bind();
    Class->StaticLink(true);
    Class->GetDefaultObject();
    Class->UpdateCustomPropertyListForPostConstruction();

    return Class;
}

void UDynamicReplicationGeneratedClass::SetPendingDestroy(UClass* Class)
{
    UDynamicReplicationGeneratedClass* pRemovedClass = Cast<UDynamicReplicationGeneratedClass>(Class);
    if (pRemovedClass)
    {
        pRemovedClass->GetDefaultObject()->MarkPendingKill();
        pRemovedClass->MarkPendingKill();
    }
}

void UDynamicReplicationGeneratedClass::OnRepNotify(UObject* Context, FFrame& Stack, RESULT_DECL)
{
    UDynamicReplicationComponent* Component = CastChecked<UDynamicReplicationComponent>(Context);
    UDynamicReplicationGeneratedClass* Class = CastChecked<UDynamicReplicationGeneratedClass>(Context->GetClass());

    int PropertyId = Class->FunctionToIds.FindChecked(Stack.Node);
    Component->ProcessValueChanged(PropertyId);
}

//////////////////////////////////////////////////////////////////////////
UDynamicReplicationComponent::UDynamicReplicationComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , TempProto(nullptr)
    , bNeedPostRepNotify(false)
{
    if (!HasAnyFlags(RF_ClassDefaultObject))
    {
        TempProto = NewObject<UProtobufMessageRef>(this, TEXT("TempProto"));
        Codec = UGameCommon::Get(this)->GetRPCNetworkManager()->GetCodec();
        check(Codec.IsValid());

#ifdef USE_TEMP_PROTO_SOLUTION
        ProtoProperties.OwnerComponent = this;
#endif
    }
}

void UDynamicReplicationComponent::ProcessValueChanged(int PropertyId)
{
    if (PostNotifyProperties.Contains(PropertyId))
    {
        bNeedPostRepNotify = true;
    }

    OnValueChanged.ExecuteIfBound(PropertyId);
}

void UDynamicReplicationComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    OnEndPlay.ExecuteIfBound(GetOwner());
    ClearTempProto();
    Super::EndPlay(EndPlayReason);
}

FArrayProperty* UDynamicReplicationComponent::FindArrayProperty(int PropertyId)
{
    auto Class = Cast<UDynamicReplicationGeneratedClass>(GetClass());
    check(Class);

    FProperty** Property = Class->IdToProperties.Find(PropertyId);
    if (!Property)
    {
        UE_LOG(DynamicReplicationComponentLog, Error, TEXT("DynamicReplicationComponent::FindArrayProperty failed, propertyid: %d."),
            PropertyId);
        return nullptr;
    }

    return CastField<FArrayProperty>(*Property);
}

#if WITH_PROTO_CHECK
struct FCheckHeader
{
    int32 MessageSize;
    uint8 Digest[16];
    int32 PropertyId;
    FString MessageName;

    FCheckHeader(int32 InSize, uint8* InDigest, int32 InPropertyId, const FString& InMessageName)
        : MessageSize(InSize), PropertyId(InPropertyId), MessageName(InMessageName)
    {
        FMemory::Memcpy(Digest, InDigest, 16);
    }
    FCheckHeader()
        : MessageSize(0), PropertyId(0)
    {
        FMemory::Memzero(Digest, 16);
    }
};

FArchive& operator<<(FArchive& Ar, struct FCheckHeader& Value)
{
    Ar << Value.MessageSize;
    Ar.Serialize(Value.Digest, 16);
    Ar << Value.PropertyId;
    Ar << Value.MessageName;
    return Ar;
}
#endif

bool UDynamicReplicationComponent::SetProto(int PropertyId, const FString& MessageName, ULuaTableRef* TableRef)
{
#ifdef USE_TEMP_PROTO_SOLUTION
    auto Class = Cast<UDynamicReplicationGeneratedClass>(GetClass());
    if (ProtoProperties.Items.Num() == 0)
    {
        check(Class->ProtoItemIndex == Class->ProtoItemIndexToPropertyId.Num());
        ProtoProperties.Items.AddDefaulted(Class->ProtoItemIndex);
        ProtoProperties.MarkArrayDirty();
    }

    int ItemIndex = Class->PropertyIdToProtoItemIndex.FindChecked(PropertyId);
    auto& PropertyItem = ProtoProperties.Items[ItemIndex];
    auto& RawData = PropertyItem.RawData;

    if (TableRef)
    {
        check(Codec.IsValid());
        if (!FMessageLuaUtil::LuaTableToArrayData(Codec.Pin().Get(), MessageName, LUA_TABLE_REF_U2F(TableRef), nullptr, RawData))
        {
            UE_LOG(DynamicReplicationComponentLog, Error, TEXT("DynamicReplicationComponent::LuaTableToArrayData failed, propertyid: %d, message name: %s."),
                PropertyId, *MessageName);
            return false;
        }
    }
    else
    {
        if (RawData.Num() == 0)
        {
            // TableRef是空，并且之前没数据，那么认为一致，所以没必要dirty
            return true;
        }

        // TableRef是空，直接清掉RawData
        RawData.Empty();
    }

    ProtoProperties.MarkItemDirty(PropertyItem);
#else
    FArrayProperty* ArrayProperty = FindArrayProperty(PropertyId);
    check(ArrayProperty && ArrayProperty == GetClass()->FindPropertyByName(*MessageName));

    check(Codec.IsValid());

    uint8 TempBuffer[65535];
    int32 MessageSize = 0;
    if (!FMessageLuaUtil::LuaTableToRawBuffer(Codec.Pin().Get(), MessageName, LUA_TABLE_REF_U2F(TableRef), nullptr, TempBuffer, sizeof(TempBuffer), MessageSize))
    {
        UE_LOG(DynamicReplicationComponentLog, Error, TEXT("DynamicReplicationComponent::LuaTableToRawData failed, propertyid: %d, message name: %s."),
            PropertyId, *MessageName);
        return false;
    }

    FScriptArrayHelper_InContainer ArrayHelper(ArrayProperty, this);

#if WITH_PROTO_CHECK
    uint8 Digest[16];
    FMD5 Md5;
    Md5.Update(TempBuffer, MessageSize);
    Md5.Final(Digest);

    TArray<uint8> RawData;
    FMemoryWriter Writer(RawData, true);
    FCheckHeader Header(MessageSize, Digest, PropertyId, MessageName);
    Writer << Header;

    int HeaderSize = RawData.Num();
    ArrayHelper.Resize(MessageSize + HeaderSize);
    FMemory::Memcpy(ArrayHelper.GetRawPtr(), RawData.GetData(), HeaderSize);

    Writer.Serialize(TempBuffer, MessageSize);
    check(ArrayHelper.Num() == RawData.Num());
#else
    int32 HeaderSize = 0;
    ArrayHelper.Resize(MessageSize);
#endif

    assert(MessageSize > 0);
    FMemory::Memcpy(ArrayHelper.GetRawPtr(HeaderSize), TempBuffer, MessageSize);

#if WITH_PROTO_CHECK
    check(ArrayProperty->Identical(ArrayProperty->ContainerPtrToValuePtr<void>(this, 0), (const void*)&RawData, 0));
    TArray<uint8>& ArrayData = *(TArray<uint8>*)(ArrayProperty->ContainerPtrToValuePtr<void>(this, 0));
    check(ArrayData == RawData);
#endif
#endif

    return true;
}

bool UDynamicReplicationComponent::GetProto(int PropertyId, const FString& MessageName, UProtobufMessageRef* &Out)
{
#ifdef USE_TEMP_PROTO_SOLUTION
    auto Class = Cast<UDynamicReplicationGeneratedClass>(GetClass());
    int ItemIndex = Class->PropertyIdToProtoItemIndex.FindChecked(PropertyId);
    auto& RawData = ProtoProperties.Items[ItemIndex].RawData;

    if (RawData.Num() > 0)
    {
        auto Message = Codec.Pin()->Decode(RawData.GetData(), RawData.Num());
        if (Message == nullptr)
        {
            UE_LOG(DynamicReplicationComponentLog, Error, TEXT("DynamicReplicationComponent::Decode failed, propertyid: %d, message name: %s."),
                PropertyId, *MessageName);
            return false;
        }

        ClearTempProto();
        TempProto->Message = Message;
        Out = TempProto;
    }
    else
    {
        Out = nullptr;
        return true;
    }

#else
    FArrayProperty* ArrayProperty = FindArrayProperty(PropertyId);
    check(ArrayProperty && ArrayProperty == GetClass()->FindPropertyByName(*MessageName));

    FScriptArrayHelper_InContainer ArrayHelper(ArrayProperty, this);

#if WITH_PROTO_CHECK
    TArray<uint8> RawData;
    RawData.AddUninitialized(ArrayHelper.Num());
    FMemory::Memcpy(RawData.GetData(), ArrayHelper.GetRawPtr(), ArrayHelper.Num());
    FMemoryReader Reader(RawData, true);
    FCheckHeader Header;
    Reader << Header;
    int32 HeaderSize = Reader.Tell();

    uint8 ClientDigest[16];
    FMD5 Md5;
    Md5.Update(ArrayHelper.GetRawPtr(HeaderSize), ArrayHelper.Num() - HeaderSize);
    Md5.Final(ClientDigest);

#define VERIFY_RETURN(__test, __desc) \
    if(!(__test)) \
    { \
        TArray<uint8>& ArrayData = *(TArray<uint8>*)(ArrayProperty->ContainerPtrToValuePtr<void>(this, 0)); \
        FString ArrayDisplayData; \
        for (int32 ii = HeaderSize; ii < ArrayData.Num(); ii++) \
        { \
            ArrayDisplayData.AppendChar(ArrayData[ii]); \
            ArrayDisplayData.AppendChar(' '); \
        } \
        UE_LOG(DynamicReplicationComponentLog, Error, TEXT("DynamicReplicationComponent error: %s, server: property id: %d, message name: %s, size: %d, client: property id: %d, message name: %s, size: %d. client data: [%s]"), \
            __desc, \
            Header.PropertyId, *Header.MessageName, Header.MessageSize, \
            PropertyId, *MessageName, ArrayHelper.Num() - HeaderSize, \
            *ArrayDisplayData); \
            return false; \
    }

    VERIFY_RETURN(Header.MessageSize == ArrayHelper.Num() - HeaderSize, TEXT("message size is not same"));
    VERIFY_RETURN(Header.PropertyId == PropertyId, TEXT("property id is not same"));
    VERIFY_RETURN(Header.MessageName == MessageName, TEXT("message name is not same"));
    VERIFY_RETURN(FMemory::Memcmp(&Header.Digest, &ClientDigest, 16) == 0, TEXT("md5 is not same"));

#undef VERIFY_RETURN
#else
    int32 HeaderSize = 0;
#endif

    auto Message = Codec.Pin()->Decode(ArrayHelper.GetRawPtr(HeaderSize), ArrayHelper.Num() - HeaderSize);
    if (Message == nullptr)
    {
        UE_LOG(DynamicReplicationComponentLog, Error, TEXT("DynamicReplicationComponent::Decode failed, propertyid: %d, message name: %s, size: %d."),
            PropertyId, *MessageName, ArrayHelper.Num());
        return false;
    }

    ClearTempProto();
    TempProto->Message = Message;
    Out = TempProto;
#endif

    return true;
}

void UDynamicReplicationComponent::AddRepNotifyProperties(const TArray<int>& Properties)
{
    for (int PropertyId : Properties)
    {
        PostNotifyProperties.Add(PropertyId);
    }
}

bool UDynamicReplicationComponent::IsProtoPropetyReplicated(int PropertyId)
{
    auto Class = Cast<UDynamicReplicationGeneratedClass>(GetClass());
    int ItemIndex = Class->PropertyIdToProtoItemIndex.FindChecked(PropertyId);
    return ItemIndex < ProtoProperties.Items.Num();
}

void UDynamicReplicationComponent::PostRepNotifies()
{
    Super::PostRepNotifies();

    if (bNeedPostRepNotify)
    {
        bNeedPostRepNotify = false;
        OnPostRepNotify.ExecuteIfBound();
    }
}

void UDynamicReplicationComponent::ClearTempProto()
{
    if (TempProto && Codec.IsValid() && TempProto->Message)
    {
        Codec.Pin()->DestroyMessage(TempProto->Message);
        TempProto->Message = nullptr;
    }
}

//////////////////////////////////////////////////////////////////////////
#ifdef USE_TEMP_PROTO_SOLUTION
void FProtoPropertyItem::PreReplicatedRemove(const FProtoPropertyArray& InArraySerializer)
{
    check(0);
}

void FProtoPropertyItem::PostReplicatedAdd(const FProtoPropertyArray& InArraySerializer)
{
    OnChanged(InArraySerializer, true);
}

void FProtoPropertyItem::PostReplicatedChange(const FProtoPropertyArray& InArraySerializer)
{
    OnChanged(InArraySerializer, false);
}

void FProtoPropertyItem::OnChanged(const FProtoPropertyArray& InArraySerializer, bool Initial)
{
    if (PropertyId < 0)
    {
        int FindIndex = -1;
        auto& Items = InArraySerializer.Items;
        for (int ii = 0; ii < Items.Num(); ii++)
        {
            if (&Items[ii] == this)
            {
                FindIndex = ii;
                break;
            }
        }
        if (FindIndex < 0)
        {
            UE_LOG(DynamicReplicationComponentLog, Fatal, TEXT("FProtoPropertyItem::PostReplicatedChange error: %d"));
        }

        PropertyId = InArraySerializer.OwnerComponent->FindProtoPropertyId(FindIndex);
        check(PropertyId >= 0);
    }

    auto OwnerRole = InArraySerializer.OwnerComponent->GetOwnerRole();
    auto Class = Cast<UDynamicReplicationGeneratedClass>(InArraySerializer.OwnerComponent->GetClass());
    auto RepType = Class->PropertyIdToRepType.FindChecked(PropertyId);

    bool bProcess = false;
    switch (RepType)
    {
    case COND_None:
        bProcess = true;
        break;
    case COND_InitialOnly:
        bProcess = Initial;
        break;
    case COND_OwnerOnly:
        bProcess = OwnerRole == ROLE_Authority || OwnerRole == ROLE_AutonomousProxy;
        break;
    case COND_SkipOwner:
        bProcess = OwnerRole != ROLE_Authority && OwnerRole != ROLE_AutonomousProxy;
        break;
    case COND_SimulatedOnly:
        bProcess = OwnerRole == ROLE_SimulatedProxy;
        break;
    case COND_AutonomousOnly:
        bProcess = OwnerRole == ROLE_AutonomousProxy;
        break;
    case COND_SimulatedOrPhysics:
        bProcess = OwnerRole == ROLE_SimulatedProxy;
        break;
    case COND_InitialOrOwner:
        bProcess = Initial || (OwnerRole == ROLE_Authority || OwnerRole == ROLE_AutonomousProxy);
        break;
        //case COND_Custom:
        //    break;
        //case COND_ReplayOrOwner:
        //    break;
        //case COND_ReplayOnly:
        //    break;
        //case COND_SimulatedOnlyNoReplay:
        //    break;
        //case COND_SimulatedOrPhysicsNoReplay:
        //    break;
        //case COND_SkipReplay:
        //    break;
        //case COND_Max:
        //    break;
    default:
        break;
    }

    if (bProcess)
    {
        InArraySerializer.OwnerComponent->ProcessValueChanged(PropertyId);
    }
}

void UDynamicReplicationComponent::GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME(UDynamicReplicationComponent, ProtoProperties);
}

int UDynamicReplicationComponent::FindProtoPropertyId(int ItemIndex)
{
    auto Class = Cast<UDynamicReplicationGeneratedClass>(GetClass());
    return Class->ProtoItemIndexToPropertyId.FindChecked(ItemIndex);
}
#endif