// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UMG/KMCheckBox.h"
#include "TouchInputCheckBox.generated.h"

/**
 * 
 */
UCLASS()
class UTouchInputCheckBox : public UKMCheckBox
{
	GENERATED_BODY()

	UTouchInputCheckBox();
	
protected:
	//~ Begin UWidget Interface
	virtual void OnWidgetRebuilt() override;
	//~ End UWidget Interface

	FReply SlateHandleMouseButtonDown(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent);
	FReply SlateHandleMouseMove(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent);
	FReply SlateHandleMouseButtonUp(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent);

	UFUNCTION(BlueprintCallable, Category = "TouchInput")
	void SetTouchInputUserWidget(class UTouchInputUserWidget* UserWidget);

private:
	class UTouchInputUserWidget* TouchInputUserWidget;
	bool bMouseDown;
};
