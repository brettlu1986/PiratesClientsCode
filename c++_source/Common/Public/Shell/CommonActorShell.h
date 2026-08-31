// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "ProtobufCodec.h"
#include "CommonActorShell.generated.h"


class ULuaTableRef;
class UProtobufMessageRef;
class FKMScriptActorSpawnContext;


UCLASS()
class COMMON_API UCommonActorShell : public UObject
{
    GENERATED_UCLASS_BODY()

public:

    void Init(FKMScriptActorSpawnContext* Context, TWeakPtr<ProtobufCodec> InCodec);
    void Uninit();

    UFUNCTION()
    void SetActorSpawnInitData(const FString& ProtoName, ULuaTableRef* TableRef, int InstanceId, bool BeginPlayManually);

    UFUNCTION()
    void ResetActorSpawnInitData();

    UFUNCTION()
    UProtobufMessageRef* GetActorSpawnInitData(AActor* Actor);

    UFUNCTION()
    void SetControllerReplicatedInitData(AKMPlayerController* Controller, 
        const FString& ProtoName, ULuaTableRef* TableRef, int LogicInstanceId);

    UFUNCTION()
    bool DefineReplicatedProperty(AActor* Actor, const FName& ProtoName);

    UFUNCTION()
    bool UndefineReplicatedProperty(AActor* Actor, const FName& ProtoName);

    UFUNCTION()
    bool SetReplicatedPropertyValue(AActor* Actor, const FName& ProtoName, class ULuaTableRef* TableRef);

    UFUNCTION()
    void ReplicateActorPropertyNow(AActor* Actor);

    UFUNCTION()
    void ReplicateActorPropertyNowByType(AActor* Actor, bool bMulticast);

    UFUNCTION()
    void MarkAllActorPropertyReplicate(AActor* Actor);

    UFUNCTION()
    void UndefineAllReplicatedProperties(AActor* Actor);

    UFUNCTION()
    const FString& FindAvatarPartData(int nPartId, int nDataIndex) const;

public:
    UProtobufMessageRef* RawDataToMessageRef(const TArray<uint8>& RawData);

private:

    UPROPERTY()
    UProtobufMessageRef* MsgRef;

private:

    FKMScriptActorSpawnContext* ActorSpawnContext;
    TWeakPtr<ProtobufCodec> Codec;
};
