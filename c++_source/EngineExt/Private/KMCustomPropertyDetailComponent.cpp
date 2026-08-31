// Fill out your copyright notice in the Description page of Project Settings.

#include "KMCustomPropertyDetailComponent.h"
#include "EngineExt.h"


UKMCustomPropertyDetailComponent::FOnCustomPropertyPropertyChangedDelegate UKMCustomPropertyDetailComponent::OnPropertyChangedDelegate;

UKMCustomPropertyDetailComponent::UKMCustomPropertyDetailComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , NeedRefreshDetailValue(false)
{
    bIsEditorOnly = true;
}

void UKMCustomPropertyDetailComponent::SetActorPropertyVisibility(const FString& PropertyName, bool bVisible)
{
    if (bVisible)
    {
        if (HiddenPropertyNames.Contains(PropertyName))
        {
            HiddenPropertyNames.Remove(PropertyName);
            SetRefreshDetail();
        }
    }
    else
    {
        if (!HiddenPropertyNames.Contains(PropertyName))
        {
            HiddenPropertyNames.Add(PropertyName);
            SetRefreshDetail();
        }
    }
}

bool UKMCustomPropertyDetailComponent::GetActorPropertyVisibility(const FString& PropertyName)
{
    return !HiddenPropertyNames.Contains(PropertyName);
}

void UKMCustomPropertyDetailComponent::OnActorPropertyChanged(const FString& PropertyName)
{
    OnPropertyChangedDelegate.ExecuteIfBound(this, PropertyName);
}
