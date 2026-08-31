
#include "Gestures/KMGestureRecognizer.h"
#include "Common.h"


#include "Gestures/Base/GestureResult.h"

#include "Gestures/GestureListen/DoubleTapGestureListen.h"
#include "Gestures/GestureListen/DragGestureListen.h"
#include "Gestures/GestureListen/FlickGestureListen.h"
#include "Gestures/GestureListen/HoldGestureListen.h"
#include "Gestures/GestureListen/PinchGestureListen.h"
#include "Gestures/GestureListen/TapGestureListen.h"
#include "Gestures/GestureListen/TwistGestureListen.h"
#include "Gestures/GestureListen/CustomGestureListen.h"

UKMGestureRecognizer::~UKMGestureRecognizer()
{
    DeactiveAll();
}

void UKMGestureRecognizer::Tick(float DeltaSeconds)
{
    for (auto& Pair : ListenArray)
    {
        auto &Listen = Pair.Value;
        if (IsValid(Listen))
        {
            Listen->Tick(DeltaSeconds);
        }
    }

    FilterActiveResult();
    SendActiveResult();
}

bool UKMGestureRecognizer::IsTickable() const
{
    return !HasAnyFlags(RF_ClassDefaultObject);
}

bool UKMGestureRecognizer::IsTickableWhenPaused() const
{
    return true;
}

TStatId UKMGestureRecognizer::GetStatId() const
{
    return TStatId();
}

void UKMGestureRecognizer::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	UKMGestureRecognizer* This = CastChecked<UKMGestureRecognizer>(InThis);
	for (auto& Pair : This->ListenArray)
	{
		Collector.AddReferencedObject(Pair.Value, This);
	}
	Super::AddReferencedObjects(This, Collector);
}

void UKMGestureRecognizer::SetPlayerController(APlayerController* PlayerController)
{
	ReturnIfNullUObject(PlayerController);

	UInputComponent* InputComponent = PlayerController->InputComponent;
	ReturnIfNullUObject(InputComponent);

	InputComponent->BindTouch(IE_Pressed	, this, &UKMGestureRecognizer::TouchStartByInput);
	InputComponent->BindTouch(IE_Released	, this, &UKMGestureRecognizer::TouchStopByInput);
	InputComponent->BindTouch(IE_Repeat		, this, &UKMGestureRecognizer::TouchMoveByInput);
}

void UKMGestureRecognizer::CloseSelfTouchListen()
{
	bSelfTouchListenClosed = true;
}

void UKMGestureRecognizer::OpenSelfTouchListen()
{
	bSelfTouchListenClosed = false;
}

void UKMGestureRecognizer::ActiveListen(EGestureType Type)
{
    ReturnIfTrue(ListenArray.Contains(Type));
    UGestureListen* Listen;
    switch (Type){
    case EGestureType::Tap:
        Listen = NewObject<UTapGestureListen>(this);
        break;
//     case EGestureType::Flick:
//         Listen = NewObject<UFlickGestureListen>(this);
//         break;
    case EGestureType::Drag:
        Listen = NewObject<UDragGestureListen>(this);
        break;
//     case EGestureType::Hold:
//         Listen = NewObject<UHoldGestureListen>(this);
//         break;
//     case EGestureType::Custom:
//         Listen = NewObject<UCustomGestureListen>(this);
//         break;
//     case EGestureType::Twist:
//         Listen = NewObject<UTwistGestureListen>(this);
//         break;
    case EGestureType::DoubleTap:
        Listen = NewObject<UDoubleTapGestureListen>(this);
        break;
//     case EGestureType::Pinch:
//         Listen = NewObject<UPinchGestureListen>(this);
//         break;
    default:
        return;
    }
    Listen->Init();
    Listen->OnActiveDelegate.BindUObject(this, &UKMGestureRecognizer::OnActiveEvent);
    Listen->OnDeactiveDelegate.BindUObject(this, &UKMGestureRecognizer::OnFailEvent);
    Listen->Execute();
    ListenArray.Add(Type, Listen);
}

void UKMGestureRecognizer::DeactiveListen(EGestureType Type)
{
    ReturnIfFalse(ListenArray.Contains(Type));
    ListenArray[Type]->Cancel();
    ListenArray.Remove(Type);
}

void UKMGestureRecognizer::DeactiveAll()
{
//     for (auto& Pair : ListenArray)
//     {
//         if (IsValid(Pair.Value))
//         {
//             DeactiveListen(Pair.Key);
//         }
//     }
}

void UKMGestureRecognizer::TouchStart(ETouchIndex::Type FingerIndex, FVector Location)
{
	ReturnIfFalse(bSelfTouchListenClosed);
    for (auto& Pair : ListenArray)
    {
        auto &Listen = Pair.Value;
        if (IsValid(Listen))
        {
            Listen->TouchStart(FingerIndex, Location);
        }
    }
}

void UKMGestureRecognizer::TouchMove(ETouchIndex::Type FingerIndex, FVector Location)
{
	ReturnIfFalse(bSelfTouchListenClosed);
    for (auto& Pair : ListenArray)
    {
        auto &Listen = Pair.Value;
        if (IsValid(Listen))
        {
            Listen->TouchMove(FingerIndex, Location);
        }
    }
}

void UKMGestureRecognizer::TouchStop(ETouchIndex::Type FingerIndex, FVector Location)
{
	ReturnIfFalse(bSelfTouchListenClosed);
    for (auto& Pair : ListenArray)
    {
        auto &Listen = Pair.Value;
        if (IsValid(Listen))
        {
            Listen->TouchStop(FingerIndex, Location);
        }
    }
}

