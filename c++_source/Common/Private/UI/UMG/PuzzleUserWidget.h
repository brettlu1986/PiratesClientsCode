// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UI/UMG/PiratesUserWidget.h"
#include "Components/Border.h"
#include "Components/CanvasPanelSlot.h"
#include "PuzzleUserWidget.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FPuzzleItemBingo, UBorder*, PuzzleItem);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FPuzzleItemInPos);

/**
 * 
 */

UCLASS()
class UPuzzleUserWidget : public UPiratesUserWidget
{
	GENERATED_BODY()
	
public:

	UFUNCTION(BlueprintCallable, Category = "PuzzleUserWidget")
	void Init(UBorder* RotateCircle, float DiviationPosRange, float DiviatiojnAngleRange);

	UFUNCTION(BlueprintCallable, Category = "PuzzleUserWidget")
	void SetSelectedPuzzle(UBorder* RotateCircle, FVector2D GoalPos);

	UPROPERTY(BlueprintAssignable)
	FPuzzleItemBingo OnPuzzleItemBingo;

	UPROPERTY(BlueprintAssignable)
	FPuzzleItemInPos OnPuzzleItemInPos;

private:
	enum PuzzleState
	{
		NONE = 0,
		MOVE,
		ROTATE
	};


	virtual FReply NativeOnTouchStarted(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent) override;
	virtual FReply NativeOnTouchMoved(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent) override;
	virtual FReply NativeOnTouchEnded(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent) override;

	UFUNCTION()
	FEventReply OnRotateCircleMouseStarted(const FGeometry& InGeometry, const FPointerEvent& InMouseEvent);


	float GetTouchAngle(const FGeometry& InGeometry, FVector2D TouchedLocalPosition);
	float GetAngleOfTwoVector(FVector2D VectorA, FVector2D VectorB);
	float GetMouseRotateDeltaAngle(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent);
	bool CheckPositionIsOutOfRange(FVector2D TargetPos);
	void MovePuzzle(const FPointerEvent& InGestureEvent);
	void RotatePuzzle(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent);
	void CheckIsInPosition();
	float GetCurPuzzleAngle();
	FVector2D GetCurPuzzlePos();


	UBorder* RotateCircle;
	UBorder* SelectedPuzzle;
	UCanvasPanelSlot* CanvasPanelRotateCircleSlot;
	UCanvasPanelSlot* CanvasPanelPuzzleItemSlot;
	FVector2D CurCirclePostion;
	FVector2D LastRotateVector;
	FVector2D GoalPos;
	bool CanMove;
	bool CanRotate;
	float RotateSpeed;
	float DiviationPosRange;
	float DiviationAngleRange;
	int InPosZorder;
	int NormalZorder;
	int SelectedZorder;
	int CircleZorder;
	PuzzleState CurPuzzleState;
};
