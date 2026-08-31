// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/UMG/SystemInfoWidget.h"
#include "Common.h"
#include "HAL/PlatformMisc.h"
#include "Components/Image.h"
#include "Components/ProgressBar.h"
#include "Components/TextBlock.h"

const FString DEFAULT_TIME_FORMAT = TEXT("%H:%M");
const int DEFAULT_BATTERY_LOW_LEVEL = 10;
const int MIN_BATTERY_LEVEL = 0;
const int MAX_BATTERY_LEVEL = 100;

USystemInfoWidget::USystemInfoWidget(const FObjectInitializer& ObjectInitializer)
	: Super					(ObjectInitializer)
	, TimeFormat			(DEFAULT_TIME_FORMAT)
	, BatteryLowLevel		(DEFAULT_BATTERY_LOW_LEVEL)
	, bLastIsWifi			(true)
	, LastBatteryLevel		(-1)
	, LastBatteryUIState	(EBatteryUIState::COMMON)
{
}

void USystemInfoWidget::NativeConstruct()
{
	Super::NativeConstruct();
	Update();
}

void USystemInfoWidget::NativeTickInternal(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTickInternal(MyGeometry, InDeltaTime);
	Update();
}

EBatteryUIState USystemInfoWidget::GetBatteryUIState()
{
	if (FPlatformMisc::IsRunningOnBattery())
	{
		if (LastBatteryLevel <= BatteryLowLevel)
		{
			return EBatteryUIState::LOW;
		}
		else
		{
			return EBatteryUIState::COMMON;
		}
	}
	else
	{
		return EBatteryUIState::CHARGING;
	}
}

int USystemInfoWidget::GetBatteryLevel()
{
	int BatteryLevel = FPlatformMisc::GetBatteryLevel();
	if (FPlatformMisc::IsRunningOnBattery() || BatteryLevel >= 0)
	{
		return FMath::Clamp(BatteryLevel, MIN_BATTERY_LEVEL, MAX_BATTERY_LEVEL);
	}
	else
	{
		return MAX_BATTERY_LEVEL;
	}
}

void USystemInfoWidget::Update()
{
	UpdateNet();
	UpdateBatteryLevel();
	UpdateBatteryState();
	UpdateTime();
}

void USystemInfoWidget::UpdateNet()
{
	ReturnIfNullUObject(imgNet);

	bool bIsWifi = FPlatformMisc::HasActiveWiFiConnection();
	ReturnIfTrue(bLastIsWifi == bIsWifi);
	bLastIsWifi = bIsWifi;

	FSlateBrush& Brush = imgNet->Brush;
	Brush.SetResourceObject(bIsWifi ? WifiNetRes : MobileNetRes);
	imgNet->SetBrush(Brush);
}

void USystemInfoWidget::UpdateBatteryLevel()
{
	ReturnIfNullUObject(pgbBattery);

	int BatteryLevel = GetBatteryLevel();
	ReturnIfTrue(LastBatteryLevel == BatteryLevel);
	LastBatteryLevel = BatteryLevel;

	pgbBattery->SetPercent((float)BatteryLevel / MAX_BATTERY_LEVEL);
}

void USystemInfoWidget::UpdateBatteryState()
{
	ReturnIfNullUObject(imgBatteryBg);
	ReturnIfNullUObject(pgbBattery);

	EBatteryUIState BatteryUIState = GetBatteryUIState();
	ReturnIfTrue(LastBatteryUIState == BatteryUIState);
	LastBatteryUIState = BatteryUIState;

	if (auto Color = BatteryColorMap.Find(BatteryUIState))
	{
		imgBatteryBg->SetColorAndOpacity(*Color);
		pgbBattery->SetFillColorAndOpacity(*Color);
	}
}

void USystemInfoWidget::UpdateTime()
{
	ReturnIfNullUObject(txtTime);

	const FDateTime& DataTime = FDateTime::Now();
	ReturnIfTrue(LastDataTime == DataTime);
	LastDataTime = DataTime;

	const FString& TimeString = DataTime.ToString(*TimeFormat);
	txtTime->SetText(FText::FromString(TimeString));
}