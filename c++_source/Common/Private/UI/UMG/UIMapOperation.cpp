#include "UI/UMG/UIMapOperation.h"
#include "Common.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/OverlaySlot.h"
#include "Shell/EngineExtActorShell.h"
#include "Kismet/KismetMathLibrary.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "Blueprint/SlateBlueprintLibrary.h"
#include "Components/Slider.h"
#include "UMG/KMCanvasPanel.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "Shell/CommonShell.h"
#include "Blueprint/WidgetTree.h"

#define LOCTEXT_NAMESPACE "UIMapOperation"


DEFINE_LOG_CATEGORY_STATIC(LogMapOperation, Log, All);
//ui map 操作基类
UUIMapOpBase::UUIMapOpBase(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, bEnable(true)
	, bMirror(false)
	, TickInterval(0.0)
	, LastTickDeltaSeconds(0.0)
{
}

void UUIMapOpBase::SetEnable(bool bInEnable)
{
	bEnable = bInEnable;
}

bool UUIMapOpBase::GetEnable()
{
	return bEnable;
}

void UUIMapOpBase::SetMirror(bool bInMirror)
{
	bMirror = bInMirror;
}

void UUIMapOpBase::SetTickInterval(float InTickInterval)
{
	TickInterval = InTickInterval;
}

//带actor的操作类
void UUIMapOpWithActor::BindActor(AActor* Actor)
{
	//Actor->OnEndPlay.AddUniqueDynamic(this, &UUIMapOpWithActor::OnActorEndPlay);
	if (!Actor->OnEndPlay.IsAlreadyBound(this, &UUIMapOpWithActor::OnActorDestroy))
		Actor->OnEndPlay.AddDynamic(this, &UUIMapOpWithActor::OnActorDestroy);
}

void UUIMapOpWithActor::UnBindActor(AActor* Actor)
{
    Actor->OnEndPlay.RemoveDynamic(this, &UUIMapOpWithActor::OnActorDestroy);
}

//ui map 刷新地图位置
UUIMapMove::UUIMapMove(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pSelfActor(nullptr)
	, pSelfWidget(nullptr)
	, pOwner(nullptr)
	, InterSpeed(0)
	, UIMapPos(FVector2D(0, 0))
	, LastSelfPos(FVector(0, 0, 0))
	, UILocation(FVector2D(0, 0))
	, UIMapOrigin(FVector2D(0, 0))
	, pRadarMapWidget(nullptr)
{
    MapWidgetArray.Empty();
}

void UUIMapMove::InitParam(UUIMapUserWidget* pInOwner, AActor* pInActor, UCanvasPanel* pInWidget, UWidget* pInSelfWidget, UCanvasPanel* pMovedWidget, UKMRadarMap* pInRadarMapWidget)
{
	check(pInOwner && pInActor && pInWidget && pInRadarMapWidget);
	if(pSelfActor)
	{
		UnBindActor(pSelfActor);
	}
	pOwner = pInOwner;
	pSelfActor = pInActor;
	pSelfWidget = pInSelfWidget;
    MapWidgetArray.Add(pInWidget);
    MapWidgetArray.Add(pMovedWidget);
	pRadarMapWidget = pInRadarMapWidget;
	BindActor(pSelfActor);
	UIMapOrigin = pOwner->GetUIMapOrigin();
	OnNativeTick(0);
}

void UUIMapMove::SetInterSpeed(float Speed)
{
	InterSpeed = Speed;
}

void UUIMapMove::OnNativeTick(float DeltaSeconds)
{
	if (pOwner == nullptr || pSelfActor == nullptr || MapWidgetArray.Num() <= 0 || pSelfWidget == nullptr)
	{
		return;
	}
	/*FRotator Rotation = pSelfActor->K2_GetActorRotation();
	if (bMirror)
	{
		pSelfWidget->SetRenderTransformAngle(180 - Rotation.Yaw);
	}
	else
	{
		pSelfWidget->SetRenderTransformAngle(Rotation.Yaw);
	}*/
	FVector CurrentSelfPos = pSelfActor->K2_GetActorLocation();
	UCanvasPanelSlot* WidgetSlotOne = Cast<UCanvasPanelSlot>(MapWidgetArray[0]->Slot);
	if (WidgetSlotOne == nullptr)
	{
		return;
	}
	FVector2D Location = WidgetSlotOne->GetPosition();
	UIMapOrigin = pOwner->GetUIMapOrigin();
	UILocation = pOwner->CalculateUIMapLocation(CurrentSelfPos);
	if (bMirror)
	{
		FVector2D UIMapSize = pOwner->GetUIMapValidSize() + pOwner->GetUIMapValidOffset() * 2;
		UILocation.X = UIMapSize.X - UILocation.X;

	}
	UIMapPos.X = UIMapOrigin.X - UILocation.X;
	UIMapPos.Y = UIMapOrigin.Y - UILocation.Y;
	if (CurrentSelfPos.Equals(LastSelfPos, 0.1) && UIMapPos.Equals(Location, 0.1))
	{
		return;
	}
	LastSelfPos = CurrentSelfPos;
	//UKMRadarMap* pRadarMap = Cast<UKMRadarMap>(pOwner->WidgetTree->FindWidget("radarMap"));
	if (pRadarMapWidget)
	{
		pRadarMapWidget->OnViewPortPosChange(-UIMapPos);
	}
	//UE_LOG(LogMapOperation, Log, TEXT("UUIMapMove::CalculatePoint,UIMapPos(%f,%f) UIMapOrigin(%f,%f) CurrentSelfPos(%f,%f) AbsolutePos(%f,%f)"), UIMapPos.X, UIMapPos.Y, UIMapOrigin.X, UIMapOrigin.Y, CurrentSelfPos.X, CurrentSelfPos.Y, AbsolutePos.X, AbsolutePos.Y);
    for (auto& it : MapWidgetArray)
    {
        UCanvasPanelSlot* WidgetSlot = Cast<UCanvasPanelSlot>(it->Slot);
        if (WidgetSlot)
        {
			WidgetSlot->SetPosition(UIMapPos);
        }
    }
}

void UUIMapMove::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pSelfActor);
	pSelfActor = nullptr;
}

//ui map 刷新地图坐标
UUIMapCoord::UUIMapCoord(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pSelfActor(nullptr)
	, pCoordWidget(nullptr)
	, pOwner(nullptr)
	, nCoordInterval(1)
	, nLastUILocationX(-1)
	, nLastUILocationY(-1)
{
	CoordFormatText = LOCTEXT("UIMapCoord", "{0}, {1}");
}

void UUIMapCoord::InitParam(UUIMapUserWidget* pInOwner, AActor* pInActor, UTextBlock* pInWidget, float nInCoordInterval, const FText& InFormatText)
{
	check(pInOwner && pInActor && pInWidget);
	if (pSelfActor)
	{
		UnBindActor(pSelfActor);
	}
	pOwner = pInOwner;
	pSelfActor = pInActor;
	pCoordWidget = pInWidget;
	nCoordInterval = nInCoordInterval;
	CoordFormatText = InFormatText;
	BindActor(pSelfActor);
}

void UUIMapCoord::OnNativeTick(float DeltaSeconds)
{
	if (pOwner == nullptr || pSelfActor == nullptr || pCoordWidget == nullptr)
	{
		return;
	}

	FVector Location = pSelfActor->K2_GetActorLocation();
	FVector2D MapSize3D = pOwner->Get3DMapSize();
	int32 nUILocationX = FMath::RoundToInt((Location.X + MapSize3D.X / 2) / nCoordInterval);
	int32 nUILocationY = FMath::RoundToInt((MapSize3D.Y / 2 - Location.Y) / nCoordInterval);
	if (nUILocationX != nLastUILocationX || nUILocationY != nLastUILocationY)
	{
		FText CoordText = FText::Format(CoordFormatText, FText::FromString(FString::FromInt(nUILocationX)), FText::FromString(FString::FromInt(nUILocationY)));
		pCoordWidget->SetText(CoordText);
		nLastUILocationX = nUILocationX;
		nLastUILocationY = nUILocationY;
	}
}

void UUIMapCoord::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pSelfActor);
	pSelfActor = nullptr;
}

//ui map 动态刷新点
UUIMapOpPointWithActor::UUIMapOpPointWithActor(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pOwner(nullptr)
	, nFactor(1.0)
{
}

void UUIMapOpPointWithActor::OnNativeTick(float DeltaSeconds)
{
	if (pOwner == nullptr)
	{
		return;
	}
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i=0; i<nPointCounts; i++)
	{
		FContentPoint& ContentPoint = ContentPointArray[i];
		AActor* pActor = ContentPoint.pContentActor;
		UWidget* pWidget = ContentPoint.pContentWidget;
		FVector2D UILocation = pOwner->CalculateUIMapLocation(pActor->K2_GetActorLocation());
		if (bMirror)
		{
			FVector2D UIMapSize = pOwner->GetUIMapValidSize() + pOwner->GetUIMapValidOffset() * 2;
			UILocation.X = UIMapSize.X - UILocation.X;
		}
		UCanvasPanelSlot* WidgetSlot = Cast<UCanvasPanelSlot>(pWidget->Slot);
		if (WidgetSlot)
		{
			WidgetSlot->SetPosition(UILocation);
			/*FVector2D CurrentSize = ContentPoint.UISize * ScaleZoom;
			WidgetSlot->SetSize(CurrentSize);*/
		}
		if (ContentPoint.bCanRotation)
		{
			FRotator Rotation = pActor->K2_GetActorRotation();
			if (bMirror)
			{
				pWidget->SetRenderTransformAngle(180 - Rotation.Yaw);
			}
			else
			{
				pWidget->SetRenderTransformAngle(Rotation.Yaw);
			}
			
		}
	}
}

void UUIMapOpPointWithActor::InitParam(UUIMapUserWidget* pInOwner, float nInFactor)
{
	check(pInOwner);
	pOwner = pInOwner;
	nFactor = nInFactor;
}

void UUIMapOpPointWithActor::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	int32 nUniqueId = Actor->GetUniqueID();
	RemoveContentPoint(nUniqueId);
}

int32 UUIMapOpPointWithActor::AddContentPoint(AActor* pInActor, UWidget* pInWidget, bool bInCanRotation)
{
	check(pInActor && pInWidget);
	int32 nUniqueId = pInActor->GetUniqueID();
	if (!CheckActorExist(nUniqueId))
	{
		ContentPointArray.Add(FContentPoint(pInActor, pInWidget, bInCanRotation));
		BindActor(pInActor);
	}
	return nUniqueId;
}

int32 UUIMapOpPointWithActor::AddContentPointWithSize(AActor* pInActor, UWidget* pInWidget, UWidget* pInImageWidget, FVector2D InUISize, bool bInCanRotation)
{
	check(pInActor && pInWidget);
	int32 nUniqueId = pInActor->GetUniqueID();
	if (!CheckActorExist(nUniqueId))
	{
		ContentPointArray.Add(FContentPoint(pInActor, pInWidget, InUISize, bInCanRotation));
		BindActor(pInActor);
	}
	return nUniqueId;
}

void UUIMapOpPointWithActor::RemoveContentPoint(int32 nId)
{
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i=0; i<nPointCounts; i++)
	{
		FContentPoint& ContentPoint = ContentPointArray[i];
		int32 nUniqueId = ContentPoint.pContentActor->GetUniqueID();
		if (nUniqueId == nId)
		{
            UnBindActor(ContentPoint.pContentActor);
			ContentPointArray.RemoveAt(i);
			break;
		}
	}
}

