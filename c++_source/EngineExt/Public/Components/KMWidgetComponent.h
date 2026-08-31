// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/WidgetComponent.h"
#include "HAL/CriticalSection.h"
#include "KMWidgetComponent.generated.h"

/**
 * 
 */
class UCanvasPanel;
UCLASS(Blueprintable, ClassGroup = "UserInterface", hidecategories = (Object, Activation, "Components|Activation", Sockets, Base, Lighting, LOD, Mesh), editinlinenew, meta = (BlueprintSpawnableComponent))
class ENGINEEXT_API UKMWidgetComponent : public UWidgetComponent
{
    GENERATED_UCLASS_BODY()
	
private:
	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;

public:
    /** Used to determine anim time */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Widget", meta = (UIMin = "0.1"))
    float MinDistance;
	
    /** Used to determine anim time */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Widget", meta = (UIMin = "0.1"))
    float MaxDistance;

    /** Used to determine anim time */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Widget", meta = (UIMin = "0.1"))
    float ScaleRate;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Widget", meta = (UIMin = "0.1"))
    UCanvasPanel* WidgetPanel;

protected: // 3d batch rendering
	/** set to true means this widget wants to be batch rendered */
	UPROPERTY(EditAnywhere, Category = "PirBatchRendering")
	bool bBatchRendering;

	/** the material used in batch rendering */
	UPROPERTY(EditAnywhere, Category = "PirBatchRendering", meta = (editcondition = "bBatchRendering"))
	UMaterialInterface* BatchRenderingMaterial;

	/** the base view size used in scaling, 0 means no effect */
	UPROPERTY(EditAnywhere, Category = "PirBatchRendering", meta = (editconditon = "bBatchRendering"))
	float BaseViewSize;

	/** the minimum scale can be applied to the widget, 0 means no limited */
	UPROPERTY(EditAnywhere, Category = "PirBatchRendering", meta = (editconditon = "bBatchRendering"))
	float MinScale;

	/** the maximum scale can be applied to the widget, 0 means no limited */
	UPROPERTY(EditAnywhere, Category = "PirBatchRendering", meta = (editconditon = "bBatchRendering"))
	float MaxScale;

	/** if set, ShouldDrawWidget always return false */
	bool bDisableRedraw;

public:// 3d batch rendering
	bool Need3DBatchRendering() const { return bBatchRendering; }
	void Set3DBatchRendering(bool bVal) { bBatchRendering = bVal; }
	bool NeedRedraw() const { return bRedrawRequested; }
	void SetRedraw(bool bVal) { bRedrawRequested = bVal; }
	/** get the current widget being rendered */
	TSharedPtr<SWidget> GetCurrentSlateWidget() const { return CurrentSlateWidget.Pin(); }
	/** get the material used in batch rendering */
	const UMaterialInterface* GetBatchRenderingMaterial() const { return BatchRenderingMaterial; }
	/** get the fixed screen size used in batch rendering */
	float GetBatchRenderingBaseViewSize() const { return BaseViewSize; }
	FORCEINLINE float GetBatchRenderingMinScale() const { return MinScale; }
	FORCEINLINE float GetBatchRenderingMaxScale() const { return MaxScale; }
	bool GetManuallyRedraw() const { return bManuallyRedraw; }
	/** see SetDisableRedraw */
	void SetDisableRedraw(bool bVal) { bDisableRedraw = bVal; }

protected:
	/** see SetDisableRedraw */
	virtual bool ShouldDrawWidget() const;
};
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
class AKMWidgetBatchRenderer;
extern ENGINEEXT_API int32 CVar3DWidgetBatching;
class ENGINEEXT_API FKMWidgetBatcher
{
	friend class AKMWidgetBatchRenderer;

public:
	static void SetupBatching(UKMWidgetComponent* InWidgetComponent);

	static APlayerController* GetPlayerController(UKMWidgetComponent* Widget);

private:
	static void RemoveRenderer(const UMaterialInterface* KeyMaterial)
	{
		FScopeLock Lock(&MapLock);
		MaterialToRenderer.Remove(KeyMaterial);
	}

	static bool NeedSetupBatching(const UKMWidgetComponent* InWidgetComponent);

	static AKMWidgetBatchRenderer* GetOrCreateRenderer(const UKMWidgetComponent* KeyWidget);

	static TMap<TWeakObjectPtr<const UMaterialInterface>, AKMWidgetBatchRenderer*> MaterialToRenderer;

private:
	/** for WorldToBatchRendering thread-safe accessing */
	static FCriticalSection MapLock;

	FKMWidgetBatcher() {}
	FKMWidgetBatcher(const FKMWidgetBatcher&);
	FKMWidgetBatcher& operator=(const FKMWidgetBatcher&);
};

/**
* Default class for batch rendering
*/
UCLASS()
class ENGINEEXT_API AKMWidgetBatchRenderer : public AActor
{
	GENERATED_BODY()

public:
	AKMWidgetBatchRenderer();

	const UMaterialInterface* GetBachingMaterial() const { return BachingMaterial; }
	/**
	* add reference to the RendererClass
	*/
	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

public: // AActor Interface
	virtual void BeginPlay() override;
	virtual void EndPlay(EEndPlayReason::Type EndPlayReason) override;

protected:
	friend class FKMWidgetBatcher;
	static AKMWidgetBatchRenderer* SpawnInWorld(UWorld* InWorld);

	virtual void AddWidgetComponent(UKMWidgetComponent* InWidgetComponent) {
		// default class do nothing
	}

	virtual void RemoveWidgetComponent(TWeakObjectPtr<UKMWidgetComponent> InWidgetComponent) {
		// default class do nothing
	}

	virtual bool CanRender() const { return false; }

private:
	static TSubclassOf<AKMWidgetBatchRenderer> RendererClass;

	/** remove self from the batcher */
	DECLARE_DELEGATE_OneParam(FEndPlayDelegate, const UMaterialInterface*);
	FEndPlayDelegate EndPlayDelegate;

	/** mateial for batch rendering */
	UPROPERTY(Transient)
	const UMaterialInterface* BachingMaterial;

};
 