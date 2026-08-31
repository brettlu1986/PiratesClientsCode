// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Avatar/GameAvatarPartMeshMergeNode.h"
#include "Common.h"
#include "Game/Avatar/GameAvatarPartSkeletonMeshNode.h"
#include "Shell/CommonShell.h"
#include "Game/Merge/KMCharacterMeshMerge.h"
#include "Game/Merge/KMShipMeshMerge.h"
#define USE_MERGE_SKELETON_MESH

DEFINE_LOG_CATEGORY_STATIC(UGameAvatarPartMeshMergeNodeLog, Log, All);

//int32 MergeSkeletalMeshSwitch = 1;
//FAutoConsoleVariableRef CVarMergeSkeletalMesh(
//    TEXT("r.MergeSkeletalMesh"),
//    MergeSkeletalMeshSwitch,
//    TEXT("MergeSkeletalMesh, 0 : No Merging; 1 : Merge")
//);

UGameAvatarPartMeshMergeNode::UGameAvatarPartMeshMergeNode(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , bClearRootComponentMesh(false)
    , bUsedMerge(false)
{
}

void UGameAvatarPartMeshMergeNode::RefreshSelf_Implementation()
{
    ShipFlags.Empty();
    AllComopnents.Empty();
    AllSkeletals.Empty();
    AllStatics.Empty();
    AllStaticMeshComponents.Empty();

    int iCount = Children.Num();
    for (int ii = 0; ii < iCount; ii++)
    {
        Children[ii]->GetAsset(this);
    }

    if (ShipFlagComponent)
    {
        ShipFlagComponent->DestroyComponent(true);
        ShipFlagComponent = nullptr;
    }
    if (MergeStaticMeshComponent)
    {
        MergeStaticMeshComponent->DestroyComponent(true);
        MergeStaticMeshComponent = nullptr;
    }

    USkeletalMesh* ReturnSkeletal = nullptr;
	if (bUsedMerge)
	{
		TArray<FStaticMergeParameter1> Flags;

		if (ShipFlags.Num() > 0)
		{

			for (int i = 0; i < ShipFlags.Num(); i++)
			{
				if (!ShipFlags[i] || !ShipFlags[i]->GetStaticMesh())
				{
					UE_LOG(UGameAvatarPartMeshMergeNodeLog, Error, TEXT("ShipFlags Commponent or StaticMesh is null"));
					continue;
				}

				FName AttachName = ShipFlags[i]->GetAttachSocketName();
				FStaticMergeParameter1 FlagParam;
				FlagParam.BoneName = AttachName;

				FTransform SocketTrans1 = ShipFlags[i]->GetSocketTransform(AttachName, ERelativeTransformSpace::RTS_Actor);
				FlagParam.Offset = SocketTrans1;

				FlagParam.PartID = 0;
				FlagParam.Static = ShipFlags[i];
				Flags.Add(FlagParam);
			}
		}
		ReturnSkeletal = FKMShipMeshMerge::Get().KMMergeStaticWithSkeleton(AllSkeletals, AllStatics, Flags);
	}
    if (ReturnSkeletal)
    {
		//reset material slot name for new material
		if (ReturnSkeletal->Materials.Num() > 0)
		{
			ReturnSkeletal->Materials[0].MaterialSlotName = FName(TEXT("hull"));
		}

        if (!SkeletalMeshComponent)
        {
            SkeletalMeshComponent = NewObject<USkeletalMeshComponent>(Actor, USkeletalMeshComponent::StaticClass());
            
            SkeletalMeshComponent->RegisterComponentWithWorld(Actor->GetWorld());
            Actor->AddOwnedComponent(SkeletalMeshComponent);
            SkeletalMeshComponent->AttachToComponent(Actor->GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform);
            SkeletalMeshComponent->SetAnimInstanceClass(RootComponent->AnimClass);
            SkeletalMeshComponent->SetAnimationMode(RootComponent->GetAnimationMode());
        }
        SkeletalMeshComponent->SetSkeletalMesh(ReturnSkeletal);

        for (int i = 0; i < AllComopnents.Num(); i++)
        {
            AllComopnents[i]->SetVisibility(false);
            AllComopnents[i]->SetComponentTickEnabled(false);
        }

        for (int i = 0; i < AllStaticMeshComponents.Num(); i++)
        {
            AllStaticMeshComponents[i]->SetVisibility(false);
            AllStaticMeshComponents[i]->SetComponentTickEnabled(false);
        }
        //if (ShipFlags.Num() > 0)
        //{
        //    TArray<int32> PartIDs;
        //    ShipFlagComponent = FKMShipMeshMerge::Get().MergeFlagofShip(ShipFlags, PartIDs, Actor);
        //}
		//if (ShipFlagComponent)
		//{
		for (int i = 0; i < ShipFlags.Num(); i++)
		{
			ShipFlags[i]->SetVisibility(false);
			ShipFlags[i]->SetComponentTickEnabled(false);
		}
        //}
        //else
        //{
		//UE_LOG(UGameAvatarPartMeshMergeNodeLog, Log, TEXT("SkeletalMeshComponent->RelativeLocation %s"), *SkeletalMeshComponent->RelativeLocation.ToString());

		//for (int i = 0; i < ShipFlags.Num(); i++)
		//{
		//	FName AttachName = ShipFlags[i]->GetAttachSocketName();
		//	ShipFlags[i]->DetachFromComponent(FDetachmentTransformRules::KeepRelativeTransform);
		//	ShipFlags[i]->AttachToComponent(SkeletalMeshComponent, FAttachmentTransformRules::KeepRelativeTransform, AttachName);
		//	ShipFlags[i]->SetVisibility(true);
		//	ShipFlags[i]->SetComponentTickEnabled(true);

		//	UE_LOG(UGameAvatarPartMeshMergeNodeLog, Error, TEXT("ShipFlags[i]->attach name %s"), *AttachName.ToString());
		//	UE_LOG(UGameAvatarPartMeshMergeNodeLog, Error, TEXT("ShipFlags[i]->RelativeLocation %s"), *ShipFlags[i]->RelativeLocation.ToString());
		//}
        //}
    }
    else
    {
        if (AllStatics.Num() > 0)
        {
			//if without render; do nothing
			if (FApp::CanEverRender())
			{
				UStaticMesh* StaticMesh;
				MergeStaticMeshComponent = FKMShipMeshMerge::Get().MergeSameStaticMesh(AllStatics, FVector::ZeroVector, StaticMesh, Actor);
				if (MergeStaticMeshComponent)
				{
					MergeStaticMeshComponent->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform, ShipBaseSlot);
					if (StaticMesh)
					{
						MergeStaticMeshComponent->SetStaticMesh(StaticMesh);
					}
					else
					{
						MergeStaticMeshComponent->DestroyComponent(true);
						MergeStaticMeshComponent = nullptr;
					}
				}
			}

        }

        for (int i = 0; i < AllComopnents.Num(); i++)
        {
            AllComopnents[i]->SetVisibility(true);
            AllComopnents[i]->SetComponentTickEnabled(true);
        }

        for (int i = 0; i < AllStaticMeshComponents.Num(); i++)
        {
            AllStaticMeshComponents[i]->SetVisibility(false);
            AllStaticMeshComponents[i]->SetComponentTickEnabled(false);
        }
    }
}

