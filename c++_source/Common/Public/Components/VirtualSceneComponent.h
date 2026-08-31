// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/SceneComponent.h"


#include "VirtualSceneComponent.generated.h"

/**
 * xwh: with virtual transform and tick. A Virtual Scene Component can always be detached from its real parent, when
 keeping the virtual transform follow the virtual parent. Check out GetVirtualTransform_Implementation to find out how.
 Any children classes can override GetVirtualTransform() to implement customized behaviors, e.g. conceptual local transform.
 OriginalRealParent is only used to attach back to real parent easier. "meta = (ChildCanTick..." also allows the children
 to tick, while an ordinary Scene Component cannot.
 */
UCLASS(ClassGroup = (Utility, Common), BlueprintType, Blueprintable, hideCategories = (Trigger, PhysicsVolume), meta = (ChildCanTick, BlueprintSpawnableComponent, IgnoreCategoryKeywordsInSubclasses, ShortTooltip = "A virtual Scene Component."))
class COMMON_API UVirtualSceneComponent : public USceneComponent
{
	GENERATED_BODY()
	
public:

    virtual void BeginPlay() override;


    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Virtual Transform")
    FTransform RelativeTransformToVirtualParent;
	
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Virtual Transform")
    USceneComponent* VirtualParent;

    // This real parent does not affect virtual transform. Only to be attached to.
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Virtual Transform")
    USceneComponent* OriginalRealParent;



    UFUNCTION(BlueprintPure, BlueprintNativeEvent, BlueprintCallable, Category = "Virtual Transform")
    FTransform GetVirtualTransform();

    UFUNCTION(BlueprintCallable, Category = "Virtual Transform")
    void AttachToOriginalRealParent();

    UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Virtual Transform")
    void SetVirtualParent(USceneComponent* aVirtualParent);
};
