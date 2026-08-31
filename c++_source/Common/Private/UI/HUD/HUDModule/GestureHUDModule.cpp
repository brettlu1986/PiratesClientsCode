// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/HUD/HUDModule/GestureHUDModule.h"
#include "Common.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "Shell/EngineExtShell.h"

struct UGestureHUDModule::Impl
{
	UGestureHUDModule*	Owner;
	UTexture2D*         JoystickTexture;
	UTexture2D*         JoystickPadActiveTexture;
	UTexture2D*         JoystickPadDeactiveTexture;
	FVector2D			DistanceDelta;
	FVector2D			CurrentPosition;
	FVector2D			StartPosition;
    float               JoystickTextureSize;
	bool				bJoystickEnable;

	Impl(UGestureHUDModule* Parent)
		: Owner						(Parent)
		, JoystickTexture			(nullptr)
		, JoystickPadActiveTexture	(nullptr)
		, JoystickPadDeactiveTexture(nullptr)
		, DistanceDelta				(FVector2D::ZeroVector)
		, CurrentPosition			(FVector2D::ZeroVector)
        , JoystickTextureSize		(256.f)
		, bJoystickEnable			(false)
	{
	}

	void BeginPlay()
	{
	}

	void DrawHUD(UCanvas* Canvas)
	{
        ReturnIfNullUObject(Canvas);
		ReturnIfFalse(bJoystickEnable);
		DrawVirtualJoystick(Canvas);
	}

	void DrawVirtualJoystick(UCanvas* Canvas)
    {
        ReturnIfNullUObject(Canvas);
		if (DistanceDelta.Equals(FVector2D::ZeroVector, 0.000001f))
		{
			DrawDeactivePad(Canvas);
		}
		else
		{
			DrawTextureAndRotate(Canvas, JoystickPadActiveTexture, StartPosition, CalcDistanceDeltaAngle());
			DrawTextureAndRotate(Canvas, JoystickTexture, CurrentPosition);
		}
	}

	void DrawDeactivePad(UCanvas* Canvas)
	{
		ReturnIfNullUObject(Canvas);
		ReturnIfNullUObject(JoystickPadDeactiveTexture);

		FVector2D ViewportSize = UWidgetLayoutLibrary::GetViewportSize(Owner->GetWorld());
		float Scale = UWidgetLayoutLibrary::GetViewportScale(Owner->GetWorld());
		float TextureSize = JoystickPadDeactiveTexture->GetSizeX() * Scale;
		FVector2D Location = FVector2D(TextureSize / 2 + 40, ViewportSize.Y - 40 - TextureSize / 2);
		DrawTextureAndRotate(Canvas, JoystickPadDeactiveTexture, Location);
	}

	void DrawTextureAndRotate(UCanvas *Canvas, UTexture2D* Texture, const FVector2D& Location, float Angle = 0.f)
    {
        ReturnIfNullUObject(Canvas);
        ReturnIfNullUObject(Texture);

		float Scale = UWidgetLayoutLibrary::GetViewportScale(Owner->GetWorld());
		float TextureSize = Texture->GetSizeX() * Scale;
		FCanvasTileItem TileItem(Location - TextureSize / 2.f, Texture->Resource, FLinearColor::White);
		TileItem.Rotation	= FRotator	(0.f, Angle, 0.f);
		TileItem.PivotPoint = FVector2D	(0.5f, 0.5f);
		TileItem.Size		= FVector2D	(TextureSize, TextureSize);
		TileItem.BlendMode	= SE_BLEND_Translucent;
		Canvas->DrawItem(TileItem);
	}

	float CalcDistanceDeltaAngle()
	{
		if (FLOAT_EQUAL_ZERO(DistanceDelta.Y))
		{
			return DistanceDelta.X > 0.f ? 90.f : 180.f;
		}
		
		float Angle = FMath::Atan2(DistanceDelta.X, -DistanceDelta.Y);
		return Angle * 180.f / PI;
	}

	void AddReferencedObjects(FReferenceCollector& Collector)
	{
		Collector.AddReferencedObject(JoystickTexture, Owner);
		Collector.AddReferencedObject(JoystickPadActiveTexture, Owner);
		Collector.AddReferencedObject(JoystickPadDeactiveTexture, Owner);
	}
};

UGestureHUDModule::UGestureHUDModule(const FObjectInitializer& ObjectInitializer)
	: Super (ObjectInitializer)
	, impl  (MakeShareable(new Impl(this)))
{
}

UGestureHUDModule::~UGestureHUDModule()
{
}

void UGestureHUDModule::BeginPlay()
{
	//impl->JoystickTexture = Cast<UTexture2D>(StaticLoadObject(UTexture2D::StaticClass(), NULL, *JoystickTexturePath));
	//impl->JoystickPadActiveTexture = Cast<UTexture2D>(StaticLoadObject(UTexture2D::StaticClass(), NULL, *JoystickPadActiveTexturePath));
	//impl->JoystickPadDeactiveTexture = Cast<UTexture2D>(StaticLoadObject(UTexture2D::StaticClass(), NULL, *JoystickPadDeactiveTexturePath));

    impl->JoystickTexture = Cast<UTexture2D>(UEngineExtShell::StaticLoadObjectWithoutFlush(JoystickTexturePath));
    impl->JoystickPadActiveTexture = Cast<UTexture2D>(UEngineExtShell::StaticLoadObjectWithoutFlush(JoystickPadActiveTexturePath));
    impl->JoystickPadDeactiveTexture = Cast<UTexture2D>(UEngineExtShell::StaticLoadObjectWithoutFlush(JoystickPadDeactiveTexturePath));
}

void UGestureHUDModule::DrawHUD(UCanvas* Canvas)
{
	impl->DrawHUD(Canvas);
}

void UGestureHUDModule::RecordVirtualJoystick(const FVector2D& DistanceDelta, const FVector2D& CurrentPosition, const FVector2D& StartPosition)
{
	impl->DistanceDelta = DistanceDelta;
	impl->CurrentPosition = CurrentPosition;
	impl->StartPosition = StartPosition;
}

void UGestureHUDModule::HideVirtualJoystick()
{
	impl->DistanceDelta = FVector2D::ZeroVector;
	impl->CurrentPosition = FVector2D::ZeroVector;
}

void UGestureHUDModule::SetVirtualJoystickEnable(bool Enable)
{
	impl->bJoystickEnable = Enable;
}

void UGestureHUDModule::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	UGestureHUDModule* This = CastChecked<UGestureHUDModule>(InThis);
	if (This->impl.IsValid())
	{
		This->impl->AddReferencedObjects(Collector);
	}
	Super::AddReferencedObjects(This, Collector);
}