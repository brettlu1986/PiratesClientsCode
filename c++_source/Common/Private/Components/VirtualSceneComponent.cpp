// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/VirtualSceneComponent.h"
#include "Common.h"
#include "Kismet/KismetMathLibrary.h"
#include "ExtendBlueprintFunctions.h"


FTransform UVirtualSceneComponent::GetVirtualTransform_Implementation()
{
    return VirtualParent ?
        UKismetMathLibrary::ComposeTransforms(RelativeTransformToVirtualParent, VirtualParent->GetComponentTransform()) :
        RelativeTransformToVirtualParent;
}

void UVirtualSceneComponent::AttachToOriginalRealParent()
{
    if (OriginalRealParent)
    {
        this->K2_AttachToComponent(OriginalRealParent,
            FName("None"),
            EAttachmentRule::KeepRelative,
            EAttachmentRule::KeepRelative,
            EAttachmentRule::KeepRelative,
            true);
    }
}

void UVirtualSceneComponent::BeginPlay()
{
    OriginalRealParent = this->GetAttachParent();

    // Make the original real parent the default virtual parent.
    SetVirtualParent(OriginalRealParent);

    Super::BeginPlay();
}

void UVirtualSceneComponent::SetVirtualParent_Implementation(USceneComponent* aVirtualParent)
{
    if (aVirtualParent)
    {
        VirtualParent = aVirtualParent;

        RelativeTransformToVirtualParent = UExtendBlueprintFunctions::ConvertTransformToRelativeFixed(GetComponentTransform(),
            VirtualParent->GetComponentTransform());
    }
}