bool UUIMapOpPointWithActor::CheckActorExist(int32 nInUniqueId)
{
	int32 nPointCounts = ContentPointArray.Num();
	for (int i = 0; i < nPointCounts; i++)
	{
		AActor* pActor = ContentPointArray[i].pContentActor;
		if (pActor != nullptr && pActor->GetUniqueID() == nInUniqueId)
		{
			return true;
		}
	}
	return false;
}

//ui map 导航路径
UUIMapNav::UUIMapNav(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, nNavPointInterval(1)
	, bStartNavigate(false)
	, nNavStartIndex(0)
	, pSelfActor(nullptr)
{
}


void UUIMapNav::OnNativeTick(float DeltaSeconds)
{
	if (bStartNavigate && pSelfActor)
	{
		FVector2D SelfLocation(pSelfActor->K2_GetActorLocation());
		int32 nRouteWidgetCount = NavWidgetArray.Num();
		for (int32 i = nNavStartIndex; i < nRouteWidgetCount; i++)
		{
			const FVector2D& CurrentPos = NavPosArray[i];
			float nDis = FVector2D::Distance(CurrentPos, SelfLocation);
			if (nDis < nNavPointInterval * 0.9f)
			{
				NavWidgetArray[i]->SetVisibility(ESlateVisibility::Collapsed);
				nNavStartIndex++;
				break;
			}
		}
		if (nNavStartIndex >= nRouteWidgetCount)
		{
			bStartNavigate = false;
		}
	}
}

void UUIMapNav::InitParam( AActor* pInActor)
{
	check(pInActor);
	pSelfActor = pInActor;
	BindActor(pSelfActor);
}

void UUIMapNav::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pSelfActor);
	pSelfActor = nullptr;
	StopNavigate();
}

void UUIMapNav::StartNavigate(const TArray<FVector2D>& InNavPosArray, 
	const TArray<UWidget*>& InNavWidgetArray, float nInNavPointInterval)
{
	check(pSelfActor);
	bStartNavigate = true;
	nNavStartIndex = 0;
	NavPosArray = InNavPosArray;
	NavWidgetArray = InNavWidgetArray;
	nNavPointInterval = nInNavPointInterval;
}

void UUIMapNav::StopNavigate()
{
	bStartNavigate = false;
	nNavStartIndex = 0;
	NavPosArray.Empty();
	NavWidgetArray.Empty();
}

//ui map 摄像机夹角
UUIMapCameraFov::UUIMapCameraFov(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, nCameraRotationOffset(0)
	, pFovWidget(nullptr)
	, pCameraMngr(nullptr)
	, nLastFovAngle(0)
{
}

void UUIMapCameraFov::InitParam(float nInCameraRotationOffset, UKMCircleProgressBarSimple* pInFovWidget)
{
	check(pInFovWidget);
	nCameraRotationOffset = nInCameraRotationOffset;
	pFovWidget = pInFovWidget;
	UWorld* ThisWorld = GetWorld();
	if (ThisWorld != nullptr)
	{
		pCameraMngr = UGameplayStatics::GetPlayerCameraManager(ThisWorld, 0);
		if (pCameraMngr != nullptr)
		{
			BindActor(pCameraMngr);
		}
	}
	
}

void UUIMapCameraFov::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pCameraMngr);
	pCameraMngr = nullptr;
}

void UUIMapCameraFov::OnNativeTick(float DeltaSeconds)
{
	if (pCameraMngr == nullptr || pFovWidget == nullptr)
	{
		return;
	}
	float nFovAngle = pCameraMngr->GetFOVAngle();
	FRotator Rotation = pCameraMngr->GetCameraRotation();
	float nFovOffset = nFovAngle / 2;
	if (bMirror)
	{
		pFovWidget->SetRenderTransformAngle(270 - (Rotation.Yaw - nFovOffset + nCameraRotationOffset));
	}
	else
	{
		pFovWidget->SetRenderTransformAngle(Rotation.Yaw - nFovOffset + nCameraRotationOffset);
	}
	
    if (nFovAngle != nLastFovAngle)
	{
	    pFovWidget->SetPercent(nFovAngle / 360);
	    nLastFovAngle = nFovAngle;
	}
}

//ui map 方位刷新点
UUIMapOpOrientationWithActor::UUIMapOpOrientationWithActor(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pOwner(nullptr)
	, pSelfActor(nullptr)
	, pOrientationRoot(nullptr)
	, pMapWidget(nullptr)
	, MapShape(EMapShape::MAP_Square)
	, ShowRange(FVector2D(1, 1))
	, ShowOffset(FVector2D(0, 0))
{
}

void UUIMapOpOrientationWithActor::OnNativeTick(float DeltaSeconds)
{
	if (pOwner == nullptr || pSelfActor == nullptr || pOrientationRoot == nullptr || pMapWidget == nullptr)
	{
		return;
	}
	//标记点父级的位置
	FVector2D UISelfLocation = pOwner->CalculateUIMapLocation(pSelfActor->K2_GetActorLocation());
	FVector2D UIMapOrigin = pOwner->GetUIMapOrigin();
	FVector2D UIMapPos(UIMapOrigin.X - UISelfLocation.X + ShowOffset.X, UIMapOrigin.Y - UISelfLocation.Y + ShowOffset.Y);
	UCanvasPanelSlot* MapWidgetSlot = Cast<UCanvasPanelSlot>(pMapWidget->Slot);
	if (MapWidgetSlot)
	{
		MapWidgetSlot->SetPosition(UIMapPos);
	}
	CalculatePoint(UISelfLocation);
}

void UUIMapOpOrientationWithActor::CalculatePoint(const FVector2D& InSelfPos)
{
	//标记点的位置
	FVector2D UITargetLocation, OrientationPos, AbsoluteOrientation, OrientationLocal;
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FContentPoint& ContentPoint = ContentPointArray[i];
		AActor* pActor = ContentPoint.pContentActor;
		UWidget* pWidget = ContentPoint.pContentWidget;
		UITargetLocation = pOwner->CalculateUIMapLocation(pActor->K2_GetActorLocation());
		float nDis = FVector2D::Distance(InSelfPos, UITargetLocation);
		if (MapShape == EMapShape::MAP_Circle)
		{
			if (nDis > ShowRange.X)
			{
				float a1 = UITargetLocation.Y - InSelfPos.Y;
				float b1 = UITargetLocation.X - InSelfPos.X;
				float c1 = nDis;
				float c = nDis - ShowRange.X;
				float a = a1 / c1 * c;
				float b = b1 / c1 * c;
				OrientationPos.X = UITargetLocation.X - b;
				OrientationPos.Y = UITargetLocation.Y - a;
			}
			else
			{
				OrientationPos = UITargetLocation;
			}
		}
		else if (MapShape == EMapShape::MAP_Square)
		{
			float nRangeK = ShowRange.Y / ShowRange.X;
			FVector2D Diff = UITargetLocation - InSelfPos;
			float nDiffSize = Diff.Size();
			float nPointK = FMath::Abs(Diff.Y / Diff.X);
			FVector2D SignDiff = Diff.GetSignVector();
			if (nPointK >= nRangeK)
			{
				float nPointSize = FMath::Abs(nDiffSize / Diff.Y * ShowRange.Y);
				if (nDis > nPointSize)
				{
					OrientationPos.X = InSelfPos.X + Diff.X / nDiffSize * nPointSize;
					OrientationPos.Y = InSelfPos.Y + ShowRange.Y * SignDiff.Y;
				}
				else
				{
					OrientationPos = UITargetLocation;
				}
				
			}
			else
			{
				float nPointSize = FMath::Abs(nDiffSize / Diff.X * ShowRange.X);
				if (nDis > nPointSize)
				{
					OrientationPos.X = InSelfPos.X + ShowRange.X * SignDiff.X;
					OrientationPos.Y = InSelfPos.Y + Diff.Y / nDiffSize * nPointSize;
				}
				else
				{
					OrientationPos = UITargetLocation;
				}
			}
			/*UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpOrientationWithActor::CalculatePoint,Diff(%f,%f) SignDiff(%f,%f) nRangeK(%f) nPointK(%f) OrientationPos(%f,%f)"), Diff.X, Diff.Y, SignDiff.X, SignDiff.Y
				, nRangeK, nPointK, OrientationPos.X, OrientationPos.Y);*/
		}
		
		AbsoluteOrientation = pMapWidget->GetCachedGeometry().LocalToAbsolute(OrientationPos);
		OrientationLocal = pOrientationRoot->GetCachedGeometry().AbsoluteToLocal(AbsoluteOrientation);
		UCanvasPanelSlot* WidgetSlot = Cast<UCanvasPanelSlot>(pWidget->Slot);
		if (WidgetSlot)
		{
			WidgetSlot->SetPosition(OrientationLocal);
		}
		if (ContentPoint.bCanRotation)
		{
			FRotator Rotation = pActor->K2_GetActorRotation();
			pWidget->SetRenderTransformAngle(Rotation.Yaw);
		}

	}
}

void UUIMapOpOrientationWithActor::InitParam(UUIMapUserWidget* pInOwner, AActor* pInSelfActor, UWidget* pInOrientationRoot, UWidget* pInMapWidget, FVector2D InShowRange, FVector2D InOffset, EMapShape InMapShape)
{
	check(pInOwner && pInSelfActor && pInOrientationRoot && pInMapWidget);
	if (pSelfActor)
	{
		UnBindActor(pSelfActor);
	}
	pOwner = pInOwner;
	pSelfActor = pInSelfActor;
	pOrientationRoot = pInOrientationRoot;
	pMapWidget = pInMapWidget;
	/*nScopeRadius = nInScopeRadius;
	nOrientationOffset = nInOffset;*/
	ShowRange = InShowRange;
	ShowOffset = InOffset;
	BindActor(pInSelfActor);
}

void UUIMapOpOrientationWithActor::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	int32 nUniqueId = Actor->GetUniqueID();
	RemoveOrientationPoint(nUniqueId);
	if (Actor->GetUniqueID() == pSelfActor->GetUniqueID())
	{
		UnBindActor(pSelfActor);
		pSelfActor = nullptr;
	}
}

bool UUIMapOpOrientationWithActor::CheckActorExist(int32 nInUniqueId)
{
    int32 nPointCounts = ContentPointArray.Num();
    for (int i = 0; i < nPointCounts; i++)
    {
        AActor* pActor = ContentPointArray[i].pContentActor;
        if (pActor != nullptr && pActor->GetUniqueID() == nInUniqueId)
        {
            return true;
        }
    }
    return false;
}

int32 UUIMapOpOrientationWithActor::AddOrientationPoint(AActor* pInActor, UWidget* pInWidget, bool bInCanRotation)
{
	check(pInActor && pInWidget);
	int32 nUniqueId = pInActor->GetUniqueID();
    if (!CheckActorExist(nUniqueId))
    {
        ContentPointArray.Add(FContentPoint(pInActor, pInWidget, bInCanRotation));
        BindActor(pInActor);
    }

	return nUniqueId;
}

