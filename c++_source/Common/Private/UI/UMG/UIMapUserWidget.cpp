#include "UI/UMG/UIMapUserWidget.h"
#include "Common.h"
#include "UIMapOperation.h"


UUIMapUserWidget::UUIMapUserWidget(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, MapSize3D((FVector2D(1.0f, 1.0f)))
	, UIMapValidSize(FVector2D(1.0f, 1.0f))
	, UIMapValidOffset(FVector2D::ZeroVector)
	, MapOrigin3D(FVector2D::ZeroVector)
	, UIMapOrigin(FVector2D::ZeroVector)
	, bUpdate(false)
{
	ContentOpArray.Empty();
}

void UUIMapUserWidget::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTick(MyGeometry, InDeltaTime);

	int32 nMapFuncCount = ContentOpArray.Num();
	for (int32 i=0; i<nMapFuncCount; i++)
	{
		if (ContentOpArray[i]->GetEnable())
		{
			ContentOpArray[i]->OnNativeTick(InDeltaTime);
		}
		else if (bUpdate)
		{
			ContentOpArray[i]->OnNativeTick(0);
		}
	}
}

void UUIMapUserWidget::RegisterOperation(UUIMapOpBase* pOpObj)
{
	ContentOpArray.Add(pOpObj);
}

void UUIMapUserWidget::UnregisterOperation(UUIMapOpBase* pOpObj)
{
	int32 RemoveIndex = -1;
	for (int32 i = 0; i < ContentOpArray.Num(); i++)
	{
		if (ContentOpArray[i] == pOpObj)
		{
			RemoveIndex = i;
			break;
		}
	}
	if (RemoveIndex >= 0)
	{
		ContentOpArray.RemoveAt(RemoveIndex);
	}
}

void UUIMapUserWidget::UnregisterAllOperation()
{
	ContentOpArray.Empty();
}

void UUIMapUserWidget::InitMapParam(const FVector2D& In3DMapSize, const FVector2D& InUIMapValidSize,
	const FVector2D& InUIMapValidOffset, const FVector2D& In3DMapOrigin, const FVector2D& InUIMapOrigin)
{
	MapSize3D = In3DMapSize;
	UIMapValidSize = InUIMapValidSize;
	UIMapValidOffset = InUIMapValidOffset;
	MapOrigin3D = In3DMapOrigin;
	UIMapOrigin = InUIMapOrigin;
	bUpdate = true;
}

FVector2D UUIMapUserWidget::CalculateUIMapLocation(const FVector& InWorldPos)
{
	FVector2D UIPos;
	if (MapSize3D.X > 0 && MapSize3D.Y > 0)
	{
		UIPos.X = (InWorldPos.X - MapOrigin3D.X)*UIMapValidSize.X / MapSize3D.X + UIMapValidOffset.X;
		UIPos.Y = (InWorldPos.Y - MapOrigin3D.Y)*UIMapValidSize.Y / MapSize3D.Y + UIMapValidOffset.Y;
	}
	return UIPos;
}

FVector2D UUIMapUserWidget::CalculateUISize(const FVector2D& InSceneSize)
{
	FVector2D UISize = InSceneSize / MapSize3D * (UIMapValidSize + 2 * UIMapValidOffset);
	return UISize;
}

const FVector2D& UUIMapUserWidget::GetUIMapOrigin() const
{
	return UIMapOrigin;
}

const FVector2D& UUIMapUserWidget::Get3DMapOrigin() const
{
	return MapOrigin3D;
}

const FVector2D& UUIMapUserWidget::Get3DMapSize() const
{
	return MapSize3D;
}

const FVector2D& UUIMapUserWidget::GetUIMapValidSize() const
{
	return UIMapValidSize;
}

const FVector2D& UUIMapUserWidget::GetUIMapValidOffset() const
{
	return UIMapValidOffset;
}

void UUIMapUserWidget::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	UUIMapUserWidget* This = CastChecked<UUIMapUserWidget>(InThis);
	for (auto& OperationObj : This->ContentOpArray)
	{
		Collector.AddReferencedObject(OperationObj, This);
	}
	Super::AddReferencedObjects(This, Collector);
}
