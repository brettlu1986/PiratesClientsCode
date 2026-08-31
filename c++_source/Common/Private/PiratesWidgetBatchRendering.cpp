//

#include "PiratesWidgetBatchRendering.h"
#include "Common.h"
#include "PrimitiveSceneProxy.h"
#include "Slate/WidgetRenderer.h"

DECLARE_STATS_GROUP(TEXT("Pir_WidgetBatching"), STATGROUP_PirWidgetBatching, STATCAT_Advanced);
DECLARE_CYCLE_STAT(TEXT("Pir_AddWidget"), STAT_PirAddWidget, STATGROUP_PirWidgetBatching);
DECLARE_CYCLE_STAT(TEXT("Pir_UpdateRenderingData"), STAT_PirUpdateRenderingData, STATGROUP_PirWidgetBatching);

float GTimeIntervalToSortWidgets = 1.f;
FAutoConsoleVariableRef TimeIntervalToSortWidgetCVar(
	TEXT("pir.TimeIntervalToSortWidgets"),
	GTimeIntervalToSortWidgets,
	TEXT("Time interval to sort widgets from back to front in widget batching.")
);

/**
* every this time, the batching renderer will use the desired size to draw the widget when the next redrawing happening
*/
static float GTimeIntervalResetCurrentDrawSize = 100.f;
FAutoConsoleVariableRef CVarTimeIntervalResetCurrentDrawSize(
	TEXT("pir.TimeIntervalResetCurrentDrawSize"),
	GTimeIntervalResetCurrentDrawSize,
	TEXT("every this time, the batching renderer will use the desired size to draw the widget when the next redrawing happening")
);
/**
* 主角色的名字片使用此值进行缩放
*/
TAutoConsoleVariable<float> CVarCharacterNameSizeScale(
	TEXT("pir.CharacterNameSizeScale"),
	0.35f,
	TEXT("Character Name Size Scale.")
);

APiratesWidgetBatchRenderer::APiratesWidgetBatchRenderer()
:Super()
{
	PrimaryActorTick.bCanEverTick = true;
	PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	RootComponent = CreateDefaultSubobject<UPirWidgetBatchRenderingComponent>(TEXT("UPirWidgetBatchRenderingComponent"));
	RenderComponentCached = (UPirWidgetBatchRenderingComponent*)RootComponent;
	RenderComponentCached->SetDrawSize(FVector2D(1024, 512));
	RenderComponentCached->SetRedrawTime(1.f);
	RenderComponentCached->SetDrawAtDesiredSize(true);
}

static FORCEINLINE bool IsViewTarget(AActor* WidgetOwner, APlayerController* PC)
{
	check(WidgetOwner);
	check(PC);
	return PC->GetPawn() == WidgetOwner;
}

void APiratesWidgetBatchRenderer::AddWidgetComponent(UKMWidgetComponent* InWidgetComponent)
{
	check(InWidgetComponent);
	//if (IsViewTarget(InWidgetComponent->GetOwner(), FKMWidgetBatcher::GetPlayerController(InWidgetComponent))) return;

	TWeakObjectPtr<UKMWidgetComponent> WeakWidgetPtr(InWidgetComponent);
	check(WeakWidgetPtr.IsValid());

	FScopeLock Lock(&WidgetSetLock);
	bool bAlreadyAdded = WidgetSet.Contains(WeakWidgetPtr);
	// add to render component
	if (RenderComponentCached->AddWidget(WeakWidgetPtr, bAlreadyAdded))
	{
		// add to WidgetSet
		WidgetSet.Emplace(WeakWidgetPtr);
	}
	WeakWidgetPtr->SetRedraw(false);
}

void APiratesWidgetBatchRenderer::RemoveWidgetComponent(TWeakObjectPtr<UKMWidgetComponent> InWidgetComponent)
{
	// remove widget from WidgetSet
	{
		FScopeLock Lock(&WidgetSetLock);
		WidgetSet.Remove(InWidgetComponent);
	}
	// remove widget from RenderComponentCached
	RenderComponentCached->RemoveWidget(InWidgetComponent);
}

void APiratesWidgetBatchRenderer::BeginPlay()
{
	Super::BeginPlay();
}

