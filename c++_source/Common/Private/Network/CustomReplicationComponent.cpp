// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/CustomReplicationComponent.h"
#include "Common.h"
#include "Util/LuaTableRef.h"
#include "ProtobufCodec.h"
#include "Util/MessageLuaUtil.h"
#include "Game/GameCommon.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Net/UnrealNetwork.h"
#include "Game/Lua/LuaCustomDataWrapper.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Misc/Crc.h"
#include "Network/RPCNetworkManager.h"
#include "Shell/EngineExtActorShell.h"

#if ENABLE_GAME_MESSAGE_OBFUSCATION
#include "Util/DataObfuscationUtil.h"
#endif

#define REPLICATION_PROTO_USE_MESSAGE_FRAME 0

DEFINE_LOG_CATEGORY_STATIC(ReplicatedCustomPropertyComponentLog, Log, All)

//////////////////////////////////////////////////////////////////////////
const uint32 FCustomReplicationComponentInfo::GetCRC() const
{
    uint32 Ret = 0;
    for (auto const& DefineInfo : Defines)
    {
        uint32 NameHash = GetTypeHash(DefineInfo.PropertyName.ToString());
        ELifetimeCondition RepType = DefineInfo.RepType.GetValue();
        Ret = FCrc::MemCrc32(&NameHash, sizeof(uint32), Ret);
        Ret = FCrc::MemCrc32(&DefineInfo.PropertyType, sizeof(ECustomReplicatedPropertyType), Ret);
        Ret = FCrc::MemCrc32(&RepType, sizeof(ELifetimeCondition), Ret);
        Ret = FCrc::MemCrc32(&DefineInfo.PropertyId, sizeof(int32), Ret);
    }
    return Ret;
}

bool FReplicatedPropertyData::Serialize(FArchive& Archive, bool Read)
{
    switch (Type)
    {
    case ECustomReplicatedPropertyType::Bool:
        Archive << BoolValue;
        break;
    case ECustomReplicatedPropertyType::Int:
        Archive << IntValue;
        break;
    case ECustomReplicatedPropertyType::Float:
        Archive << FloatValue;
        break;
    case ECustomReplicatedPropertyType::Proto:
        Archive << *ProtoValue;
        break;
    default:
        check(false);
        return false;
    }
    return true;
}

void FReplicatedPropertyData::MarkDirty()
{
    OwnerArray->MarkDataDirty(this);

#if WITH_VERIFY_DATA
    auto& DataArray = *OwnerArray;
    for (int ii = 0; ii < DataArray.GetPropertyCount(); ii++)
    {
        auto& Data = DataArray.GetProperty(ii);
        if (&Data == this && OwnerArray->IndexNeedVerified.Contains(ii))
        {
            UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("MarkDirty actor [%s] netguid: %d, property: %s, history: %d"),
                *OwnerArray->OwnerComponent->GetOwner()->GetName(), UEngineExtActorShell::GetActorNetGuid(OwnerArray->OwnerComponent->GetOwner()),
                *PropertyName.ToString(), History);
            break;
        }
    }
#endif
}

//////////////////////////////////////////////////////////////////////////
void FReplicatedCustomPropertyArray::Init(UCustomReplicationComponent* InOwnerComponent, const TArray<const FCustomReplicationPropertyDefine*>& Defines)
{
    CurrentHistory = 0;
    OwnerComponent = InOwnerComponent;
    PropertyCount = Defines.Num();
    check(PropertyCount < 65535);
    if (PropertyCount == 0)
    {
        return;
    }

    ProtoCount = 0;
    for (auto DefineInfo : Defines)
    {
        if (DefineInfo->PropertyType == ECustomReplicatedPropertyType::Proto)
        {
            ++ProtoCount;
        }
    }

    AllRawData = static_cast<uint8*>(FMemory::Malloc(PropertyCount * sizeof(FReplicatedPropertyData) + ProtoCount * sizeof(TArray<uint8>)));
    TArray<uint8>* AllProtoData = (TArray<uint8>*)(AllRawData + PropertyCount * sizeof(FReplicatedPropertyData));

    int ProtoIndex = 0;
    FReplicatedPropertyData* PropertyData = nullptr;
    FReplicatedPropertyData* AllPropertyData = (FReplicatedPropertyData*)AllRawData;
    for (uint32 ii = 0; ii < PropertyCount; ++ii)
    {
        PropertyData = AllPropertyData + ii;
        auto DefineInfo = Defines[ii];
        switch (DefineInfo->PropertyType)
        {
        case ECustomReplicatedPropertyType::Bool:
        {
            new(PropertyData) FReplicatedPropertyData(DefineInfo->PropertyId, DefineInfo->PropertyName, this, false);
            break;
        }
        case ECustomReplicatedPropertyType::Int:
        {
            new(PropertyData) FReplicatedPropertyData(DefineInfo->PropertyId, DefineInfo->PropertyName, this, 0);
            break;
        }
        case ECustomReplicatedPropertyType::Float:
        {
            new(PropertyData) FReplicatedPropertyData(DefineInfo->PropertyId, DefineInfo->PropertyName, this, 0.0f);
            break;
        }
        case ECustomReplicatedPropertyType::Proto:
        {
            auto* ProtoData = AllProtoData + ProtoIndex;
            ++ProtoIndex;
            new(ProtoData) TArray<uint8>(); // 因为之前没执行过构造函数，所以这里补一下
            new(PropertyData) FReplicatedPropertyData(DefineInfo->PropertyId, DefineInfo->PropertyName, this, *ProtoData);
            break;
        }
        default:
            check(false);
            return;
        }
    }
}

