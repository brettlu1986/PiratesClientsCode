// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#include "UI/UMG/TouchInputUserWidget.h"
#include "Common.h"
#include "Game/Input/InputManager.h"
#include "Blueprint/SlateBlueprintLibrary.h"
#include "Shell/CommonShell.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"

FReply UTouchInputUserWidget::NativeOnTouchStarted(const FGeometry& Geometry, const FPointerEvent& Input)
{
	if (bIgnoreTouchStart)
	{
		return UUserWidget::NativeOnTouchStarted(Geometry, Input);
	}
    UUserWidget::NativeOnTouchStarted(Geometry, Input);
	InputTouchStart(Input);
	return FReply::Unhandled();
}

FReply UTouchInputUserWidget::NativeOnTouchMoved(const FGeometry& Geometry, const FPointerEvent& Input)
{
    UUserWidget::NativeOnTouchMoved(Geometry, Input);
	InputTouchMove(Input);
	return FReply::Unhandled();
}

FReply UTouchInputUserWidget::NativeOnTouchEnded(const FGeometry& Geometry, const FPointerEvent& Input)
{
    UUserWidget::NativeOnTouchEnded(Geometry, Input);
	InputTouchStop(Input);
	return FReply::Unhandled();
}

void UTouchInputUserWidget::NativeOnMouseLeave(const FPointerEvent& Input)
{
	UUserWidget::NativeOnMouseLeave(Input);
	// InputTouchStop(Input);
}

void UTouchInputUserWidget::InterruptTouch()
{
	for (auto& Pair : TouchCache)
	{
		InputManager->TouchStop(Pair.Key, Pair.Value);
	}
	TouchCache.Empty();
}

void UTouchInputUserWidget::NativeConstruct()
{
	UCommonShell* CommonShell = UCommonShell::GetCommon(this);
	InputManager = CommonShell->GetInputManager();
	CommonShell->GetGameDelegateManager()->GameMisc->OnAnyUITouchEnded.AddDynamic(this, &UTouchInputUserWidget::OnAnyUITouchEnded);
}

void UTouchInputUserWidget::NativeDestruct()
{
	UCommonShell* CommonShell = UCommonShell::GetCommon(this);
	CommonShell->GetGameDelegateManager()->GameMisc->OnAnyUITouchEnded.RemoveDynamic(this, &UTouchInputUserWidget::OnAnyUITouchEnded);
}

void UTouchInputUserWidget::OnAnyUITouchEnded(const FGeometry& Geometry, const FPointerEvent& Input)
{
	ETouchIndex::Type TouchIndex = GetTouchIndex(Input);
	if (FVector* TouchLocation = TouchCache.Find(TouchIndex))
	{
		InputManager->TouchStop(TouchIndex, *TouchLocation);
	}
}

ETouchIndex::Type UTouchInputUserWidget::GetTouchIndex(const FPointerEvent& Input)
{
	return static_cast<ETouchIndex::Type>(Input.GetPointerIndex());
}

FVector UTouchInputUserWidget::GetTouchLocation(const FPointerEvent& Input)
{
	const FVector2D& ScreenPosition = Input.GetScreenSpacePosition();
	FVector2D PixelPosition;
	FVector2D ViewpointPosition;
	USlateBlueprintLibrary::AbsoluteToViewport(this, ScreenPosition, PixelPosition, ViewpointPosition);
	return FVector(PixelPosition, 0);
}

void UTouchInputUserWidget::InputTouchStart(const FPointerEvent& Input)
{
	ETouchIndex::Type TouchIndex = GetTouchIndex(Input);
	const FVector& TouchLocation = GetTouchLocation(Input);
	InputManager->TouchStart(TouchIndex, TouchLocation);
	TouchCache.Add(TouchIndex, TouchLocation);
}

void UTouchInputUserWidget::InputTouchMove(const FPointerEvent& Input)
{
	ETouchIndex::Type TouchIndex = GetTouchIndex(Input);
	const FVector& TouchLocation = GetTouchLocation(Input);
	InputManager->TouchMove(TouchIndex, TouchLocation);
	TouchCache.Add(TouchIndex, TouchLocation);
}

void UTouchInputUserWidget::InputTouchStop(const FPointerEvent& Input)
{
	ETouchIndex::Type TouchIndex = GetTouchIndex(Input);
	const FVector& TouchLocation = GetTouchLocation(Input);
	InputManager->TouchStop(TouchIndex, TouchLocation);
	TouchCache.Remove(TouchIndex);
}