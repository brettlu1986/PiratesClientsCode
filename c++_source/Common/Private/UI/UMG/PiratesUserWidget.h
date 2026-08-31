// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#pragma  once

#include "Blueprint/UserWidget.h"
#include "PiratesUserWidget.generated.h"

DECLARE_DYNAMIC_DELEGATE(FAnimationEventDeleagte);
DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnTickEvent, const FGeometry&, MyGeometry, float, InDeltaTime);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FUserWidgetDestroy);

UCLASS()
class COMMON_API UPiratesUserWidget : public UUserWidget
{
	GENERATED_UCLASS_BODY()

private:
	UFUNCTION(BlueprintCallable, Category = Animation)
	void AnimationEvent(FString EventName);

protected:
	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;
	//yangjingzhao for 4.20
	//virtual void NativePaint(FPaintContext& InContext) const override;
	/**
	* Native implemented paint function for the Widget
	* Returns the maximum LayerID painted on
	*/
	//virtual int32 NativePaint(const FPaintArgs& Args, const FGeometry& AllottedGeometry, const FSlateRect& MyCullingRect, FSlateWindowElementList& OutDrawElements, int32 LayerId, const FWidgetStyle& InWidgetStyle, bool bParentEnabled) const;

	virtual void AddToScreen(ULocalPlayer* LocalPlayer, int32 ZOrder) override;
	virtual void RemoveFromParent() override;
	virtual void OnLevelRemovedFromWorld(ULevel* InLevel, UWorld* InWorld) override;
	virtual FReply NativeOnTouchEnded(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent) override;
	
	virtual void OnPostLoadMap(UWorld* CurrentWorld);
	virtual void NativeTickInternal(const FGeometry& MyGeometry, float InDeltaTime);

public:
	UFUNCTION(BlueprintCallable, Category = Animation)
	void BindAnimationEvent(const FString& EventName, FAnimationEventDeleagte Delegate);

	UFUNCTION(BlueprintCallable, Category = Animation)
	void UnbindAnimationEvent(const FString& EventName);

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tick", meta = (UIMin = "0.0"))
	float TickInterval;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tick")
	bool TickEnabled;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool bTopWindow;

protected:
	bool bRemovedByLevelUnload;

private:

	
	
	int32 CurrentZOrder;

	float LastTickDeltaSeconds;

	TMap < FString, FAnimationEventDeleagte > AnimationEventArray;
};