void UUIMapOpOrientationWithActor::RemoveOrientationPoint(int32 nId)
{
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FContentPoint& ContentPoint = ContentPointArray[i];
		int32 nUniqueId = ContentPoint.pContentActor->GetUniqueID();
		if (nUniqueId == nId)
		{
            UnBindActor(ContentPoint.pContentActor);
			ContentPointArray.RemoveAt(i);
			break;
		}
	}
}



UUIMapOpStaticPath::UUIMapOpStaticPath(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{

}

void UUIMapOpStaticPath::OnNativeTick(float DeltaSeconds)
{
    for (FPathInfo& PathInfo : PathInfos)
    {
        AActor* pActor = PathInfo.pActor;
        if (pActor != nullptr)
        {
            FVector ActorLocation = pActor->K2_GetActorLocation();
            FVector2D Location2D(ActorLocation.X, ActorLocation.Y);
            float RemainingLength = FVector2D::Distance(Location2D, PathInfo.EndPoint);
            if (PathInfo.LastRemainingLength < 0)
                PathInfo.LastRemainingLength = RemainingLength;
            float Percent = 0.0f;
            if (RemainingLength <= PathInfo.LastRemainingLength)
            {
                Percent = RemainingLength / PathInfo.PathLength;
                Percent = FMath::Max(FMath::Min(Percent, 1.f), 0.f);
                PathInfo.LastRemainingLength = RemainingLength;
            }

            PathInfo.pProgressBar->SetPercent(1 - Percent);
        }
    }
}

int UUIMapOpStaticPath::AddPath(AActor* InActor, UProgressBar* PathWidget, const FVector2D& Start, const FVector2D& End)
{
    check(InActor && PathWidget);
    int nUniqueId = InActor->GetUniqueID();
    bool bExisted = false;
    for (FPathInfo& PathInfo : PathInfos)
    {
        if (PathInfo.pActor != nullptr && PathInfo.pActor->GetUniqueID() == nUniqueId)
        {
            bExisted = true;
            break;
        }
    }

    if (!bExisted)
    {
        PathInfos.Add(FPathInfo(InActor, PathWidget, Start, End));
        // TODO yangjingzhao
        // PathWidget->EnableClip = false;
        BindActor(InActor);
    }
    return nUniqueId;
}

void UUIMapOpStaticPath::RemovePath(int PathId)
{
    int Length = PathInfos.Num();
    for (int idx = 0; idx < Length; idx++)
    {
        FPathInfo& PathInfo = PathInfos[idx];
        if (PathInfo.pActor->GetUniqueID() == PathId)
        {
            UnBindActor(PathInfo.pActor);
            PathInfos.RemoveAt(idx);
            break;
        }
    }
}


void UUIMapOpStaticPath::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
    int nUniqueId = Actor->GetUniqueID();
    RemovePath(nUniqueId);
}

//FFA毒圈

UUIMapOpPoisonCircle::UUIMapOpPoisonCircle(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pSelfActor(nullptr)
	, pOwner(nullptr)
	, pSafeCircleWidget(nullptr)
	, pPoisonCircleWidget(nullptr)
	, SafeCircleCenter(FVector(0, 0, 0))
	, SafeCircleRadius(0.f)
	, PoisonCircleCenter(FVector(0, 0, 0))
	, PoisonCircleRadius(0.f)
	, PoisonCircleStartRadius(0.f)
	, pDistanceWidget(nullptr)
	, pProgressWidget(nullptr)
	, pSelfWidget(nullptr)
{

}

void UUIMapOpPoisonCircle::SetSafeCircle(const FVector& InCircleCenter, float InCircleRadius, float InPoisonCircleRadius)
{
	//UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpPoisonCircle::SetSafeCircle,InCircleCenter(%f,%f) InCircleRadius(%f)"), InCircleCenter.X, InCircleCenter.Y, InCircleRadius);
	//UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpPoisonCircle::SetSafeCircle,PoisonCircleStartRadius(%f) PoisonCircleRadius(%f) SafeCircleRadius(%f)"), InPoisonCircleRadius, PoisonCircleRadius, InCircleRadius);
	pSafeCircleWidget->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
	SafeCircleCenter = InCircleCenter;
	SafeCircleRadius = InCircleRadius;
	PoisonCircleStartRadius = InPoisonCircleRadius;
}

void UUIMapOpPoisonCircle::SetPoisonCircle(const FVector& InCircleCenter, float InCircleRadius)
{
	pPoisonCircleWidget->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
	PoisonCircleCenter = InCircleCenter;
	PoisonCircleRadius = InCircleRadius;
}

void UUIMapOpPoisonCircle::SetPoisonProgress(UKMTextBlock* pInDistanceWidget, UKMProgressBar* pInProgressWidget, UWidget* pInSelfWidget, const FText& InFormatText)
{
	pDistanceWidget = pInDistanceWidget;
	pProgressWidget = pInProgressWidget;
	pSelfWidget = pInSelfWidget;
	FormatText = InFormatText;
}

void UUIMapOpPoisonCircle::InitParam(AActor* pInActor, UUIMapUserWidget* pInOwner, UWidget* pInWidget, UKMFFAMapElement* pInMapElementWidget)
{
	check(pInActor);
	if (pSelfActor)
	{
		UnBindActor(pSelfActor);
	}
	pSelfActor = pInActor;
	pOwner = pInOwner;
	pSafeCircleWidget = pInWidget;
	pPoisonCircleWidget = pInMapElementWidget;
	BindActor(pSelfActor);
}


void UUIMapOpPoisonCircle::OnNativeTick(float DeltaSeconds)
{
	UpdateSafeCircle(SafeCircleCenter, SafeCircleRadius, pSafeCircleWidget);
	UpdateSafeCircle(PoisonCircleCenter, PoisonCircleRadius, pPoisonCircleWidget);
	UpdatePoisonProgress();
}

void UUIMapOpPoisonCircle::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pSelfActor);
	pSelfActor = nullptr;
}

void UUIMapOpPoisonCircle::UpdateSafeCircle(FVector& InCenterPoint, float InCircleRadius, UWidget* pInWidget)
{
	if (pInWidget && pOwner)
	{
		FVector2D UILocation = pOwner->CalculateUIMapLocation(InCenterPoint);
		
		const FVector2D& UIMapValidSize = pOwner->GetUIMapValidSize();
		const FVector2D& Map3DSize = pOwner->Get3DMapSize();
		FVector2D UICircleSize = FVector2D(InCircleRadius / Map3DSize.X * UIMapValidSize.X, InCircleRadius / Map3DSize.Y * UIMapValidSize.Y) * 2;
		if (bMirror)
		{
			FVector2D UIMapSize = UIMapValidSize + pOwner->GetUIMapValidOffset() * 2;
			UILocation.X = UIMapSize.X - UILocation.X;
		}
		if (pInWidget)
		{
			UKMFFAMapElement* pMapWidget = Cast<UKMFFAMapElement>(pInWidget);
			if (pMapWidget)
			{
				pPoisonCircleWidget->SetCircleInfo(UILocation, UICircleSize, UIMapValidSize);
			}
			else
			{
				UCanvasPanelSlot* CanvasSlot = Cast<UCanvasPanelSlot>(pInWidget->Slot);
				if (CanvasSlot)
				{
					CanvasSlot->SetSize(UICircleSize);
					CanvasSlot->SetPosition(UILocation);
				}
			}
		}
	}
}

void UUIMapOpPoisonCircle::UpdatePoisonProgress()
{
	if(pSelfActor)
	{
		if(pProgressWidget)
		{
			float Progress = (PoisonCircleStartRadius - PoisonCircleRadius) / FMath::Max((PoisonCircleStartRadius - SafeCircleRadius), 1.0f);
			pProgressWidget->SetPercent(Progress, false);
			//UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpPoisonCircle::UpdatePoisonProgress,PoisonCircleStartRadius(%f) PoisonCircleRadius(%f) SafeCircleRadius(%f) Progress(%f) diffrence(%f)"), PoisonCircleStartRadius, PoisonCircleRadius, SafeCircleRadius, Progress, FMath::Max((PoisonCircleStartRadius - SafeCircleRadius), 1.0f));
		}
		if (pDistanceWidget)
		{
			FVector SelfLocation = pSelfActor->GetActorLocation();
			float nDistancePoison = FMath::Sqrt(FMath::Square(PoisonCircleCenter.X - SelfLocation.X) + FMath::Square(PoisonCircleCenter.Y - SelfLocation.Y));
			float nDistanceSafe = FMath::Sqrt(FMath::Square(SafeCircleCenter.X - SelfLocation.X) + FMath::Square(SafeCircleCenter.Y - SelfLocation.Y));
			EHorizontalAlignment HorizonAlignment = HAlign_Left;
			
			UOverlaySlot* pSelfSlot = Cast<UOverlaySlot>(pSelfWidget->Slot);
			UOverlaySlot* pDistanceSlot = Cast<UOverlaySlot>(pDistanceWidget->Slot);
			if (pSelfSlot && pDistanceSlot)
			{
				EHorizontalAlignment CurrentAlignment = pSelfSlot->HorizontalAlignment;
				if (SafeCircleRadius <= 0 || nDistanceSafe <= SafeCircleRadius)
				{
					pDistanceWidget->SetVisibility(ESlateVisibility::Collapsed);
					if (CurrentAlignment != HAlign_Right)
					{
						pSelfSlot->SetPadding(FMargin(0.f, 0.f, 0.f, 0.f));
					}
					HorizonAlignment = HAlign_Right;
				}
				else if(nDistanceSafe > SafeCircleRadius && nDistancePoison < PoisonCircleRadius)
				{
					pDistanceWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
					FVector2D DisWidgetSize = pDistanceWidget->GetCachedGeometry().GetLocalSize();
					FVector2D SelfWidgetSize = pSelfWidget->GetCachedGeometry().GetLocalSize();
					float HalfTotalSizeX = DisWidgetSize.X / 2 + SelfWidgetSize.X / 2;
					//FMargin CurrentMargin = FMargin(DisWidgetSize.X / 2 - HalfTotalSizeX, 0.f, 0.f, 0.f);
					FMargin CurrentMargin = FMargin(-DisWidgetSize.X / 2, 0.f, 0.f, 0.f);
					pDistanceSlot->SetPadding(CurrentMargin);
					//CurrentMargin.Left = HalfTotalSizeX - SelfWidgetSize.X / 2;
					CurrentMargin.Left = SelfWidgetSize.X / 2;
					pSelfSlot->SetPadding(CurrentMargin);
					HorizonAlignment = HAlign_Center;
				}
				else
				{
					pDistanceWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
					if(CurrentAlignment != HAlign_Left)
					{
						pDistanceWidget->SetJustification(ETextJustify::Center);
						FMargin ZeroMargin = FMargin(0.f, 0.f, 0.f, 0.f);
						pDistanceSlot->SetPadding(ZeroMargin);
						pSelfSlot->SetPadding(ZeroMargin);
					}
					HorizonAlignment = HAlign_Left;
				}
				
				pSelfSlot->SetHorizontalAlignment(HorizonAlignment);
			}
			if(pDistanceWidget->IsVisible())
			{
				nDistanceSafe = FMath::Max(0.f, nDistanceSafe - SafeCircleRadius);
				int32 nDistanceMeter = FMath::RoundToInt(nDistanceSafe / 100);
				FText ShowText = FText::Format(FormatText, FText::FromString(FString::FromInt(nDistanceMeter)));
				pDistanceWidget->SetText(ShowText);
			}
		}
		
	}
}