class FProtoPropertyArrayState : public INetDeltaBaseState
{
public:
    FProtoPropertyArrayState(int InHistory)
        : INetDeltaBaseState()
        , History(InHistory)
    {
#if WITH_VERIFY_DATA
        static uint64 s_Id = 0;
        StateId = ++s_Id;
#endif
    }

    virtual bool IsStateEqual(INetDeltaBaseState* OtherState) override
    {
        FProtoPropertyArrayState* Other = static_cast<FProtoPropertyArrayState*>(OtherState);
        return History == Other->History;
    }

    uint64 History;

#if WITH_VERIFY_DATA
    uint64 StateId;
#endif
};

bool FReplicatedCustomPropertyArray::NetDeltaSerialize(FNetDeltaSerializeInfo & Params)
{
    // 我们不需要删除，不需要guid什么的，这里只处理项目需要的
    if (Params.GatherGuidReferences || Params.bUpdateUnmappedObjects)
    {
        return true;
    }

    if (Params.MoveGuidToUnmapped)
    {
        return false;
    }

    if (Params.Writer)
    {
#if !ENABLE_GAME_MESSAGE_OBFUSCATION
        FBitWriter& Writer = *Params.Writer;
#else
        static TArray<uint8> TempSrc, TempObfuscation;
        TempSrc.SetNumUninitialized(0, false);
        TempObfuscation.SetNumUninitialized(0, false);
        FMemoryWriter Writer(TempSrc, true);
#endif
        
        uint64 OldHistory = 0;        
        if (Params.OldState)
        {
            OldHistory = static_cast<FProtoPropertyArrayState*>(Params.OldState)->History;
        }
      
        if (OldHistory == CurrentHistory)
        {
            return false;
        }
        
        FProtoPropertyArrayState* StateInfo = new FProtoPropertyArrayState(CurrentHistory);
        *Params.NewState = MakeShareable(StateInfo);

#if WITH_VERIFY_DATA
        FString DirtyPropertyInfo;
        Writer << StateInfo->StateId;
        Writer << CurrentHistory;        
        auto& StateData = PendingVerifiedData.Emplace(StateInfo->StateId);
        FVerifyData* VerifiedData = nullptr;
#endif
        
        // BitWriter竟然没有tell和seek，太蛋疼了！
#if !ENABLE_GAME_MESSAGE_OBFUSCATION
        int64 StartNum = Writer.GetNumBits();
#else
        int64 StartNum = Writer.Tell();
#endif
        // 这里如果保险的话应该写个size进去，客户端出错时直接跳过size，这样后面serialize不会出错
        uint16 DirtyCount = 0;
        Writer << DirtyCount;

        // 这里图省事写了索引，如果想保险就写propertyid，客户端在自己查，但在这之前有crc校验，所以理论上只要能两边对的上，写什么都行
        for (uint16 ii = 0; ii < PropertyCount; ++ii)
        {
            auto& PropertyData = GetProperty(ii);
            if (PropertyData.History != INDEX_NONE && PropertyData.History > OldHistory)
            {
                ++DirtyCount;
                Writer << ii;
                PropertyData.Serialize(Writer, false);
                
#if WITH_VERIFY_DATA
                DirtyPropertyInfo += PropertyData.PropertyName.ToString();
                DirtyPropertyInfo += TEXT(", ");
                if (IndexNeedVerified.Contains(ii))
                {
                    if (VerifiedData == nullptr)
                    {
                        VerifiedData = &StateData.Emplace_GetRef(CurrentHistory);
                    }
                    
                    UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("WriteData actor [%s] netguid: %d, stateid: %d, history: %d, property: %s"),
                        *OwnerComponent->GetOwner()->GetName(), UEngineExtActorShell::GetActorNetGuid(OwnerComponent->GetOwner()),
                        StateInfo->StateId, CurrentHistory, *PropertyData.PropertyName.ToString());
                    VerifiedData->Data.Add(ii);
                    VerifiedData->PropertyName.Add(PropertyData.PropertyName);
                }
#endif
            }
        }

#if !ENABLE_GAME_MESSAGE_OBFUSCATION
        // 因为没seek，所以只能这么盖
        appBitsCpy(Writer.GetData(), StartNum, (uint8*)&DirtyCount, 0, sizeof(uint16) * 8);
#else
        Writer.Seek(StartNum);
        Writer << DirtyCount;
        FDataObfuscationUtil::ObfuscateWithRedundancy(TempObfuscation, TempSrc.GetData(), TempSrc.Num());
        *Params.Writer << TempObfuscation;
#endif

#if WITH_VERIFY_DATA
        UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("WriteData actor [%s] netguid: %d, stateid: %d, history: %d, dirtycount: %d, properties: {%s}"),
            *OwnerComponent->GetOwner()->GetName(), 
            UEngineExtActorShell::GetActorNetGuid(OwnerComponent->GetOwner()), 
            StateInfo->StateId,
            CurrentHistory,
            DirtyCount,
            *DirtyPropertyInfo);
