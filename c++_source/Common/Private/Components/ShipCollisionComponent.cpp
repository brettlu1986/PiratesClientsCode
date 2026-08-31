// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/ShipCollisionComponent.h"
#include "Common.h"

#if WITH_EDITOR

void UShipCollisionComponent::PostInitProperties()
{
    Super::PostInitProperties();

    Visualize();
}

void UShipCollisionComponent::Visualize()
{
    // Temporarily remove the trouble.
    return;

    if (VisualMaterial)
    {
        float Lerp = (FMath::Clamp(this->DamageScale, 0.8f, 1.2f) - 0.8f) / 0.4f;
        FLinearColor FinalColor = FLinearColor::LerpUsingHSV(
            FLinearColor(0.0f, 1.0f, 0.0f, 0.05f), FLinearColor(1.0f, 0.0f, 0.0f, 0.1f), Lerp);

        UMaterialInstanceDynamic *MatInstance = this->CreateDynamicMaterialInstance(
            0, VisualMaterial);
        MatInstance->SetVectorParameterValue("Color", FinalColor);
        MatInstance->GetMaterial()->SaveConfig();
    }
}

void UShipCollisionComponent::PostEditChangeProperty(struct FPropertyChangedEvent& PropertyChangedEvent)
{
    Super::PostEditChangeProperty(PropertyChangedEvent);

    // Visualize();
}

#endif
