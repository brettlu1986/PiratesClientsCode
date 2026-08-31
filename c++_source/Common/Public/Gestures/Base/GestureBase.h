#pragma once

#include "GestureBase.generated.h"

DECLARE_DELEGATE_OneParam(FGestureResultDelegate, class UGestureResult*);

//监听的手势类型
UENUM(BlueprintType)
enum class EGestureType : uint8
{
	None,		// 无
	Tap,		// 点击
//	Flick,		// 轻扫
	Drag,		// 拖动
// 	Hold,		// 长按
// 	Custom,		// 自定义手势
// 	Twist,		// 扭转
 	DoubleTap,	// 双击
//	Pinch		// 捏合
};

//自定义手势类型
UENUM(BlueprintType)
enum class ECustomGestureType : uint8
{
	None,		// 无
	Caret,		// 倒V
	Circle,		// 圆圈
	Star,		// 五角星
	Triangle,	// 三角形
	V,			// V
	Z			// Z
};

//自定义手势类型
UENUM(BlueprintType)
enum class EFlickDirection : uint8
{
	Up,			// 上
	Left,		// 下
	Down,		// 左
	Right		// 右
};

// 多指触摸的手势
const TArray<EGestureType> MULTI_GESTURE_START =
{
// 	EGestureType::Twist,
// 	EGestureType::DoubleTap,
// 	EGestureType::Twist
};

struct FFingerInfo
{
	float ElapsedTime;
	float StartTime;
	TArray<FVector2D> Positions;

	FFingerInfo()
		: ElapsedTime   (0.f)
		, StartTime     (0.f)
	{
	}

	FVector2D GetDeltaPositionFromStart()
	{
		if (Positions.Num() == 0)
		{
			return FVector2D::ZeroVector;
		}
		return Positions.Last() - Positions[0];
	}

	float GetDeltaDistanceFromStart()
	{
		return GetDeltaPositionFromStart().Size();
	}
};
