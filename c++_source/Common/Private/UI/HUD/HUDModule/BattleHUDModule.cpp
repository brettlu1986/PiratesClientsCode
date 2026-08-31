// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/HUD/HUDModule/BattleHUDModule.h"
#include "Common.h"
#include "UI/HUD/CustomWidget/BitmapFontText.h"
#include "UI/HUD/HUDModule/BitmapFontHUDModule.h"

struct FBattleData
{
	UBitmapFontText	*TextWidget;
	FVector2D		Position;
	float			FontSize;
	float			ElapseTime;
	bool			IsFree;

	FBattleData(UBitmapFontText	*InTextWidget)
		: TextWidget(InTextWidget)
		, Position	(0.f, 0.f)
		, FontSize	(0.f)
		, ElapseTime(0.f)
		, IsFree	(false)
	{
	}
};

struct UBattleHUDModule::Impl
{
    UBattleHUDModule	*Owner;
    float				DeltaTime;
	float				DataAnimLastTime;
	TArray<FBattleData>	DataArray;

	Impl(UBattleHUDModule* Parent) 
		: Owner		(Parent)
	{
	}

	void BeginPlay()
	{
		InitData();
	}

	void InitData()
	{
		if (FLOAT_EQUAL_ZERO(Owner->DataScaleAnimTime))
		{
			Owner->DataScaleAnimTime = 0.2f;
		}
		if (FLOAT_EQUAL_ZERO(Owner->DataHideAnimTime))
		{
			Owner->DataScaleAnimTime = 0.5f;
		}
		DataAnimLastTime = Owner->DataScaleAnimTime + Owner->DataHideAnimTime + Owner->DataHideDelayTime;
	}

	void Tick(float DeltaSeconds)
	{
		DeltaTime = DeltaSeconds;
	}

	void DrawHUD(UCanvas *Canvas)
	{
		ReturnIfNullUObject(Canvas);

		for (auto& BattleData : DataArray)
		{
			if (BattleData.IsFree)
			{
				continue;
			}
			DrawTextWidget(BattleData);
			BattleData.ElapseTime += DeltaTime;
			if (BattleData.ElapseTime > DataAnimLastTime)
			{
				ReleaseBattleData(BattleData);
			}
		}
	}

	void DrawTextWidget(const FBattleData& BattleData)
	{
		ReturnIfNullUObject(BattleData.TextWidget);
		float Scale = 1.f;
		BattleData.TextWidget->Position.X = BattleData.Position.X;
		BattleData.TextWidget->Position.Y = BattleData.Position.Y;
		const float DataScaleAnimTimeHalf = Owner->DataScaleAnimTime / 2;
		if (BattleData.ElapseTime < DataScaleAnimTimeHalf) // 放大时间
		{
			Scale = Owner->DataScaleMaxRatio * (BattleData.ElapseTime / DataScaleAnimTimeHalf);
			BattleData.TextWidget->Position.X -= BattleData.FontSize * Scale / 2;
			BattleData.TextWidget->Position.Y -= BattleData.FontSize * Scale / 2;
		}
		else if (BattleData.ElapseTime < Owner->DataScaleAnimTime) // 缩小时间
		{
			Scale = 1 + (Owner->DataScaleMaxRatio - 1) * (1 - (BattleData.ElapseTime - DataScaleAnimTimeHalf) / DataScaleAnimTimeHalf);
			BattleData.TextWidget->Position.X -= BattleData.FontSize * Scale / 2;
			BattleData.TextWidget->Position.Y -= BattleData.FontSize * Scale / 2;
		}
		else if (BattleData.ElapseTime > Owner->DataScaleAnimTime + Owner->DataHideDelayTime)
		{
			const float Ratio = (BattleData.ElapseTime - Owner->DataScaleAnimTime - Owner->DataHideDelayTime) / Owner->DataHideAnimTime;
			BattleData.TextWidget->Position.X -= BattleData.FontSize / 2 - Ratio * Owner->DataMoveOffsetXRatio;
			BattleData.TextWidget->Position.Y -= BattleData.FontSize / 2 + Ratio * Owner->DataMoveOffsetYRatio;
			BattleData.TextWidget->Alpha = 1 - Ratio;
		}
		else
		{
			BattleData.TextWidget->Position.X -= BattleData.FontSize / 2;
			BattleData.TextWidget->Position.Y -= BattleData.FontSize / 2;
		}

		BattleData.TextWidget->FontSize = BattleData.FontSize * Scale;
		BattleData.TextWidget->Draw(Owner->PiratesHUD);
	}

	FBattleData& AcquireBattleData()
	{
		for (auto& BattleData : DataArray)
		{
			if (BattleData.IsFree)
			{
				BattleData.IsFree = false;
				return BattleData;
			}
		}

		DataArray.Add(FBattleData(GetBitmapFontText()));
		return DataArray.Last();
	}

	void ReleaseBattleData(FBattleData &BattleData)
	{
		BattleData.TextWidget->Reset();
		BattleData.Position = FVector2D(0.f, 0.f);
		BattleData.ElapseTime = 0.f;
		BattleData.IsFree = true;
	}

	UBitmapFontText* GetBitmapFontText()
	{
		auto BitmapFontHUDModule = Owner->PiratesHUD->GetBitmapFontHUDModule();
		ReturnIfNullUObject(BitmapFontHUDModule, nullptr);
		return BitmapFontHUDModule->Acquire();
	}

	void AddBattleData(uint8 FontType, FVector2D Position, FString BattleText, float FontSize, float FontKerning)
	{
		FBattleData& BattleData = AcquireBattleData();
		BattleData.Position = Position;
		BattleData.FontSize = FontSize;
		BattleData.TextWidget->SetFontType(FontType);
		BattleData.TextWidget->Position = Position;
		BattleData.TextWidget->Text = BattleText;
		BattleData.TextWidget->FontSize = FontSize;
		BattleData.TextWidget->FontKerning = FontKerning;
		BattleData.TextWidget->Visible = true;
	}
};

UBattleHUDModule::UBattleHUDModule(const FObjectInitializer& ObjectInitializer)
	: Super					(ObjectInitializer)
	, impl					(MakeShareable(new Impl(this)))
	, DataScaleAnimTime		(0.2f)
	, DataHideAnimTime		(0.5f)
	, DataHideDelayTime		(0.2f)
	, DataMoveOffsetXRatio	(60.f)
	, DataMoveOffsetYRatio	(200.f)
	, DataScaleMaxRatio		(2.f)
{

}

UBattleHUDModule::~UBattleHUDModule()
{

}

void UBattleHUDModule::BeginPlay()
{
	impl->BeginPlay();
}

void UBattleHUDModule::Tick(float DeltaSeconds)
{
	impl->Tick(DeltaSeconds);
}

void UBattleHUDModule::DrawHUD(UCanvas *Canvas)
{
	impl->DrawHUD(Canvas);
}

void UBattleHUDModule::AddBattleData(uint8 FontType, FVector2D Position, FString BattleText, float FontSize, float FontKerning)
{
	impl->AddBattleData(FontType, Position, BattleText, FontSize, FontKerning);
}