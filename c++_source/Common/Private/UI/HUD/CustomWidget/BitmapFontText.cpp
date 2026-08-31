// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/HUD/CustomWidget/BitmapFontText.h"
#include "Common.h"
#include "UI/HUD/HUDModule/BitmapFontHUDModule.h"

struct UBitmapFontText::Impl
{
	UBitmapFontText			*Owner;
	UBitmapFontHUDModule	*BitmapFontHUDModule;
	UTexture2D				*Texture;
	uint8					FontType;

	TMap<FString, FBitmapCharData> CharDataMap;

	Impl(UBitmapFontText* BitmapFontText)
		: Owner					(BitmapFontText)
		, BitmapFontHUDModule	(nullptr)
		, Texture				(nullptr)
		, FontType				(0)
	{
	}

	void Init(UBitmapFontHUDModule* InBitmapFontHUDModule)
	{
		check(InBitmapFontHUDModule);
		BitmapFontHUDModule = InBitmapFontHUDModule;
		Texture = BitmapFontHUDModule->GetFontTexture(FontType);
	}

	void Draw(AHUD* HUD)
	{
		ReturnIfFalse(Owner->Visible);
		ReturnIfNullUObject(HUD);
		ReturnIfNullUObject(Texture);

		float LastXEnd = Owner->Position.X;
		for (int i = 0; i < Owner->Text.Len(); ++i)
		{
			const FBitmapCharData& Data = GetCharData(Owner->Text.Mid(i, 1));
			if ((Data.Width == 0.f) && (Data.Height == 0.f))
			{
				continue;
			}
			const float Width = Data.Width * Owner->FontSize / Data.Height;
			HUD->DrawTexture(Texture
				, LastXEnd
				, Owner->Position.Y
				, Width
				, Owner->FontSize
				, Data.TextureU
				, Data.TextureV
				, Data.TextureUWidth
				, Data.TextureVHeight
				, FLinearColor(1.f, 1.f, 1.f, Owner->Alpha));

			LastXEnd += Width + Owner->FontKerning * Owner->FontSize;
		}
	}

	float GetFontWidth()
	{
		if ((Owner->FontSize == 0.f) || (Owner->Text.Len() == 0))
		{
			return 0.f;
		}

		float Width = 0.f;
		for (int i = 0; i < Owner->Text.Len(); ++i)
		{
			const FBitmapCharData& Data = GetCharData(Owner->Text.Mid(i, 1));
			Width += Data.Width * Owner->FontSize / Data.Height;
		}
		Width += (Owner->Text.Len() - 1) * Owner->FontKerning;
		return Width;
	}

	const FBitmapCharData& GetCharData(FString Char)
	{
		if (!CharDataMap.Contains(Char))
		{
			const FBitmapCharData& Data = BitmapFontHUDModule->GetCharData(FontType, Char);
			CharDataMap.Add(Char, Data);
		}
		return CharDataMap[Char];
	}

	void SetFontType(uint8 InFontType)
	{
		FontType = InFontType;
		Texture = BitmapFontHUDModule->GetFontTexture(FontType);
		CharDataMap.Empty();
	}

	void Reset()
	{
		SetFontType(0);
		Owner->Position		= FVector2D(0.f, 0.f);
		Owner->FontSize		= 128.f;
		Owner->FontKerning	= 0.f;
		Owner->Alpha		= 1.f;
		Owner->Text			= "";
		Owner->Visible		= true;
	}
};
UBitmapFontText::UBitmapFontText(const FObjectInitializer& ObjectInitializer)
	: Super			(ObjectInitializer)
	, impl			(MakeShareable(new Impl(this)))
	, Position		(0.f, 0.f)
	, FontSize		(128.f)
	, FontKerning	(0.f)
	, Alpha			(1.f)
	, Text			("")
	, Visible		(true)
{
}

UBitmapFontText::~UBitmapFontText()
{
}

void UBitmapFontText::Init(UBitmapFontHUDModule* BitmapFontHUDModule)
{
	impl->Init(BitmapFontHUDModule);
}

void UBitmapFontText::Draw(AHUD* HUD)
{
	impl->Draw(HUD);
}

void UBitmapFontText::SetFontType(uint8 FontType)
{
	impl->SetFontType(FontType);
}

uint8 UBitmapFontText::GetFontType()
{
	return impl->FontType;
}

float UBitmapFontText::GetFontWidth()
{
	return impl->GetFontWidth();
}

float UBitmapFontText::GetFontHeight()
{
	return FontSize;
}

void UBitmapFontText::Reset()
{
	impl->Reset();
}