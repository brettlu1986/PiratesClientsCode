// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "InputCoreTypes.h"
#include "InputBase.generated.h"

DECLARE_DYNAMIC_DELEGATE(FInputKeyDeleagte);
DECLARE_DYNAMIC_DELEGATE_OneParam(FInputAxisDelegate, float, AxisValue);
DECLARE_DYNAMIC_DELEGATE_OneParam(FInputGestureDelegate, class UGestureResult*, GestureResult);

#define InputBindKeyFunction(Key)    									\
void InputBindPressed##Key()											\
{																		\
	if (KeyPressedBindings.Contains(#Key))								\
	{																	\
		KeyPressedBindings[#Key].ExecuteIfBound();						\
	}																	\
}																		\
																		\
void InputBindReleased##Key()											\
{																		\
	if (KeyReleasedBindings.Contains(#Key))								\
	{																	\
		KeyReleasedBindings[#Key].ExecuteIfBound();						\
	}																	\
}

#define InputBindKey(Key)                                                             				\
InputComponent->BindKey(EKeys::Key, IE_Pressed, this, &UInputManager::InputBindPressed##Key);		\
InputComponent->BindKey(EKeys::Key, IE_Released, this, &UInputManager::InputBindReleased##Key);

UENUM(BlueprintType)
enum class EInputAxis : uint8
{
	MoveForward,
	MoveRight,
	Turn,
	LookUp
};

UENUM(BlueprintType)
enum class EInputKey : uint8
{
	Left,
	Up,
	Right,
	Down,

	Zero,
	One,
	Two,
	Three,
	Four,
	Five,
	Six,
	Seven,
	Eight,
	Nine,

	A,
	B,
	C,
	D,
	E,
	F,
	G,
	H,
	I,
	J,
	K,
	L,
	M,
	N,
	O,
	P,
	Q,
	R,
	S,
	T,
	U,
	V,
	W,
	X,
	Y,
	Z,
	
	SpaceBar,
    LeftMouseButton,
    RightMouseButton,
    Escape,
    LeftControl,
    LeftAlt,
    LeftShift,
    Equals
};
