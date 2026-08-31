// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/UMG/TouchInputButton.h"
#include "Common.h"
#include "Slate/SKMButton.h"
#include "TouchInputUserWidget.h"

UTouchInputButton::UTouchInputButton()
	: bMouseDown(false)
{

}

void UTouchInputButton::OnWidgetRebuilt()
{
	MyKMButton->OnMouseButtonDownEvent.BindUObject(this, &UTouchInputButton::SlateHandleMouseButtonDown);
	MyKMButton->OnMouseButtonUpEvent.BindUObject(this, &UTouchInputButton::SlateHandleMouseButtonUp);
	MyKMButton->OnMouseMoveEvent.BindUObject(this, &UTouchInputButton::SlateHandleMouseMove);
}

FReply UTouchInputButton::SlateHandleMouseButtonDown(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent)
{
	bMouseDown = true;
	if (TouchInputUserWidget)
	{
		TouchInputUserWidget->InputTouchStart(InPointerEvent);
	}
	return FReply::Unhandled();
}

FReply UTouchInputButton::SlateHandleMouseMove(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent)
{
	if (TouchInputUserWidget && bMouseDown)
	{
		TouchInputUserWidget->InputTouchMove(InPointerEvent);
	}
	return FReply::Unhandled();
}

FReply UTouchInputButton::SlateHandleMouseButtonUp(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent)
{
	if (TouchInputUserWidget && bMouseDown)
	{
		TouchInputUserWidget->InputTouchStop(InPointerEvent);
	}
	bMouseDown = false;
	return FReply::Unhandled();
}

void UTouchInputButton::SetTouchInputUserWidget(class UTouchInputUserWidget* InUserWidget)
{
	TouchInputUserWidget = InUserWidget;
}
