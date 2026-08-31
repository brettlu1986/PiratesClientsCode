// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Avatar/GameAvatarPartSkeletonMeshNode.h"
#include "Common.h"
#include "Shell/EngineExtShell.h"

DEFINE_LOG_CATEGORY_STATIC(UGameAvatarPartSkeletonMeshNodeLog, Log, All);

UGameAvatarPartSkeletonMeshNode::UGameAvatarPartSkeletonMeshNode(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , Component(nullptr)
    , RootComponent(nullptr)
    , AutoCreateSkeletalMeshComponent(false)    
{

}

bool UGameAvatarPartSkeletonMeshNode::SetRawData_Implementation(const FString& In)
{
    MeshPath = In;
    int Len = MeshPath.Len();
    if (Len > 0 && MeshPath[Len - 1] == ';')
    {
        MeshPath.RemoveAt(Len - 1);
    }
    return true;
}

bool UGameAvatarPartSkeletonMeshNode::GetRawData_Implementation(FString& Out)
{
    Out = MeshPath + ';';
    return true;
}

USkeletalMeshComponent* UGameAvatarPartSkeletonMeshNode::CreateSkeletalMeshComponent()
{
    Component = NewObject<USkeletalMeshComponent>(Actor, USkeletalMeshComponent::StaticClass());
    Component->RegisterComponentWithWorld(Actor->GetWorld());
    Component->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    //if (!RootComponent)
        Actor->AddOwnedComponent(Component);

    return Component;
}


void UGameAvatarPartSkeletonMeshNode::LoadSkeletalMesh()
{
    if (MeshPath.Len() > 0)
    {
        //FStringAssetReference AssetRef(MeshPath);
        //UObject* Object = AssetRef.TryLoad();
        UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(MeshPath);
        if (Object == nullptr)
        {
            FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
                TEXT("UGameAvatarPartSkeletonMeshNode load failed: %s"), *MeshPath);
            return;
        }
        auto NewMesh = Cast<USkeletalMesh>(Object);
        check(NewMesh);
        //if (NewMesh && RootComponent)
        //{
        //    if (RootComponent->SkeletalMesh)
        //    {
        //        NewMesh->Skeleton = RootComponent->SkeletalMesh->Skeleton;
        //    }
        //    Component->SetAnimInstanceClass(NewMesh->AnimClass);
        //    Component->SetAnimationMode(NewMesh->GetAnimationMode());
        //}
        Component->SetSkeletalMesh(NewMesh);
        if (RootComponent)
        {
            Component->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform,
                SlotName.IsValid() ? SlotName : NAME_None);
            Component->SetMasterPoseComponent(RootComponent);
        }
    }
    else
    {
        // TODO: 这样是否合适？是否需要记下老的skeleton？
        Component->SetSkeletalMesh(nullptr);
    }
}

void UGameAvatarPartSkeletonMeshNode::RefreshSelf_Implementation()
{
    if (!Component && AutoCreateSkeletalMeshComponent && (MeshPath.Len() > 0))
    {
        CreateSkeletalMeshComponent();
    }
    if (Component)
    {
        LoadSkeletalMesh();
    }
}

void UGameAvatarPartSkeletonMeshNode::GetAsset_Implementation(UGameAvatarPartProcessNodeBase* From)
{
    if (Component && Component->SkeletalMesh)
    {
        From->AddSkeletalMesh(Component->SkeletalMesh, SlotName, FTransform(), Component);
    }
    else if(MeshPath.Len() > 0)
    {
        //FStringAssetReference AssetRef(MeshPath);
        //UObject* Object = AssetRef.TryLoad();
        UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(MeshPath);
        if (Object == nullptr)
        {
            FMsg::Logf(__FILE__, __LINE__, TEXT("GameAvatar"), ELogVerbosity::Error,
                TEXT("UGameAvatarPartSkeletonMeshNode load failed: %s"), *MeshPath);
            return;
        }
        auto NewMesh = Cast<USkeletalMesh>(Object);
        check(NewMesh);
        From->AddSkeletalMesh(NewMesh, SlotName, FTransform(), nullptr);
    }
}


void UGameAvatarPartSkeletonMeshNode::CollectResources_Implementation(TArray<FString>& OutResources)
{
    if (!MeshPath.IsEmpty())
    {
        OutResources.Emplace(MeshPath);
    }
    if (!MaterialPath.IsEmpty())
    {
        OutResources.Emplace(MaterialPath);
    }
}