//标记连线
UUIMapOpFlagPointLine::UUIMapOpFlagPointLine(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pOwner(nullptr)
	, pSelfActor(nullptr)
	, nLastLandId(0)
	, nVisibleDistance(0.0)
	, SelfLastLocation(FVector::ZeroVector)
	, bTargetRegionVisible(true)
	, bSelfRegionVisible(true)
	, LandWeight(5.0f)
	, OceanWeight(1.0f)
	, bSwimming(false)
	, bHuman(false)
{
	LineNodeList.Empty();
	FlagPointInfoList.Empty();
	PathArray.Reserve(32);
	PathArray.Empty();
}

int32 UUIMapOpFlagPointLine::SetFlagLine(FVector InTargetLocation, UKMDottedLine* pInDottedLineWidget)
{
	LineNodeList.Empty();
	LineTargetLocation = InTargetLocation;
	pDottedLineWidget = pInDottedLineWidget;
	RefreshNodeList(LineNodeList, InTargetLocation);
	return LineNodeList.Num();
}

void UUIMapOpFlagPointLine::RemoveFlagLine()
{
	LineNodeList.Empty();
	pDottedLineWidget = nullptr;
}


int32 UUIMapOpFlagPointLine::AddFlagPoint(UWidget* pInWidget, FVector InTargetLocation, UKMTextBlock* pInTextWidget, const FText& InFormatText)
{
	int32 nAddUniqueId = pInWidget->GetUniqueID();
	int32 nPointCounts = FlagPointInfoList.Num();
	bool bExist = false;
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FFlagPointInfo& FlagPointInfo = FlagPointInfoList[i];
		int32 nUniqueId = FlagPointInfo.pWidget->GetUniqueID();
		if (nAddUniqueId == nUniqueId)
		{
			FlagPointInfo.TargetLocation = InTargetLocation;
			FlagPointInfo.FormatText = InFormatText;
			bExist = true;
			break;
		}
	}
	if (!bExist)
	{
		FlagPointInfoList.Add(FFlagPointInfo(pInWidget, InTargetLocation, pInTextWidget, InFormatText));
	}
	return nAddUniqueId;
}

void UUIMapOpFlagPointLine::RemoveFlagPoint(int32 nInUniqueId)
{
	int32 nPointCounts = FlagPointInfoList.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FFlagPointInfo& FlagInfo = FlagPointInfoList[i];
		int32 nUniqueId = FlagInfo.pWidget->GetUniqueID();
		if (nUniqueId == nInUniqueId)
		{
			//FlagInfo.pWidget->SetVisibility(ESlateVisibility::Collapsed);
			FlagPointInfoList.RemoveAt(i);
			break;
		}
	}
}

void UUIMapOpFlagPointLine::SetLineVisibleDistance(float nInVisibleDistance)
{
	nVisibleDistance = nInVisibleDistance;
	RefreshNodeList(LineNodeList, LineTargetLocation);
}

void UUIMapOpFlagPointLine::SetTargetRegionVisible(bool bInRegionVisible)
{
	bTargetRegionVisible = bInRegionVisible;
	RefreshNodeList(LineNodeList, LineTargetLocation);
}

void UUIMapOpFlagPointLine::SetSelfRegionVisible(bool bInRegionVisible)
{
	bSelfRegionVisible = bInRegionVisible;
	RefreshNodeList(LineNodeList, LineTargetLocation);
}

void UUIMapOpFlagPointLine::SetSelfIsSwimming(bool bInSwimming)
{
	bSwimming = bInSwimming;
	/*if (!bInSwimming && pSelfActor)
	{
		UPiratesGridTypeManager* GridTypeManager = UCommonShell::GetCommon(this)->GetGridTypeManager();
		FVector SelfLocation = pSelfActor->GetActorLocation();
		nLastLandId = GridTypeManager->GetLandID(SelfLocation.X, SelfLocation.Y);
	}*/
	RefreshNodeList(LineNodeList, LineTargetLocation);
}

void UUIMapOpFlagPointLine::InitParam(UUIMapUserWidget* pInOwner, AActor* pInActor, float InLandWeight, float InOceanWeight, bool bInHuman, int32 InLandId)
{
	check(pInActor);
	if (pSelfActor)
	{
		UnBindActor(pSelfActor);
	}
	pOwner = pInOwner;
	pSelfActor = pInActor;
	BindActor(pSelfActor);
	LandWeight = InLandWeight;
	OceanWeight = InOceanWeight;
	bHuman = bInHuman;
	/*UPiratesGridTypeManager* GridTypeManager = UCommonShell::GetCommon(this)->GetGridTypeManager();
	FVector SelfLocation = pSelfActor->GetActorLocation();
	nLastLandId = GridTypeManager->GetLandID(SelfLocation.X, SelfLocation.Y);*/
	nLastLandId = InLandId;
}

FVector UUIMapOpFlagPointLine::GetShortestDistanceLocation(TArray<FVector2D>& PosList, const FVector& TargetLocation)
{
	double nShortestDistanceSquare = (float)MAX_int64;
	FVector ShortestLocation;
	for (int32 i = 0; i < PosList.Num(); i++)
	{
		FVector2D& Pos = PosList[i];
		double nDistanceSquare = FMath::Square(TargetLocation.X - Pos.X) + FMath::Square(TargetLocation.Y - Pos.Y);
		if(nDistanceSquare < nShortestDistanceSquare)
		{
			nShortestDistanceSquare = nDistanceSquare;
			ShortestLocation.X = Pos.X;
			ShortestLocation.Y = Pos.Y;
		}
	}
	return ShortestLocation;
}

void UUIMapOpFlagPointLine::DrawFlagLine(const FVector& InSelfLocation)
{
	if (pDottedLineWidget == nullptr)
	{
		return;
	}
	pDottedLineWidget->EmptyPointList();
	if (LineNodeList.Num() == 0)
	{
		return;
	}
	pDottedLineWidget->AddPoint(pOwner->CalculateUIMapLocation(InSelfLocation));
	for (int32 i = 0; i < LineNodeList.Num(); i++)
	{
		FVector2D& NodeLocation = LineNodeList[i];
		pDottedLineWidget->AddPoint(pOwner->CalculateUIMapLocation(FVector(NodeLocation.X, NodeLocation.Y, 0.f)));
	}
	pDottedLineWidget->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
}

void UUIMapOpFlagPointLine::RefreshNodeList(TArray<FVector2D>& NodeList, const FVector& InTargetLocation)
{
	if (pSelfActor == nullptr || pDottedLineWidget == nullptr)
	{
		return;
	}
	LineNodeList.Empty(4);
	UPiratesGridTypeManager* GridTypeManager = UCommonShell::GetCommon(this)->GetGridTypeManager();
	FVector SelfLocation = pSelfActor->GetActorLocation();
	FVector2D UISelfLocation = pOwner->CalculateUIMapLocation(SelfLocation);
	FVector2D TargetLocation2D = FVector2D(InTargetLocation);
	FVector2D UITargetPos = pOwner->CalculateUIMapLocation(InTargetLocation);
	EPiratesGridRegionType SelfRegionType = GridTypeManager->GetRegionType(SelfLocation.X, SelfLocation.Y);
	int32 nSelfLandId = 0;
	if (bSelfRegionVisible)
	{
		if (SelfRegionType == EPiratesGridRegionType::Land || SelfRegionType == EPiratesGridRegionType::Shore)
		{
			nSelfLandId = GridTypeManager->GetLandID(SelfLocation.X, SelfLocation.Y);
		}
		else if (bSwimming && nLastLandId > 0)
		{
			nSelfLandId = nLastLandId;
		}
		else if (bHuman/* || SelfRegionType == EPiratesGridRegionType::Rock || SelfRegionType == EPiratesGridRegionType::Lake*/)
		{
			FVector2D ClosestLocation;
			GridTypeManager->GetClosestPositionOfRegionType(SelfLocation.X, SelfLocation.Y, EPiratesGridRegionType::Shore, ClosestLocation);
			nSelfLandId = GridTypeManager->GetLandID(ClosestLocation.X, ClosestLocation.Y);
		}
	}
	
	int32 nTargetLandId = 0;
	EPiratesGridRegionType TargetRegionType = GridTypeManager->GetRegionType(InTargetLocation.X, InTargetLocation.Y);
	if (bTargetRegionVisible)
	{
		if (TargetRegionType == EPiratesGridRegionType::Land || TargetRegionType == EPiratesGridRegionType::Shore)
		{
			nTargetLandId = GridTypeManager->GetLandID(InTargetLocation.X, InTargetLocation.Y);
		}
		else if (TargetRegionType == EPiratesGridRegionType::Rock || TargetRegionType == EPiratesGridRegionType::Lake || TargetRegionType == EPiratesGridRegionType::Port )
		{
			FVector2D ClosestLocation;
			GridTypeManager->GetClosestPositionOfRegionType(InTargetLocation.X, InTargetLocation.Y, EPiratesGridRegionType::Shore, ClosestLocation);
			nTargetLandId = GridTypeManager->GetLandID(ClosestLocation.X, ClosestLocation.Y);
		}
	}
	if (nSelfLandId == nTargetLandId)
	{
		LineNodeList.Add(TargetLocation2D);
	}
	else
	{
		PathArray.Empty();
		TArray<FVector2D> MarkPosList;
		MarkPosList.Reserve(32);
		FVector NextNodeLocation = SelfLocation;
		if (nSelfLandId != 0)
		{
			bool bResult = GridTypeManager->GetMarkPositions(nSelfLandId, EPiratesGridRegionType::Shore, MarkPosList);
			if (bResult)
			{
				for (FVector2D& Pos : MarkPosList)
				{
					PathArray.Add(FPathNodeInfo(Pos, LandWeight));
				}
			}
		}
		MarkPosList.Empty();
		float TargetWeight = OceanWeight;
		if (nTargetLandId != 0)
		{
			TargetWeight = LandWeight;
			bool bResult = GridTypeManager->GetMarkPositions(nTargetLandId, EPiratesGridRegionType::Shore, MarkPosList);
			if (bResult)
			{
				if (PathArray.Num() == 0)
				{
					for (FVector2D& Pos : MarkPosList)
					{
						PathArray.Add(FPathNodeInfo(Pos, OceanWeight));
					}
				}
				else
				{
					for (FPathNodeInfo& Node : PathArray)
					{
						for (FVector2D& Pos : MarkPosList)
						{
							Node.NextTargetList.Add(FPathNodeInfo(Pos, OceanWeight));
						}
					}
				}
				
			}
		}
		double nShortestDistanceSquare = (float)MAX_int64;
		double nPathDistance = 0.0;
		FVector2D SelfLocation2D = FVector2D(SelfLocation);
		for (FPathNodeInfo& Node : PathArray)
		{
			//nPathDistance = FVector2D::DistSquared(SelfLocation2D, Node.NodePos);
			if (Node.NextTargetList.Num() > 0)
			{
				for (FPathNodeInfo& NextNode : Node.NextTargetList)
				{
					nPathDistance = FVector2D::DistSquared(SelfLocation2D, Node.NodePos) * Node.Weight;
					nPathDistance += FVector2D::DistSquared(Node.NodePos, NextNode.NodePos) * NextNode.Weight;
					nPathDistance += FVector2D::DistSquared(NextNode.NodePos, TargetLocation2D) * TargetWeight;
					if (nPathDistance < nShortestDistanceSquare)
					{
						if (LineNodeList.Num() == 0)
						{
							LineNodeList.Add(Node.NodePos);
							LineNodeList.Add(NextNode.NodePos);
							LineNodeList.Add(TargetLocation2D);
						}
						else
						{
							LineNodeList[0] = Node.NodePos;
							LineNodeList[1] = NextNode.NodePos;
							LineNodeList[2] = TargetLocation2D;
						}
						nShortestDistanceSquare = nPathDistance;
					}
				}
			}
			else
			{
				nPathDistance = FVector2D::DistSquared(SelfLocation2D, Node.NodePos) * Node.Weight;
				nPathDistance += FVector2D::DistSquared(Node.NodePos, TargetLocation2D) * TargetWeight;
				if (nPathDistance < nShortestDistanceSquare)
				{
					if (LineNodeList.Num() == 0)
					{
						LineNodeList.Add(Node.NodePos);
						LineNodeList.Add(TargetLocation2D);
					}
					else
					{
						LineNodeList[0] = Node.NodePos;
						LineNodeList[1] = TargetLocation2D;
					}
					nShortestDistanceSquare = nPathDistance;
				}
			}
			
			
		}

	}
	DrawFlagLine(SelfLocation);
}