#endif
    }
    else
    {
        check(Params.Reader);
#if !ENABLE_GAME_MESSAGE_OBFUSCATION        
        FBitReader& Reader = *Params.Reader;
#else
        static TArray<uint8> TempSrc, TempObfuscation;
        TempSrc.SetNumUninitialized(0, false);
        TempObfuscation.SetNumUninitialized(0, false);
        *Params.Reader << TempObfuscation;
        FDataObfuscationUtil::DeobfuscateWithRedundancy(TempSrc, TempObfuscation.GetData(), TempObfuscation.Num());
        FMemoryReader Reader(TempSrc, true);
#endif

#if WITH_VERIFY_DATA
        FString DirtyPropertyInfo;
        uint64 TempCurrentHistory, StateId = 0;
        TArray<uint16> DataNeedSendToVerify;
        Reader << StateId;
        Reader << TempCurrentHistory;
#endif

        uint16 DirtyCount = 0;
        Reader << DirtyCount;
        if (DirtyCount == 0)
        {
            // 到这里理论上必须有值
            return false;
        }

        uint32* DirtyPropertyIds = static_cast<uint32*>(FMemory_Alloca(sizeof(uint32)*DirtyCount));
        for (uint16 ii = 0; ii < DirtyCount; ++ii)
        {
            uint16 Index = 0;
            Reader << Index;

            if (Index < 0 || Index >= PropertyCount)
            {
                OwnerComponent->NotifyPropTypeMismatch();
                return false;
            }

            auto& PropertyData = GetProperty(Index);
            PropertyData.Serialize(Reader, true);
            DirtyPropertyIds[ii] = PropertyData.PropertyId;            

            if (Reader.IsError())
            {
                OwnerComponent->PrintAllPropertySize();
#if !ENABLE_GAME_MESSAGE_OBFUSCATION
                UE_LOG(ReplicatedCustomPropertyComponentLog, Fatal, TEXT("NetDeltaSerialize failed, property name: %s, id: %d, reader num: %d, pos: %d, buffersize: %d"),
                    *PropertyData.PropertyName.ToString(),
                    PropertyData.PropertyId,
                    Reader.GetNumBits(), Reader.GetPosBits(), Reader.GetBuffer().Num());
#else
                UE_LOG(ReplicatedCustomPropertyComponentLog, Fatal, TEXT("NetDeltaSerialize failed, property name: %s, id: %d"),
                    *PropertyData.PropertyName.ToString(),
                    PropertyData.PropertyId);
#endif
            }

#if WITH_VERIFY_DATA
            DirtyPropertyInfo += PropertyData.PropertyName.ToString();
            DirtyPropertyInfo += TEXT(", ");
            if (IndexNeedVerified.Contains(Index))
            {
                DataNeedSendToVerify.Add(Index);
                UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("ReadData actor [%s] netguid: %d, stateid: %d, history: %d, property: %s"),
                    *OwnerComponent->GetOwner()->GetName(), UEngineExtActorShell::GetActorNetGuid(OwnerComponent->GetOwner()),
                    StateId, TempCurrentHistory, *PropertyData.PropertyName.ToString());
            }
#endif
        }

        for (uint16 ii = 0; ii < DirtyCount; ++ii)
        {            
            OwnerComponent->OnRepProperty(DirtyPropertyIds[ii]);
        }

