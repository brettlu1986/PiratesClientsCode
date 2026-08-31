// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Engine/NetSerialization.h"
#include "CustomReplicationComponent.generated.h"

#define WITH_VERIFY_DATA 0

class UProtobufMessageRef;
class ULuaTableRef;
class UCustomReplicationComponent;
struct FReplicatedCustomPropertyArray;
class ProtobufCodec;
class ULuaCustomDataWrapper;

UENUM()
enum class ECustomReplicatedPropertyType : uint8
{
    Invalid = 0,
    Bool,
    Int,
    Float,
    Proto,
    
    End,
};

//////////////////////////////////////////////////////////////////////////
USTRUCT()
struct COMMON_API FCustomReplicationPropertyDefine
{
    GENERATED_USTRUCT_BODY()

    UPROPERTY()
    FName PropertyName;

    UPROPERTY()
    ECustomReplicatedPropertyType PropertyType;

    UPROPERTY()
    TEnumAsByte<ELifetimeCondition> RepType;

    UPROPERTY()
    int32 PropertyId;

    //UPROPERTY()
    //bool IsArray;

    FCustomReplicationPropertyDefine()
        : PropertyType(ECustomReplicatedPropertyType::Bool)
        , RepType(ELifetimeCondition::COND_None)
        , PropertyId(-1)
        //, IsArray(false)
    {
    }
};

struct FCustomReplicationComponentInfo
{
    TArray<FCustomReplicationPropertyDefine> Defines;
    const uint32 GetCRC() const;
};

//////////////////////////////////////////////////////////////////////////
struct FReplicatedPropertyData
{
    FReplicatedPropertyData(int InPropertyId, const FName& Name, FReplicatedCustomPropertyArray* InOwnerArray, bool InValue)
        : PropertyId(InPropertyId)
        , Type(ECustomReplicatedPropertyType::Bool)
        , History(INDEX_NONE)        
        , OwnerArray(InOwnerArray)
        , PropertyName(Name)
        , BoolValue(InValue)
    {}

    FReplicatedPropertyData(int InPropertyId, const FName& Name, FReplicatedCustomPropertyArray* InOwnerArray, int InValue)
        : PropertyId(InPropertyId)        
        , Type(ECustomReplicatedPropertyType::Int)
        , History(INDEX_NONE)
        , OwnerArray(InOwnerArray)
        , PropertyName(Name)
        , IntValue(InValue)
    {}

    FReplicatedPropertyData(int InPropertyId, const FName& Name, FReplicatedCustomPropertyArray* InOwnerArray, float InValue)
        : PropertyId(InPropertyId)        
        , Type(ECustomReplicatedPropertyType::Float)
        , History(INDEX_NONE)
        , OwnerArray(InOwnerArray)
        , PropertyName(Name)
        , FloatValue(InValue)
    {}

    FReplicatedPropertyData(int InPropertyId, const FName& Name, FReplicatedCustomPropertyArray* InOwnerArray, TArray<uint8>& InValue)
        : PropertyId(InPropertyId)        
        , Type(ECustomReplicatedPropertyType::Proto)
        , History(INDEX_NONE)
        , OwnerArray(InOwnerArray)
        , PropertyName(Name)
        , ProtoValue(&InValue)
    {}

    bool Serialize(FArchive& Archive, bool Read);
    void MarkDirty();

    uint32 PropertyId;    
    ECustomReplicatedPropertyType Type;
    uint64 History;
    FReplicatedCustomPropertyArray* OwnerArray;
    FName PropertyName;

    union
    {
        int64 IntValue;
        bool BoolValue;
        float FloatValue;
        TArray<uint8>* ProtoValue;
    };
};

//////////////////////////////////////////////////////////////////////////
USTRUCT()
struct FReplicatedCustomPropertyArray
{
    GENERATED_USTRUCT_BODY()