void UUIMapOpFlagPointLine::OnNativeTick(float DeltaSeconds)
{
	
	if(pOwner && pSelfActor)
	{
		FVector SelfLocation = pSelfActor->GetActorLocation();
		FVector TargetLocation = SelfLocation;
		FVector2D TargetLocation2D = FVector2D(TargetLocation);
		FVector2D UISelfLocation = pOwner->CalculateUIMapLocation(SelfLocation);
		FVector2D LastUILocation = UISelfLocation;
		FVector2D UIFlagLocation;
		FVector2D UISize;
		FVector2D Origin;
		FVector2D Alignment;
		const FVector2D& UIMapValidSize = pOwner->GetUIMapValidSize();
		const FVector2D& Map3DSize = pOwner->Get3DMapSize();

		if (pDottedLineWidget && LineNodeList.Num() > 0)
		{
			if (FVector::Dist2D(SelfLocation, LineTargetLocation) > nVisibleDistance)
			{
				LastTickDeltaSeconds += DeltaSeconds;
				if (LastTickDeltaSeconds >= TickInterval /*&& LineNodeList.Num() > 0*/ && !SelfLocation.Equals(SelfLastLocation, 0.1))
				{
					RefreshNodeList(LineNodeList, LineTargetLocation);
					LastTickDeltaSeconds = 0;
				}
				
				DrawFlagLine(SelfLocation);
			}
			else
			{
				pDottedLineWidget->SetVisibility(ESlateVisibility::Collapsed);
			}
		}
		
		 
		for (FFlagPointInfo FlagInfo : FlagPointInfoList)
		{
			if (FlagInfo.pWidget)
			{
				FVector2D UILocation = pOwner->CalculateUIMapLocation(FlagInfo.TargetLocation);
				UCanvasPanelSlot* WidgetSlot = Cast<UCanvasPanelSlot>(FlagInfo.pWidget->Slot);
				if (WidgetSlot)
				{
					WidgetSlot->SetPosition(UILocation);
				}
			}
			if (FlagInfo.pTextWidget)
			{
				float nDistance = FMath::Sqrt(FMath::Square(FlagInfo.TargetLocation.X - SelfLocation.X) + FMath::Square(FlagInfo.TargetLocation.Y - SelfLocation.Y));
				int32 nDistanceMeter = FMath::RoundToInt(nDistance / 100);
				FText ShowText = FText::Format(FlagInfo.FormatText, FText::FromString(FString::FromInt(nDistanceMeter)));
				FlagInfo.pTextWidget->SetText(ShowText);
			}
		}
		SelfLastLocation = SelfLocation;
	}
	
}

void UUIMapOpFlagPointLine::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pSelfActor);
	pSelfActor = nullptr;
}

//方向罗盘
UUIMapOpCompass::UUIMapOpCompass(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pCompassWidget(nullptr)
	, nFactor(6.58)
	, Rotation(FRotator(180.f, 180.f, 180.f))
	, pSelfActor(nullptr)
	, nFlagPointIndex(0)
	, pOwner(nullptr)
	, nCriticalDegreeOffset(0.f)
{

}



void UUIMapOpCompass::InitParam(AActor* pInSelfActor, UUIMapUserWidget* pInOwner, UWidget* pInCompassWidget, float nInFactor, FRotator InRotation, float nInCriticalDegreeOffset)
{
	check(pInSelfActor && pInOwner && pInCompassWidget);
	if (pSelfActor)
	{
		UnBindActor(pSelfActor);
	}
	pSelfActor = pInSelfActor;
	BindActor(pSelfActor);
	pCompassWidget = pInCompassWidget;
	nFactor = nInFactor;
	Rotation = InRotation;
	pOwner = pInOwner;
	nCriticalDegreeOffset = nInCriticalDegreeOffset;
}


void UUIMapOpCompass::OnNativeTick(float DeltaSeconds)
{
	if (pCompassWidget && pSelfActor != nullptr)
	{
		APlayerCameraManager* pPlayerCamera = UGameplayStatics::GetPlayerCameraManager(this, 0);
		if (!pPlayerCamera)
		{
			return;
		}
		FRotator CameraRotation = pPlayerCamera->GetCameraRotation();
		FRotator Delta = CameraRotation - Rotation;
		Delta.Normalize();
		float UIPosX = Delta.Yaw * -1 * nFactor;

		UCanvasPanelSlot* pCanvasSlot = Cast<UCanvasPanelSlot>(pCompassWidget->Slot);
		if (pCanvasSlot)
		{
			pCanvasSlot->SetPosition(FVector2D(UIPosX, 0.f));
		}
		
		//标记点
		const FVector SelfLocation = pSelfActor->GetActorLocation();
		FVector2D UISelfLocaton = pOwner->CalculateUIMapLocation(SelfLocation);
		int32 nPointNum = FlagPointInfoList.Num();
		FVector2D FlagUILocation;
		float FlagUIPosX;
		FRotator FlagRotator = FRotator(CameraRotation.Pitch, 0.0, CameraRotation.Roll);
		FRotator FlagDelta;
		for(int i = 0; i < nPointNum; i++)
		{
			FFlagPoint& FlagPoint = FlagPointInfoList[i];
			FlagUILocation = pOwner->CalculateUIMapLocation(FlagPoint.PointLocation);
			float nOffsetX = FlagUILocation.X - UISelfLocaton.X;
			float nOffsetY = FlagUILocation.Y - UISelfLocaton.Y;
			float nDegree = FMath::RadiansToDegrees(FMath::Atan2(nOffsetY, nOffsetX));
			FlagRotator.Yaw = nDegree;
			FlagDelta = FlagRotator - Rotation;
			FlagDelta.Normalize();
			FlagUIPosX = FlagDelta.Yaw * nFactor;

			//标记点与东方向修正角度在临界角度（180/-180 +/- 偏移角度）时，且与玩家摄像机朝向的夹角在某个偏移范围内，修正标记点的位置
			if (FlagDelta.Yaw >= (180 - nCriticalDegreeOffset) && (FlagDelta.Yaw - Delta.Yaw) > (360 - nCriticalDegreeOffset * 2))
			{
				FlagUIPosX = FlagUIPosX - 360 * nFactor;
			}
			else if (FlagDelta.Yaw <= (-180 + nCriticalDegreeOffset) && (FlagDelta.Yaw - Delta.Yaw) < (-360 + nCriticalDegreeOffset * 2))
			{
				FlagUIPosX = FlagUIPosX + 360 * nFactor;
			}
			
			//UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpCompass::CalculatePoint,nDegree(%f) CameraRotation(%f,%f,%f) UIPosX(%f) FlagUIPosX(%f) FlagDelta(%f) Delta(%f)"), nDegree, CameraRotation.Pitch, CameraRotation.Yaw, CameraRotation.Roll, UIPosX, FlagUIPosX, FlagDelta.Yaw, Delta.Yaw);
			pCanvasSlot = Cast<UCanvasPanelSlot>(FlagPoint.pWidget->Slot);
			if (pCanvasSlot)
			{
				pCanvasSlot->SetPosition(FVector2D(FlagUIPosX, 0.f));
			}
			if (FlagPoint.pTextWidget)
			{
				float nDistance = FMath::Sqrt(FMath::Square(FlagPoint.PointLocation.X - SelfLocation.X) + FMath::Square(FlagPoint.PointLocation.Y - SelfLocation.Y));
				int32 nDistanceMeter = FMath::RoundToInt(nDistance / 100);
				FText ShowText = FText::Format(FlagPoint.FormatText, FText::FromString(FString::FromInt(nDistanceMeter)));
				FlagPoint.pTextWidget->SetText(ShowText);
			}
		}
	}

}


int32 UUIMapOpCompass::AddFlagPoint(UWidget* pInWidget, UTextBlock* pInTextWidget, const FText& InFormatText, const FVector& InLocation)
{
	check(pInWidget);
	FlagPointInfoList.Add(FFlagPoint(nFlagPointIndex, pInWidget, pInTextWidget, InFormatText, InLocation));

	return nFlagPointIndex++;
}

void UUIMapOpCompass::RemoveFlagPoint(int32 nPointIndex)
{
	int32 nPointCounts = FlagPointInfoList.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FFlagPoint& FlagPoint = FlagPointInfoList[i];
		if (FlagPoint.nPointIndex == nPointIndex)
		{
			FlagPointInfoList.RemoveAt(i);
			break;
		}
	}
}

void UUIMapOpCompass::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pSelfActor);
	pSelfActor = nullptr;
}


UUIMapOpSafeCirclePath::UUIMapOpSafeCirclePath(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , pSelfActor(nullptr)
    , pOwner(nullptr)
    , pWidget(nullptr)
    , SafeCircleCenter(FVector(0, 0, 0))
    , SafeCircleRadius(0.0f)
{

}


void UUIMapOpSafeCirclePath::InitParam(AActor* pInActor, UUIMapUserWidget* pInOwner)
{
    check(pInActor);
    if (pSelfActor)
    {
        UnBindActor(pSelfActor);
    }
    pOwner = pInOwner;
    pSelfActor = pInActor;
    BindActor(pSelfActor);
}

void UUIMapOpSafeCirclePath::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pSelfActor);
    pSelfActor = nullptr;
}


void UUIMapOpSafeCirclePath::SetSafeCircle(const FVector& InCircleCenter, float InCircleRadius, UWidget* pInLineWidget)
{
    SafeCircleCenter = InCircleCenter;
    SafeCircleRadius = InCircleRadius;
    pWidget = pInLineWidget;
}

