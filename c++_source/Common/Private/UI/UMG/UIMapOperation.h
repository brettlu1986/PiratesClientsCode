

#pragma  once

#include "PiratesUserWidget.h"
#include "KMObject.h"
#include "UI/UMG/UIMapUserWidget.h"
#include "Components/CanvasPanel.h"
#include "Components/ProgressBar.h"
#include "Components/TextBlock.h"
#include "UMG/KMCircleProgressBarSimple.h"
#include "UMG/KMFFAMapElement.h"
#include "UMG/KMTextBlock.h"
#include "UMG/KMProgressBar.h"
#include "UMG/KMDottedLine.h"
#include "UMG/KMRadarMap.h"
#include "UIMapOperation.generated.h"



struct FContentPoint
{
	AActor* pContentActor;
	UWidget* pContentWidget;
	UWidget* pRotationWidget;
	UWidget* pStateWidget;
	UWidget* pStateWidgetEx;
	FVector2D UISize;
	bool bCanRotation;
	bool bScaleSize;
	FContentPoint(AActor* pInContentActor, UWidget* pInContentWidget, bool bInCanRotation)
		:pContentActor(pInContentActor)
		, pContentWidget(pInContentWidget)
		, pRotationWidget(nullptr)
		, pStateWidget(nullptr)
		, pStateWidgetEx(nullptr)
		, UISize(FVector2D(1.0, 1.0))
		, bCanRotation(bInCanRotation)
		, bScaleSize(false)
	{}
	FContentPoint(AActor* pInContentActor, UWidget* pInContentWidget, FVector2D InUISize, bool bInCanRotation)
		:pContentActor(pInContentActor)
		, pContentWidget(pInContentWidget)
		, pRotationWidget(nullptr)
		, pStateWidget(nullptr)
		, pStateWidgetEx(nullptr)
		, UISize(InUISize)
		, bCanRotation(bInCanRotation)
		, bScaleSize(true)
	{}
	FContentPoint(AActor* pInContentActor, UWidget* pInContentWidget, UWidget* pInRotationWidget, UWidget* pInStateWidget, UWidget* pInStateWidgetEx, bool bInCanRotation)
		:pContentActor(pInContentActor)
		, pContentWidget(pInContentWidget)
		, pRotationWidget(pInRotationWidget)
		, pStateWidget(pInStateWidget)
		, pStateWidgetEx(pInStateWidgetEx)
		, bCanRotation(bInCanRotation)
	{}

};


struct FContentStaticPoint
{
	
	UWidget* pContentWidget;
	FVector PointLocation;
	UTextBlock* pTextWidget;
	float DefaultFontSize;
	UWidget* pIconWidget;
	FVector2D DefaultSize;

	FContentStaticPoint(UWidget* pInContentWidget, FVector InPointLocation)
		: pContentWidget(pInContentWidget)
		, PointLocation(InPointLocation)
		, pTextWidget(nullptr)
		, DefaultFontSize(0)
		, pIconWidget(nullptr)
		, DefaultSize(FVector2D::ZeroVector)
	{}
	FContentStaticPoint(UWidget* pInContentWidget, FVector InPointLocation, UTextBlock* pInTextWidget, float InDefaultFontSize, UWidget* pInIconWidget, FVector2D InDefaultSize)
		: pContentWidget(pInContentWidget)
		, PointLocation(InPointLocation)
		, pTextWidget(pInTextWidget)
		, DefaultFontSize(InDefaultFontSize)
		, pIconWidget(pInIconWidget)
		, DefaultSize(InDefaultSize)
	{}

};
//ui map 操作基类

UCLASS()
class COMMON_API UUIMapOpBase : public UKMObject
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) {}
	
	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetEnable(bool bInEnable);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	bool GetEnable();

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetMirror(bool bInMirror);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetTickInterval(float InTickInterval);

protected:
	bool bEnable;
	bool bMirror;
	float TickInterval;
	float LastTickDeltaSeconds;
};



UCLASS()
class COMMON_API UUIMapOpWithActor : public UUIMapOpBase
{
	GENERATED_BODY()
public:
	

protected:
	void BindActor(AActor* Actor);
    void UnBindActor(AActor* Actor);

    UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) {}
};