void UKMGestureRecognizer::TouchStartByInput(ETouchIndex::Type FingerIndex, FVector Location)
{
	ReturnIfTrue(bSelfTouchListenClosed);
	for (auto& Pair : ListenArray)
	{
		auto &Listen = Pair.Value;
		if (IsValid(Listen))
		{
			Listen->TouchStart(FingerIndex, Location);
		}
	}
}

void UKMGestureRecognizer::TouchMoveByInput(ETouchIndex::Type FingerIndex, FVector Location)
{
	ReturnIfTrue(bSelfTouchListenClosed);
	for (auto& Pair : ListenArray)
	{
		auto &Listen = Pair.Value;
		if (IsValid(Listen))
		{
			Listen->TouchMove(FingerIndex, Location);
		}
	}
}

void UKMGestureRecognizer::TouchStopByInput(ETouchIndex::Type FingerIndex, FVector Location)
{
	ReturnIfTrue(bSelfTouchListenClosed);
	for (auto& Pair : ListenArray)
	{
		auto &Listen = Pair.Value;
		if (IsValid(Listen))
		{
			Listen->TouchStop(FingerIndex, Location);
		}
	}
}

void UKMGestureRecognizer::OnActiveEvent(UGestureResult* Result)
{
    ActiveMessages.Add(Result);
}

void UKMGestureRecognizer::OnFailEvent(UGestureResult* Result)
{
    OnGestureDeactive.ExecuteIfBound(Result);
    RemoveActiveResultByType(Result->GestureType);
}

void UKMGestureRecognizer::RemoveActiveResultByType(EGestureType ResultType)
{
    for (int i = ActiveMessages.Num() - 1; i >= 0; --i)
    {
        if (ActiveMessages[i]->GestureType == ResultType)
        {
            ActiveMessages.RemoveAt(i);
        }
    }

    for (int i = FilteredMessages.Num() - 1; i >= 0; --i)
    {
        if (FilteredMessages[i]->GestureType == ResultType)
        {
            FilteredMessages.RemoveAt(i);
        }
    }

    for (int i = FilteredTempMessages.Num() - 1; i >= 0; --i)
    {
        if (FilteredTempMessages[i]->GestureType == ResultType)
        {
            FilteredTempMessages.RemoveAt(i);
        }
    }
}

void UKMGestureRecognizer::FilterActiveResult()
{
    ReturnIfTrue(ActiveMessages.Num() <= 0);
    // 只有一个，无需顾虑，直接发送
    if (ActiveMessages.Num() == 1)
    {
        FilteredMessages.Append(ActiveMessages);
        ActiveMessages.Empty();
        return;
    }
    // 存在多个ActiveResult时，需要过滤
    SortActiveResult();
    for (int i = 0; i < ActiveMessages.Num(); ++i)
    {
        UGestureResult* CurItem = ActiveMessages[i];
        // 如果不支持多手势共存，直接添加
        if (MULTI_GESTURE_START.Contains(CurItem->GestureType))
        {
            FilteredMessages.Add(CurItem);
            break;
        }
        // 如果是第一个，直接先保存下来
        if (FilteredTempMessages.Num() == 0)
        {
            FilteredTempMessages.Add(CurItem);
            continue;
        }
        if (FilteredTempMessages.Last()->FingerIndex == CurItem->FingerIndex)
        {
            // Priority相同，保存当前
            if (CurItem->Priority == FilteredTempMessages.Last()->Priority)
            {
                FilteredTempMessages.Add(CurItem);
            }
            // 当前Priority大于之前Temp中的Priority，清空Temp，并保存当前
            else if (CurItem->Priority > FilteredTempMessages.Last()->Priority)
            {
                FilteredTempMessages.Empty();
                FilteredTempMessages.Add(CurItem);
            }
        }
        else
        {
            FilteredMessages.Append(FilteredTempMessages);
            FilteredTempMessages.Empty();
            FilteredTempMessages.Add(CurItem);
        }
        // 如果遍历到了最后，将当前Temp加入发送队列
        if (i + 1 == ActiveMessages.Num())
        {
            FilteredMessages.Append(FilteredTempMessages);
        }
    }
    ActiveMessages.Empty();
    FilteredTempMessages.Empty();
}

void UKMGestureRecognizer::SortActiveResult()
{
    // 对ActiveResult进行初步排序
	ActiveMessages.Sort([](const UGestureResult& A, const UGestureResult& B)
	{
		// 都不支持多手势共存，按优先级排序
		if (MULTI_GESTURE_START.Contains(A.GestureType) && MULTI_GESTURE_START.Contains(B.GestureType))
		{
			return B.Priority < A.Priority;
		}
		// 只有一个不支持多手势共存，不支持的排前面
		if (MULTI_GESTURE_START.Contains(A.GestureType))
		{
			return false;
		}
		if (MULTI_GESTURE_START.Contains(B.GestureType))
		{
			return true;
		}
		// 都支持多手势共存时，如果FingerIndex相同时，按优先级排序
		if (B.FingerIndex == A.FingerIndex)
		{
			return B.Priority < A.Priority;
		}
		// 否则按照FingerIndex排序
		return B.FingerIndex > A.FingerIndex;
		return false;
	});
}

void UKMGestureRecognizer::SendActiveResult()
{    
    for(int i = 0; i < FilteredMessages.Num(); i++ )
	{
		OnActiveDelegate.ExecuteIfBound(FilteredMessages[i]);
    }
    FilteredMessages.Empty();
}
