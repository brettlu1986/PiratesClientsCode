// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Game/Misc/GameHitInfo.h"
#include "KMPawn.generated.h"

class UDamageType;

UCLASS()
class ENGINEEXT_API AKMPawn : public APawn
{
	GENERATED_UCLASS_BODY()

public:
	UFUNCTION(BlueprintImplementableEvent, Category="KMPawn")
	void OnPostPossessed();

public:
    const TArray<uint8>& GetInitProtoData() const { return InitProtoData; }

    UFUNCTION(BlueprintPure, Category = "KMPawn")
    const int GetLogicInstanceId() const { return LogicInstanceId; }

    UFUNCTION()
    void BeginPlayManually();

    void PreBeginPlay();
    void OrignalBeginPlay();
    void PostBeginPlay();
	inline const bool HasBeginPlayCompletely() const { return bHasBeginPlayCompletely; }
	virtual float TakeDamage(float DamageAmount, struct FDamageEvent const& DamageEvent, class AController* EventInstigator, AActor* DamageCauser) override;

protected:
    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    virtual void OnSerializeNewActor(FOutBunch& OutBunch) override;
	virtual void OnActorChannelOpen(FInBunch& InBunch, UNetConnection* Connection) override;
    virtual void GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const override;
    virtual void PreReplication(IRepChangedPropertyTracker & ChangedPropertyTracker) override;
    virtual void Destroyed() override;

public:
	DECLARE_DYNAMIC_MULTICAST_DELEGATE_FiveParams(FTakeCommonDamageSignature, AActor*, DamagedActor, float, Damage, const UDamageType*, DamageType, class AController*, InstigatedBy, AActor*, DamageCauser);
	UPROPERTY(BlueprintAssignable, Category = "Game|Damage")
    FTakeCommonDamageSignature OnTakeCommonDamageEx;

	DECLARE_DYNAMIC_MULTICAST_DELEGATE_SixParams(FTakePointDamageExSignature, AActor*, DamagedActor, float, Damage, const UDamageType*, DamageType, class AController*, InstigatedBy, AActor*, DamageCauser, const FHitResult&, HitInfo);
	UPROPERTY(BlueprintAssignable, Category = "Game|Damage")
	FTakePointDamageExSignature OnTakePointDamageEx;

	DECLARE_DYNAMIC_MULTICAST_DELEGATE_SixParams(FTakeRadialDamageExSignature, AActor*, DamagedActor, float, Damage, const UDamageType*, DamageType, class AController*, InstigatedBy, AActor*, DamageCauser, const FHitResult&, HitInfo);
	UPROPERTY(BlueprintAssignable, Category = "Game|Damage")
	FTakeRadialDamageExSignature OnTakeRadialDamageEx;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Game|Damage")
    TEnumAsByte<ECollisionChannel> DamagedChannel;

    DECLARE_DYNAMIC_MULTICAST_DELEGATE_FiveParams(FTakeHitInfo, AActor*, DamagedActor, float, Damage, AActor*, Insigator, AActor*, DamageCauser, UClass*, DamageTypeClass);
    UPROPERTY(BlueprintAssignable, Category = "Game|Damage")
    FTakeHitInfo OnRepHitInfo;

protected:
    UPROPERTY(BlueprintReadOnly, Transient, Category = "Game|Damage", ReplicatedUsing = OnRep_HitInfo)
    FGameHitInfo HitInfo;

    UFUNCTION()
    void OnRep_HitInfo();

private:
    TArray<uint8> InitProtoData;
    int LogicInstanceId;
    bool IsBeginPlayManually;
    bool bHasBeginPlayCompletely;
    float LastTakeHitTimeTimeout;
    bool HasActorChannelOpened;  // 防止重复触发delegate
};
