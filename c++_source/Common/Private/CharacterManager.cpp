
#include "CharacterManager.h"
#include "Common.h"
#include "SkeletalMeshMerge.h"

void UCharacterManager::Init()
{

}

/* ----------------------------------------------------- */
/*				Public Function			*/

FCharacterInstance UCharacterManager::CreateCharacter(EPlayerCareer career, FString head, FString chest, FString hand, FString feet, FString weapon_right)
{
	FCharacterInstance character;
	character.Actor = GetWorld()->SpawnActor(AActor::StaticClass());
#if WITH_EDITOR
	character.Actor->SetActorLabel(FString(TEXT("alex")));
#endif
	character.SkeletonMesh = NewObject<USkeletalMeshComponent>(character.Actor, USkeletalMeshComponent::StaticClass());
	character.SkeletonMesh->RegisterComponent();
	character.Actor->SetRootComponent(character.SkeletonMesh);
   // character.Actor->GetRootPrimitiveComponent()->CastShadow = 0;

	character.Weapon_Right_Mesh = NewObject<USkeletalMeshComponent>(character.Actor, USkeletalMeshComponent::StaticClass());
	character.Weapon_Right_Mesh->RegisterComponent();
	//character.Weapon_Right_Mesh->AttachTo(character.SkeletonMesh, "weapon_hand_r");
    character.Weapon_Right_Mesh->CastShadow = 0;

	character.career = career;
	character.Head = head;
	character.Chest = chest;
	character.Hand = hand;
	character.Feet = feet;
	character.Weapon_Right = weapon_right;

	UObject* pObject = NULL;
	USkeletalMesh* SkeletonVisualAsset = NULL;

	pObject = this->GetAsset(this->GetSkeletonPath(character.career));
	if (pObject != NULL)
	{
		SkeletonVisualAsset = Cast<USkeletalMesh>(pObject);
		character.SkeletonMesh->SetSkeletalMesh(SkeletonVisualAsset);
	}

	pObject = this->GetAsset(this->GetWeaponPath(character.career,character.Weapon_Right));
	if (pObject != NULL)
	{
		SkeletonVisualAsset = Cast<USkeletalMesh>(pObject);
		character.Weapon_Right_Mesh->SetSkeletalMesh(SkeletonVisualAsset);
	}

	FString equipments[4] = {character.Head,character.Chest,character.Hand,character.Feet};
	TArray<USkeletalMesh*> meshes;
	for (int i = 0; i < 4; i ++)
	{
		pObject = this->GetAsset(this->GetEquipmentPath(character.career, equipments[i]));
		if (pObject != NULL)
		{
			SkeletonVisualAsset = Cast<USkeletalMesh>(pObject);
			meshes.Add(SkeletonVisualAsset);
		}
	}

	this->CombineObject(character.Actor, meshes, false);

	// play animation
	pObject = this->GetAsset("/Game/Resources/Characters/Roles/Fox/Animation/ch_pc_hou_breath");
	UAnimationAsset* anim = Cast<UAnimationAsset>(pObject);
	character.SkeletonMesh->PlayAnimation(anim, true);
	return character;
}

void UCharacterManager:: UpdateHead(FCharacterInstance &character, FString new_equip)
{
	character.Head = new_equip;
	this->UpdateEquipment(character);
}

void UCharacterManager::UpdateChest(FCharacterInstance &character, FString new_equip)
{
	character.Chest = new_equip;
	this->UpdateEquipment(character);
}

void UCharacterManager::UpdateHand(FCharacterInstance &character, FString new_equip)
{
	character.Hand = new_equip;
	this->UpdateEquipment(character);
}

void UCharacterManager::UpdateFeet(FCharacterInstance &character, FString new_equip)
{
	character.Feet = new_equip;
	this->UpdateEquipment(character);
}

void UCharacterManager::UpdateWeapon(FCharacterInstance &character, FString new_equip)
{
	character.Weapon_Right = new_equip;
	UObject* pObject = this->GetAsset(this->GetWeaponPath(character.career, character.Weapon_Right));
	if (pObject != NULL)
	{
		USkeletalMesh* SkeletonVisualAsset = Cast<USkeletalMesh>(pObject);
		character.Weapon_Right_Mesh->SetSkeletalMesh(SkeletonVisualAsset);
	}
}

int UCharacterManager::AddCharacterToArray(FCharacterInstance character)
{
	this->characterArray.Add(character);
	return characterArray.Num() - 1;
}

FCharacterInstance UCharacterManager::GetCharacterFromArray(int index)
{
	return this->characterArray[index];
}

/* ----------------------------------------------------- */
/*				Private Function		 	*/

void UCharacterManager::UpdateEquipment(FCharacterInstance &character)
{
	UObject* pObject = NULL;
	USkeletalMesh* SkeletonVisualAsset = NULL;

	FString equipments[4] = { character.Head,character.Chest,character.Hand,character.Feet };
	TArray<USkeletalMesh*> meshes;
	for (int i = 0; i < 4; i++)
	{
		pObject = this->GetAsset(this->GetEquipmentPath(character.career, equipments[i]));
		if (pObject != NULL)
		{
			SkeletonVisualAsset = Cast<USkeletalMesh>(pObject);
			meshes.Add(SkeletonVisualAsset);
		}
	}

	this->CombineObject(character.Actor, meshes, false);
}

void UCharacterManager::UpdateWeapon()
{

}

void UCharacterManager::CombineObject(AActor* skeleton, TArray<USkeletalMesh*> meshes, bool combineMaterial)
{
	USkeletalMeshComponent* skeletonMesh = Cast<USkeletalMeshComponent>(skeleton->GetComponentByClass(USkeletalMeshComponent::StaticClass()));
	
	//USkeletalMesh* targetMesh = ConstructObject<USkeletalMesh>(USkeletalMesh::StaticClass(), this, FName("MergedMesh"));
	USkeletalMesh* targetMesh = NewObject<USkeletalMesh>(this, USkeletalMesh::StaticClass());
	targetMesh->Skeleton = skeletonMesh->SkeletalMesh->Skeleton;
	
	TArray<FSkelMeshMergeSectionMapping> skeletonSections;
	FSkeletalMeshMerge mergeMesh(targetMesh, meshes, skeletonSections,0);
	bool mergeState = mergeMesh.DoMerge();
	if (mergeState)
	{
		skeletonMesh->SetSkeletalMesh(targetMesh);
	}
}

FString UCharacterManager::GetSkeletonPath(EPlayerCareer career)
{
	return FString(TEXT("/Game/Resources/Characters/Roles/Fox/Skeleton/ch_pc_hou"));
}

FString UCharacterManager::GetEquipmentPath(EPlayerCareer career,FString name)
{
	FString path = FString(TEXT("/Game/Resources/Characters/Roles/Fox/Equipment/"));
	path.Append(name);
	return path;
}

FString UCharacterManager::GetWeaponPath(EPlayerCareer career,FString name)
{
	FString path = FString(TEXT("/Game/Resources/Characters/Roles/Fox/Weapon/"));
	path.Append(name);
	return path;
}

UObject* UCharacterManager::GetAsset(FString path)
{
	FStringAssetReference gameAssetRef = path;
	UObject* pObject = gameAssetRef.TryLoad();
	return pObject;
}

