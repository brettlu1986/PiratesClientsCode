// Fill out your copyright notice in the Description page of Project Settings.

#include "KMWidgetComponent.h"
#include "EngineExt.h"
#include "Kismet/GameplayStatics.h"

UKMWidgetComponent::UKMWidgetComponent(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
    PrimaryComponentTick.bAllowTickOnDedicatedServer = false;
	MinScale = 1.f;
}

void UKMWidgetComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
	ReturnIfTrue(IsRunningDedicatedServer());
	ReturnIfNullUObject(Widget);

	// setup batching rendering if asked
	if (Need3DBatchRendering())
	{
		auto PC = FKMWidgetBatcher::GetPlayerController(this);
		if (PC)
		{
			FKMWidgetBatcher::SetupBatching(this);
		}
		else
		{
			// if player controller is not ready, we need to skip all the following calculation
			return;
		}
	}

	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (Space == EWidgetSpace::Screen)
	{
		APlayerController* PlayerController = UGameplayStatics::GetPlayerController(this, 0);
		ReturnIfNullUObject(PlayerController);
		ReturnIfNullUObject(PlayerController->PlayerCameraManager);

		FVector CameraLocation = PlayerController->PlayerCameraManager->GetCameraLocation();
		FVector OwnerLocation = GetOwner()->GetActorLocation();
		FVector DirectionVec = CameraLocation - OwnerLocation;
		ReturnIfFalse(ScaleRate > 0);

		float fDistance = DirectionVec.Size();
		ReturnIfFalse(fDistance > MinDistance);

		if (fDistance > MaxDistance)
		{
			Widget->SetVisibility(ESlateVisibility::Collapsed);
		}
		else
		{
			Widget->SetVisibility(ESlateVisibility::Visible);
			float fScale = 1 - (fDistance - MinDistance) / ScaleRate;
			fScale = FMath::Clamp<float>(fScale, 0, 1);
			Widget->SetRenderTransformPivot(FVector2D(0.5, 1.f));
			Widget->SetRenderScale(FVector2D(fScale, fScale));
		}
	}
}
/** see SetDisableRedraw */
bool UKMWidgetComponent::ShouldDrawWidget() const
{
	if (!bDisableRedraw)
	{
		return Super::ShouldDrawWidget();
	}
	else
	{
		return false;
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
int32 CVar3DWidgetBatching = 0;
FAutoConsoleVariableRef CVar3DWidgetBatchingRef(
	TEXT("pir.3DWidgetBatching"),
	CVar3DWidgetBatching,
	TEXT("For quickly enable/disable widget batch rendering.")
);

TMap<TWeakObjectPtr<const UMaterialInterface>, AKMWidgetBatchRenderer*> FKMWidgetBatcher::MaterialToRenderer;

FCriticalSection FKMWidgetBatcher::MapLock;

TSubclassOf<AKMWidgetBatchRenderer> AKMWidgetBatchRenderer::RendererClass;

bool FKMWidgetBatcher::NeedSetupBatching(const UKMWidgetComponent* InWidgetComponent)
{
	return CVar3DWidgetBatching
		&& InWidgetComponent->Need3DBatchRendering()
		&& InWidgetComponent->NeedRedraw()
		&& InWidgetComponent->GetWorld()->IsGameWorld()
		&& InWidgetComponent->GetWidgetSpace() == EWidgetSpace::World
		;
}

void FKMWidgetBatcher::SetupBatching(UKMWidgetComponent* InWidgetComponent)
{
	// global disabled, batching is not set, world is not game
	if(!NeedSetupBatching(InWidgetComponent)) return;
	// get renderer thread-safe
	AKMWidgetBatchRenderer* BatchRenderer = GetOrCreateRenderer(InWidgetComponent);
	// can render
	if (BatchRenderer && BatchRenderer->CanRender())
	{
		BatchRenderer->AddWidgetComponent(InWidgetComponent);
	}
	else
	{
		// else disable baching
		CVar3DWidgetBatching = 0;
	}
}

 APlayerController* FKMWidgetBatcher::GetPlayerController(UKMWidgetComponent* Widget)
{
	ULocalPlayer* LPlayer = Widget->GetOwnerPlayer();
	return LPlayer ? LPlayer->GetPlayerController(nullptr) : nullptr;
}

AKMWidgetBatchRenderer* FKMWidgetBatcher::GetOrCreateRenderer(const UKMWidgetComponent* KeyWidget)
{
	const UMaterialInterface* BachingMaterial = KeyWidget->GetBatchRenderingMaterial();
	if (!BachingMaterial) return nullptr;

	AKMWidgetBatchRenderer** BatchRenderer = MaterialToRenderer.Find(BachingMaterial);
	if (!BatchRenderer)
	{
		FScopeLock Lock(&MapLock);
		BatchRenderer = MaterialToRenderer.Find(BachingMaterial);
		if (!BatchRenderer)
		{
			AKMWidgetBatchRenderer* NewRenderer = AKMWidgetBatchRenderer::SpawnInWorld(KeyWidget->GetWorld());
			NewRenderer->EndPlayDelegate.BindStatic(&FKMWidgetBatcher::RemoveRenderer);
			NewRenderer->BachingMaterial = BachingMaterial;
			MaterialToRenderer.Emplace(BachingMaterial, NewRenderer);
			BatchRenderer = &NewRenderer;
		}
		check(BatchRenderer && *BatchRenderer);
	}
	return *BatchRenderer;
}

AKMWidgetBatchRenderer::AKMWidgetBatchRenderer()
	: Super()
{

}

AKMWidgetBatchRenderer* AKMWidgetBatchRenderer::SpawnInWorld(UWorld* InWorld)
{
	if (*RendererClass == nullptr)
	{
		FString ClassName;
		GConfig->GetString(TEXT("/Script/EngineExt.KMWidgetBatchRenderer"), TEXT("RenderClassName"), ClassName, GEngineIni);
		FSoftClassPath ClassPath(ClassName);
		RendererClass = LoadClass<AKMWidgetBatchRenderer>(nullptr, *ClassPath.ToString());
	}

	if (*RendererClass != nullptr)
	{
		return Cast<AKMWidgetBatchRenderer>(InWorld->SpawnActor(*RendererClass));
	}
	
	return Cast<AKMWidgetBatchRenderer>(InWorld->SpawnActor(AKMWidgetBatchRenderer::StaticClass()));
}

void AKMWidgetBatchRenderer::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	if (*RendererClass != nullptr)
	{
		UClass* RendererClassPtr = *RendererClass;
		Collector.AddReferencedObject(RendererClassPtr);
		RendererClass = RendererClassPtr;
	}
	Super::AddReferencedObjects(InThis, Collector);
}

void AKMWidgetBatchRenderer::BeginPlay()
{
	Super::BeginPlay();
}

void AKMWidgetBatchRenderer::EndPlay(EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
	EndPlayDelegate.Execute(BachingMaterial);
}