void APiratesWidgetBatchRenderer::EndPlay(EEndPlayReason::Type Reason)
{
	Super::EndPlay(Reason);
	for (const auto& widget : WidgetSet)
	{
		RenderComponentCached->RemoveWidget(widget);
	}
	WidgetSet.Empty();
}

void APiratesWidgetBatchRenderer::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	if (!CVar3DWidgetBatching) return;

	ULocalPlayer* TargetPlayer = RenderComponentCached->GetOwnerPlayer();
	auto PC = TargetPlayer ? TargetPlayer->GetPlayerController(nullptr) : nullptr;
	if (PC && PC->GetPawn())
	{
		//SetActorLocation(PC->GetPawn()->GetActorLocation());
		SetActorLocation(PC->PlayerCameraManager->GetCameraLocation());
		RenderComponentCached->CameraRot = PC->PlayerCameraManager->GetCameraRotation();
		RenderComponentCached->CameraLoc = PC->PlayerCameraManager->GetCameraLocation();

		// get valid comps
		TArray<FWeakWidgetCompPtr> InValidComps;
		for (auto& elem : WidgetSet)
		{
			if (!elem.IsValid())
			{
				InValidComps.Add(elem);
			}
		}

		// remove invalid comps
		for (auto& elem : InValidComps)
		{
			RemoveWidgetComponent(elem);
		}

		// sort and update render data
		if (WidgetSet.Num())
		{
			RenderComponentCached->SortWidgetsBySize();
			RenderComponentCached->UpdateRenderData();
		}

		// 如果没有实时刷新的widget恢复可见状态，则保持响应刷新
		RenderComponentCached->SetManuallyRedraw(true);
		for (auto& Widget : WidgetSet)
		{
			TSharedPtr<SWidget> SlateWidget =  Widget->GetCurrentSlateWidget();
			EVisibility evisibility = SlateWidget->GetVisibility();
			if (evisibility != EVisibility::Collapsed && evisibility != EVisibility::Hidden && !Widget->GetManuallyRedraw())
			{
				RenderComponentCached->SetManuallyRedraw(false);
				break;
			}
		}
	}
}
///////////////////////////////////////////////////////////////////////////
// FWidgetBatchRendering3DSceneProxy
///////////////////////////////////////////////////////////////////////////

struct FWidgetBatchRenderingData
{
	typedef uint32 IndexType;
	TArray<FDynamicMeshVertex> MeshVertices;
	TArray<IndexType> Indices;
};

class FWidgetBatchRendering3DSceneProxy final : public FPrimitiveSceneProxy
{
	FVector Origin;
	UTextureRenderTarget2D* RenderTarget;
	UMaterialInstanceDynamic* MaterialInstance;
	FMaterialRelevance MaterialRelevance;
	UBodySetup* BodySetup;
	EWidgetBlendMode BlendMode;
	EWidgetGeometryMode GeometryMode;
	float ArcAngle;

	TSharedPtr<FWidgetBatchRenderingData> RenderingData;
	FMatrix IdentityTransform;

public:
	SIZE_T GetTypeHash() const override
	{
		static size_t UniquePointer;
		return reinterpret_cast<size_t>(&UniquePointer);
	}

	FWidgetBatchRendering3DSceneProxy(UPirWidgetBatchRenderingComponent* InComponent)
		: FPrimitiveSceneProxy(InComponent)
		, RenderTarget(InComponent->GetRenderTarget())
		, MaterialInstance(InComponent->GetMaterialInstance())
		, BodySetup(InComponent->GetBodySetup())
		, BlendMode(InComponent->GetBlendMode())
		, GeometryMode(InComponent->GetGeometryMode())
		, ArcAngle(FMath::DegreesToRadians(InComponent->GetCylinderArcAngle()))
		, RenderingData(nullptr)
	{
		bWillEverBeLit = false;
		MaterialRelevance = MaterialInstance->GetRelevance(GetScene().GetFeatureLevel());

		IdentityTransform = FTransform::Identity.ToMatrixWithScale();
		// Fix sp renderer indirect lighting switch bug. by zhaoshuai2
		//IndirectLightingType = 0;
	}

