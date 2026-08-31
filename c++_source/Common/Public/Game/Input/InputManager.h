// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "InputBase.h"
#include "Gestures/Base/GestureBase.h"
#include "InputManager.generated.h"

class UKMGestureRecognizer;

UCLASS(BlueprintType)
class COMMON_API UInputManager : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "InputManager")
	void Init();

    UFUNCTION(BlueprintCallable, Category = "InputManager")
	void SetPlayerController(APlayerController* PlayerController);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Key Pressed by Event"), Category = "InputManager")
	void BindKeyPressedDelegate(FInputKeyDeleagte Delegate, EInputKey InputKey);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Key Released by Event"), Category = "InputManager")
	void BindKeyReleasedDelegate(FInputKeyDeleagte Delegate, EInputKey InputKey);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Gesture Active by Event"), Category = "InputManager")
	void BindGestureActiveDelegate(FInputGestureDelegate Delegate, EGestureType GestureType);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Gesture Deactive by Event"), Category = "InputManager")
	void BindGestureDeactiveDelegate(FInputGestureDelegate Delegate, EGestureType GestureType);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Axis by Event"), Category = "InputManager")
	void BindAxisDelagate(FInputAxisDelegate Delegate, EInputAxis InputAxis);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Unbind Input by Event"), Category = "InputManager")
	void UnbindKeyDelegate(FInputKeyDeleagte Delegate);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Unbind Gesture by Event"), Category = "InputManager")
	void UnbindGestureDelegate(FInputGestureDelegate Delegate);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Key Pressed by Function Name", DefaultToSelf = "Object"), Category = "InputManager")
	void BindKeyPressed(UObject* Object, FString FunctionName, EInputKey InputKey);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Key Released by Function Name", DefaultToSelf = "Object"), Category = "InputManager")
	void BindKeyReleased(UObject* Object, FString FunctionName, EInputKey InputKey);
	
	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Gesture Active by Function Name", DefaultToSelf = "Object"), Category = "InputManager")
	void BindGestureActive(UObject* Object, FString FunctionName, EGestureType GestureType);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Bind Gesture Deactive by Function Name", DefaultToSelf = "Object"), Category = "InputManager")
	void BindGestureDeactive(UObject* Object, FString FunctionName, EGestureType GestureType);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Unbind Input by Function Name", DefaultToSelf = "Object"), Category = "InputManager")
	void UnbindKey(UObject* Object, FString FunctionName);

	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Unbind Gesture by Function Name", DefaultToSelf = "Object"), Category = "InputManager")
	void UnbindGesture(UObject* Object, FString FunctionName);

	UFUNCTION(BlueprintCallable, Category = "InputManager")
	void TouchStart(ETouchIndex::Type FingerIndex, FVector Location);

	UFUNCTION(BlueprintCallable, Category = "InputManager")
	void TouchMove(ETouchIndex::Type FingerIndex, FVector Location);

	UFUNCTION(BlueprintCallable, Category = "InputManager")
	void TouchStop(ETouchIndex::Type FingerIndex, FVector Location);

	UFUNCTION(BlueprintCallable, Category = "InputManager")
	void CloseGestureSelfTouchListen();

	UFUNCTION(BlueprintCallable, Category = "InputManager")
	void OpenGestureSelfTouchListen();

private:
	FString GetEnumValueName(FString EnumName, uint8 EnumValue);

	void BindInputEvent();

	// Lua Signature
	UFUNCTION(BlueprintCallable, Category = "InputManager")
	void FireKey();

	UFUNCTION(BlueprintCallable, Category = "InputManager")
	void FireGesture(UGestureResult* GestureResult);

private:
	UPROPERTY()
	UKMGestureRecognizer* GestureRecognizer;
	
	APlayerController* PlayerController;

	TMap<FString, FInputKeyDeleagte> KeyPressedBindings;

	TMap<FString, FInputKeyDeleagte> KeyReleasedBindings;

	TMap<EGestureType, FInputGestureDelegate> GestureActiveBindings;

	TMap<EGestureType, FInputGestureDelegate> GestureDeactiveBindings;

	TMap<EInputAxis, FInputAxisDelegate> AxisBindings;

public:
	// Delegate Callback
	void OnGestureActiveEvent(UGestureResult* GestureResult);
	void OnGestureDeactiveEvent(UGestureResult* GestureResult);

	void OnMoveForwardEvent(float AxisValue);
	void OnMoveRightEvent(float AxisValue);
	void OnTurnEvent(float AxisValue);
	void OnLookUpEvent(float AxisValue);

	InputBindKeyFunction(Left);
	InputBindKeyFunction(Up);
	InputBindKeyFunction(Right);
	InputBindKeyFunction(Down);

	InputBindKeyFunction(Zero);
	InputBindKeyFunction(One);
	InputBindKeyFunction(Two);
	InputBindKeyFunction(Three);
	InputBindKeyFunction(Four);
	InputBindKeyFunction(Five);
	InputBindKeyFunction(Six);
	InputBindKeyFunction(Seven);
	InputBindKeyFunction(Eight);
	InputBindKeyFunction(Nine);

	InputBindKeyFunction(A);
	InputBindKeyFunction(B);
	InputBindKeyFunction(C);
	InputBindKeyFunction(D);
	InputBindKeyFunction(E);
	InputBindKeyFunction(F);
	InputBindKeyFunction(G);
	InputBindKeyFunction(H);
	InputBindKeyFunction(I);
	InputBindKeyFunction(J);
	InputBindKeyFunction(K);
	InputBindKeyFunction(L);
	InputBindKeyFunction(M);
	InputBindKeyFunction(N);
	InputBindKeyFunction(O);
	InputBindKeyFunction(P);
	InputBindKeyFunction(Q);
	InputBindKeyFunction(R);
	InputBindKeyFunction(S);
	InputBindKeyFunction(T);
	InputBindKeyFunction(U);
	InputBindKeyFunction(V);
	InputBindKeyFunction(W);
	InputBindKeyFunction(X);
	InputBindKeyFunction(Y);
	InputBindKeyFunction(Z);
	InputBindKeyFunction(SpaceBar);
    InputBindKeyFunction(LeftMouseButton);
    InputBindKeyFunction(RightMouseButton);
    InputBindKeyFunction(Escape);
    InputBindKeyFunction(LeftControl);
    InputBindKeyFunction(LeftAlt);
    InputBindKeyFunction(LeftShift);
    InputBindKeyFunction(Equals);
};