void UUIMapOpSafeCirclePath::OnNativeTick(float DeltaSeconds)
{
    if (pOwner && pSelfActor && pWidget)
    {
        FVector SelfLocation = pSelfActor->GetActorLocation();
        FVector2D UISelfLocation = pOwner->CalculateUIMapLocation(SelfLocation);
        FVector2D UIFlagLocation = pOwner->CalculateUIMapLocation(SafeCircleCenter);
        FVector2D UISize;
        FVector2D Origin;
        FVector2D Alignment;
        const FVector2D& UIMapValidSize = pOwner->GetUIMapValidSize();
        if (bMirror)
        {
            FVector2D UIMapSize = UIMapValidSize + pOwner->GetUIMapValidOffset() * 2;
            UISelfLocation.X = UIMapSize.X - UISelfLocation.X;
            UIFlagLocation.X = UIMapSize.X - UIFlagLocation.X;
        }

        float ToCenter = FVector::Dist2D(SelfLocation, SafeCircleCenter);
        if (ToCenter <= SafeCircleRadius)
        {
            pWidget->SetVisibility(ESlateVisibility::Collapsed);
            return;
        }

        pWidget->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
        UISize = UIFlagLocation - UISelfLocation;
        UISize.X = FMath::Abs(UISize.X);
        UISize.Y = FMath::Abs(UISize.Y);
        float Distance = FVector2D::Distance(UISelfLocation, UIFlagLocation);

        Origin = FVector2D(FMath::Min(UISelfLocation.X, UIFlagLocation.X), FMath::Min(UISelfLocation.Y, UIFlagLocation.Y));
        Alignment = FVector2D((UISelfLocation.X - Origin.X) / UISize.X, (UISelfLocation.Y - Origin.Y) / UISize.Y);
        UCanvasPanelSlot* pCanvasSlot = Cast<UCanvasPanelSlot>(pWidget->Slot);
        if (pCanvasSlot)
        {
            pCanvasSlot->SetSize(UISize);
            pCanvasSlot->SetAlignment(Alignment);
            pCanvasSlot->SetPosition(UISelfLocation);
        }
  
    }

}

UUIMapOpFFATeamMember::UUIMapOpFFATeamMember(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pOwner(nullptr)
	, pSelfActor(nullptr)
	, pMapWidget(nullptr)
	, bShowInRange(false)
	, ShowRange(FVector2D(1.0, 1.0))
	, ShowOffset(FVector2D::ZeroVector)
{
}

void UUIMapOpFFATeamMember::OnNativeTick(float DeltaSeconds)
{
	if (pOwner == nullptr || pSelfActor == nullptr)
	{
		return;
	}
	FVector2D UISelfLocation = pOwner->CalculateUIMapLocation(pSelfActor->K2_GetActorLocation());
	FVector2D UITargetLocation, OrientationPos, AbsoluteOrientation, OrientationLocal;
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FContentPoint& ContentPoint = ContentPointArray[i];
		AActor* pActor = ContentPoint.pContentActor;
		UWidget* pWidget = ContentPoint.pContentWidget;
		UITargetLocation = pOwner->CalculateUIMapLocation(pActor->K2_GetActorLocation());
		float nDis = FVector2D::Distance(UISelfLocation, UITargetLocation);
		
		
		float nRangeK = ShowRange.Y / ShowRange.X;
		FVector2D Diff = UITargetLocation - UISelfLocation;
		float nDiffSize = Diff.Size();
		float nPointK = FMath::Abs(Diff.Y / Diff.X);
		FVector2D SignDiff = Diff.GetSignVector();
		if (bShowInRange)
		{
			if (nPointK >= nRangeK)
			{
				float nPointSize = FMath::Abs(nDiffSize / Diff.Y * ShowRange.Y);
				if (nDis > nPointSize)
				{
					OrientationPos.X = UISelfLocation.X + Diff.X / nDiffSize * nPointSize + ShowOffset.X;
					OrientationPos.Y = UISelfLocation.Y + ShowRange.Y * SignDiff.Y + ShowOffset.Y;
					ContentPoint.pRotationWidget->SetVisibility(ESlateVisibility::Collapsed);
					ContentPoint.pStateWidget->SetVisibility(ESlateVisibility::Collapsed);
					ContentPoint.pStateWidgetEx->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
				}
				else
				{
					OrientationPos = UITargetLocation;
					ContentPoint.pRotationWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
					ContentPoint.pStateWidget->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
					ContentPoint.pStateWidgetEx->SetVisibility(ESlateVisibility::Collapsed);
				}

			}
			else
			{
				float nPointSize = FMath::Abs(nDiffSize / Diff.X * ShowRange.X);
				if (nDis > nPointSize)
				{
					OrientationPos.X = UISelfLocation.X + ShowRange.X * SignDiff.X + ShowOffset.X;
					OrientationPos.Y = UISelfLocation.Y + Diff.Y / nDiffSize * nPointSize + ShowOffset.Y;
					ContentPoint.pRotationWidget->SetVisibility(ESlateVisibility::Collapsed);
					ContentPoint.pStateWidget->SetVisibility(ESlateVisibility::Collapsed);
					ContentPoint.pStateWidgetEx->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
				}
				else
				{
					OrientationPos = UITargetLocation;
					ContentPoint.pRotationWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
					ContentPoint.pStateWidget->SetVisibility(ESlateVisibility::SelfHitTestInvisible);
					ContentPoint.pStateWidgetEx->SetVisibility(ESlateVisibility::Collapsed);
				}
			}
		}
		else
		{
			OrientationPos = UITargetLocation;
		}
		
		if (bMirror)
		{
			FVector2D UIMapSize = pOwner->GetUIMapValidSize() + pOwner->GetUIMapValidOffset() * 2;
			OrientationPos.X = UIMapSize.X - OrientationPos.X;
		}
		/*UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpOrientationWithActor::CalculatePoint,Diff(%f,%f) SignDiff(%f,%f) nRangeK(%f) nPointK(%f) OrientationPos(%f,%f)"), Diff.X, Diff.Y, SignDiff.X, SignDiff.Y
			, nRangeK, nPointK, OrientationPos.X, OrientationPos.Y);*/
		

		/*AbsoluteOrientation = pMapWidget->GetCachedGeometry().LocalToAbsolute(OrientationPos);
		OrientationLocal = pOrientationRoot->GetCachedGeometry().AbsoluteToLocal(AbsoluteOrientation);*/
		UCanvasPanelSlot* WidgetSlot = Cast<UCanvasPanelSlot>(pWidget->Slot);
		if (WidgetSlot)
		{
			WidgetSlot->SetPosition(OrientationPos);
		}
		if (ContentPoint.bCanRotation)
		{
			FRotator Rotation = pActor->K2_GetActorRotation();

			if (bMirror)
			{
				ContentPoint.pRotationWidget->SetRenderTransformAngle(180 - Rotation.Yaw);
			}
			else
			{
				ContentPoint.pRotationWidget->SetRenderTransformAngle(Rotation.Yaw);
			}
			//pWidget->SetRenderTransformAngle(Rotation.Yaw);
		}

	}
}

void UUIMapOpFFATeamMember::InitParam(UUIMapUserWidget* pInOwner, AActor* pInSelfActor, UWidget* pInMapWidget, bool bInShowInRange, FVector2D InShowRange, FVector2D InOffset)
{
	check(pInOwner && pInSelfActor && pInMapWidget);
	pOwner = pInOwner;
	if (pSelfActor)
	{
		UnBindActor(pSelfActor);
		RemoveContentPoint(pSelfActor->GetUniqueID());
	}
	pSelfActor = pInSelfActor;
	BindActor(pSelfActor);
	pMapWidget = pInMapWidget;
	bShowInRange = bInShowInRange;
	ShowRange = InShowRange;
	ShowOffset = InOffset;
}

void UUIMapOpFFATeamMember::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	int32 nUniqueId = Actor->GetUniqueID();
	RemoveContentPoint(nUniqueId);
	if (pSelfActor && nUniqueId == pSelfActor->GetUniqueID())
	{
		UnBindActor(pSelfActor);
		pSelfActor = nullptr;
	}
}

int32 UUIMapOpFFATeamMember::AddContentPoint(AActor* pInActor, UWidget* pInWidget, UWidget* pInRotationWidget, UWidget* pInStateWidget, UWidget* pInStateWidgetEx, bool bInCanRotation)
{
	check(pInActor && pInWidget);
	int32 nUniqueId = pInActor->GetUniqueID();
	if (!CheckActorExist(nUniqueId))
	{
		ContentPointArray.Add(FContentPoint(pInActor, pInWidget, pInRotationWidget, pInStateWidget, pInStateWidgetEx, bInCanRotation));
		BindActor(pInActor);
	}
	return nUniqueId;
}

void UUIMapOpFFATeamMember::RemoveContentPoint(int32 nId)
{
	if (pSelfActor && nId == pSelfActor->GetUniqueID())
	{
		UnBindActor(pSelfActor);
		pSelfActor = nullptr;
	}
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FContentPoint& ContentPoint = ContentPointArray[i];
		int32 nUniqueId = ContentPoint.pContentActor->GetUniqueID();
		if (nUniqueId == nId)
		{
			UnBindActor(ContentPoint.pContentActor);
			ContentPointArray.RemoveAt(i);
			break;
		}
	}
}

bool UUIMapOpFFATeamMember::CheckActorExist(int32 nInUniqueId)
{
	int32 nPointCounts = ContentPointArray.Num();
	for (int i = 0; i < nPointCounts; i++)
	{
		AActor* pActor = ContentPointArray[i].pContentActor;
		if (pActor != nullptr && pActor->GetUniqueID() == nInUniqueId)
		{
			return true;
		}
	}
	return false;
}