	/** FPrimitiveSceneProxy interface. */
	virtual void GetDynamicMeshElements(const TArray<const FSceneView*>& Views, const FSceneViewFamily& ViewFamily,
		uint32 VisibilityMap, FMeshElementCollector& Collector) const override
	{
		// do not render during a scene capture
		if (Views[0]->bIsSceneCapture) return;

		if (!CVar3DWidgetBatching)
		{
			((TSharedPtr<FWidgetBatchRenderingData>)RenderingData).Reset();
			return;
		}

		FMaterialRenderProxy* ParentMaterialProxy = MaterialInstance->GetRenderProxy();
		if (RenderTarget && GeometryMode == EWidgetGeometryMode::Plane)
		{
			if (RenderTarget->Resource && RenderingData.IsValid())
			{
				FDynamicMeshBuilder MeshBuilder(Views[0]->GetFeatureLevel());
				MeshBuilder.AddVertices(RenderingData->MeshVertices);
				MeshBuilder.AddTriangles(RenderingData->Indices);

				for (int32 ViewIndex = 0; ViewIndex < Views.Num(); ++ViewIndex)
				{
					MeshBuilder.GetMesh(IdentityTransform, ParentMaterialProxy, SDPG_World, false, true, ViewIndex, Collector);
				}
				// consume the render data
				((TSharedPtr<FWidgetBatchRenderingData>)RenderingData).Reset();
			}
		}
	}

	void UpdateMeshData_RenderThread(FWidgetBatchRenderingData* InRenderingData)
	{
		// todo : SCOPE_CYCLE_COUNTER

		check(IsInRenderingThread());

		if (!InRenderingData) return;

		RenderingData = MakeShareable(InRenderingData);
	}

	virtual FPrimitiveViewRelevance GetViewRelevance(const FSceneView* View) const override
	{
		bool bVisible = true;

		FPrimitiveViewRelevance Result;

		MaterialRelevance.SetPrimitiveViewRelevance(Result);

		Result.bDrawRelevance = IsShown(View) && bVisible && View->Family->EngineShowFlags.WidgetComponents;
		Result.bDynamicRelevance = true;
		Result.bShadowRelevance = false;
		Result.bEditorPrimitiveRelevance = false;

		// For non-transparent dynamic element gathering in SPRenderer, should set lazyGather to true.
		//Result.bLazyGather = true;

		return Result;
	}

	virtual void GetLightRelevance(const FLightSceneProxy* LightSceneProxy, bool& bDynamic, bool& bRelevant, bool& bLightMapped, bool& bShadowMapped) const override
	{
		bDynamic = false;
		bRelevant = false;
		bLightMapped = false;
		bShadowMapped = false;
	}

	virtual void OnTransformChanged() override
	{
		Origin = GetLocalToWorld().GetOrigin();
	}

	virtual bool CanBeOccluded() const override
	{
		return !MaterialRelevance.bDisableDepthTest;
	}

	virtual uint32 GetMemoryFootprint(void) const override { return(sizeof(*this) + GetAllocatedSize()); }
};
///////////////////////////////////////////////////////////////////////////
// UPirWidgetBatchRenderingComponent
///////////////////////////////////////////////////////////////////////////
void UPirWidgetBatchRenderingComponent::BeginPlay()
{
	Super::BeginPlay();

	TSharedPtr<SWrapBox> WrapBox = SNew(SWrapBox);
	WrapBox->SetWrapWidth(1024);
	// Test this !!!
	WrapBox->SetVisibility(EVisibility::HitTestInvisible);
	SetSlateWidget(WrapBox);

	TranslucencySortPriority = 1;

	SetCollisionEnabled(ECollisionEnabled::NoCollision);

	bManuallyRedraw = true;

	check(bDrawAtDesiredSize);

	Space = EWidgetSpace::World;

	BaseScaleFactor = 0.f;

	bBaseScaleFactorResolved = false;

	DefaultDrawSize = DrawSize;

	LastTimeDrawAtDesiredSize = 0.0;
}

FBoxSphereBounds UPirWidgetBatchRenderingComponent::CalcBounds(const FTransform& LocalToWorld) const
{
	/*FBoxSphereBounds TransformedBounds = LocalBounds;
	TransformedBounds.BoxExtent *= BoundsScale;
	TransformedBounds.SphereRadius *= BoundsScale;
	return TransformedBounds;*/
	FBoxSphereBounds TransformedBounds(FBox(FVector(-1000, -1000, -1000), FVector(1000, 1000, 1000)));
	TransformedBounds = TransformedBounds.TransformBy(LocalToWorld);
	TransformedBounds.BoxExtent *= BoundsScale;
	TransformedBounds.SphereRadius *= BoundsScale;
	return TransformedBounds;
}