// ui map 刷新地图位置
UCLASS(Blueprintable)
class COMMON_API UUIMapMove : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(UUIMapUserWidget* pInOwner, AActor* pInActor, UCanvasPanel* pInWidget, UWidget* pInSelfWidget, UCanvasPanel* pMovedWidget, UKMRadarMap* pInRadarMapWidget);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetInterSpeed(float Speed);

protected:
	//yangjingzhao for 4.20
   // UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	AActor* pSelfActor;
	UWidget* pSelfWidget;
	UUIMapUserWidget* pOwner;
    TArray<UCanvasPanel*> MapWidgetArray;
	float InterSpeed;
	FVector2D UIMapPos;
	FVector LastSelfPos;
	FVector2D UILocation;
	FVector2D UIMapOrigin;
	UKMRadarMap* pRadarMapWidget;
};



// ui map 刷新地图坐标
UCLASS()
class COMMON_API UUIMapCoord : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(UUIMapUserWidget* pInOwner, AActor* pInActor, UTextBlock* pInWidget, float nInCoordInterval, const FText& InFormatText);

protected:
    //UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	AActor* pSelfActor;
	UTextBlock* pCoordWidget;
	UUIMapUserWidget* pOwner;
	float nCoordInterval;
	int32 nLastUILocationX;
	int32 nLastUILocationY;
	FText CoordFormatText;
};

UCLASS()
class COMMON_API UUIMapOpPointWithActor : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(UUIMapUserWidget* pInOwner, float nInFactor);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	int32 AddContentPoint(AActor* InActor, UWidget* pInWidget, bool bInCanRotation);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	int32 AddContentPointWithSize(AActor* pInActor, UWidget* pInWidget, UWidget* pInImageWidget, FVector2D InUISize, bool bInCanRotation);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void RemoveContentPoint(int32 nId);

private:
	bool CheckActorExist(int32 nInUniqueId);

protected:
    //UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	TArray<FContentPoint> ContentPointArray;
	UUIMapUserWidget* pOwner;
	float nFactor;
};



UCLASS()
class COMMON_API UUIMapNav : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(AActor* pInActor);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void StartNavigate(const TArray<FVector2D>& InNavPosArray, const TArray<UWidget*>& InNavWidgetArray, float nInNavPointInterval);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void StopNavigate();

protected:
    //UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	float nNavPointInterval;
	bool bStartNavigate;
	int32 nNavStartIndex;
	TArray<FVector2D> NavPosArray;
	TArray<UWidget*> NavWidgetArray;
	AActor* pSelfActor;
};



UCLASS()
class COMMON_API UUIMapCameraFov : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()

public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(float nCameraRotationOffset, UKMCircleProgressBarSimple* pInFovWidget);

protected:
    //UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	float nCameraRotationOffset;
	UKMCircleProgressBarSimple* pFovWidget;
	APlayerCameraManager* pCameraMngr;
	float nLastFovAngle;
};

UENUM(BlueprintType)
enum class EMapShape : uint8
{
	MAP_Circle,
	MAP_Square,
};


UCLASS()
class COMMON_API UUIMapOpOrientationWithActor : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
		void InitParam(UUIMapUserWidget* pInOwner, AActor* pInSelfActor, UWidget* pInOrientationRoot, UWidget* pInMapWidget, FVector2D InShowRange, FVector2D InOffset, EMapShape InMapShape);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
		int32 AddOrientationPoint(AActor* InActor, UWidget* pInWidget, bool bInCanRotation);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
		void RemoveOrientationPoint(int32 nId);

protected:
	//UFUNCTION()
    virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
    bool CheckActorExist(int32 nInUniqueId);
	void CalculatePoint(const FVector2D& InSelfPos);

private:
	TArray<FContentPoint> ContentPointArray;
	UUIMapUserWidget* pOwner;
	AActor* pSelfActor;
	UWidget* pOrientationRoot;
	UWidget* pMapWidget;
	EMapShape MapShape;
	FVector2D ShowRange;
	FVector2D ShowOffset;
};


struct FPathInfo
{
    AActor* pActor;
    UProgressBar* pProgressBar;
    FVector2D StartPoint;
    FVector2D EndPoint;
    float PathLength;
    float LastRemainingLength;

    FPathInfo()
        : pActor(nullptr)
        , pProgressBar(nullptr)
        , StartPoint(0.f, 0.f)
        , EndPoint(0.f, 0.f)
        , PathLength(1.f)
        , LastRemainingLength(-1.f)