#if WITH_VERIFY_DATA
        UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("ReadData actor [%s] netguid: %d, stateid: %d, history: %d, dirtycount: %d, properties: {%s}"),
            *OwnerComponent->GetOwner()->GetName(),
            UEngineExtActorShell::GetActorNetGuid(OwnerComponent->GetOwner()),
            StateId,
            TempCurrentHistory,
            DirtyCount,
            *DirtyPropertyInfo);

        if (DataNeedSendToVerify.Num())
        {
            UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("SendVerifyClientData actor [%s] netguid: %d, stateid: %d, history: %d, property count: %d"),
                *OwnerComponent->GetOwner()->GetName(), UEngineExtActorShell::GetActorNetGuid(OwnerComponent->GetOwner()), 
                StateId, TempCurrentHistory, DataNeedSendToVerify.Num());
            OwnerComponent->SendVerifyClientData(*this, StateId, TempCurrentHistory, DataNeedSendToVerify);
        }
#endif
    }
    return true;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
UCustomReplicationComponent::UCustomReplicationComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , TempProto(nullptr)
    , bNeedPostRepNotify(false)
{
#if WITH_VERIFY_DATA
    PrimaryComponentTick.bCanEverTick = true;
#endif
}

#define VERIFY_PROPERTY_RETURN(PropertyId, ValueType) \
    auto Property = FindProperty(PropertyId); \
    if (!Property) \
    { \
        return false; \
    } \
    if (Property->Type != ValueType) \
    { \
        NotifyPropTypeMismatch(); \
        return false; \
    }

bool UCustomReplicationComponent::SetBool(int PropertyId, const bool& Value)
{
    VERIFY_PROPERTY_RETURN(PropertyId, ECustomReplicatedPropertyType::Bool);
    if (Property->BoolValue != Value)
    {
        Property->BoolValue = Value;
        Property->MarkDirty();
    }
    return true;
}

bool UCustomReplicationComponent::GetBool(int PropertyId, bool& Value)
{
    VERIFY_PROPERTY_RETURN(PropertyId, ECustomReplicatedPropertyType::Bool);
    Value = Property->BoolValue;
    return true;
}

bool UCustomReplicationComponent::SetInt(int PropertyId, const int& Value)
{
    VERIFY_PROPERTY_RETURN(PropertyId, ECustomReplicatedPropertyType::Int);
    if (Property->IntValue != Value)
    {
        Property->IntValue = Value;
        Property->MarkDirty();
    }
    return true;
}

bool UCustomReplicationComponent::GetInt(int PropertyId, int& Value)
{
    VERIFY_PROPERTY_RETURN(PropertyId, ECustomReplicatedPropertyType::Int);
    Value = Property->IntValue;
    return true;
}

bool UCustomReplicationComponent::SetFloat(int PropertyId, const float& Value)
{
    VERIFY_PROPERTY_RETURN(PropertyId, ECustomReplicatedPropertyType::Float);
    if (!FMath::IsNearlyEqual(Property->FloatValue, Value, 1.e-6f))
    {
        Property->FloatValue = Value;
        Property->MarkDirty();
    }
    return true;
}

bool UCustomReplicationComponent::GetFloat(int PropertyId, float& Value)
{
    VERIFY_PROPERTY_RETURN(PropertyId, ECustomReplicatedPropertyType::Float);
    Value = Property->FloatValue;
    return true;
}