FPrimitiveSceneProxy* UPirWidgetBatchRenderingComponent::CreateSceneProxy()
{
	if (CurrentSlateWidget.IsValid())
	{
		if (!MaterialInstance)
		{
			APiratesWidgetBatchRenderer* Renderer = Cast<APiratesWidgetBatchRenderer>(GetOwner());
			check(Renderer);
			UMaterialInterface* BaseMaterial = const_cast<UMaterialInterface*>(Renderer->GetBachingMaterial());
			check(BaseMaterial);
			MaterialInstance = UMaterialInstanceDynamic::Create(BaseMaterial, this);
			UpdateMaterialInstanceParameters();
		}
		RequestRedraw();
		LastWidgetRenderTime = 0;
		return new FWidgetBatchRendering3DSceneProxy(this);
	}
	return nullptr;
}

void UPirWidgetBatchRenderingComponent::DrawWidgetToRenderTarget(float DeltaTime)
{
	if (GUsingNullRHI)
	{
		return;
	}

	if (!SlateWindow.IsValid())
	{
		return;
	}

	const int32 MaxAllowedDrawSize = GetMax2DTextureDimension();
	if (DrawSize.X <= 0 || DrawSize.Y <= 0 || DrawSize.X > MaxAllowedDrawSize || DrawSize.Y > MaxAllowedDrawSize)
	{
		return;
	}

	CurrentDrawSize = DrawSize;

	const float DrawScale = 1.0f;

	// force to draw at desired size
	// the draw size will be scaled up when collected widgets ask for larger area
	{
		SlateWindow->SlatePrepass(DrawScale);

		FVector2D DesiredSize = SlateWindow->GetDesiredSize();
		DesiredSize.X = FMath::RoundToInt(DesiredSize.X);
		DesiredSize.Y = FMath::RoundToInt(DesiredSize.Y);

		if (GetCurrentTime() - LastTimeDrawAtDesiredSize >= GTimeIntervalResetCurrentDrawSize)
		{
			/// return to the initialize size
			CurrentDrawSize = DefaultDrawSize;
			LastTimeDrawAtDesiredSize = GetCurrentTime();
		}
		// get max size
		CurrentDrawSize.X = FMath::Max<int32>(CurrentDrawSize.X, DesiredSize.X);
		CurrentDrawSize.Y = FMath::Max<int32>(CurrentDrawSize.Y, DesiredSize.Y);

		WidgetRenderer->SetIsPrepassNeeded(false);
	}

	if (CurrentDrawSize != DrawSize)
	{
		DrawSize = CurrentDrawSize;
		UpdateBodySetup(true);
		RecreatePhysicsState();
	}

	UpdateRenderTarget(CurrentDrawSize);

	// The render target could be null if the current draw size is zero
	if (RenderTarget)
	{
		bRedrawRequested = false;

		WidgetRenderer->DrawWindow(
			RenderTarget,
			SlateWindow->GetHittestGrid(),
			SlateWindow.ToSharedRef(),
			DrawScale,
			CurrentDrawSize,
			DeltaTime);

		LastWidgetRenderTime = GetCurrentTime();
	}
}

bool UPirWidgetBatchRenderingComponent::AddWidget(FWeakWidgetCompPtr WidgetPtr, bool bAlreadAdded)
{
	check(WidgetPtr.IsValid());
	bool bAddSuccessful = true;
	if (!bAlreadAdded)
	{
		bAddSuccessful = false;
		FScopeLock Lock(&CompSlotLock);
		// attach the widget to the slot
		TSharedPtr<SWidget> TargetWidget = WidgetPtr->GetCurrentSlateWidget();
		if (TargetWidget.IsValid())
		{
			// get a new slot
			SWrapBox::FSlot* NewSlot;
			SWrapBox* SWBox = (SWrapBox*)SlateWidget.Get();
			NewSlot = &SWBox->AddSlot();
			check(NewSlot);
			NewSlot->AttachWidget(TargetWidget.ToSharedRef());
			// map the widget and slot
			ComponentToSlotMap.Emplace(WidgetPtr, NewSlot);
			bAddSuccessful = true;
		}
	}
	if (bAddSuccessful)
	{
		// 禁止重绘
		WidgetPtr->SetDisableRedraw(true);

		// 如果WidgetPtr为非手工重绘，将RenderComponentCached设置为非手工重绘
		if (!WidgetPtr->GetManuallyRedraw())
		{
			SetManuallyRedraw(false);
			// 同时设RenderComponentCached更新率为30帧每秒
			SetRedrawTime(0.033f);
		}
	}
	// notify redraw
	RequestRedraw();
	return bAddSuccessful;
}

