// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/UMG/PuzzleUserWidget.h"
#include "Common.h"
#include "Blueprint/SlateBlueprintLibrary.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "Blueprint/WidgetBlueprintLibrary.h"
#include "Kismet/KismetMathLibrary.h"
void UPuzzleUserWidget::Init(class UBorder* InRotateCircle, float InDiviationPosRange, float InDiviatiojnAngleRange)
{

	CurPuzzleState = NONE;
	RotateSpeed = 1.2f;
	InPosZorder = 5;
	NormalZorder = 10;
	SelectedZorder = 21;
	CircleZorder = 20;
	RotateCircle = InRotateCircle;
	DiviationPosRange = InDiviationPosRange;
	DiviationAngleRange = InDiviatiojnAngleRange;

	if (RotateCircle)
	{
		UCanvasPanelSlot* CanvasPanelSlot = Cast<UCanvasPanelSlot>(RotateCircle->Slot);
		CanvasPanelRotateCircleSlot = CanvasPanelSlot;
		CanvasPanelRotateCircleSlot->SetZOrder(CircleZorder);
		RotateCircle->OnMouseButtonDownEvent.BindUFunction(this, FName("OnRotateCircleMouseStarted"));
	}
}


//获取选中的图块
void UPuzzleUserWidget::SetSelectedPuzzle(class UBorder* InSelectedPuzzle, FVector2D InGoalPos)
{
	
	if (IsValid(CanvasPanelPuzzleItemSlot))
	{
		CanvasPanelPuzzleItemSlot->SetZOrder(NormalZorder);
	}
	CurPuzzleState = MOVE;
	SelectedPuzzle = InSelectedPuzzle;
	if (!RotateCircle->IsVisible())
	{
		RotateCircle->SetVisibility(ESlateVisibility::Visible);
	}
	
	if (IsValid(SelectedPuzzle) && IsValid(CanvasPanelRotateCircleSlot))
	{
		UCanvasPanelSlot* CanvasPanelSlot = Cast<UCanvasPanelSlot>(SelectedPuzzle->Slot);
		CanvasPanelPuzzleItemSlot = CanvasPanelSlot;
		FVector2D PuzzleItemPosition = CanvasPanelPuzzleItemSlot->GetPosition();
		CanvasPanelRotateCircleSlot->SetPosition(PuzzleItemPosition);
		CanvasPanelPuzzleItemSlot->SetZOrder(SelectedZorder);
	
	}
	GoalPos = InGoalPos;
}

float UPuzzleUserWidget::GetTouchAngle(const FGeometry& InGeometry, FVector2D TouchedLocalPosition)
{

	FVector2D CircleToMouseDirection = TouchedLocalPosition - CurCirclePostion;
	CircleToMouseDirection.Normalize();
	FVector2D NvY(0.0f, -1.0f);
	float Angle = GetAngleOfTwoVector(CircleToMouseDirection, NvY);
	return Angle;
}



FReply UPuzzleUserWidget::NativeOnTouchStarted(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent)
{
	return FReply::Handled();
}



//获取差值角度
float UPuzzleUserWidget::GetMouseRotateDeltaAngle(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent)
{
	FVector2D LastTouchedPosition = InGestureEvent.GetLastScreenSpacePosition();
	FVector2D CurTouchedPosition = InGestureEvent.GetScreenSpacePosition();
	LastTouchedPosition = USlateBlueprintLibrary::AbsoluteToLocal(InGeometry, LastTouchedPosition);
	CurTouchedPosition = USlateBlueprintLibrary::AbsoluteToLocal(InGeometry, CurTouchedPosition);
	float LastAngle = GetTouchAngle(InGeometry, LastTouchedPosition);
	float Angle = GetTouchAngle(InGeometry, CurTouchedPosition);
	float Result = Angle - LastAngle;
	return Result;
}

void UPuzzleUserWidget::CheckIsInPosition()
{

	if (CurPuzzleState == NONE)
	{
		return;
	}

	if (!(IsValid(SelectedPuzzle) && IsValid(CanvasPanelPuzzleItemSlot) && IsValid(RotateCircle)))
	{
		return;
	}

	FVector2D CurPuzzlePos = GetCurPuzzlePos();
	FVector2D GoalRangeMax = GoalPos + DiviationPosRange;
	FVector2D GoalRangeMini = GoalPos - DiviationPosRange;

	float CurPuzzleAngle = GetCurPuzzleAngle();
	float GoalAngleMax = +DiviationAngleRange;
	float GoalAngleMini = -DiviationAngleRange;
	if (CurPuzzlePos <= GoalRangeMax && CurPuzzlePos >= GoalRangeMini)
	{
		OnPuzzleItemInPos.Broadcast();
	}


	if (!((CurPuzzlePos <= GoalRangeMax && CurPuzzlePos >= GoalRangeMini) && (CurPuzzleAngle <= GoalAngleMax && CurPuzzleAngle >= GoalAngleMini)))
	{
		return;
	}

	CurPuzzleState = NONE;

	CanvasPanelPuzzleItemSlot->SetPosition(GoalPos);
	CanvasPanelPuzzleItemSlot->SetZOrder(InPosZorder);
	SelectedPuzzle->SetRenderTransformAngle(0);
	OnPuzzleItemBingo.Broadcast(SelectedPuzzle);
	SelectedPuzzle = nullptr;
	CanvasPanelPuzzleItemSlot = nullptr;
	RotateCircle->SetVisibility(ESlateVisibility::Collapsed);

}


