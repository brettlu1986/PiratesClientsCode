// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#include "UI/UMG/PiratesUserWidget.h"
#include "Common.h"
#include "UI/UMG/PiratesUserWidget.h"
#include "Shell/CommonShell.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"

UPiratesUserWidget::UPiratesUserWidget(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, TickInterval(0.f)
	, TickEnabled(false)
	, bTopWindow(false)
    , bRemovedByLevelUnload(false)
    , CurrentZOrder(0)
	, LastTickDeltaSeconds(0)
{
}

void UPiratesUserWidget::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	GInitRunaway();
	TickActionsAndAnimation(MyGeometry, InDeltaTime);
	if (TickEnabled)
	{
		if (TickInterval <= 0)
		{
			NativeTickInternal(MyGeometry, InDeltaTime);
		}
		else
		{
			LastTickDeltaSeconds += InDeltaTime;
			if (LastTickDeltaSeconds >= TickInterval)
			{
				NativeTickInternal(MyGeometry, InDeltaTime);
				LastTickDeltaSeconds = 0;
			}
		}
	}
}

void UPiratesUserWidget::NativeTickInternal(const FGeometry& MyGeometry, float InDeltaTime)
{
	Tick(MyGeometry, InDeltaTime);
}

//yangjingzhao for 4.20
//int32 UUserWidget::NativePaint(const FPaintArgs& Args, const FGeometry& AllottedGeometry, const FSlateRect& MyCullingRect, FSlateWindowElementList& OutDrawElements, int32 LayerId, const FWidgetStyle& InWidgetStyle, bool bParentEnabled) const
//{
//	if (bHasScriptImplementedPaint)
//	{
//		FPaintContext Context(AllottedGeometry, MyCullingRect, OutDrawElements, LayerId, InWidgetStyle, bParentEnabled);
//		OnPaint(Context);
//
//		return FMath::Max(LayerId, Context.MaxLayer);
//	}
//
//	return LayerId;
//}

void UPiratesUserWidget::AddToScreen(ULocalPlayer* LocalPlayer, int32 ZOrder)
{
	Super::AddToScreen(LocalPlayer, ZOrder);

	CurrentZOrder = ZOrder;
}

void UPiratesUserWidget::RemoveFromParent()
{
	Super::RemoveFromParent();
	if (bRemovedByLevelUnload)
	{
		bRemovedByLevelUnload = false;
		FCoreUObjectDelegates::PostLoadMapWithWorld.RemoveAll(this);
	}
}

void UPiratesUserWidget::OnLevelRemovedFromWorld(ULevel* InLevel, UWorld* InWorld)
{
	Super::OnLevelRemovedFromWorld(InLevel, InWorld);

	if (InLevel == nullptr && InWorld == GetWorld())// && IsInViewport())
	{
		FCoreUObjectDelegates::PostLoadMapWithWorld.AddUObject(this, &UPiratesUserWidget::OnPostLoadMap);
		bRemovedByLevelUnload = true;
	}
}

FReply UPiratesUserWidget::NativeOnTouchEnded(const FGeometry& InGeometry, const FPointerEvent& InGestureEvent)
{
	UCommonShell* pCommponShell = UCommonShell::GetCommon(this);
	if (pCommponShell)
	{
		pCommponShell->GetGameDelegateManager()->GameMisc->OnAnyUITouchEnded.Broadcast(InGeometry, InGestureEvent);
	}
	
	if (bTopWindow)
	{
		return FReply::Handled();
	}
	return Super::NativeOnTouchEnded(InGeometry, InGestureEvent);
}

void UPiratesUserWidget::OnPostLoadMap(UWorld* CurrentWorld)
{
	if (GWorld == GetWorld())
	{
		bRemovedByLevelUnload = false;
		FCoreUObjectDelegates::PostLoadMapWithWorld.RemoveAll(this);
		AddToViewport(CurrentZOrder);
	}
}

void UPiratesUserWidget::AnimationEvent(FString EventName)
{
	if (AnimationEventArray.Contains(EventName))
	{
		AnimationEventArray[EventName].ExecuteIfBound();
	}
}

void UPiratesUserWidget::BindAnimationEvent(const FString& EventName, FAnimationEventDeleagte Delegate)
{
	if (Delegate.IsBound())
	{
		if (AnimationEventArray.Contains(EventName))
		{
			AnimationEventArray[EventName] = Delegate;
			UE_LOG(LogBlueprintUserMessages, Warning, TEXT("BindAnimationEvent conflict, EventName : %s"), *EventName);
		}
		else
		{
			AnimationEventArray.Add(EventName, Delegate);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("BindAnimationEvent passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}
}

void UPiratesUserWidget::UnbindAnimationEvent(const FString& EventName)
{
	AnimationEventArray.Remove(EventName);
}