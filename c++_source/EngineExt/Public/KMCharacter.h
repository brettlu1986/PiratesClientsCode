// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GlobalDefinition.h"
#include "Game/Misc/GameHitInfo.h"
#include "GameFramework/Character.h"
#include "KMCharacter.generated.h"


UCLASS()
class ENGINEEXT_API AKMCharacter : public ACharacter
{
	GENERATED_UCLASS_BODY()

	struct FImplement;
	friend FImplement;
	TSharedPtr<FImplement> Impl;

public:
	UFUNCTION()
	void SetSkeletalMeshes(const int MergeMaterial, const TArray<FString>& MeshesPath);

private:

	USkeletalMeshComponent* WeaponMeshComponet;
	void CombineMesh(TArray<USkeletalMesh*> Meshes);

public:
    const TArray<uint8>& GetInitProtoData() const { return InitProtoData; }

    UFUNCTION(BlueprintPure, Category = "KMCharacter")
    const int GetLogicInstanceId() const { return LogicInstanceId; }

	void ResetSkeletalMeshComponentDrawDistance();

    UFUNCTION()
    void BeginPlayManually();

    void PreBeginPlay();
    void OrignalBeginPlay();
    void PostBeginPlay();
	inline const bool HasBeginPlayCompletely() const { return bHasBeginPlayCompletely; }
	virtual float TakeDamage(float DamageAmount, struct FDamageEvent const& DamageEvent, class AController* EventInstigator, AActor* DamageCauser) override;
    bool IsHideActorComsInGame()  { return bHideActorComsInGame; }

	static int GetCharacterDrawDis();

protected:
    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    virtual void OnSerializeNewActor(FOutBunch& OutBunch) override;
    virtual void OnActorChannelOpen(FInBunch& InBunch, UNetConnection* Connection) override;
    virtual void GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const override;
    virtual void PreReplication(IRepChangedPropertyTracker & ChangedPropertyTracker) override;
    virtual void Destroyed() override;

    virtual void FellOutOfWorld(const class UDamageType& dmgType) override;
    virtual void OutsideWorldBounds() override;

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

    UPROPERTY(EditDefaultsOnly)
    bool EnableDebugLog;

protected:
    UPROPERTY(BlueprintReadOnly, Transient, Category = "Game|Damage", ReplicatedUsing = OnRep_HitInfo)
    FGameHitInfo HitInfo;

    UFUNCTION()
    void OnRep_HitInfo();

// significance
public:
	UPROPERTY(EditAnywhere, Category = "KMCharacterSignificance")
	FName SignificanceTag = TEXT("KMCharacter");

	/** register into the significance manager */
	UFUNCTION(BlueprintCallable, Category = "KMCharacterSignificance")
	void RegisterToSignificance();

	/** unregister from the significance manager */
	UFUNCTION(BlueprintCallable, Category = "KMCharacterSignificance")
	void UnRegisterFromSignificance();

	UFUNCTION(BlueprintImplementableEvent, Category = "KMCharacterSignificance")
	float OnSignificance(UObject* Obj, const FTransform& Trans);

	UFUNCTION(BlueprintImplementableEvent, Category = "KMCharacterSignificance")
	void OnPostSignificance(UObject* Obj, float OldVal, float CurrentVal, bool bBeingUnregistered);

protected:
	/** apply hidden in game */
	UFUNCTION(BlueprintCallable, Category = "KMCharacterSignificance")
	void HideComponentsInGame(bool Flag);

	/** update bHideActorComsInGame */
	void SetHideActorComsInGame(bool InVal) { bHideActorComsInGame = InVal; }
// ~significance

protected:
	virtual void SetReplicateMovement(bool bInReplicateMovement) override;
    virtual void PostNetReceive() override;
	void VerifyMovementSyncChange();

private:
    TArray<uint8> InitProtoData;
    int LogicInstanceId;
    bool IsBeginPlayManually;
    bool bHasBeginPlayCompletely;
    float LastTakeHitTimeTimeout;
    bool HasActorChannelOpened;  // 防止重复触发delegate
    bool bHideActorComsInGame;

    // 当此变量为true时，如果IsReplicateMovement为false，则影响attachment的replicate和movement component rpc
    bool EnableAttachmentAndMovementRPCDependingOnReplicateMovement;
};