//队友头像名字显示图标
UUIMapOpFFATeamMemberHead::UUIMapOpFFATeamMemberHead(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pOwner(nullptr)
	, pSelfActor(nullptr)
	, pCameraMngr(nullptr)
	, pPlayerController(nullptr)
	, BorderLeftTop(FVector2D::ZeroVector)
	, BorderRightBottom(FVector2D(1920.f, 1080.f))
	, pHeadRootWidget(nullptr)
	, ShowDist(1000.f)
	, HeadOffset(100.f)
	, CutoutSpacerWidth(0.f)
{
	DistanceFormatText = LOCTEXT("UIMapOpFFATeamMemberHead", "{0}m");
}

void UUIMapOpFFATeamMemberHead::OnNativeTick(float DeltaSeconds)
{
	if (pOwner == nullptr || pSelfActor == nullptr || pPlayerController == nullptr || pCameraMngr == nullptr)
	{
		return;
	}
	FVector SelfLocation = pSelfActor->GetActorLocation();
	FTransform ActorTransform = pCameraMngr->GetTransform();
	FRotator Rotation;
	int32 nPointCounts = ContentPointArray.Num();
	FVector2D UILocation;
	FRotator CameraRotation = pCameraMngr->GetCameraRotation();
	FVector SelfFowardLocation = CameraRotation.Vector().GetSafeNormal();
	FVector2D UIScreenPos;
	FVector2D AbsoluteCoordinate;
	FVector2D ViewPortSize = UWidgetLayoutLibrary::GetViewportSize(this);
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FHeadNamePoint& ContentPoint = ContentPointArray[i];
		if (ContentPoint.pContentActor == pSelfActor)
		{
			ContentPoint.pMainDistBgWidget->SetVisibility(ESlateVisibility::Collapsed);
			ContentPoint.pHeadDistBgWidget->SetVisibility(ESlateVisibility::Collapsed);
			ContentPoint.pMainHeadWidget->SetVisibility(ESlateVisibility::Collapsed);
			ContentPoint.pHeadWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
			continue;
		}
		FVector ActorLocation = ContentPoint.pContentActor->GetActorLocation();
		ActorLocation.Z += HeadOffset;
		FVector RelativeLocation = ActorTransform.InverseTransformPosition(ActorLocation);
		Rotation = UKismetMathLibrary::FindLookAtRotation(SelfFowardLocation, RelativeLocation);
		float nDist = FVector::Distance(SelfLocation, ActorLocation) / 100;
		if (nDist > ShowDist)
		{
			ContentPoint.pMainDistBgWidget->SetVisibility(ESlateVisibility::Collapsed);
			ContentPoint.pHeadDistBgWidget->SetVisibility(ESlateVisibility::Collapsed);
		}
		else
		{
			ContentPoint.pMainDistBgWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
			ContentPoint.pHeadDistBgWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
			FText FomatText = FText::Format(DistanceFormatText, (int32)nDist);
			ContentPoint.pMainDistWidget->SetText(FomatText);
			ContentPoint.pHeadDistWidget->SetText(FomatText);
		}
		
		//ContentPoint.pRotationWidget->SetRenderTransformAngle(Rotation.Yaw - 90);
		UWorld* ThisWorld = GetWorld();
		//if (ThisWorld->GetTimeSeconds() - ContentPoint.pContentActor->GetLastRenderTime() < 0.1f)
		{
			bool bRet = pPlayerController->ProjectWorldLocationToScreen(ActorLocation, UIScreenPos, false);
			if (bRet)
			{
				
				//if (FMath::Abs(Rotation.Yaw) > (nHalfFov + 5) || FMath::Abs(FMath::RadiansToDegrees(angleUp) - 90) > PitchScope)
				bool bOutOfXRange = false;
				bool bOutOfYTopRange = false;
				bool bOutOfYBottomRange = false;
				if (UIScreenPos.X <= 0.f || UIScreenPos.X >= ViewPortSize.X)
				{
					bOutOfXRange = true;
				}
				if (UIScreenPos.Y <= 0.f)
				{
					bOutOfYTopRange = true;
				}
				else if (UIScreenPos.Y >= ViewPortSize.Y)
				{
					bOutOfYBottomRange = true;
				}
				if (bOutOfXRange || bOutOfYTopRange || bOutOfYBottomRange)
				{
					if (bOutOfYBottomRange)
					{
						ContentPoint.pRotationWidget->SetRenderTransformAngle(Rotation.Pitch + Rotation.Yaw + 90);
					}
					else
					{
						ContentPoint.pRotationWidget->SetRenderTransformAngle(Rotation.Yaw - 90);
					}
					USlateBlueprintLibrary::ScreenToWidgetAbsolute(this, UIScreenPos, AbsoluteCoordinate);
					ContentPoint.pMainHeadWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
					//ContentPoint.pMainDistWidget->SetText(FomatText);
					//ContentPoint.pHeadDistWidget->SetText(FomatText);
					ContentPoint.pHeadWidget->SetVisibility(ESlateVisibility::Collapsed);
					//ContentPoint.pRotationWidget->SetRenderTransformAngle(Rotation.Yaw - 90);

					UILocation = pHeadRootWidget->GetCachedGeometry().AbsoluteToLocal(AbsoluteCoordinate);
					UILocation.X = FMath::Clamp(UILocation.X, BorderLeftTop.X, BorderRightBottom.X - CutoutSpacerWidth);
					UILocation.Y = FMath::Clamp(UILocation.Y, BorderLeftTop.Y, BorderRightBottom.Y);
					/*UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::OnNativeTick,Rotation(%f,%f,%f) CameraRotation(%f,%f,%f) PitchScope(%f) UIScreenPos(%f,%f) UILocation(%f, %f)"),
						Rotation.Yaw, Rotation.Pitch, Rotation.Roll, CameraRotation.Yaw, CameraRotation.Pitch, CameraRotation.Roll, PitchScope
					, UIScreenPos.X, UIScreenPos.Y, UILocation.X, UILocation.Y);*/
				}
				else
				{
					ContentPoint.pRotationWidget->SetRenderTransformAngle(Rotation.Yaw - 90);
					ContentPoint.pMainHeadWidget->SetVisibility(ESlateVisibility::Collapsed);
					ContentPoint.pHeadWidget->SetVisibility(ESlateVisibility::HitTestInvisible);
					//ContentPoint.pHeadDistWidget->SetText(FomatText);
				}
				
			}
			else
			{
				/*UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::OnNativeTick,Rotation(%f,%f,%f) CameraRotation(%f,%f,%f) UIScreenPos(%f,%f) UILocation(%f, %f)"),
					Rotation.Yaw, Rotation.Pitch, Rotation.Roll, CameraRotation.Yaw, CameraRotation.Pitch, CameraRotation.Roll
					, UIScreenPos.X, UIScreenPos.Y, UILocation.X, UILocation.Y);*/
				ContentPoint.pRotationWidget->SetRenderTransformAngle(Rotation.Pitch + Rotation.Yaw + 270);
				UILocation.X = BorderRightBottom.Y / FMath::Tan(FMath::DegreesToRadians(Rotation.Yaw - 270));
				UILocation.X = FMath::Clamp(UILocation.X, BorderLeftTop.X, BorderRightBottom.X - CutoutSpacerWidth);
				UILocation.Y = BorderRightBottom.Y;
			}
		}
		
		UCanvasPanelSlot* WidgetSlot = Cast<UCanvasPanelSlot>(ContentPoint.pMainHeadWidget->Slot);
		if (WidgetSlot)
		{
			WidgetSlot->SetPosition(UILocation);
		}

	}
}

void UUIMapOpFFATeamMemberHead::InitParam(UUIMapUserWidget* pInOwner, AActor* pInSelfActor, UWidget* pInHeadRootWidget, FVector2D InBorderLeftTop, FVector2D InBorderRightBottom, float InShowDist, float InHeadOffset, float InCutoutSpacerWidth)
{
	check(pInOwner && pInSelfActor && pInHeadRootWidget);
	pOwner = pInOwner;
	if (pSelfActor)
	{
		UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::InitParam,nUniqueId(%d)"), pSelfActor->GetUniqueID());
		UnBindActor(pSelfActor);
		RemoveContentPoint(pSelfActor->GetUniqueID());
		
	}
	
	pSelfActor = pInSelfActor;
	BindActor(pSelfActor);
	pHeadRootWidget = pInHeadRootWidget;
	BorderLeftTop = InBorderLeftTop;
	BorderRightBottom = InBorderRightBottom;
	ShowDist = InShowDist;
	HeadOffset = InHeadOffset;
	CutoutSpacerWidth = InCutoutSpacerWidth;
	UWorld* ThisWorld = GetWorld();
	if (ThisWorld != nullptr)
	{
		if (pCameraMngr == nullptr)
		{
			pCameraMngr = UGameplayStatics::GetPlayerCameraManager(ThisWorld, 0);
			if (pCameraMngr != nullptr)
			{
				BindActor(pCameraMngr);
			}
		}
		if (pPlayerController == nullptr)
		{
			pPlayerController = UGameplayStatics::GetPlayerController(ThisWorld, 0);
			if (pPlayerController != nullptr)
			{
				BindActor(pPlayerController);
			}
		}
	}
}

void UUIMapOpFFATeamMemberHead::SetDistanceFormatText(const FText& InFormateText)
{
	DistanceFormatText = InFormateText;
}

void UUIMapOpFFATeamMemberHead::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	int32 nUniqueId = Actor->GetUniqueID();
	UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::OnActorDestroy,nUniqueId(%d)"), nUniqueId);
	if (pCameraMngr && nUniqueId == pCameraMngr->GetUniqueID())
	{
		UnBindActor(pCameraMngr);
		pCameraMngr = nullptr;
	}
	if (pSelfActor && nUniqueId == pSelfActor->GetUniqueID())
	{
		UnBindActor(pSelfActor);
		pSelfActor = nullptr;
	}
	if (pPlayerController && nUniqueId == pPlayerController->GetUniqueID())
	{
		UnBindActor(pPlayerController);
		pPlayerController = nullptr;
	}
	RemoveContentPoint(nUniqueId);
}

int32 UUIMapOpFFATeamMemberHead::AddContentPoint(AActor* pInActor, UWidget* pInMainHeadWidget, UWidget* pInMainDistBgWidget, UTextBlock* pMainDistWidget, UWidget* pInHeadWidget, UWidget* pInHeadDistBgWidget, UTextBlock* pInHeadDistWidget, UWidget* pInRotationWidget, bool bInCanRotation)
{
	check(pInActor && pInMainHeadWidget && pMainDistWidget && pInHeadWidget && pInHeadDistWidget && pInRotationWidget);
	int32 nUniqueId = pInActor->GetUniqueID();
	UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::AddContentPoint,nUniqueId(%d)"), nUniqueId);
	if (!CheckActorExist(nUniqueId))
	{
		ContentPointArray.Add(FHeadNamePoint(pInActor, pInMainHeadWidget, pInMainDistBgWidget, pMainDistWidget, pInHeadWidget, pInHeadDistBgWidget, pInHeadDistWidget, pInRotationWidget, bInCanRotation));
		BindActor(pInActor);
		UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::AddContentPoint, real add nUniqueId(%d)"), nUniqueId);
	}
	return nUniqueId;
}

void UUIMapOpFFATeamMemberHead::RemoveContentPoint(int32 nId)
{
	UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::RemoveContentPoint,nUniqueId(%d)"), nId);
	if (pSelfActor && nId == pSelfActor->GetUniqueID())
	{
		UnBindActor(pSelfActor);
		pSelfActor = nullptr;
	}
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FHeadNamePoint& ContentPoint = ContentPointArray[i];
		int32 nUniqueId = ContentPoint.pContentActor->GetUniqueID();
		if (nUniqueId == nId)
		{
			UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::RemoveContentPoint,real remove,nUniqueId(%d)"), nUniqueId);
			UnBindActor(ContentPoint.pContentActor);
			ContentPointArray.RemoveAt(i);
			break;
		}
	}
}

bool UUIMapOpFFATeamMemberHead::CheckActorExist(int32 nInUniqueId)
{
	int32 nPointCounts = ContentPointArray.Num();
	UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::CheckActorExist,nUniqueId(%d)"), nInUniqueId);
	for (int i = 0; i < nPointCounts; i++)
	{
		AActor* pActor = ContentPointArray[i].pContentActor;
		if (pActor != nullptr && pActor->GetUniqueID() == nInUniqueId)
		{
			UE_LOG(LogMapOperation, Log, TEXT("UUIMapOpFFATeamMemberHead::CheckActorExist,true,nUniqueId(%d)"), nInUniqueId);
			return true;
		}
	}
	return false;
}

void UUIMapOpFFATeamMemberHead::SetHeadOffset(float InHeadOffset)
{
	HeadOffset = InHeadOffset;
}

