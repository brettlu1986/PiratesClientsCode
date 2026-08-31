// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#include "UI/HUD/PiratesHUD.h"
#include "Common.h"

#include "UI/HUD/HUDModule/GestureHUDModule.h"
#include "UI/HUD/HUDModule/ComboHUDModule.h"
#include "UI/HUD/HUDModule/BattleHUDModule.h"
#include "UI/HUD/HUDModule/BitmapFontHUDModule.h"

//for ocean cull using sceneview in canvas
#include "Loading/OceanCullVolume.h"
#include "RenderExtendBlueprintFunctions.h"
#include "OceanSystem.h"

DEFINE_LOG_CATEGORY_STATIC(LogPiratesHUD, Log, All);

struct APiratesHUD::Impl
{
    TArray<UHUDModuleBase*> HUDModuleArray;

	APiratesHUD		        *Owner;
	UGestureHUDModule		*GestureHUDModule;
	UComboHUDModule			*ComboHUDModule;
	UBattleHUDModule		*BattleHUDModule;
	UBitmapFontHUDModule	*BitmapFontHUDModule;

	Impl(APiratesHUD* Parent)
        : Owner                 (Parent)
		, GestureHUDModule		(nullptr)
		, ComboHUDModule		(nullptr)
		, BattleHUDModule		(nullptr)
		, BitmapFontHUDModule	(nullptr)
    {
	}

	void BeginPlay()
	{
		GestureHUDModule = NewObject<UGestureHUDModule>(Owner, TEXT("GestureHUDModule"));
		ComboHUDModule = NewObject<UComboHUDModule>(Owner, TEXT("ComboHUDModule"));
		if (Owner->BattleHUDModuleClass != nullptr)
		{
			BattleHUDModule = NewObject<UBattleHUDModule>(Owner, Owner->BattleHUDModuleClass);
		}
		else
		{
			BattleHUDModule = NewObject<UBattleHUDModule>(Owner, TEXT("BattleHUDModule"));
		}
		if (Owner->BitmapFontHUDModuleClass != nullptr)
		{
			BitmapFontHUDModule = NewObject<UBitmapFontHUDModule>(Owner, Owner->BitmapFontHUDModuleClass);
		}
		else
		{
			BitmapFontHUDModule = NewObject<UBitmapFontHUDModule>(Owner, TEXT("BitmapFontHUDModule"));
		}

		HUDModuleArray.Add(GestureHUDModule);
		HUDModuleArray.Add(ComboHUDModule);
		HUDModuleArray.Add(BattleHUDModule);
		HUDModuleArray.Add(BitmapFontHUDModule);

		for (auto& HUDModule : HUDModuleArray)
		{
			HUDModule->BeginPlay();
		}
	}

	void DrawHUD()
	{
		for (auto& HUDModule : HUDModuleArray)
		{
			HUDModule->DrawHUD(Owner->Canvas);
		}
	}

	void Tick(float DeltaSeconds)
	{
		for (auto& HUDModule : HUDModuleArray)
		{
			HUDModule->Tick(DeltaSeconds);
		}
	}

	void AddReferencedObjects(FReferenceCollector& Collector)
	{
		for (auto& HUDModule : HUDModuleArray)
		{
			Collector.AddReferencedObject(HUDModule, Owner);
		}
	}
};

APiratesHUD::APiratesHUD(const FObjectInitializer& ObjectInitializer)
	: Super	(ObjectInitializer)
	, impl	(MakeShareable(new Impl(this)))
{
}

APiratesHUD::~APiratesHUD()
{

}

void APiratesHUD::BeginPlay()
{
	Super::BeginPlay();
//	impl->BeginPlay();
}

void APiratesHUD::DrawHUD()
{
	Super::DrawHUD();
//	impl->DrawHUD();

	//yangjingzhao add for subtitle
	if (SubtitleManager)
	{
		SubtitleManager->DrawSubtitle(Canvas);
	}

	// unused logic
	////tick for ocean cull on low end
	//int32 PerformanceLevel = URenderExtendBlueprintFunctions::GetDevicePerformanceLevel();
	//if (PerformanceLevel == 0 && Canvas && GetWorld())
	//{
	//	bool ShowFlag = false;

	//	TArray<AActor*> OceanCulls;
	//	UGameplayStatics::GetAllActorsOfClass(GetWorld(), AOceanCullVolume::StaticClass(), OceanCulls);
	//	for (int32 Index = 0; Index < OceanCulls.Num(); Index++)
	//	{
	//		if (OceanCulls[Index])
	//		{
	//			ShowFlag |= Cast<AOceanCullVolume>(OceanCulls[Index])->CheckVolumeInFrustum(Canvas);
	//		}
	//	}

	//	if (ShowFlag != OceanVisible && OceanCulls.Num() > 0)
	//	{
	//		OceanVisible = ShowFlag;
	//		UE_LOG(LogPiratesHUD, Log, TEXT("change ocean hidden *****************  %d"), ShowFlag);
	//		//hide ocean
	//		TArray<AActor*> Oceans;

	//		UGameplayStatics::GetAllActorsOfClass(GetWorld(), AOceanSystem::StaticClass(), Oceans);

	//		for (int32 OceanIndex = 0; OceanIndex < Oceans.Num(); ++OceanIndex)
	//		{
	//			Cast<AOceanSystem>(Oceans[OceanIndex])->SetActorHiddenInGame(!OceanVisible);
	//		}
	//	}
	//}

}

void APiratesHUD::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
//	impl->Tick(DeltaSeconds);
}

void APiratesHUD::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	APiratesHUD* This = CastChecked<APiratesHUD>(InThis);
	This->impl->AddReferencedObjects(Collector);
	Super::AddReferencedObjects(This, Collector);
}

UGestureHUDModule* APiratesHUD::GetGestureHUDModule()
{
	return impl->GestureHUDModule;
}

UComboHUDModule* APiratesHUD::GetComboHUDModule()
{
	return impl->ComboHUDModule;
}

UBattleHUDModule* APiratesHUD::GetBattleHUDModule()
{
	return impl->BattleHUDModule;
}

UBitmapFontHUDModule* APiratesHUD::GetBitmapFontHUDModule()
{
	return impl->BitmapFontHUDModule;
}

UKMSubtitleManager* APiratesHUD::TryGetSubtitleManager()
{
    if (!SubtitleManager)
    {
        SubtitleManager = NewObject<UKMSubtitleManager>(this, TEXT("KMSubtitleManager"));
    }
    return SubtitleManager;
}

void APiratesHUD::StartPlaySubtitleforSequence(const FString& SubtitlePath)
{
    if (!SubtitleManager)
    {
        SubtitleManager = NewObject<UKMSubtitleManager>(this, TEXT("KMSubtitleManager"));
    }

	SubtitleManager->StartPlaySubtitleforSequence(SubtitlePath);
}

void APiratesHUD::RestartSubtittle()
{
    if (SubtitleManager)
    {
        SubtitleManager->Restart();
    }
}

void APiratesHUD::StopSubtitle()
{
    if (SubtitleManager)
    {
        SubtitleManager->StopSubtitle();
    }
}

void APiratesHUD::TestPlaySubtitle(FString InStr)
{
	UE_LOG(LogPiratesHUD, Log, TEXT("TestPlaySubtitle"));
	StartPlaySubtitleforSequence(InStr);
}