bool UCustomReplicationComponent::SetProto(int PropertyId, const FString& MessageName, ULuaTableRef* TableRef)
{
    VERIFY_PROPERTY_RETURN(PropertyId, ECustomReplicatedPropertyType::Proto);
    check(Codec.IsValid());

    int OldSize = Property->ProtoValue->Num();
    uint8* OldValue = nullptr;
    if (OldSize > 0)
    {
        OldValue = (uint8*)FMemory_Alloca(OldSize);
        FMemory::Memcpy(OldValue, Property->ProtoValue->GetData(), OldSize);
    }
    
#if REPLICATION_PROTO_USE_MESSAGE_FRAME
    bool UseFrame = true;
#else
    bool UseFrame = false;
#endif

    if (TableRef != nullptr)
    {
        if (!FMessageLuaUtil::LuaTableToArrayData(Codec.Pin().Get(), MessageName, LUA_TABLE_REF_U2F(TableRef), nullptr, *Property->ProtoValue, UseFrame))
        {
            UE_LOG(ReplicatedCustomPropertyComponentLog, Error, TEXT("ReplicatedCustomPropertyComponentLog::SetProto failed, can not convert data %s."), *MessageName);
            return false;
        }
    }
    else
    {
        Property->ProtoValue->Empty(Property->ProtoValue->Max());
    }

    if (Property->ProtoValue->Num() != OldSize || (OldSize > 0 && FMemory::Memcmp(OldValue, Property->ProtoValue->GetData(), OldSize) != 0))
    {
        Property->MarkDirty();
    }
    return true;
}

bool UCustomReplicationComponent::GetProto(int PropertyId, const FString& MessageName, UProtobufMessageRef* &Out)
{
    Out = nullptr;
    VERIFY_PROPERTY_RETURN(PropertyId, ECustomReplicatedPropertyType::Proto);
    checkf(Property->PropertyName.ToString() == MessageName, TEXT("GetProto failed, input message: %s, propertyid: %d, finded property name: %s"),
        *MessageName, PropertyId, *Property->PropertyName.ToString());

    ClearTempProto();

    check(Codec.IsValid());
    const google::protobuf::Message* Message = nullptr;
    if (Property->ProtoValue->Num() == 0)
    {
        Message = Codec.Pin()->CreateMessage(TCHAR_TO_UTF8(*MessageName));
    }
    else
    {
#if REPLICATION_PROTO_USE_MESSAGE_FRAME
        Message = Codec.Pin()->Decode(Property->ProtoValue->GetData(), Property->ProtoValue->Num());
#else
        Message = Codec.Pin()->DecodeWithoutFrame(MessageName, Property->ProtoValue->GetData(), Property->ProtoValue->Num());
#endif
    }

    if (Message == nullptr)
    {
        UE_LOG(ReplicatedCustomPropertyComponentLog, Error, TEXT("ReplicatedCustomPropertyComponentLog::Decode failed, name: %s."), *MessageName);
        return false;
    }

    TempProto->Message = Message;
    Out = TempProto;
    return true;
}

#undef VERIFY_PROPERTY_RETURN

bool UCustomReplicationComponent::IsValidProperty(int PropertyId)
{
    return FindProperty(PropertyId) != nullptr;
}

void UCustomReplicationComponent::AddRepNotifyProperties(const TArray<int>& Properties)
{
    for (int PropertyId : Properties)
    {
        PostNotifyProperties.Add(PropertyId);
    }
}

void UCustomReplicationComponent::OnRegister()
{
    Super::OnRegister();

    if (HasAnyFlags(RF_ClassDefaultObject))
    {
        return;
    }

    auto GameCommon = UGameCommon::Get(this);
    if (!GameCommon || !GameCommon->GetRPCNetworkManager())
    {
        return;
    }

    if (TempProto)
    {
        // 初始化过了
        return;
    }

    auto* DefineInfo = GameCommon->GetRPCNetworkManager()->GetCustomReplicationDefineInfo(DefineInfoName);
    if (!DefineInfo)
    {
        return;
    }

    TempProto = NewObject<UProtobufMessageRef>(this, TEXT("TempProto"));
    Codec = GameCommon->GetRPCNetworkManager()->GetCodec();

    TArray<const FCustomReplicationPropertyDefine*> RepAll, RepSkipOwner, RepOwnerOnly, RepInitialOnly;
    RepAll.Reserve(DefineInfo->Num());
    RepSkipOwner.Reserve(DefineInfo->Num());
    RepOwnerOnly.Reserve(DefineInfo->Num());
    RepInitialOnly.Reserve(DefineInfo->Num());
    PropertyIdToData.Reserve(DefineInfo->Num());

    // 暂时只支持下面几种，有需求以后在加
    for (auto& Info : *DefineInfo)
    {
        switch (Info.RepType)
        {
        case ELifetimeCondition::COND_None:
            RepAll.Emplace(&Info);
            break;
        case ELifetimeCondition::COND_SkipOwner:
            RepSkipOwner.Emplace(&Info);
            break;
        case ELifetimeCondition::COND_OwnerOnly:
            RepOwnerOnly.Emplace(&Info);
            break;
        case ELifetimeCondition::COND_InitialOnly:
            RepInitialOnly.Emplace(&Info);
            break;
        default:
            NotifyPropTypeMismatch();
            return;
        }
    }

    BuildProperties(PropertyRepAll, RepAll);
    BuildProperties(PropertyRepSkipOwner, RepSkipOwner);
    BuildProperties(PropertyRepOwnerOnly, RepOwnerOnly);
    BuildProperties(PropertyRepInitialOnly, RepInitialOnly);
}