    FReplicatedCustomPropertyArray()
        : OwnerComponent(nullptr)
        , AllRawData(nullptr)
        , CurrentHistory(0)
        , PropertyCount(0)
        , ProtoCount(0)        
    {}

    ~FReplicatedCustomPropertyArray()
    {
        if (AllRawData)
        {
            FReplicatedPropertyData* AllPropertyData = (FReplicatedPropertyData*)AllRawData;
            for (uint32 ii = 0; ii < PropertyCount; ++ii)
            {
                (AllPropertyData + ii)->~FReplicatedPropertyData();
            }

            TArray<uint8>* AllProtoData = (TArray<uint8>*)(AllRawData + PropertyCount * sizeof(FReplicatedPropertyData));
            for (uint32 ii = 0; ii < ProtoCount; ++ii)
            {
                (AllProtoData + ii)->~TArray<uint8>();
            }

            FMemory::Free(AllRawData);
            AllRawData = nullptr;
        }    
    }  
    
    void Init(UCustomReplicationComponent* InOwnerComponent, const TArray<const FCustomReplicationPropertyDefine*>& Defines);    
    bool NetDeltaSerialize(FNetDeltaSerializeInfo & DeltaParms);

    FORCEINLINE FReplicatedPropertyData& GetProperty(uint32 Index)
    {
        check(Index >= 0 && Index < PropertyCount);
        return ((FReplicatedPropertyData*)AllRawData)[Index];
    }
    FORCEINLINE const int GetPropertyCount() const
    {
        return PropertyCount;
    }
    FORCEINLINE void MarkDataDirty(FReplicatedPropertyData* Data)
    {
        check(Data);
        Data->History = ++CurrentHistory;
    }

    UCustomReplicationComponent* OwnerComponent;
    uint8* AllRawData;
    uint64 CurrentHistory;
    uint32 PropertyCount;
    uint32 ProtoCount;

#if WITH_VERIFY_DATA
    struct FVerifyData
    {
        double Time;
        uint64 History;
        TArray<uint16> Data;
        TArray<FName> PropertyName;
        FVerifyData(uint64 h)
            : History(h)
        {
            Time = FPlatformTime::Seconds();
        }
    };

    typedef TInlineAllocator<4> TTempStackInlineAllocator;
    TSet<int, DefaultKeyFuncs<int>, TSetAllocator<TSparseArrayAllocator<TTempStackInlineAllocator, TTempStackInlineAllocator> >> IndexNeedVerified;
    TMap<uint64, TArray<FVerifyData> > PendingVerifiedData;
    void VerifyClientData(uint64 StateId, uint64 ClientHistory, const TArray<uint16>& ClientData);
    void Tick();    
#endif
};

//////////////////////////////////////////////////////////////////////////
template<>
struct TStructOpsTypeTraits< FReplicatedCustomPropertyArray > : public TStructOpsTypeTraitsBase2< FReplicatedCustomPropertyArray >
{
    enum
    {
        WithNetDeltaSerializer = true,

        // WithCopy必须为false，防止拷贝struct
        // 虚幻在replayout初始化时会拷贝一份struct数据以备后面比较用，然后在ActorChannelClose时析构这个struct，
        // 如果不关掉WithCopy，那么在拷贝时FReplicatedCustomPropertyArray中的AllRawData也会被拷贝，但只考的是指针（默认构造拷贝）
        // 所以在ActorChannelClose析构这个备用的struct时，也会把allrawdata删掉，这会component中引用的struct里的指针就非法了
        // 然后在GC时component析构，在析构真正的struct时就挂了
        WithCopy = false,
    };
};