    {}
    FPathInfo(AActor* pInContentActor, UProgressBar* pInContentWidget, const FVector2D& Start, const FVector2D& End)
        : pActor(pInContentActor)
        , pProgressBar(pInContentWidget)
        , StartPoint(Start)
        , EndPoint(End)
    {
        PathLength = FVector2D::Distance(Start, End);
        LastRemainingLength = -1.f;
    }
};


UCLASS()
class COMMON_API UUIMapOpStaticPath : public UUIMapOpWithActor
{
    GENERATED_UCLASS_BODY()
public:
    virtual void OnNativeTick(float DeltaSeconds) override;
    UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
    int AddPath(AActor* InActor, UProgressBar* PathWidget, const FVector2D& Start, const FVector2D& End);

    UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
    void RemovePath(int PathId);

protected:
    virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
    TArray<FPathInfo> PathInfos;
};

UCLASS()
class COMMON_API UUIMapOpPoisonCircle : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;
	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetSafeCircle(const FVector& InCircleCenter, float InCircleRadius, float InPoisonCircleRadius);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetPoisonCircle(const FVector& InCircleCenter, float InCircleRadius);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(AActor* pInActor, UUIMapUserWidget* pInOwner, UWidget* pInWidget, UKMFFAMapElement* pInMapElementWidget);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetPoisonProgress(UKMTextBlock* pInDistanceWidget, UKMProgressBar* pInProgressWidget, UWidget* pInSelfWidget, const FText& InFormatText);

protected:
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	void UpdateSafeCircle(FVector& InCenterPoint, float InCircleRadius, UWidget* pInWidget);
	void UpdatePoisonProgress();

private:
	AActor * pSelfActor;
	UUIMapUserWidget* pOwner;
	UWidget* pSafeCircleWidget;
	UKMFFAMapElement* pPoisonCircleWidget;
	FVector SafeCircleCenter;
	float SafeCircleRadius;
	FVector PoisonCircleCenter;
	float PoisonCircleRadius;
	float PoisonCircleStartRadius;
	UKMTextBlock* pDistanceWidget;
	UKMProgressBar* pProgressWidget;
	UWidget* pSelfWidget;
	FText FormatText;
};

UCLASS()
class COMMON_API UUIMapOpFlagPointLine : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	int32 SetFlagLine(FVector InTargetLocation, UKMDottedLine* pInDottedLineWidget);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void RemoveFlagLine();

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	int32 AddFlagPoint(UWidget* pInWidget, FVector InTargetLocation, UKMTextBlock* pInTextWidget, const FText& InFormatText);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void RemoveFlagPoint(int32 nInUniqueId);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetLineVisibleDistance(float nInVisibleDistance);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetSelfIsSwimming(bool bInSwimming);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetTargetRegionVisible(bool bInRegionVisible);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetSelfRegionVisible(bool bInRegionVisible);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(UUIMapUserWidget* pInOwner, AActor* pInActor, float InLandWeight, float InOceanWeight, bool bInHuman, int32 InLandId);


protected:
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	FVector GetShortestDistanceLocation(TArray<FVector2D>& PosList, const FVector& TargetLocation);
	void RefreshNodeList(TArray<FVector2D>& NodeList, const FVector& InTargetLocation);
	void DrawFlagLine(const FVector& InSelfLocation);
private:
	struct FFlagPointInfo
	{
		UWidget* pWidget;
		FVector TargetLocation;
		UKMTextBlock* pTextWidget;
		FText FormatText;

		FFlagPointInfo()
			: pWidget(nullptr)
			, TargetLocation(FVector::ZeroVector)
			, pTextWidget(nullptr)
			, FormatText(FText::GetEmpty())
		{
		}
		FFlagPointInfo(UWidget* pInWidget, FVector InTargetLocation, UKMTextBlock* pInTextWidget, const FText& InFormatText)
			: pWidget(pInWidget)
			, TargetLocation(InTargetLocation)
			, pTextWidget(pInTextWidget)
			, FormatText(InFormatText)
		{
		}
	};
	struct FPathNodeInfo
	{
		FVector2D NodePos;
		float Weight;
		TArray<FPathNodeInfo> NextTargetList;
		FPathNodeInfo()
			: NodePos(FVector2D::ZeroVector)
			, Weight(1.0f)
		{
			NextTargetList.Reserve(32);
			NextTargetList.Empty();
		}
		FPathNodeInfo(FVector2D InNodePos, float InWeight)
			: NodePos(InNodePos)
			, Weight(InWeight)
		{
			NextTargetList.Reserve(32);
			NextTargetList.Empty();
		}
	};
	TArray<FVector2D> LineNodeList;
	TArray<UWidget*> LineWidgetList;
	UKMDottedLine* pDottedLineWidget;
	TArray<FFlagPointInfo> FlagPointInfoList;
	TArray<FPathNodeInfo> PathArray;
	FVector LineTargetLocation;
	UUIMapUserWidget * pOwner;
	AActor* pSelfActor;
	int32 nLastLandId;
	float nVisibleDistance;
	FVector SelfLastLocation;
	bool bTargetRegionVisible;
	bool bSelfRegionVisible;
	float LandWeight;
	float OceanWeight;
	bool bSwimming;
	bool bHuman;
};