void UCustomReplicationComponent::GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME(UCustomReplicationComponent, PropertyRepAll);
    DOREPLIFETIME_CONDITION(UCustomReplicationComponent, PropertyRepSkipOwner, COND_SkipOwner);
    DOREPLIFETIME_CONDITION(UCustomReplicationComponent, PropertyRepOwnerOnly, COND_OwnerOnly);
    DOREPLIFETIME_CONDITION(UCustomReplicationComponent, PropertyRepInitialOnly, COND_InitialOnly);
}

void UCustomReplicationComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    OnEndPlay.ExecuteIfBound(GetOwner());
    ClearTempProto();

    Super::EndPlay(EndPlayReason);
}

void UCustomReplicationComponent::PostRepNotifies()
{
    Super::PostRepNotifies();

    if (bNeedPostRepNotify)
    {
        bNeedPostRepNotify = false;
        OnPostRepNotify.ExecuteIfBound();
    }
}

void UCustomReplicationComponent::ClearTempProto()
{
    if (TempProto && Codec.IsValid() && TempProto->Message)
    {
        Codec.Pin()->DestroyMessage(TempProto->Message);
        TempProto->Message = nullptr;
    }
}

FReplicatedPropertyData* UCustomReplicationComponent::FindProperty(int PropertyId)
{
    auto* Ret = PropertyIdToData.Find(PropertyId);
    return Ret ? *Ret : nullptr;
}

void UCustomReplicationComponent::OnRepProperty(int PropertyId)
{
    if (PostNotifyProperties.Contains(PropertyId))
    {
        bNeedPostRepNotify = true;
    }

    OnValueChanged.ExecuteIfBound(PropertyId);
}

void UCustomReplicationComponent::NotifyPropTypeMismatch()
{
    if (auto GameCommon = UGameCommon::Get(this))
    {
        auto GameDelegateManager = GameCommon->GetGameDelegateManager();
        if (GameDelegateManager && GameDelegateManager->GameMisc)
        {
            GameDelegateManager->GameMisc->OnRepPropTypeMismatch.ExecuteIfBound();
        }
    }
}


void UCustomReplicationComponent::BuildProperties(FReplicatedCustomPropertyArray& PropertyArray,
    const TArray<const FCustomReplicationPropertyDefine*>& Defines)
{
    PropertyArray.Init(this, Defines);

    for (uint32 ii = 0; ii < PropertyArray.PropertyCount; ++ii)
    {
        auto& PropertyData = PropertyArray.GetProperty(ii);
        check(PropertyIdToData.Find(PropertyData.PropertyId) == nullptr);
        PropertyIdToData.Add(PropertyData.PropertyId, &PropertyData);
    }
}

void UCustomReplicationComponent::PrintAllPropertySize()
{
    UE_LOG(ReplicatedCustomPropertyComponentLog, Error, TEXT("OwnerName: %s, uniqueid: %d"), *GetOwner()->GetName(), GetOwner()->GetUniqueID());

    auto PrintPropertySize = [&](const TCHAR* Desc, FReplicatedCustomPropertyArray& PropertyArray) {
        int TotalSize = 0;
        for (uint32 ii = 0; ii < PropertyArray.PropertyCount; ii++)
        {
            auto& PropertyData = PropertyArray.GetProperty(ii);

            int PropertySize = 0;
            FString PropertyType;
            switch (PropertyData.Type)
            {
            case ECustomReplicatedPropertyType::Bool:
            {
                PropertyType = TEXT("Bool");
                PropertySize = sizeof(PropertyData.BoolValue);
                break;
            }
            case ECustomReplicatedPropertyType::Int:
            {
                PropertyType = TEXT("Int");
                PropertySize = sizeof(PropertyData.IntValue);
                break;
            }
            case ECustomReplicatedPropertyType::Float:
            {
                PropertyType = TEXT("Float");
                PropertySize = sizeof(PropertyData.FloatValue);
                break;
            }
            case ECustomReplicatedPropertyType::Proto:
            {
                PropertyType = TEXT("Proto");
                PropertySize = PropertyData.ProtoValue->Num();
                break;
            }
            default:
                break;
            }

            UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("Property name: %s, id: %d, type: %s, size: %d"),
                *PropertyData.PropertyName.ToString(), PropertyData.PropertyId, *PropertyType, PropertySize);
            TotalSize += PropertySize;
        }

        UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("PropertyArray: %s, property count: %d, total size: %d"),
            Desc, PropertyArray.PropertyCount, TotalSize);
    };

    PrintPropertySize(TEXT("PropertyRepAll"), PropertyRepAll);
    PrintPropertySize(TEXT("PropertyRepSkipOwner"), PropertyRepSkipOwner);
    PrintPropertySize(TEXT("PropertyRepOwnerOnly"), PropertyRepOwnerOnly);
    PrintPropertySize(TEXT("PropertyRepInitialOnly"), PropertyRepInitialOnly);
}

