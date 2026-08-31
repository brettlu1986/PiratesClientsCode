//

#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "KMWidgetComponent.h"
#include "HAL/CriticalSection.h"
#include "Runtime/Slate/Public/Widgets/Layout/SWrapBox.h"

#include "PiratesWidgetBatchRendering.generated.h"

class UPirWidgetBatchRenderingComponent;
typedef TWeakObjectPtr<UKMWidgetComponent> FWeakWidgetCompPtr;
UCLASS()
class COMMON_API APiratesWidgetBatchRenderer : public AKMWidgetBatchRenderer
{
	GENERATED_BODY()

public:
	APiratesWidgetBatchRenderer();

public: // AKMWidgetBatchRenderer Interface
	virtual bool CanRender() const override { return true; }
	/** add new widget to widget set and render component */
	virtual void AddWidgetComponent(UKMWidgetComponent* InWidgetComponent) override;
	/** Invalid widgets will be removed in Tick */
	virtual void RemoveWidgetComponent(TWeakObjectPtr<UKMWidgetComponent> InWidgetComponent) override;

public: // AActor Interface
	virtual void BeginPlay() override;
	virtual void EndPlay(EEndPlayReason::Type Reason) override;
	/** remove invalid widgets and update render data */
	virtual void Tick(float DeltaTime) override;

private:
	FCriticalSection WidgetSetLock;
	TSet<FWeakWidgetCompPtr> WidgetSet;
	UPirWidgetBatchRenderingComponent* RenderComponentCached;
};

UCLASS()
class UPirWidgetBatchRenderingComponent : public UWidgetComponent
{
	GENERATED_BODY()

public: // UActorComponent Interface
	/** create swrap box */
	virtual void BeginPlay() override;

	// USceneComponent Interface
	virtual FBoxSphereBounds CalcBounds(const FTransform& LocalToWorld) const override;

    // UPrimitiveComponent Interface
	virtual FPrimitiveSceneProxy* CreateSceneProxy() override;

protected: // UWidgetComponent Interface
	virtual void DrawWidgetToRenderTarget(float DeltaTime) override;

private:
	friend class APiratesWidgetBatchRenderer;
	/** add to swrap box */
	bool AddWidget(FWeakWidgetCompPtr WidgetPtr, bool bAlreadAdded);
	/** remove from wrap box */
	void RemoveWidget(FWeakWidgetCompPtr WidgetPtr);
	/** sort widgets by size */
	void SortWidgetsBySize();
	/** calculate render data and send to scene proxy in render thread  */
	void UpdateRenderData();

	void SortWidgetCompsFrontToBack();

private:
	FCriticalSection CompSlotLock;

	TMap<FWeakWidgetCompPtr, SWrapBox::FSlot*> ComponentToSlotMap;

	/** mateial for batch rendering */
	UPROPERTY(Transient)
	const UMaterialInterface* BachingMaterial;

	/** for rotating the widget to face the camera */
	FRotator CameraRot;

	/** for sorting the widget components from back to front */
	FVector CameraLoc;

	/** for cache the default draw size */
	FIntPoint DefaultDrawSize;

	/** last time of drawing at desired size */
	double LastTimeDrawAtDesiredSize;

	/** last time of sorting widget components from back to front */
	double LastWidgetSortTime;

	float BaseScaleFactor;

	/** calculate scale factor in UpdateRenderData once and only once */
	bool bBaseScaleFactorResolved;
};