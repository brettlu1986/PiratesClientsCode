// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Avatar/GameAvatarPartStaticMeshMergeNode.h"
#include "Common.h"
#include "Game/Avatar/GameAvatarPartStaticMeshNode.h"
#include "KMStaticMeshMerge.h"
#include "Shell/EngineExtShell.h"

DEFINE_LOG_CATEGORY_STATIC(UGameAvatarPartStaticMeshMergeNodeLog, Log, All);


UGameAvatarPartStaticMeshMergeNode::UGameAvatarPartStaticMeshMergeNode(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    //, InstanceMeshComponent(nullptr)
    , IncludebRecursionChildren(false)
{
}

UStaticMesh* UGameAvatarPartStaticMeshMergeNode::GetNodeStaticMesh_Implementation(UGameAvatarPartStaticMeshNode* Node)
{
    //FStringAssetReference AssetRef(Node->GetMeshPath());
    //UObject* Object = AssetRef.TryLoad();
    UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(Node->GetMeshPath());
    if (Object == nullptr)
    {
        UE_LOG(UGameAvatarPartStaticMeshMergeNodeLog, Error, 
            TEXT("UGameAvatarPartStaticMeshMergeNode load failed: %s"), *Node->GetMeshPath());
        return nullptr;
    }
    UStaticMesh* NewMesh = Cast<UStaticMesh>(Object);
    check(NewMesh);
    return NewMesh;
}

FTransform UGameAvatarPartStaticMeshMergeNode::GetNodeWorldTransform_Implementation(UGameAvatarPartStaticMeshNode* Node)
{
    if (Node->GetTransformComponent())
    {
        return Node->GetTransformComponent()->GetSocketTransform(Node->GetSlotName());
    }
    return FTransform();
}

void UGameAvatarPartStaticMeshMergeNode::MergeMesh(const TArray<UStaticMesh*>& MeshesToMerge, const TArray<FTransform>& ToWorldTransforms, const FVector& Pivot, UStaticMesh*& OutMesh)
{
    if (MeshesToMerge.Num() == 0)
    {
        return;
    }
    if (MeshesToMerge.Num() != ToWorldTransforms.Num())
    {
        UE_LOG(UGameAvatarPartStaticMeshMergeNodeLog, Warning,
            TEXT("UGameAvatarPartStaticMeshMergeNode MergeMesh failed, the merged mesh number is not equal with transforms"));
        return;
    }

	double StartTime = FPlatformTime::Seconds();
	FKMStaticMeshMerge Merger;
	OutMesh = Merger.MergeStaticMeshes(MeshesToMerge, ToWorldTransforms, Pivot);
	UE_LOG(UGameAvatarPartStaticMeshMergeNodeLog, Log, TEXT("Merge static mesh time: %f ms."), (FPlatformTime::Seconds() - StartTime)*1000.0f);
}

void UGameAvatarPartStaticMeshMergeNode::RefreshSelf_Implementation()
{
    if (!StaticMeshComponent)
    {
        CreateStaticMeshComponent();
    }

    if (StaticMeshComponent)
    {
        TArray<UGameAvatarPartStaticMeshNode*> Nodes;        
        GetMergedNodes(Nodes);

        TArray<UStaticMesh*> MeshesToMerge;
        TArray<FTransform> ToWorldTransforms;
        int iCount = Nodes.Num();
        for (int ii = 0; ii < iCount; ii++)
        {
            UGameAvatarPartStaticMeshNode* Node = Nodes[ii];
            if (Node)
            {
                UStaticMesh* NewMesh = GetNodeStaticMesh(Node);
                if (!NewMesh)
                {
                    continue;;
                }

                MeshesToMerge.Add(NewMesh);
                ToWorldTransforms.Add(GetNodeWorldTransform(Node));
            }
        }

        if (MeshesToMerge.Num() && TransformComponent)
        {
            FAttachmentTransformRules Rule(EAttachmentRule::KeepRelative, false);
            StaticMeshComponent->AttachToComponent(TransformComponent, Rule, SlotName.IsValid() ? SlotName : NAME_None);

            UStaticMesh* OutMesh = nullptr;
            MergeMesh(MeshesToMerge, ToWorldTransforms, StaticMeshComponent->K2_GetComponentToWorld().GetLocation(), OutMesh);
            StaticMeshComponent->SetStaticMesh(OutMesh);
        }
    }


    // Test 
    //if (!InstanceMeshComponent)
    //{
    //    InstanceMeshComponent = NewObject<UInstancedStaticMeshComponent>(Actor, UInstancedStaticMeshComponent::StaticClass());
    //    InstanceMeshComponent->RegisterComponentWithWorld(Actor->GetWorld());
    //    Actor->AddOwnedComponent(InstanceMeshComponent);
    //}
    //if (InstanceMeshComponent)
    //{
    //    InstanceMeshComponent->ClearInstances();
    //    UStaticMesh* NewMesh = nullptr;
    //    TArray<UGameAvatarPartStaticMeshNode*> Nodes;
    //    GetMergedNodes(Nodes);
    //    int iCount = Nodes.Num();
    //    for (int ii=0; ii<iCount; ii++)
    //    {
    //        UGameAvatarPartStaticMeshNode* Node = Nodes[ii];
    //        if (!NewMesh)
    //        {
    //            FStringAssetReference AssetRef(Node->GetMeshPath());
    //            UObject* Object = AssetRef.TryLoad();
    //            if (Object == nullptr)
    //            {
    //                FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
    //                    TEXT("UGameAvatarPartStaticMeshNode load failed: %s"), *Node->GetMeshPath());
    //                return;
    //            }
    //            NewMesh = Cast<UStaticMesh>(Object);
    //            check(NewMesh);
    //            InstanceMeshComponent->SetStaticMesh(NewMesh);

    //            if (TransformComponent)
    //            {
    //                FAttachmentTransformRules Rule(EAttachmentRule::KeepRelative, false);
    //                InstanceMeshComponent->AttachToComponent(TransformComponent, Rule, SlotName.IsValid() ? SlotName : NAME_None);
    //            }
    //        }

    //        FQuat TempRotation(Node->GetWorldRotation());
    //        FVector TempLocation(Node->GetWorldLocation());
    //        FVector TempScale(Node->GetWorldScale());
    //        FTransform Trans(TempRotation, TempLocation, TempScale);
    //        InstanceMeshComponent->AddInstanceWorldSpace(Trans);
    //    }
    //}
}

void UGameAvatarPartStaticMeshMergeNode::GetMergedNodes_Implementation(TArray<UGameAvatarPartStaticMeshNode*>& Out)
{
    if (IncludebRecursionChildren)
    {
        TArray<UGameAvatarPartProcessNodeBase*> AllChildren;
        GetChildren(AllChildren, true);

        int iCount = AllChildren.Num();
        for (int i = 0; i < iCount; i++)
        {
            auto Node = Cast<UGameAvatarPartStaticMeshNode>(AllChildren[i]);
            if (Node)
            {
                Out.Add(Node);
            }
        }
    }
    else
    {
        int iCount = Children.Num();
        Out.Reserve(iCount);
        for (int i = 0; i < iCount; i++)
        {
            auto Node = Cast<UGameAvatarPartStaticMeshNode>(Children[i]);
            if (Node)
            {
                Out.Add(Node);
            }
        }
    }
}