void UCustomReplicationComponent::SetPropertyToBeChecked(int PropertyId)
{
#if WITH_VERIFY_DATA
    auto* CheckedProperty = FindProperty(PropertyId);
    if (!CheckedProperty)
    {
        return;
    }

    auto& DataArray = *CheckedProperty->OwnerArray;
    for (int ii=0; ii<DataArray.GetPropertyCount(); ii++)
    {
        auto& Data = DataArray.GetProperty(ii);
        if (CheckedProperty == &Data)
        {
            DataArray.IndexNeedVerified.Add(ii);
            break;
        }
    }
#endif
}

//////////////////////////////////////////////////////////////////////////
// RPCs
//void UCustomReplicationComponent::SendToServer(ULuaCustomDataWrapper* Wrapper)
//{
//    check(Wrapper);
//    ServerReceivedData(Wrapper->RawData);
//}
//
//void UCustomReplicationComponent::SendToClient(ULuaCustomDataWrapper* Wrapper)
//{
//    check(Wrapper);
//    ClientReceivedData(Wrapper->RawData);
//}
//
//void UCustomReplicationComponent::Multicast(ULuaCustomDataWrapper* Wrapper)
//{
//    check(Wrapper);
//    ClientReceivedMulticastData(Wrapper->RawData);
//}
//
//void UCustomReplicationComponent::ReliableMulticast(ULuaCustomDataWrapper* Wrapper)
//{
//    check(Wrapper);
//    ClientReceivedReliableMulticastData(Wrapper->RawData);
//}
//
//bool UCustomReplicationComponent::ServerReceivedData_Validate(const TArray<uint8>& Data)
//{
//    return Data.Num() > 0;
//}
//
//void UCustomReplicationComponent::ServerReceivedData_Implementation(const TArray<uint8>& Data)
//{
//    OnReceivedRawData(Data);
//}
//
//void UCustomReplicationComponent::ClientReceivedData_Implementation(const TArray<uint8>& Data)
//{
//    OnReceivedRawData(Data);
//}
//
//void UCustomReplicationComponent::ClientReceivedMulticastData_Implementation(const TArray<uint8>& Data)
//{
//    OnReceivedRawData(Data);
//}
//
//void UCustomReplicationComponent::ClientReceivedReliableMulticastData_Implementation(const TArray<uint8>& Data)
//{
//    OnReceivedRawData(Data);
//}
//
//void UCustomReplicationComponent::OnReceivedRawData(const TArray<uint8>& Data)
//{
//    if (OnRecvData.IsBound())
//    {
//        auto Wrapper = ULuaCustomDataWrapper::Get();
//        Wrapper->RawData = Data;
//        OnRecvData.ExecuteIfBound(Wrapper);
//    }
//}

#if WITH_VERIFY_DATA
void UCustomReplicationComponent::TickComponent(float DeltaSeconds, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
    Super::TickComponent(DeltaSeconds, TickType, ThisTickFunction);

    PropertyRepAll.Tick();
    PropertyRepSkipOwner.Tick();
    PropertyRepOwnerOnly.Tick();
    PropertyRepInitialOnly.Tick();
}

