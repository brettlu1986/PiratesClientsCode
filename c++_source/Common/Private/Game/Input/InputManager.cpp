// Fill out your copyright notice in the Description page of Project Settings.

#include "Game/Input/InputManager.h"
#include "Common.h"
#include "Gestures/KMGestureRecognizer.h"
#include "Gestures/Base/GestureResult.h"

void UInputManager::Init()
{
	GestureRecognizer = NewObject<UKMGestureRecognizer>();

	// 激活手势识别
	GestureRecognizer->ActiveListen(EGestureType::Tap);
	GestureRecognizer->ActiveListen(EGestureType::Drag);
	GestureRecognizer->ActiveListen(EGestureType::DoubleTap);

	// 注册手势
	GestureRecognizer->OnActiveDelegate.BindUObject(this, &UInputManager::OnGestureActiveEvent);
	GestureRecognizer->OnGestureDeactive.BindUObject(this, &UInputManager::OnGestureDeactiveEvent);
}

void UInputManager::SetPlayerController(APlayerController* InPlayerController)
{
	ReturnIfNullUObject(InPlayerController);
	PlayerController = InPlayerController;
	if (GestureRecognizer)
	{
		GestureRecognizer->SetPlayerController(PlayerController);
	}
	BindInputEvent();
}

void UInputManager::BindKeyPressedDelegate(FInputKeyDeleagte Delegate, EInputKey InputKey)
{
	if (Delegate.IsBound())
	{
		FString KeyName = GetEnumValueName("EInputKey", (uint8)InputKey);
		if (KeyPressedBindings.Contains(KeyName))
		{
			// UE_LOG(LogBlueprintUserMessages, Warning, TEXT("BindKeyPressed conflict, KeyName : %s"), *KeyName);
			KeyPressedBindings[KeyName] = Delegate;
		}
		else
		{
			KeyPressedBindings.Add(KeyName, Delegate);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("BindKeyPressed passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}
}

void UInputManager::BindKeyReleasedDelegate(FInputKeyDeleagte Delegate, EInputKey InputKey)
{
	if (Delegate.IsBound())
	{
		FString KeyName = GetEnumValueName("EInputKey", (uint8)InputKey);
		if (KeyReleasedBindings.Contains(KeyName))
		{
			// UE_LOG(LogBlueprintUserMessages, Warning, TEXT("BindKeyReleased conflict, KeyName : %s"), *KeyName);
			KeyReleasedBindings[KeyName] = Delegate;
		}
		else
		{
			KeyReleasedBindings.Add(KeyName, Delegate);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("BindKeyReleased passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}
}

void UInputManager::BindGestureActiveDelegate(FInputGestureDelegate Delegate, EGestureType GestureType)
{
	if (Delegate.IsBound())
	{
		FString GestureName = GetEnumValueName("EGestureType", (uint8)GestureType);
		if (GestureActiveBindings.Contains(GestureType))
		{
			// UE_LOG(LogBlueprintUserMessages, Warning, TEXT("BindGestureActive conflict, GestureName : %s"), *GestureName);
			GestureActiveBindings[GestureType] = Delegate;
		}
		else
		{
			GestureActiveBindings.Add(GestureType, Delegate);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("BindGestureActive passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}
}

void UInputManager::BindGestureDeactiveDelegate(FInputGestureDelegate Delegate, EGestureType GestureType)
{
	if (Delegate.IsBound())
	{
		FString GestureName = GetEnumValueName("EGestureType", (uint8)GestureType);
		if (GestureDeactiveBindings.Contains(GestureType))
		{
			// UE_LOG(LogBlueprintUserMessages, Warning, TEXT("BindGestureDective conflict, GestureName : %s"), *GestureName);
			GestureDeactiveBindings[GestureType] = Delegate;
		}
		else
		{
			GestureDeactiveBindings.Add(GestureType, Delegate);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("BindGestureDective passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}
}

void UInputManager::BindAxisDelagate(FInputAxisDelegate Delegate, EInputAxis InputAxis)
{
	if (Delegate.IsBound())
	{
		FString EnumName = GetEnumValueName("EInputAxis", (uint8)InputAxis);
		if (AxisBindings.Contains(InputAxis))
		{
			// UE_LOG(LogBlueprintUserMessages, Warning, TEXT("BindAxisDelagate conflict, EnumName : %s"), *EnumName);
			AxisBindings[InputAxis] = Delegate;
		}
		else
		{
			AxisBindings.Add(InputAxis, Delegate);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("BindAxisDelagate passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}
}

void UInputManager::UnbindKeyDelegate(FInputKeyDeleagte Delegate)
{
	for (auto &Pair : KeyPressedBindings)
	{
		if (Pair.Value == Delegate)
		{
			KeyPressedBindings.Remove(Pair.Key);
			return;
		}
	}
	for (auto &Pair : KeyReleasedBindings)
	{
		if (Pair.Value == Delegate)
		{
			KeyReleasedBindings.Remove(Pair.Key);
			return;
		}
	}
}

void UInputManager::UnbindGestureDelegate(FInputGestureDelegate Delegate)
{
	for (auto &Pair : GestureActiveBindings)
	{
		if (Pair.Value == Delegate)
		{
			GestureActiveBindings.Remove(Pair.Key);
			return;
		}
	}
	for (auto &Pair : GestureDeactiveBindings)
	{
		if (Pair.Value == Delegate)
		{
			GestureDeactiveBindings.Remove(Pair.Key);
			return;
		}
	}
}

void UInputManager::BindKeyPressed(UObject* Object, FString FunctionName, EInputKey InputKey)
{
	FInputKeyDeleagte Delegate;
	Delegate.BindUFunction(Object, *FunctionName);
	BindKeyPressedDelegate(Delegate, InputKey);
}

void UInputManager::BindKeyReleased(UObject* Object, FString FunctionName, EInputKey InputKey)
{
	FInputKeyDeleagte Delegate;
	Delegate.BindUFunction(Object, *FunctionName);
	BindKeyReleasedDelegate(Delegate, InputKey);
}

void UInputManager::BindGestureActive(UObject * Object, FString FunctionName, EGestureType GestureType)
{
	FInputGestureDelegate Delegate;
	Delegate.BindUFunction(Object, *FunctionName);
	BindGestureActiveDelegate(Delegate, GestureType);
}

void UInputManager::BindGestureDeactive(UObject * Object, FString FunctionName, EGestureType GestureType)
{
	FInputGestureDelegate Delegate;
	Delegate.BindUFunction(Object, *FunctionName);
	BindGestureDeactiveDelegate(Delegate, GestureType);
}

void UInputManager::UnbindKey(UObject* Object, FString FunctionName)
{
	FInputKeyDeleagte Delegate;
	Delegate.BindUFunction(Object, *FunctionName);
	UnbindKeyDelegate(Delegate);
}

void UInputManager::UnbindGesture(UObject * Object, FString FunctionName)
{
	FInputGestureDelegate Delegate;
	Delegate.BindUFunction(Object, *FunctionName);
	UnbindGestureDelegate(Delegate);
}

void UInputManager::TouchStart(ETouchIndex::Type FingerIndex, FVector Location)
{
	if (GestureRecognizer)
	{
		GestureRecognizer->TouchStart(FingerIndex, Location);
	}
}

void UInputManager::TouchMove(ETouchIndex::Type FingerIndex, FVector Location)
{
	if (GestureRecognizer)
	{
		GestureRecognizer->TouchMove(FingerIndex, Location);
	}
}

void UInputManager::TouchStop(ETouchIndex::Type FingerIndex, FVector Location)
{
	if (GestureRecognizer)
	{
		GestureRecognizer->TouchStop(FingerIndex, Location);
	}
}

void UInputManager::CloseGestureSelfTouchListen()
{
	if (GestureRecognizer)
	{
		GestureRecognizer->CloseSelfTouchListen();
	}
}

void UInputManager::OpenGestureSelfTouchListen()
{
	if (GestureRecognizer)
	{
		GestureRecognizer->OpenSelfTouchListen();
	}
}

FString UInputManager::GetEnumValueName(FString EnumName, uint8 EnumValue)
{
	const UEnum* EnumPtr = FindObject<UEnum>(ANY_PACKAGE, *EnumName, true);
	if (!EnumPtr)
	{
		return FString("Invalid");
	}
	return EnumPtr->GetNameStringByIndex(EnumValue);
}

void UInputManager::FireKey()
{
}

void UInputManager::FireGesture(UGestureResult* GestureResult)
{
}

void UInputManager::OnGestureActiveEvent(UGestureResult* GestureResult)
{
	ReturnIfNullUObject(GestureResult);
	if (GestureActiveBindings.Contains(GestureResult->GestureType))
	{
		GestureActiveBindings[GestureResult->GestureType].ExecuteIfBound(GestureResult);
	}
}

void UInputManager::OnGestureDeactiveEvent(UGestureResult* GestureResult)
{
	ReturnIfNullUObject(GestureResult);
	if (GestureDeactiveBindings.Contains(GestureResult->GestureType))
	{
		GestureDeactiveBindings[GestureResult->GestureType].ExecuteIfBound(GestureResult);
	}
}


void UInputManager::OnMoveForwardEvent(float AxisValue)
{
	if (AxisBindings.Contains(EInputAxis::MoveForward))
	{
		AxisBindings[EInputAxis::MoveForward].ExecuteIfBound(AxisValue);
	}
}

void UInputManager::OnMoveRightEvent(float AxisValue)
{
	if (AxisBindings.Contains(EInputAxis::MoveRight))
	{
		AxisBindings[EInputAxis::MoveRight].ExecuteIfBound(AxisValue);
	}
}

void UInputManager::OnTurnEvent(float AxisValue)
{
	if (AxisBindings.Contains(EInputAxis::Turn))
	{
		AxisBindings[EInputAxis::Turn].ExecuteIfBound(AxisValue);
	}
}

void UInputManager::OnLookUpEvent(float AxisValue)
{
	if (AxisBindings.Contains(EInputAxis::LookUp))
	{
		AxisBindings[EInputAxis::LookUp].ExecuteIfBound(AxisValue);
	}
}

void UInputManager::BindInputEvent()
{
	UInputComponent* InputComponent = PlayerController->InputComponent;
	ReturnIfNullUObject(InputComponent);

	InputComponent->BindAxis("MoveForward", this, &UInputManager::OnMoveForwardEvent);
	InputComponent->BindAxis("MoveRight", this, &UInputManager::OnMoveRightEvent);
	InputComponent->BindAxis("Turn", this, &UInputManager::OnTurnEvent);
	InputComponent->BindAxis("Lookup", this, &UInputManager::OnLookUpEvent);

	// 引擎原生输入绑定
	InputBindKey(Left);
	InputBindKey(Up);
	InputBindKey(Right);
	InputBindKey(Down);

	InputBindKey(Zero);
	InputBindKey(One);
	InputBindKey(Two);
	InputBindKey(Three);
	InputBindKey(Four);
	InputBindKey(Five);
	InputBindKey(Six);
	InputBindKey(Seven);
	InputBindKey(Eight);
	InputBindKey(Nine);

	InputBindKey(A);
	InputBindKey(B);
	InputBindKey(C);
	InputBindKey(D);
	InputBindKey(E);
	InputBindKey(F);
	InputBindKey(G);
	InputBindKey(H);
	InputBindKey(I);
	InputBindKey(J);
	InputBindKey(K);
	InputBindKey(L);
	InputBindKey(M);
	InputBindKey(N);
	InputBindKey(O);
	InputBindKey(P);
	InputBindKey(Q);
	InputBindKey(R);
	InputBindKey(S);
	InputBindKey(T);
	InputBindKey(U);
	InputBindKey(V);
	InputBindKey(W);
	InputBindKey(X);
	InputBindKey(Y);
	InputBindKey(Z);
	InputBindKey(SpaceBar);
    InputBindKey(LeftMouseButton);
    InputBindKey(RightMouseButton);
    InputBindKey(Escape);
    InputBindKey(LeftControl);
    InputBindKey(LeftAlt);
    InputBindKey(LeftShift);
    InputBindKey(Equals);
}