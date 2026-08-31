// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/HUD/HUDModule/ComboHUDModule.h"
#include "Common.h"
#include "UI/HUD/CustomWidget/BitmapFontText.h"
#include "UI/HUD/HUDModule/BitmapFontHUDModule.h"

struct UComboHUDModule::Impl
{
	UComboHUDModule	*Owner;
	UBitmapFontText	*ComboText;
	int32			ComboCount;			// 当前连击数
	float			ElapseTime;			// 距离上次连击已消逝时间
	FVector2D		ComboPosition;		// Combo图标绘制位置
	float			ComboTextSize;		// Combo数字绘制基础大小

	Impl(UComboHUDModule* Parent) 
		: Owner			(Parent)
		, ComboText		(nullptr)
		, ComboCount	(0)
		, ElapseTime	(0.f)
	{
	}

	void BeginPlay()
	{
		auto BitmapFontTextModule = Owner->PiratesHUD->GetBitmapFontHUDModule();
		check(BitmapFontTextModule);
		ComboText = BitmapFontTextModule->Acquire();
		check(ComboText);
	}

	void Tick(float DeltaSeconds)
	{
		ElapseTime += DeltaSeconds;
		// 超时重置连击数
		if (ElapseTime >= Owner->MaxLastTime)
		{
			ComboCount = 0;
		}
	}

	void DrawHUD(UCanvas *Canvas)
    {
        ReturnIfNullUObject(Canvas);
        ReturnIfNullUObject(ComboText);
		// 连击数必须达到最小连击显示数才进行绘制
		ComboText->Visible = ComboCount >= Owner->MinComboCount;
        ReturnIfFalse(ComboText->Visible);

		const float Delta = Owner->MaxLastTime - ElapseTime;
		float Alpha = Delta > Owner->AlphaAnimTime ? 1.f : Delta / Owner->AlphaAnimTime;
		DrawCombo(Canvas, Alpha);
		DrawComboText(Alpha);
	}

	void DrawCombo(UCanvas *Canvas, float Alpha)
    {
        ReturnIfNullUObject(Owner->ComboTexture);
        ReturnIfNullUObject(GEngine->GameViewport);
		const FVector2D ViewportSize = FVector2D(GEngine->GameViewport->Viewport->GetSizeXY());
		const float ComboSizeX = Owner->ComboTexture->GetSizeX();
		const float ComboSizeY = Owner->ComboTexture->GetSizeY();
		ComboPosition.X = ViewportSize.X - ComboSizeX - 3 * ComboSizeY;
		ComboPosition.Y = ViewportSize.Y / 5;
		FCanvasTileItem TileItem(ComboPosition, Owner->ComboTexture->Resource, FLinearColor(1.f, 1.f, 1.f, Alpha));
		TileItem.BlendMode = SE_BLEND_Translucent;
		Canvas->DrawItem(TileItem);
	}

	void DrawComboText(float Alpha)
	{
		const float DrawScale = FMath::Clamp<float>(Owner->MaxScale - ElapseTime * Owner->ScaleSpeed, 1, Owner->MaxScale);
		ComboText->Position = FVector2D(ComboPosition.X + Owner->ComboTexture->GetSizeX() + Owner->ComboMarginLeft, ComboPosition.Y);
		ComboText->FontKerning = Owner->ComboTextKerning;
		ComboText->Text = FString::Printf(TEXT("%d"), ComboCount);
		ComboText->FontSize = Owner->ComboTexture->GetSizeY() * DrawScale;
		ComboText->Alpha = Alpha;
		ComboText->Draw(Owner->PiratesHUD);
	}

	void AddCombo()
	{
		ElapseTime = 0;
		ComboCount++;
	}
};

UComboHUDModule::UComboHUDModule(const FObjectInitializer& ObjectInitializer)
	: Super				(ObjectInitializer)
	, impl				(MakeShareable(new Impl(this)))
	, ComboTexture		(nullptr)
	, MinComboCount		(1)
	, MaxLastTime		(2.f)
	, MaxScale			(1.4f)
	, ComboTextKerning	(-0.3f)
	, ComboMarginLeft	(-10.f)
	, AlphaAnimTime		(0.8f)
	, ScaleSpeed		(3.f)
{

}

UComboHUDModule::~UComboHUDModule()
{

}

void UComboHUDModule::BeginPlay()
{
	impl->BeginPlay();
}

void UComboHUDModule::Tick(float DeltaSeconds)
{
	impl->Tick(DeltaSeconds);
}

void UComboHUDModule::DrawHUD(UCanvas *Canvas)
{
	impl->DrawHUD(Canvas);
}

void UComboHUDModule::AddCombo()
{
	impl->AddCombo();
}

void UComboHUDModule::SetComboTextType(uint8 TextType)
{
	impl->ComboText->SetFontType(TextType);
}