//////////////////////////////////////////////////////////////////////////
UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UCustomReplicationComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
    // Properties
    UFUNCTION()
    bool SetBool(int PropertyId, const bool& Value);

    UFUNCTION()
    bool GetBool(int PropertyId, bool& Value);

    UFUNCTION()
    bool SetInt(int PropertyId, const int& Value);

    UFUNCTION()
    bool GetInt(int PropertyId, int& Value);

    UFUNCTION()
    bool SetFloat(int PropertyId, const float& Value);

    UFUNCTION()
    bool GetFloat(int PropertyId, float& Value);

    UFUNCTION()
    bool SetProto(int PropertyId, const FString& MessageName, ULuaTableRef* TableRef);

    UFUNCTION()
    bool GetProto(int PropertyId, const FString& MessageName, UProtobufMessageRef* &Out);

    UFUNCTION()
    bool IsValidProperty(int PropertyId);

    UFUNCTION()
    void AddRepNotifyProperties(const TArray<int>& Properties);

    UFUNCTION()
    void PrintAllPropertySize();

    UFUNCTION()
    void SetPropertyToBeChecked(int PropertyId);

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

    //////////////////////////////////////////////////////////////////////////
private:
    virtual void OnRegister() override;
    virtual void GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    virtual void PostRepNotifies() override;

    friend FReplicatedCustomPropertyArray;
    void ClearTempProto();
    FReplicatedPropertyData* FindProperty(int PropertyId);
    void OnRepProperty(int PropertyId);
    void NotifyPropTypeMismatch();
    void BuildProperties(FReplicatedCustomPropertyArray& PropertyArray, 
        const TArray<const FCustomReplicationPropertyDefine*>& Defines);

public:
    // lua里得定义对应这个名字的FCustomReplicationComponentInfo
    UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
    FName DefineInfoName;

private:
    UPROPERTY(transient, Replicated)
    FReplicatedCustomPropertyArray PropertyRepAll;

    UPROPERTY(transient, Replicated)
    FReplicatedCustomPropertyArray PropertyRepSkipOwner;

    UPROPERTY(transient, Replicated)
	FReplicatedCustomPropertyArray PropertyRepOwnerOnly;

	UPROPERTY(transient, Replicated)
	FReplicatedCustomPropertyArray PropertyRepInitialOnly;

    UPROPERTY(transient)
    UProtobufMessageRef* TempProto;
    
private:
    TMap<int, FReplicatedPropertyData*> PropertyIdToData;
    TWeakPtr<ProtobufCodec> Codec;
    bool bNeedPostRepNotify;
    TSet<int> PostNotifyProperties;

//////////////////////////////////////////////////////////////////////////
// RPCs
//public:
//    // 这几个带lua参数的放这里不太好，其实应该拿出去，但为了省事就先扔这吧
//    UFUNCTION()
//    void SendToServer(ULuaCustomDataWrapper* Wrapper);
//
//    UFUNCTION()
//    void SendToClient(ULuaCustomDataWrapper* Wrapper);
//
//    UFUNCTION()
//    void Multicast(ULuaCustomDataWrapper* Wrapper);
//
//    UFUNCTION()
//    void ReliableMulticast(ULuaCustomDataWrapper* Wrapper);
//
//private:
//    // 如果外面有需求在开出去
//    UFUNCTION(Server, Reliable, WithValidation)
//    void ServerReceivedData(const TArray<uint8>& Data);
//
//    UFUNCTION(Client, Reliable)
//    void ClientReceivedData(const TArray<uint8>& Data);
//
//    UFUNCTION(NetMulticast, Unreliable)
//    void ClientReceivedMulticastData(const TArray<uint8>& Data);
//
//    UFUNCTION(NetMulticast, Reliable)
//    void ClientReceivedReliableMulticastData(const TArray<uint8>& Data);
//
//    void OnReceivedRawData(const TArray<uint8>& Data);

#if WITH_VERIFY_DATA
public:
    virtual void TickComponent(float DeltaSeconds, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
    void SendVerifyClientData(const FReplicatedCustomPropertyArray& DataArray, uint64 StateId, uint64 History, const TArray<uint16>& Data);
    void VerifyClientData(uint32 NetGuid, int RepType, uint64 StateId, uint64 History, const TArray<uint16>& Data);
#endif
};