UCLASS()
class COMMON_API UUIMapOpCompass : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;
	

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(AActor* pInSelfActor, UUIMapUserWidget* pInOwner, UWidget* pInCompassWidget, float nInFactor, FRotator InRotation, float nInCriticalDegreeOffset);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	int32 AddFlagPoint(UWidget* pInWidget, UTextBlock* pInTextWidget, const FText& InFormatText, const FVector& InStaticLocation);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void RemoveFlagPoint(int32 nPointIndex);

protected:
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	struct FFlagPoint
	{
		int32 nPointIndex;
		UWidget* pWidget;
		UTextBlock* pTextWidget;
		FText FormatText;
		FVector PointLocation;
		

		FFlagPoint(int32 nInPointIndex, UWidget* pInWidget, UTextBlock* pInTextWidget, const FText& InFormatText, const FVector& InLocation)
			:nPointIndex(nInPointIndex)
			, pWidget(pInWidget)
			, pTextWidget(pInTextWidget)
			, FormatText(InFormatText)
			, PointLocation(InLocation)
		{}
	};
	TArray<FFlagPoint> FlagPointInfoList;
	UWidget * pCompassWidget;
	float nFactor;
	FRotator Rotation;
	AActor* pSelfActor;
	int32 nFlagPointIndex;
	UUIMapUserWidget* pOwner;
	float nCriticalDegreeOffset;
};


UCLASS()
class COMMON_API UUIMapOpSafeCirclePath : public UUIMapOpWithActor
{
    GENERATED_UCLASS_BODY()
public:
    virtual void OnNativeTick(float DeltaSeconds) override;
    UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
    void SetSafeCircle(const FVector& InCircleCenter, float InCircleRadius, UWidget* pInLineWidget);

    UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
    void InitParam(AActor* pInActor, UUIMapUserWidget* pInOwner);

protected:
    virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

    /*private:
        void UpdatePath(FVector& InCenterPoint, float InCircleRadius, UWidget* pInWidget);*/

private:
    AActor * pSelfActor;
    UUIMapUserWidget* pOwner;
    UWidget* pWidget;
    FVector SafeCircleCenter;
    float SafeCircleRadius;

};

UCLASS()
class COMMON_API UUIMapOpFFATeamMember : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
		void InitParam(UUIMapUserWidget* pInOwner, AActor* pInSelfActor, UWidget* pInMapWidget, bool bInShowInRange, FVector2D InShowRange, FVector2D InOffset);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
		int32 AddContentPoint(AActor* InActor, UWidget* pInWidget, UWidget* pInRotationWidget, UWidget* pInStateWidget, UWidget* pInStateWidgetEx, bool bInCanRotation);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
		void RemoveContentPoint(int32 nId);

private:
	bool CheckActorExist(int32 nInUniqueId);

protected:
	//UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	TArray<FContentPoint> ContentPointArray;
	UUIMapUserWidget* pOwner;
	AActor* pSelfActor;
	UWidget* pMapWidget;
	bool bShowInRange;
	FVector2D ShowRange;
	FVector2D ShowOffset;
};

UCLASS()
class COMMON_API UUIMapOpFFATeamMemberHead : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(UUIMapUserWidget* pInOwner, AActor* pInSelfActor, UWidget* pInHeadRootWidget, FVector2D InBorderLeftTop, FVector2D InBorderRightBottom, float InShowDist, float InHeadOffset, float InCutoutSpacerWidth);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	int32 AddContentPoint(AActor* pInActor, UWidget* pInMainHeadWidget, UWidget* pInMainDistBgWidget, UTextBlock* pMainDistWidget, UWidget* pInHeadWidget, UWidget* pInHeadDistBgWidget, UTextBlock* pInHeadDistWidget, UWidget* pInRotationWidget, bool bInCanRotation);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void RemoveContentPoint(int32 nId);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetHeadOffset(float InHeadOffset);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetDistanceFormatText(const FText& InFormateText);

