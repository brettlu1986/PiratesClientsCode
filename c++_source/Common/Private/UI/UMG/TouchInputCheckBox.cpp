// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/UMG/TouchInputCheckBox.h"
#include "Common.h"
#include "Slate/SKMCheckBox.h"
#include "TouchInputUserWidget.h"

UTouchInputCheckBox::UTouchInputCheckBox()
	: bMouseDown(false)
{

}

void UTouchInputCheckBox::OnWidgetRebuilt()
{
	MyKMCheckBox->OnMouseButtonDownEvent.BindUObject(this, &UTouchInputCheckBox::SlateHandleMouseButtonDown);
	MyKMCheckBox->OnMouseButtonUpEvent.BindUObject(this, &UTouchInputCheckBox::SlateHandleMouseButtonUp);
	MyKMCheckBox->OnMouseMoveEvent.BindUObject(this, &UTouchInputCheckBox::SlateHandleMouseMove);
}

FReply UTouchInputCheckBox::SlateHandleMouseButtonDown(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent)
{
	bMouseDown = true;
	if (TouchInputUserWidget)
	{
		TouchInputUserWidget->InputTouchStart(InPointerEvent);
	}
	return FReply::Unhandled();
}

FReply UTouchInputCheckBox::SlateHandleMouseMove(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent)
{
	if (TouchInputUserWidget && bMouseDown)
	{
		TouchInputUserWidget->InputTouchMove(InPointerEvent);
	}
	return FReply::Unhandled();
}

FReply UTouchInputCheckBox::SlateHandleMouseButtonUp(const FGeometry& InGeometry, const FPointerEvent& InPointerEvent)
{
	if (TouchInputUserWidget && bMouseDown)
	{
		TouchInputUserWidget->InputTouchStop(InPointerEvent);
	}
	bMouseDown = false;
	return FReply::Unhandled();
}

void UTouchInputCheckBox::SetTouchInputUserWidget(class UTouchInputUserWidget* InUserWidget)
{
	TouchInputUserWidget = InUserWidget;
}