void UPirWidgetBatchRenderingComponent::RemoveWidget(FWeakWidgetCompPtr WidgetPtr)
{
	SWrapBox::FSlot** SlotValuePtr = ComponentToSlotMap.Find(WidgetPtr);
	if (SlotValuePtr)
	{
		const TSharedRef<SWidget>& WidgetRef = (*SlotValuePtr)->GetWidget();
		if (WidgetRef != SNullWidget::NullWidget && SlateWidget.IsValid())
		{
			((SWrapBox*)SlateWidget.Get())->RemoveSlot(WidgetRef);
		}
		ComponentToSlotMap.Remove(WidgetPtr);

		// 如果没有Widget需要实时刷新了，变更到手工绘制方式
		bool bNeedManuallyRedraw = true;
		for (auto& aPair : ComponentToSlotMap)
		{
			if (aPair.Key.IsValid() && !aPair.Key->GetManuallyRedraw())
			{
				bNeedManuallyRedraw = false;
				break;
			}
		}
		SetManuallyRedraw(bNeedManuallyRedraw);

		// notify redraw
		RequestRedraw();
	}
}

void UPirWidgetBatchRenderingComponent::SortWidgetsBySize()
{
	SWrapBox* WrapBox = (SWrapBox*)SlateWidget.Get();
	TPanelChildren<SWrapBox::FSlot>* Slots = (TPanelChildren<SWrapBox::FSlot>*)WrapBox->GetChildren();
	Slots->Sort([](const SWrapBox::FSlot& A, const SWrapBox::FSlot& B)
	{
		return A.GetWidget()->GetCachedGeometry().GetLocalSize().Y > B.GetWidget()->GetCachedGeometry().GetLocalSize().Y;
	});
}