float UPuzzleUserWidget::GetCurPuzzleAngle()
{
	if (!IsValid(SelectedPuzzle))
	{
		return 0.0f;
	}
	
	float Angle = SelectedPuzzle->RenderTransform.Angle;
	int AngleMultiple = FMath::FloorToInt(Angle / 360);
	Angle = Angle - 360 * AngleMultiple;
	if (Angle >= 180)
	{
		Angle = Angle - 360;
	}
	return Angle;
}

FVector2D UPuzzleUserWidget::GetCurPuzzlePos()
{
	if (IsValid(CanvasPanelPuzzleItemSlot))
	{
		return CanvasPanelPuzzleItemSlot->GetPosition();
	}

	return FVector2D(0.0f,0.0f);
}

bool UPuzzleUserWidget::CheckPositionIsOutOfRange(FVector2D TargetPos)
{
	FVector2D ViewPortSize = UWidgetLayoutLibrary::GetViewportSize(GetWorld())/ UWidgetLayoutLibrary::GetViewportScale(this);
	FVector2D MoveRangeMax = ViewPortSize - 100;
	FVector2D MoveRangeMin = FVector2D(100.0f, 100.0f);
	if ((TargetPos.X < MoveRangeMin.X) || (TargetPos.Y < MoveRangeMin.Y) || (TargetPos.X > MoveRangeMax.X) || (TargetPos.Y > MoveRangeMax.Y))
	{
		CurPuzzleState = NONE;
		return true;
	}
	return false;
}


void UPuzzleUserWidget::MovePuzzle(const FPointerEvent& InGestureEvent)
{
	if (CurPuzzleState != MOVE)
	{
		return;
	}
	if (!(IsValid(CanvasPanelPuzzleItemSlot) && IsValid(CanvasPanelRotateCircleSlot)))
	{
		return;
	}

	float ScaleValue = UWidgetLayoutLibrary::GetViewportScale(this);
	const FVector2D& DeltaPosition = InGestureEvent.GetCursorDelta() / UWidgetLayoutLibrary::GetViewportScale(this);

	const FVector2D& CurPosition = CanvasPanelPuzzleItemSlot->GetPosition();
	const FVector2D& TargetPosition = CurPosition + DeltaPosition;
	bool IsOutOfRange = CheckPositionIsOutOfRange(TargetPosition);
	if (IsOutOfRange)
	{
		return;
	}
	CanvasPanelPuzzleItemSlot->SetPosition(TargetPosition);
	CanvasPanelRotateCircleSlot->SetPosition(TargetPosition);
}


void UPuzzleUserWidget::RotatePuzzle(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent)
{
	if (CurPuzzleState != ROTATE)
	{
		return;
	}
	if (!(IsValid(RotateCircle) && IsValid(SelectedPuzzle)))
	{
		return;
	}

	float Angle = GetMouseRotateDeltaAngle(InGeometry, InGestureEvent);

	float CurCircleAngle = RotateCircle->RenderTransform.Angle + Angle;
	float CurPuzzleAngle = SelectedPuzzle->RenderTransform.Angle + Angle;
	RotateCircle->SetRenderTransformAngle(CurCircleAngle);
	SelectedPuzzle->SetRenderTransformAngle(CurPuzzleAngle);
}


FReply UPuzzleUserWidget::NativeOnTouchMoved(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent)
{

	MovePuzzle(InGestureEvent);
	RotatePuzzle(InGeometry, InGestureEvent);
	CheckIsInPosition();
	return FReply::Handled();
}

FReply UPuzzleUserWidget::NativeOnTouchEnded(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent)
{
	CurPuzzleState = NONE;
	return FReply::Handled();
}


FEventReply UPuzzleUserWidget::OnRotateCircleMouseStarted(const FGeometry& InGeometry, const FPointerEvent& IMouseEvent)
{

	if (IsValid(CanvasPanelRotateCircleSlot))
	{
		CurCirclePostion = CanvasPanelPuzzleItemSlot->GetPosition();
		CurPuzzleState = ROTATE;
	}
	
	return UWidgetBlueprintLibrary::Handled();
}

//获取两个坐标之间的角度，顺时针角度>0
float UPuzzleUserWidget::GetAngleOfTwoVector(FVector2D VectorA, FVector2D VectorB)
{
	 float AMultB = VectorA.X * VectorB.X + VectorA.Y * VectorB.Y;
	 float AMod = UKismetMathLibrary::Sqrt(VectorA.X*VectorA.X+ VectorA.Y*VectorA.Y);
	 float BMod = UKismetMathLibrary::Sqrt(VectorB.X*VectorB.X + VectorB.Y*VectorB.Y);
	 float CosAngle = AMultB / AMod / BMod;
	 float Angle = UKismetMathLibrary::Acos(CosAngle) * 180 / UKismetMathLibrary::GetPI();
	 return Angle * FMath::Sign(FVector2D::CrossProduct(VectorA, VectorB)) * -1;
}
