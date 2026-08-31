// Copyright 1998-2016 Epic Games, Inc. All Rights Reserved.

#pragma once
#include "PropertyHandle.h"
#include "DetailLayoutBuilder.h"

class IDetailLayoutBuilder;
class UKMCustomPropertyDetailComponent;

class FKMCustomPropertyDetails
{
public:
    FKMCustomPropertyDetails();
    void AddCodeViewCategory(IDetailLayoutBuilder& DetailBuilder, const TArray< TWeakObjectPtr<AActor> >& Actors);

private:
    virtual void OnActorPropertyChanged(class UKMCustomPropertyDetailComponent* Component, const FString& PropertyName);
    void Reset();

private:
    FName DetailViewIdentifier;
};