void UPirWidgetBatchRenderingComponent::UpdateRenderData()
{
	SCOPE_CYCLE_COUNTER(STAT_PirUpdateRenderingData);
	if (SceneProxy && RenderTarget)
	{
		FWidgetBatchRenderingData* NewRenderingData = new FWidgetBatchRenderingData;

		// calculate the mesh data
		TArray<FDynamicMeshVertex>& MeshVertices = NewRenderingData->MeshVertices;
		auto& Indices = NewRenderingData->Indices;

		// the number of widgets to draw
		const int32 NumWidgets = ComponentToSlotMap.Num();

		// a widget needs 4 vertices for drawing
		const int32 NumWidgetVertices(4);

		// the total number of vectors to calculate for rendering a widget
		const int32 NumWidgetVectsToCalc(NumWidgetVertices);

		// set the max number to hold and allocate memory without slack
		MeshVertices.Reset(NumWidgetVectsToCalc * NumWidgets);
		Indices.Reset(NumWidgets * 6);

		// set the array number so can be directly accessed by operator[]
		MeshVertices.AddZeroed(MeshVertices.Max());
		Indices.AddZeroed(Indices.Max());

		// see FDynamicMeshBuilder::AddVertex
		float TangentZ_W = GetBasisDeterminantSign(FVector(0, -1, 0), FVector(0, 0, -1), FVector(1, 0, 0)) < 0 ? 0 : 255;

		// sort the widget componets
		SortWidgetCompsFrontToBack();

		// for every widget, calculate the 4 vertices, texcoords and indices
		APlayerController* PC = GetWorld()->GetFirstPlayerController();
		check(PC);
		uint32 WidgetId = 0;

		for(auto& Elem : ComponentToSlotMap)
		{
			check(WidgetId < (uint32)NumWidgets);
			uint32 BaseVertOffset = WidgetId * NumWidgetVectsToCalc;
			uint32 BaseIndxOffset = WidgetId * 6; // 6 indices a widget
			++WidgetId;

			const TSharedRef<SWidget>& lWidget = Elem.Value->GetWidget();
			FWeakWidgetCompPtr lComp = Elem.Key;
			const FGeometry& lGeometry = lWidget->GetCachedGeometry();
			
			FVector2D Size = lGeometry.GetLocalSize();
			if (Size.X == 0 || Size.Y == 0) continue;
			if (!lComp->GetVisibleFlag()) continue;

			// get the component translation
			FTransform ComponentTransform = lComp->GetComponentTransform();

			// Calc the scale
			float Scale = CVarCharacterNameSizeScale.GetValueOnGameThread();
			if (lComp->GetBatchRenderingBaseViewSize() != 0.f
				&& !IsViewTarget(lComp->GetOwner(), PC))
			{
#if 0
				if (!bBaseScaleFactorResolved)
				{
					check(PC->PlayerCameraManager);
					bBaseScaleFactorResolved = true;

					FMatrix ProjectionMatrix = PC->PlayerCameraManager->GetCameraCachePOV().CalculateProjectionMatrix();
					/* another way to get the projection matrix, comment here to give some hint
					FSceneViewProjectionData ProjectionData;
					bScaleFactorResolved = LPlayer->GetProjectionData(LPlayer->ViewportClient->Viewport, EStereoscopicPass::eSSP_FULL, ProjectionData);
					ProjectionData.ProjectionMatrix = AdjustProjectionMatrixForRHI(ProjectionData.ProjectionMatrix);
					*/
					BaseScaleFactor = FMath::Max<float>(ProjectionMatrix.M[0][0], ProjectionMatrix.M[1][1]);
					if (BaseScaleFactor != 0.f)
					{
						BaseScaleFactor = 1.f / BaseScaleFactor;
					}
				}
#endif				
				//if (BaseScaleFactor != 0.f)
				{
					// tand(fov/2), fov = 45
					Scale = 0.414f * lComp->GetBatchRenderingBaseViewSize() * FVector::Dist(ComponentTransform.GetTranslation(), CameraLoc) / Size.Y;
					const float WidgetMinScale = lComp->GetBatchRenderingMinScale();
					const float WidgetMaxScale = lComp->GetBatchRenderingMaxScale();
					Scale = FMath::Max(Scale, WidgetMinScale);
					if (WidgetMaxScale > 0.f && WidgetMaxScale > WidgetMinScale)
					{
						Scale = FMath::Min(Scale, WidgetMaxScale);
					}
				}
			} // ~ if(lComp->GetBatchRenderingBaseViewSize() != 0.f)

			// see FWidget3DSceneProxy::GetDynamicMeshElements, but use pivot of the source comp
			const FVector2D lPivot = lComp->GetPivot();
			float U = Size.X * lPivot.X * Scale;
			float V = -Size.Y * lPivot.Y * Scale;
			float UL = -Size.X * (1.0f - lPivot.X) * Scale;
			float VL = Size.Y * (1.0f - lPivot.Y) * Scale;

			// convert to the normalized tex size
			Size.X /= RenderTarget->SizeX;
			Size.Y /= RenderTarget->SizeY;

			// get the upper left texcoord
			FVector2D TexCoord = lGeometry.AbsoluteToLocal(FVector2D::ZeroVector);
			TexCoord.X /= RenderTarget->SizeX;
			TexCoord.Y /= RenderTarget->SizeY;

			ComponentTransform.SetRotation(FQuat::Identity);

			MeshVertices[BaseVertOffset].Position = ComponentTransform.TransformPosition(CameraRot.RotateVector(-FVector(0, U, V)));
			MeshVertices[BaseVertOffset].TextureCoordinate[0] = FVector2D(-TexCoord.X, -TexCoord.Y);
			MeshVertices[BaseVertOffset].TangentX = FVector(0, -1, 0);
			MeshVertices[BaseVertOffset].TangentZ = FVector(1, 0, 0);
			MeshVertices[BaseVertOffset].TangentZ.Vector.W = TangentZ_W;
			MeshVertices[BaseVertOffset].Color = FColor::White;

			MeshVertices[BaseVertOffset + 1].Position = ComponentTransform.TransformPosition(CameraRot.RotateVector(-FVector(0, U, VL)));
			MeshVertices[BaseVertOffset + 1].TextureCoordinate[0] = FVector2D(-TexCoord.X, -TexCoord.Y + Size.Y);
			MeshVertices[BaseVertOffset + 1].TangentX = FVector(0, -1, 0);
			MeshVertices[BaseVertOffset + 1].TangentZ = FVector(1, 0, 0);
			MeshVertices[BaseVertOffset + 1].TangentZ.Vector.W = TangentZ_W;
			MeshVertices[BaseVertOffset + 1].Color = FColor::White;

			//MeshVertices[BaseVertOffset + 2].Position = ComponentTransform.TransformPosition(-FVector(0, UL, VL)) + ComponentTranslation;
			MeshVertices[BaseVertOffset + 2].Position = ComponentTransform.TransformPosition(CameraRot.RotateVector(-FVector(0, UL, VL)));
			MeshVertices[BaseVertOffset + 2].TextureCoordinate[0] = FVector2D(-TexCoord.X + Size.X, -TexCoord.Y + Size.Y);
			MeshVertices[BaseVertOffset + 2].TangentX = FVector(0, -1, 0);
			MeshVertices[BaseVertOffset + 2].TangentZ = FVector(1, 0, 0);
			MeshVertices[BaseVertOffset + 2].TangentZ.Vector.W = TangentZ_W;
			MeshVertices[BaseVertOffset + 2].Color = FColor::White;

			MeshVertices[BaseVertOffset + 3].Position = ComponentTransform.TransformPosition(CameraRot.RotateVector(-FVector(0, UL, V)));
			MeshVertices[BaseVertOffset + 3].TextureCoordinate[0] = FVector2D(-TexCoord.X + Size.X, -TexCoord.Y);
			MeshVertices[BaseVertOffset + 3].TangentX = FVector(0, -1, 0);
			MeshVertices[BaseVertOffset + 3].TangentZ = FVector(1, 0, 0);
			MeshVertices[BaseVertOffset + 3].TangentZ.Vector.W = TangentZ_W;
			MeshVertices[BaseVertOffset + 3].Color = FColor::White;

			Indices[BaseIndxOffset + 0] = BaseVertOffset;
			Indices[BaseIndxOffset + 1] = BaseVertOffset + 1;
			Indices[BaseIndxOffset + 2] = BaseVertOffset + 2;
			Indices[BaseIndxOffset + 3] = BaseVertOffset;
			Indices[BaseIndxOffset + 4] = BaseVertOffset + 2;
			Indices[BaseIndxOffset + 5] = BaseVertOffset + 3;

			// update TempBox, 暂时留作参考
			/*TempBox += MeshVertices[BaseVertOffset].Position;
			TempBox += MeshVertices[BaseVertOffset + 1].Position;
			TempBox += MeshVertices[BaseVertOffset + 2].Position;
			TempBox += MeshVertices[BaseVertOffset + 3].Position;*/
		}

		/*
		* send the mesh data to the mesh builder in the scene proxy
		*/
		auto lSceneProxy = SceneProxy;
		ENQUEUE_RENDER_COMMAND(FWidgetBatchRenderingUpdateRenderingData)(
			[lSceneProxy, NewRenderingData](FRHICommandListImmediate& RHICmdList)
			{
				((FWidgetBatchRendering3DSceneProxy*)lSceneProxy)->UpdateMeshData_RenderThread(NewRenderingData);
			}
		);
	}
}

void UPirWidgetBatchRenderingComponent::SortWidgetCompsFrontToBack()
{
	if (GetCurrentTime() - LastWidgetSortTime >= GTimeIntervalToSortWidgets)
	{
		ComponentToSlotMap.KeySort(
			[&](const FWeakWidgetCompPtr& A, const FWeakWidgetCompPtr& B)
		{
			return FVector::DistSquared(A->GetComponentTransform().GetTranslation(), CameraLoc) >
				FVector::DistSquared(B->GetComponentTransform().GetTranslation(), CameraLoc);
		});
		LastWidgetSortTime = GetCurrentTime();
	}
}