#include "ReplicatedProtoCallComponent.h"
void UCustomReplicationComponent::SendVerifyClientData(const FReplicatedCustomPropertyArray& DataArray, uint64 StateId, uint64 History, const TArray<uint16>& Data)
{
    ELifetimeCondition RepType = ELifetimeCondition::COND_None;
    auto* ArrayPtr = &DataArray;
    if (ArrayPtr == &PropertyRepAll)
    {
        RepType = ELifetimeCondition::COND_None;
    }
    else if (ArrayPtr == &PropertyRepSkipOwner)
    {
        RepType = ELifetimeCondition::COND_SkipOwner;
    }
    else if (ArrayPtr == &PropertyRepOwnerOnly)
    {
        RepType = ELifetimeCondition::COND_OwnerOnly;
    }
    else if (ArrayPtr == &PropertyRepInitialOnly)
    {
        RepType = ELifetimeCondition::COND_InitialOnly;
    }
    else
    {
        check(false);
    }

    auto Sender = UGameplayStatics::GetPlayerController(this, 0);
    auto Component = Sender->FindComponentByClass<UReplicatedProtoCallComponent>();
    Component->VerifyClientReplicationProperty(GetOwner(), UEngineExtActorShell::GetActorNetGuid(GetOwner()), (int)RepType, StateId, History, Data);
}

void UCustomReplicationComponent::VerifyClientData(uint32 NetGuid, int RepType, uint64 StateId, uint64 History, const TArray<uint16>& Data)
{
    FReplicatedCustomPropertyArray* DataArray = nullptr;
    switch ((ELifetimeCondition)RepType)
    {
    case ELifetimeCondition::COND_None:
        DataArray = &PropertyRepAll;
        break;
    case ELifetimeCondition::COND_SkipOwner:
        DataArray = &PropertyRepSkipOwner;
        break;
    case ELifetimeCondition::COND_OwnerOnly:
        DataArray = &PropertyRepOwnerOnly;
        break;
    case ELifetimeCondition::COND_InitialOnly:
        DataArray = &PropertyRepInitialOnly;
        break;
    default:
        check(false);
        break;
    }

    check(NetGuid == UEngineExtActorShell::GetActorNetGuid(GetOwner()));
    DataArray->VerifyClientData(StateId, History, Data);
}

void FReplicatedCustomPropertyArray::VerifyClientData(uint64 StateId, uint64 ClientHistory, const TArray<uint16>& ClientData)
{
    check(PendingVerifiedData.Num() > 0);
    auto* SavedData = PendingVerifiedData.Find(StateId);
    check(SavedData);

    for (int ii = 0; ii < SavedData->Num(); ii++)
    {
        FVerifyData& ServerData = (*SavedData)[ii];
        if (ServerData.History == ClientHistory)
        {
            FString Temp;
            for(auto& TempName : ServerData.PropertyName)
            {
                Temp += TempName.ToString();
                Temp += TEXT(",");
            }
            UE_LOG(ReplicatedCustomPropertyComponentLog, Log, TEXT("VerifyClientData actor [%s] netguid: %d, stateid: %d, index: %d, history: %d, property [%s], count: %d"),
                *OwnerComponent->GetOwner()->GetName(), UEngineExtActorShell::GetActorNetGuid(OwnerComponent->GetOwner()),
                StateId, ii, ServerData.History, *Temp, ServerData.Data.Num());

            checkf(ServerData.History == ClientHistory, TEXT("CheckHistory failed, server: %d, client: %d"), ServerData.History, ClientHistory);
            checkf(ServerData.Data == ClientData, TEXT("CheckProperty failed, server: %d, client: %d"), ServerData.Data.Num(), ClientData.Num());

            SavedData->RemoveAt(ii);
            return;
        }
    }
}

void FReplicatedCustomPropertyArray::Tick()
{
    if (PendingVerifiedData.Num() == 0)
    {
        return;
    }

    double MAX_TIME = 5.0f;
    double Now = FPlatformTime::Seconds();
    for (auto Iter = PendingVerifiedData.CreateIterator(); Iter; ++Iter)
    {
        auto& DataArray = Iter->Value;
        for(int ii=0; ii<DataArray.Num();)
        {
            auto& Data = DataArray[ii];
            if (Now - Data.Time >= MAX_TIME)
            {
                FString Temp;
                for (auto& TempName : Data.PropertyName)
                {
                    Temp += TempName.ToString();
                    Temp += TEXT(",");
                }
                UE_LOG(ReplicatedCustomPropertyComponentLog, Error, TEXT("Timeout actor [%s] netguid: %d, stateid: %d, history: %d, property [%s], count: %d"),
                    *OwnerComponent->GetOwner()->GetName(), UEngineExtActorShell::GetActorNetGuid(OwnerComponent->GetOwner()),
                    Iter->Key, Data.History, *Temp, Data.Data.Num());
                DataArray.RemoveAt(ii);
            }
            else
            {
                ++ii;
            }
        }
    }
}
#endif