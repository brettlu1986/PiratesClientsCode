#pragma once

// TODO:动态生成array在弱网rep时有几率数据错误，暂时没空查，所以先用临时解决办法绕过去，有空再说
// 开了struct 以及UProperty的ifdef UHT会报错，tnnd，不用这宏的话记得把头文件里相关的代码注了
#define USE_TEMP_PROTO_SOLUTION
#ifdef USE_TEMP_PROTO_SOLUTION
#include "Engine/NetSerialization.h"
#endif

#include "DynamicReplicationComponent.generated.h"


class UDynamicReplicationComponent;
class UProtobufMessageRef;
class ULuaTableRef;
class ProtobufCodec;
struct FProtoPropertyArray;

UENUM()
enum class EDynamicReplicationPropertyType : uint8
{
    Bool = 0,
    Int,
    Float,
    String,
    Proto,

    End,
};

USTRUCT()
struct FDynamicReplicationPropertyDefine
{
    GENERATED_USTRUCT_BODY()

    UPROPERTY()
    FName PropertyName;

    UPROPERTY()
    EDynamicReplicationPropertyType PropertyType;

    UPROPERTY()
    TEnumAsByte<ELifetimeCondition> RepType;

    UPROPERTY()
    int PropertyId;

    //UPROPERTY()
    //bool IsArray;

    FDynamicReplicationPropertyDefine()
        : PropertyType(EDynamicReplicationPropertyType::Bool)
        , RepType(ELifetimeCondition::COND_None)
        , PropertyId(-1)
        //, IsArray(false)
    {
    }
};


//////////////////////////////////////////////////////////////////////////
// 开了ifdef UHT会报错，tnnd，不用这宏的话记得把头文件里相关的代码注了
//#ifdef USE_TEMP_PROTO_SOLUTION

USTRUCT()
struct FProtoPropertyItem : public FFastArraySerializerItem
{
    GENERATED_USTRUCT_BODY()

    FProtoPropertyItem()
        : FFastArraySerializerItem()
        , PropertyId(-1)
    {}

    int32 PropertyId;

    UPROPERTY()
    TArray<uint8> RawData;

    void PreReplicatedRemove(const FProtoPropertyArray& InArraySerializer);
    void PostReplicatedAdd(const FProtoPropertyArray& InArraySerializer);
    void PostReplicatedChange(const FProtoPropertyArray& InArraySerializer);
    void OnChanged(const FProtoPropertyArray& InArraySerializer, bool Initial);
};

//////////////////////////////////////////////////////////////////////////
USTRUCT()
struct FProtoPropertyArray : public FFastArraySerializer
{
    GENERATED_USTRUCT_BODY()

    FProtoPropertyArray()
        : OwnerComponent(nullptr)
    {}

    UPROPERTY()
    TArray<FProtoPropertyItem>	Items;

    UDynamicReplicationComponent* OwnerComponent;

    bool NetDeltaSerialize(FNetDeltaSerializeInfo & DeltaParms)
    {
        return FFastArraySerializer::FastArrayDeltaSerialize<FProtoPropertyItem, FProtoPropertyArray>(Items, DeltaParms, *this);
    }
};

//////////////////////////////////////////////////////////////////////////
template<>
struct TStructOpsTypeTraits< FProtoPropertyArray > : public TStructOpsTypeTraitsBase2< FProtoPropertyArray >
{
    enum
    {
        WithNetDeltaSerializer = true,
    };
};

//#endif

//////////////////////////////////////////////////////////////////////////
UCLASS()
class COMMON_API UDynamicReplicationGeneratedClass : public UBlueprintGeneratedClass
{
    GENERATED_BODY()

public:
    UFUNCTION()
    static UBlueprintGeneratedClass* Generate(const FString& ClassName, const TArray<FDynamicReplicationPropertyDefine>& Defines);

    UFUNCTION()
    static void SetPendingDestroy(UClass* Class);

private:
    static UFunction* CreateRepFunction(UDynamicReplicationGeneratedClass* Class, const FDynamicReplicationPropertyDefine& Info);
    static FProperty* CreateRepProperty(UDynamicReplicationGeneratedClass* Class, const FDynamicReplicationPropertyDefine& Info);
    static void OnRepNotify(UObject* Context, FFrame& Stack, RESULT_DECL);
    static bool CheckSameClass(UDynamicReplicationGeneratedClass* Class, const TArray<FDynamicReplicationPropertyDefine>& Defines);

private:
    friend UDynamicReplicationComponent;
    TMap<UFunction*, int> FunctionToIds;
    TMap<int, FProperty*> IdToProperties;

#ifdef USE_TEMP_PROTO_SOLUTION
    int ProtoItemIndex;
    TMap<int, int> ProtoItemIndexToPropertyId;
    TMap<int, int> PropertyIdToProtoItemIndex;
    TMap<int, ELifetimeCondition> PropertyIdToRepType;
    TMap<int, FName> PropertyIdToPropertyName;
    friend struct FProtoPropertyItem;
#endif
};

//////////////////////////////////////////////////////////////////////////
UCLASS()
class COMMON_API UDynamicReplicationComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
    void ProcessValueChanged(int PropertyId);
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason);

    UFUNCTION()
    bool SetProto(int PropertyId, const FString& MessageName, ULuaTableRef* TableRef);

    UFUNCTION()
    bool GetProto(int PropertyId, const FString& MessageName, UProtobufMessageRef* &Out);

    UFUNCTION()
    void AddRepNotifyProperties(const TArray<int>& Properties);

    UFUNCTION()
    bool IsProtoPropetyReplicated(int PropertyId);

public:
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnValueChanged, int, PropertyId);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnEndPlay, AActor*, Actor);
    DECLARE_DYNAMIC_DELEGATE(FOnPostRepNotify);

    UPROPERTY()
    FOnValueChanged OnValueChanged;

    UPROPERTY()
    FOnEndPlay OnEndPlay;

    UPROPERTY()
    FOnPostRepNotify OnPostRepNotify;

protected:
    virtual void PostRepNotifies() override;

private:
    FArrayProperty* FindArrayProperty(int PropertyId);
    void ClearTempProto();

private:
    UPROPERTY()
    UProtobufMessageRef* TempProto;

    TWeakPtr<ProtobufCodec> Codec;
    bool bNeedPostRepNotify;
    TSet<int> PostNotifyProperties;

//#ifdef USE_TEMP_PROTO_SOLUTION
    // TODO：临时先用这个解决弱网Proto同步时数据不对的问题，有空时在查
public:
    virtual void GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const override;
    int FindProtoPropertyId(int ItemIndex);

private:
    UPROPERTY(Replicated)
    FProtoPropertyArray ProtoProperties;
//#endif
};