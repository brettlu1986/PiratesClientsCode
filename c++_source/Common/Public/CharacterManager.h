// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMObject.h"
#include "CharacterManager.generated.h"

/**
 * UCharactorManager
 */

UENUM()
enum EPlayerCareer
{
	Monkey,
};

USTRUCT(BlueprintType)
struct FCharacterInstance
{
	GENERATED_USTRUCT_BODY()

public:
	
	EPlayerCareer career;
    UPROPERTY(BlueprintReadWrite)
	FString Weapon_Right;
    UPROPERTY(BlueprintReadWrite)
	FString Head;
    UPROPERTY(BlueprintReadWrite)
	FString Chest;
    UPROPERTY(BlueprintReadWrite)
	FString Hand;
    UPROPERTY(BlueprintReadWrite)
	FString Feet;

    UPROPERTY(BlueprintReadWrite)
	AActor* Actor;

	USkeletalMeshComponent* SkeletonMesh;
	USkeletalMeshComponent* Weapon_Right_Mesh;
}; 

UCLASS()
class COMMON_API UCharacterManager : public UKMObject
{
	GENERATED_BODY()

public:

    void Init();

	UFUNCTION(BlueprintCallable, Category = "UCharacterManager")
	FCharacterInstance CreateCharacter(EPlayerCareer career, FString head, FString chest, FString hand, FString feet, FString weapon_right);

	UFUNCTION(BlueprintCallable, Category = "UCharacterManager")
	void UpdateHead(UPARAM(ref) FCharacterInstance &character,FString new_equip);

	UFUNCTION(BlueprintCallable, Category = "UCharacterManager")
	void UpdateChest(UPARAM(ref) FCharacterInstance &character, FString new_equip);

	UFUNCTION(BlueprintCallable, Category = "UCharacterManager")
	void UpdateHand(UPARAM(ref) FCharacterInstance &character, FString new_equip);

	UFUNCTION(BlueprintCallable, Category = "UCharacterManager")
	void UpdateFeet(UPARAM(ref) FCharacterInstance &character, FString new_equip);

	UFUNCTION(BlueprintCallable, Category = "UCharacterManager")
	void UpdateWeapon(UPARAM(ref) FCharacterInstance &character, FString new_equip);

	UFUNCTION(BlueprintCallable, Category = "UCharacterManager")
	int AddCharacterToArray(FCharacterInstance character);

	UFUNCTION(BlueprintCallable, Category = "UCharacterManager")
	FCharacterInstance GetCharacterFromArray(int index);

private:

	void CombineObject(AActor* skeleton, TArray<USkeletalMesh*> meshes, bool combineMaterial);
	void UpdateEquipment(FCharacterInstance &character);
	void UpdateWeapon();

 	FString GetSkeletonPath(EPlayerCareer career);
	FString GetEquipmentPath(EPlayerCareer career,FString name);
	FString GetWeaponPath(EPlayerCareer career,FString name);
	UObject* GetAsset(FString path);

private:

	TArray<FCharacterInstance> characterArray;
};