void UGameAvatarPartMeshMergeNode::AddSkeletalMesh(USkeletalMesh* SkeletalMesh, FName BoneName, FTransform Offset, USkeletalMeshComponent* MeshComponent)
{
    if (!MeshComponent)
        return;
    FSkeletalMergeParameter KPara;
    KPara.Skeletal = MeshComponent;
    KPara.BoneName = BoneName;
    KPara.Offset = Offset;
    AllSkeletals.Add(KPara);
    AllComopnents.Add(MeshComponent);
}

void UGameAvatarPartMeshMergeNode::AddStaticMesh(UStaticMesh* StaticMesh, FName BoneName, FTransform Offset, UStaticMeshComponent* MeshComponent)
{
    if (!IsValid(StaticMesh))
        return;
    FStaticMergeParameter KPara;
    KPara.Static = StaticMesh;
    if(BoneName != NAME_None)
        KPara.BoneName = BoneName;
    else 
        KPara.BoneName = ShipBaseSlot;
    KPara.Offset = Offset;
    AllStatics.Add(KPara);

    if (MeshComponent)
    {
        AllStaticMeshComponents.Add(MeshComponent);
    }
}

void UGameAvatarPartMeshMergeNode::AddShipFlag(UStaticMesh* StaticMesh, FName BoneName, FTransform Offset, UStaticMeshComponent* MeshComponent)
{
    //FKMStaticMeshMerge KPara;
    //KPara.Static = StaticMesh;
    //if (BoneName != NAME_None)
    //    KPara.BoneName = BoneName;
    //else
    //    KPara.BoneName = FName(TEXT("Point_Ship001"));
    //KPara.Offset = Offset;
    

    if (MeshComponent)
    {
        AllComopnents.Add(MeshComponent);
        ShipFlags.Add(MeshComponent);
        //UE_LOG(UGameAvatarPartMeshMergeNodeLog, Log, TEXT("MeshComponent->RelativeLocation %s"), *MeshComponent->RelativeLocation.ToString())
    }
}

