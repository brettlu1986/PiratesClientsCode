// Copyright 1998-2016 Epic Games, Inc. All Rights Reserved.

#include "KMCustomPropertyDetails.h"
#include "PiratesEditor.h"

#include "KMCustomPropertyDetailComponent.h"
#include "KMActor.h"

#include "DetailCategoryBuilder.h"
#include "PropertyEditing.h"
#include "DetailCategoryBuilder.h"
#include "IDetailsView.h"
#include "PropertyEditorModule.h"
#include "Modules/ModuleManager.h"

FKMCustomPropertyDetails::FKMCustomPropertyDetails()
{

}

void FKMCustomPropertyDetails::AddCodeViewCategory(IDetailLayoutBuilder& DetailBuilder, const TArray< TWeakObjectPtr<AActor> >& Actors)
{
    Reset();
    if (Actors.Num() == 0)
    {
        return;
    }

    AKMActor* KMActor = Cast<AKMActor>(Actors[0].Get());
    if (!KMActor)
    {
        return;
    }

    UKMCustomPropertyDetailComponent* ToolComponent = KMActor->FindComponentByClass<UKMCustomPropertyDetailComponent>();
    if (!ToolComponent)
    {
        return;
    }

    // 强制刷下
    KMActor->OnEditPropertyChanged("");

    DetailViewIdentifier = DetailBuilder.GetDetailsView()->GetIdentifier();
    UKMCustomPropertyDetailComponent::GetPropertyChangedDelegate().BindRaw(this, &FKMCustomPropertyDetails::OnActorPropertyChanged);

    TArray<UObject*> ActorArray;
    ActorArray.Add(KMActor);
    UClass* ThisClass = KMActor->GetClass();
    for (; ThisClass->IsChildOf(AKMActor::StaticClass()); ThisClass = ThisClass->GetSuperClass())
    {
        for (TFieldIterator<FProperty> IterProperty(ThisClass, EFieldIteratorFlags::ExcludeSuper, EFieldIteratorFlags::ExcludeDeprecated); IterProperty; ++IterProperty)
        {
            FProperty* Property = *IterProperty;
            if (CastField<FStrProperty>(Property)
                || CastField<FIntProperty>(Property)
                || CastField<FBoolProperty>(Property)
                || CastField<FArrayProperty>(Property)
                || CastField<FFloatProperty>(Property)
                || CastField<FByteProperty>(Property))
            {
                if (!ToolComponent->GetActorPropertyVisibility(Property->GetName()))
                {
                    TSharedRef<IPropertyHandle> PropertyHandle = DetailBuilder.GetProperty(Property->GetFName());
                    DetailBuilder.HideProperty(Property->GetFName(), KMActor->GetClass());
                }
            }
        }
    }
}

void FKMCustomPropertyDetails::OnActorPropertyChanged(UKMCustomPropertyDetailComponent* Component, const FString& PropertyName)
{
    if (Component->NeedRefreshDetail())
    {
        if (DetailViewIdentifier.IsValid())
        {
            FPropertyEditorModule& PropertyEditorModule = FModuleManager::LoadModuleChecked<FPropertyEditorModule>("PropertyEditor");
            auto ViewPtr = PropertyEditorModule.FindDetailView(DetailViewIdentifier);
            if (ViewPtr.IsValid())
            {
                bool bRefresh = false;
                TArray<UObject*> RefreshedActors;
                AActor* TargetActor = Component->GetOwner();
                const TArray< TWeakObjectPtr<AActor> >& Actors = ViewPtr->GetSelectedActors();
                for (int ii = 0; ii < Actors.Num(); ii++)
                {
                    if (Actors[ii].IsValid())
                    {
                        RefreshedActors.Add(Actors[ii].Get());
                    }

                    if (Actors[ii] == TargetActor)
                    {
                        bRefresh = true;
                    }
                }
                if (bRefresh)
                {
                    ViewPtr->SetObjects(RefreshedActors, true);
                }
            }
        }
        Component->ClearRefreshDetail();
    }
}

void FKMCustomPropertyDetails::Reset()
{
    UKMCustomPropertyDetailComponent::GetPropertyChangedDelegate().Unbind();
    DetailViewIdentifier = FName();
}