private:
	bool CheckActorExist(int32 nInUniqueId);

protected:
	//UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:

	struct FHeadNamePoint
	{
		AActor* pContentActor;
		UWidget* pMainHeadWidget;
		UWidget* pMainDistBgWidget;
		UTextBlock* pMainDistWidget;
		UWidget* pHeadWidget;
		UWidget* pHeadDistBgWidget;
		UTextBlock* pHeadDistWidget;
		UWidget* pRotationWidget;
		bool bCanRotation;
		FHeadNamePoint(AActor* pInContentActor, UWidget* pInMainHeadWidget, UWidget* pInMainDistBgWidget, UTextBlock* pInMainDistWidget, UWidget* pInHeadWidget, UWidget* pInHeadDistBgWidget, UTextBlock* pInHeadDistWidget, UWidget* pInRotationWidget, bool bInCanRotation)
			:pContentActor(pInContentActor)
			, pMainHeadWidget(pInMainHeadWidget)
			, pMainDistBgWidget(pInMainDistBgWidget)
			, pMainDistWidget(pInMainDistWidget)
			, pHeadWidget(pInHeadWidget)
			, pHeadDistBgWidget(pInHeadDistBgWidget)
			, pHeadDistWidget(pInHeadDistWidget)
			, pRotationWidget(pInRotationWidget)
			, bCanRotation(bInCanRotation)
		{}
	};
	TArray<FHeadNamePoint> ContentPointArray;
	UUIMapUserWidget* pOwner;
	AActor* pSelfActor;
	APlayerCameraManager* pCameraMngr;
	APlayerController* pPlayerController;
	FVector2D BorderLeftTop;  //x:left y:top
	FVector2D BorderRightBottom; //x:right y:bottom
	UWidget* pHeadRootWidget;
	float ShowDist;
	float HeadOffset;
	float CutoutSpacerWidth;
	FText DistanceFormatText;
};

UCLASS()
class COMMON_API UUIMapScale : public UUIMapOpWithActor
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(AActor* pInActor, UUIMapUserWidget* pInOwner, UCanvasPanel* pInWidget, USlider* pInSliderWidget, FVector2D InMinSize, FVector2D InMaxSize, UKMRadarMap* pInRadarMapWidget);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void AddPanelWidget(UCanvasPanel* pInWidget);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetInterSpeed(float Speed);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetPanelSize(float InSizeX, float InSizeY);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void SetPanelAlignment(bool bInUpdateAlignment);

protected:
	//UFUNCTION()
	virtual void OnActorDestroy(AActor* Actor, EEndPlayReason::Type EndPlayReason) override;

private:
	AActor* pSelfActor;
	UUIMapUserWidget* pOwner;
	USlider* pSliderWidget;
	float InterSpeed;
	FVector2D TargetSize;
	FVector2D TargetAlignment;
	FVector2D MinSize;
	FVector2D MaxSize;
	bool bUpdate;
	bool bUpdateAlignment;
	UKMRadarMap* pRadarMapWidget;
	TArray<UCanvasPanel*> MapWidgetArray;
};

UCLASS()
class COMMON_API UUIMapOpPoint : public UUIMapOpBase
{
	GENERATED_UCLASS_BODY()
public:
	virtual void OnNativeTick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitParam(UUIMapUserWidget* pInOwner, float InSizeFactor1, float InSizeFactor2, float InSizeFactor3);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	int32 AddContentPoint(UWidget* pInWidget, FVector InLocation);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	int32 AddContentPointWithSize(UWidget* pInWidget, FVector InLocation, UTextBlock* pInTextWidget, float InDefaultFontSize, UWidget* pInIconWidget, FVector2D InDefalutSize);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
		void RemoveContentPoint(int32 nId);

private:
	bool CheckPointExist(int32 nInUniqueId);

private:
	TArray<FContentStaticPoint> ContentPointArray;
	UUIMapUserWidget* pOwner;
	float SizeFactor1;
	float SizeFactor2;
	float SizeFactor3;
};