UUIMapScale::UUIMapScale(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pSelfActor(nullptr)
	, pOwner(nullptr)
	, pSliderWidget(nullptr)
	, InterSpeed(0)
	, TargetSize(FVector2D(0, 0))
	, TargetAlignment(FVector(0, 0, 0))
	, MinSize(FVector2D(0, 0))
	, MaxSize(FVector2D(1, 1))
	, bUpdate(false)
	, bUpdateAlignment(false)
	, pRadarMapWidget(nullptr)
{
	MapWidgetArray.Empty();
}

void UUIMapScale::InitParam(AActor* pInActor, UUIMapUserWidget* pInOwner, UCanvasPanel* pInWidget, USlider* pInSliderWidget, FVector2D InMinSize, FVector2D InMaxSize, UKMRadarMap* pInRadarMapWidget)
{
	check(pInActor && pInOwner && pInWidget && pInSliderWidget && pInRadarMapWidget);
	if (pSelfActor)
	{
		UnBindActor(pSelfActor);
		pSelfActor = nullptr;
	}
	pSelfActor = pInActor;
	BindActor(pInActor);
	pOwner = pInOwner;
	MapWidgetArray.Empty();
	MapWidgetArray.Add(pInWidget);
	pSliderWidget = pInSliderWidget;
	MinSize = InMinSize;
	MaxSize = InMaxSize;
	pRadarMapWidget = pInRadarMapWidget;
}

void UUIMapScale::AddPanelWidget(UCanvasPanel* pInWidget)
{
	MapWidgetArray.Add(pInWidget);
}

void UUIMapScale::SetInterSpeed(float Speed)
{
	InterSpeed = Speed;
}

void UUIMapScale::SetPanelSize(float InSizeX, float InSizeY)
{
	TargetSize.X = InSizeX;
	TargetSize.Y = InSizeY;
	bUpdate = true;
}

void UUIMapScale::SetPanelAlignment(bool bInUpdateAlignment)
{
	bUpdateAlignment = bInUpdateAlignment;
}

void UUIMapScale::OnNativeTick(float DeltaSeconds)
{
	if (!bUpdate || MapWidgetArray.Num() == 0 || pSelfActor == nullptr)
	{
		return;
	}
	UCanvasPanelSlot* pFirstSlotPtr = Cast<UCanvasPanelSlot>(MapWidgetArray[0]->Slot);
	FVector2D CurrentSize = pFirstSlotPtr->GetSize();
	if (CurrentSize.Equals(TargetSize, 0.01))
	{
		bUpdate = false;
		return;
	}
	//UE_LOG(LogMapOperation, Log, TEXT("UUIMapScale::OnNativeTick1,UIMapPos(%f,%f) CurTarget(%f,%f)"));
	//size scale
	FVector2D CurTarget;
	CurTarget.Y = FMath::FInterpTo(CurrentSize.Y, TargetSize.Y, DeltaSeconds, InterSpeed);
	float ScaleY = CurTarget.Y / CurrentSize.Y;
	CurTarget.X = CurrentSize.X * ScaleY;
	FVector2D UIMapOffset = pOwner->GetUIMapValidOffset();
	UIMapOffset = UIMapOffset * ScaleY;
	FVector2D UIMapValidSize = CurTarget - UIMapOffset * 2;
	pOwner->InitMapParam(pOwner->Get3DMapSize(), UIMapValidSize, UIMapOffset, pOwner->Get3DMapOrigin(), pOwner->GetUIMapOrigin());
	pSliderWidget->SetValue((CurTarget.X - MinSize.X) / (MaxSize.X - MinSize.X));

	//alignment on playerself location 
	FVector SelfLocation = pSelfActor->GetActorLocation();
	FVector2D UIMapLocation = pOwner->CalculateUIMapLocation(SelfLocation);
	FVector2D UIMapAlignment = UIMapLocation / CurTarget;

	//reset map position according to alignment
	FVector2D CurAlignment = pFirstSlotPtr->GetAlignment();
	if (bUpdateAlignment)
	{
		CurAlignment = UIMapAlignment;
	}
	FVector2D CurUIMapSize = CurTarget;// pOwner->GetUIMapValidSize() + 2 * pOwner->GetUIMapValidOffset();
	float BorderXLeft = CurUIMapSize.X * CurAlignment.X;
	float BorderXRight = CurUIMapSize.X - BorderXLeft;
	float BorderYTop = CurUIMapSize.Y * CurAlignment.Y;
	float BorderYBottom = CurUIMapSize.Y - BorderYTop;
	float nHalfViewPortSizeX = MinSize.X / 2;
	float nHalfViewPortSizeY = MinSize.Y / 2;
	float PosX = FMath::Min(BorderXLeft - nHalfViewPortSizeX, FMath::Max(0.0f, -(BorderXRight - nHalfViewPortSizeX)));
	float PosY = FMath::Min(BorderYTop - nHalfViewPortSizeY, FMath::Max(0.0f, -(BorderYBottom - nHalfViewPortSizeY)));

	for (UCanvasPanel* pWidget : MapWidgetArray)
	{
		UCanvasPanelSlot* SlotPtr = Cast<UCanvasPanelSlot>(pWidget->Slot);
		if (!SlotPtr)
		{
			continue;
		}
		
		SlotPtr->SetSize(CurTarget);
			
		if (bUpdateAlignment)
		{
			SlotPtr->SetAlignment(UIMapAlignment);
		}

		UKMCanvasPanel* pKMPanelWidget = Cast<UKMCanvasPanel>(pWidget);
		FVector2D UIMapPos = FVector2D(PosX, PosY);
		if (pKMPanelWidget)
		{
			pKMPanelWidget->SetPanelOffset(UIMapPos, false);
		}
		else
		{
			SlotPtr->SetPosition(UIMapPos);
		}
		//UE_LOG(LogMapOperation, Log, TEXT("UUIMapScale::OnNativeTick,UIMapPos(%f,%f) CurTarget(%f,%f)"), PosX, PosY, CurTarget.X, CurTarget.Y);
		//UKMRadarMap* pRadarMap = Cast<UKMRadarMap>(pOwner->WidgetTree->FindWidget("radarMap"));
		
	}
	//UE_LOG(LogMapOperation, Log, TEXT("UUIMapScale::OnNativeTick3,UIMapPos(%f,%f) CurTarget(%f,%f)"), PosX, PosY, CurTarget.X, CurTarget.Y);
	if (pRadarMapWidget)
	{
		pRadarMapWidget->OnWidgetSizeChange(UIMapValidSize);
		FVector2D ViewPortPos = FVector2D(-(PosX - BorderXLeft + nHalfViewPortSizeX), -(PosY - BorderYTop + nHalfViewPortSizeY));
		pRadarMapWidget->OnViewPortPosChange(ViewPortPos);

	}
	//UE_LOG(LogMapOperation, Log, TEXT("UUIMapScale::OnNativeTick4,UIMapPos(%f,%f) CurTarget(%f,%f)"), PosX, PosY, CurTarget.X, CurTarget.Y);
}

void UUIMapScale::OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason)
{
	UnBindActor(pSelfActor);
	pSelfActor = nullptr;
}

//ui map 静态刷新点
UUIMapOpPoint::UUIMapOpPoint(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, pOwner(nullptr)
	, SizeFactor1(0.f)
	, SizeFactor2(0.f)
	, SizeFactor3(0.f)
{
	ContentPointArray.Empty();
}

void UUIMapOpPoint::OnNativeTick(float DeltaSeconds)
{
	if (pOwner == nullptr)
	{
		return;
	}
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FContentStaticPoint& ContentPoint = ContentPointArray[i];

		UWidget* pWidget = ContentPoint.pContentWidget;
		FVector2D UILocation = pOwner->CalculateUIMapLocation(ContentPoint.PointLocation);
		if (bMirror)
		{
			FVector2D UIMapSize = pOwner->GetUIMapValidSize() + pOwner->GetUIMapValidOffset() * 2;
			UILocation.X = UIMapSize.X - UILocation.X;
		}
		UCanvasPanelSlot* WidgetSlot = Cast<UCanvasPanelSlot>(pWidget->Slot);
		if (WidgetSlot)
		{
			WidgetSlot->SetPosition(UILocation);
		}
		float ScaleZoom = FMath::Min(SizeFactor1, pOwner->GetUIMapValidSize().X / SizeFactor3 + SizeFactor2);
		if (ContentPoint.pTextWidget && ContentPoint.DefaultFontSize > 0 )
		{
			FSlateFontInfo& FontInfo = ContentPoint.pTextWidget->Font;
			FontInfo.Size = ContentPoint.DefaultFontSize * ScaleZoom;
			ContentPoint.pTextWidget->SetFont(FontInfo);
		}
		if (ContentPoint.pIconWidget && ! ContentPoint.DefaultSize.Equals(FVector2D::ZeroVector, 0.1))
		{
			UCanvasPanelSlot* pIconWidgetSlot = Cast<UCanvasPanelSlot>(ContentPoint.pIconWidget->Slot);
			if (pIconWidgetSlot)
			{
				if (SizeFactor1 == 0 && SizeFactor2 == 0 && SizeFactor3 == 0)
				{
					FVector2D CurrentSize = pOwner->CalculateUISize(ContentPoint.DefaultSize);
					pIconWidgetSlot->SetSize(CurrentSize);
					WidgetSlot->SetSize(CurrentSize);
				}
				else
				{
					FVector2D CurrentSize = ContentPoint.DefaultSize * ScaleZoom;
					pIconWidgetSlot->SetSize(CurrentSize);
					WidgetSlot->SetSize(CurrentSize);
				}
			}
		}
	}
}

void UUIMapOpPoint::InitParam(UUIMapUserWidget* pInOwner, float InSizeFactor1, float InSizeFactor2, float InSizeFactor3)
{
	check(pInOwner);
	pOwner = pInOwner;
	SizeFactor1 = InSizeFactor1;
	SizeFactor2 = InSizeFactor2;
	SizeFactor3 = InSizeFactor3;
}


int32 UUIMapOpPoint::AddContentPoint(UWidget* pInWidget, FVector InLocation)
{
	check(pInWidget);
	int32 nUniqueId = pInWidget->GetUniqueID();
	if (!CheckPointExist(nUniqueId))
	{
		ContentPointArray.Add(FContentStaticPoint(pInWidget, InLocation));
		OnNativeTick(0);
		return nUniqueId;
	}
	else
	{
		return -1;
	}
}

int32 UUIMapOpPoint::AddContentPointWithSize(UWidget* pInWidget, FVector InLocation, UTextBlock* pInTextWidget, float InDefaultFontSize, UWidget* pInIconWidget, FVector2D InDefalutSize)
{
	check(pInWidget);
	int32 nUniqueId = pInWidget->GetUniqueID();
	if (!CheckPointExist(nUniqueId))
	{
		ContentPointArray.Add(FContentStaticPoint(pInWidget, InLocation, pInTextWidget, InDefaultFontSize, pInIconWidget, InDefalutSize));
		OnNativeTick(0);
		return nUniqueId;
	}
	else
	{
		return -1;
	}
}

void UUIMapOpPoint::RemoveContentPoint(int32 nId)
{
	int32 nPointCounts = ContentPointArray.Num();
	for (int32 i = 0; i < nPointCounts; i++)
	{
		FContentStaticPoint& ContentPoint = ContentPointArray[i];
		int32 nUniqueId = ContentPoint.pContentWidget->GetUniqueID();
		if (nUniqueId == nId)
		{
			ContentPointArray.RemoveAt(i);
			break;
		}
	}
}

bool UUIMapOpPoint::CheckPointExist(int32 nInUniqueId)
{
	int32 nPointCounts = ContentPointArray.Num();
	for (int i = 0; i < nPointCounts; i++)
	{
		if (ContentPointArray[i].pContentWidget->GetUniqueID() == nInUniqueId)
		{
			return true;
		}
	}
	return false;
}


#undef LOCTEXT_NAMESPACE



