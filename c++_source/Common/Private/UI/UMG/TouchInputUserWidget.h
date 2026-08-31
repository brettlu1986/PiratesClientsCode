// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#pragma  once

#include "InputCoreTypes.h"
#include "PiratesUserWidget.h"
#include "TouchInputUserWidget.generated.h"

class UInputManager;

UCLASS()
class COMMON_API UTouchInputUserWidget : public UPiratesUserWidget
{
	GENERATED_BODY()
public:
	virtual FReply NativeOnTouchStarted(const FGeometry& Geometry, const FPointerEvent& Input) override;

	virtual FReply NativeOnTouchMoved(const FGeometry& Geometry, const FPointerEvent& Input) override;

	virtual FReply NativeOnTouchEnded(const FGeometry& Geometry, const FPointerEvent& Input) override;

	virtual void NativeOnMouseLeave(const FPointerEvent& InMouseEvent) override;

	UFUNCTION(BlueprintCallable, Category = "TouchInput")
	void InterruptTouch();

	UFUNCTION(BlueprintCallable, Category = "TouchInput")
	void InputTouchStart(const FPointerEvent& Input);

	UFUNCTION(BlueprintCallable, Category = "TouchInput")
	void InputTouchMove(const FPointerEvent& Input);

	UFUNCTION(BlueprintCallable, Category = "TouchInput")
	void InputTouchStop(const FPointerEvent& Input);

protected:
	virtual void NativeConstruct() override;
	virtual void NativeDestruct() override;

private:
	ETouchIndex::Type GetTouchIndex(const FPointerEvent& Input);

	FVector GetTouchLocation(const FPointerEvent& Input);

	UFUNCTION()
	void OnAnyUITouchEnded(const FGeometry& Geometry, const FPointerEvent& Input);

public:
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	bool bIgnoreTouchStart;

private:
	TMap<ETouchIndex::Type, FVector> TouchCache;
	UInputManager* InputManager;
};
