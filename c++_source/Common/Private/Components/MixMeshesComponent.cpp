// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/MixMeshesComponent.h"
#include "Common.h"
#include "SkeletalMeshMerge.h"
#include "GlobalDefinition.h"
#include "CharacterManager.h"
#include "Game/GameCommon.h"

FCharacterInstance character;
// Sets default values for this component's properties
UMixMeshesComponent::UMixMeshesComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	CountdownText = CreateDefaultSubobject<UTextRenderComponent>(TEXT("CountdownNumber"));
	CountdownText->SetHorizontalAlignment(EHTA_Center);
	CountdownText->SetWorldSize(150.0f);

}


// Called when the game starts
void UMixMeshesComponent::BeginPlay()
{
	Super::BeginPlay();

	// ...
	//CreateModel();

    UCharacterManager* CharacterManager = UGameCommon::Get(this)->GetCharacterManager();
	ReturnIfNullUObject(CharacterManager);
	character = CharacterManager->CreateCharacter(EPlayerCareer::Monkey, "ch_pc_hou_003_tou", "ch_pc_hou_003_shen", "ch_pc_hou_003_shou", "ch_pc_hou_003_jiao", "ch_we_one_hou_003");

}


// Called every frame
void UMixMeshesComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
	UCharacterManager* CharacterManager = UGameCommon::Get(this)->GetCharacterManager();
	ReturnIfNullUObject(CharacterManager);
	if (this->is_combine == 1)
	{
		this->is_combine = 0;
		//CreateModel();
		CharacterManager->UpdateHead(character, "ch_pc_hou_008_tou");
	}
	else if (this->is_combine == 2)
	{
		this->is_combine = 0;
		CharacterManager->UpdateChest(character, "ch_pc_hou_008_shen");
	}
	else if (this->is_combine == 3)
	{
		this->is_combine = 0;
		CharacterManager->UpdateHand(character, "ch_pc_hou_008_shou");
	}
	else if (this->is_combine == 4)
	{
		this->is_combine = 0;
		CharacterManager->UpdateFeet(character, "ch_pc_hou_008_jiao");
	}
	else if (this->is_combine == 5)
	{
		this->is_combine = 0;
		CharacterManager->UpdateWeapon(character, "ch_we_one_hou_008");
	}
}

void UMixMeshesComponent::CreateModel()
{

	//UMeshComponent* actor_finally_mesh = CreateDefaultSubobject<UMeshComponent>();
	//actor_head->SetActorLabel(FString::FString("NewName"));//gameobject.name = "NewName";
	//actor_head->SetActorLocation(FVector::FVector(0, 0, 0),false);//gameobject.transform.position = vector.zero;

	USkeletalMeshComponent* skeletonMesh = nullptr;
	USkeletalMeshComponent* skeletonMeshComponents[4]{nullptr,nullptr,nullptr,nullptr};

	skeletonMesh = Cast<USkeletalMeshComponent>(actor_base->GetComponentByClass(USkeletalMeshComponent::StaticClass()));
	if (actor_head != nullptr)
	{
		skeletonMeshComponents[0] = Cast<USkeletalMeshComponent>(actor_head->GetComponentByClass(USkeletalMeshComponent::StaticClass()));
	}
	if (actor_chest != nullptr)
	{
		skeletonMeshComponents[1] = Cast<USkeletalMeshComponent>(actor_chest->GetComponentByClass(USkeletalMeshComponent::StaticClass()));
	}
	if (actor_hand != nullptr)
	{
		skeletonMeshComponents[2] = Cast<USkeletalMeshComponent>(actor_hand->GetComponentByClass(USkeletalMeshComponent::StaticClass()));
	}
	if (actor_feet != nullptr)
	{
		skeletonMeshComponents[3] = Cast<USkeletalMeshComponent>(actor_feet->GetComponentByClass(USkeletalMeshComponent::StaticClass()));
	}

	TArray<USkeletalMesh*> skeletonMeshse;
	for (int i = 0; i < 4; i++)
	{
		if (skeletonMeshComponents[i] != nullptr)
		{
			skeletonMeshse.Add(skeletonMeshComponents[i]->SkeletalMesh);
		}
	}



	//CharacterManager->CombineObject(actor_base, skeletonMeshse,false);
	return;
	/*
	TArray<FSkelMeshMergeSectionMapping> skeletonSections;
	USkeletalMesh* targetMesh = ConstructObject<USkeletalMesh>(USkeletalMesh::StaticClass(), this, FName("MergedMesh"), RF_Transient);
	targetMesh->Skeleton = skeletonMesh->SkeletalMesh->Skeleton;
 	FSkeletalMeshMerge mergeMesh(targetMesh, skeletonMeshse, skeletonSections, 0);
 	bool mergeState = mergeMesh.DoMerge();
	if (mergeState)
	{
		skeletonMesh->SetSkeletalMesh(targetMesh);
	}

	// add weapon
	actor_weapon->AttachRootComponentToActor(actor_base, FName::FName("weapon_hand_r"));
	actor_weapon->SetActorRelativeLocation(FVector::FVector(0, 0, 0));
	actor_weapon->SetActorRelativeRotation(FQuat::FQuat(0, 0, 0, 1));
	{
		skeletonMesh->SetAnimationMode(EAnimationMode::AnimationSingleNode);
		skeletonMesh->Play(true);
	}
    */
}
