// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMCustomPropertyDetailComponent.generated.h"

UCLASS(Blueprintable, Transient, meta = (BlueprintSpawnableComponent))
class ENGINEEXT_API UKMCustomPropertyDetailComponent : public UActorComponent
{
	GENERATED_UCLASS_BODY()

    DECLARE_DELEGATE_TwoParams(FOnCustomPropertyPropertyChangedDelegate, UKMCustomPropertyDetailComponent*, const FString&);

public:
    UFUNCTION(BlueprintCallable, Category = "KMCustomPropertyDetailComponent", meta = (CallInEditor = "true"))
    void SetActorPropertyVisibility(const FString& PropertyName, bool bVisible);

    UFUNCTION(BlueprintPure, Category = "KMCustomPropertyDetailComponent", meta = (CallInEditor = "true"))
    bool GetActorPropertyVisibility(const FString& PropertyName);

    UFUNCTION(BlueprintCallable, Category = "KMCustomPropertyDetailComponent", meta = (CallInEditor = "true"))
    void SetRefreshDetail() { NeedRefreshDetailValue = true; }

    UFUNCTION(BlueprintCallable, Category = "KMCustomPropertyDetailComponent", meta = (CallInEditor = "true"))
    void OnActorPropertyChanged(const FString& PropertyName);

    static FOnCustomPropertyPropertyChangedDelegate& GetPropertyChangedDelegate() { return OnPropertyChangedDelegate; }
    void ClearRefreshDetail() { NeedRefreshDetailValue = false; }
    bool NeedRefreshDetail() { return NeedRefreshDetailValue; }

//protected:
//    UFUNCTION(BlueprintNativeEvent, Category = "KMCustomPropertyObject", meta = (CallInEditor = "true"))
//    void OnEditPropertyChanged(const FString& PropertyName);
//
//#if WITH_EDITOR
//    virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
//#endif

protected:
    TSet<FString> HiddenPropertyNames;
    static FOnCustomPropertyPropertyChangedDelegate OnPropertyChangedDelegate;
    bool NeedRefreshDetailValue;
};
