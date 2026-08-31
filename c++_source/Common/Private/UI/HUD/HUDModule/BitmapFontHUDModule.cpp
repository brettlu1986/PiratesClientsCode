// Fill out your copyright notice in the Description page of Project Settings.

#include "UI/HUD/HUDModule/BitmapFontHUDModule.h"
#include "Common.h"
#include "UI/HUD/CustomWidget/BitmapFontText.h"

struct FBitmapFontTextPair 
{
	UBitmapFontText*	BitmapFontText;
	bool				IsFree;

	FBitmapFontTextPair(UBitmapFontText* InBitmapFontText)
		: BitmapFontText(InBitmapFontText)
		, IsFree		(false)
	{}
};

struct UBitmapFontHUDModule::Impl
{
	UBitmapFontHUDModule*		Owner;
	TArray<FBitmapFontTextPair> TextPairArray;

	Impl(UBitmapFontHUDModule* Parent) : Owner(Parent)
	{
	}

	UBitmapFontText* Acquire()
	{
		for (auto& Pair : TextPairArray)
		{
			if (Pair.IsFree)
			{
				Pair.IsFree = false;
				return Pair.BitmapFontText;
			}
		}

		auto BitmapFontText = NewObject<UBitmapFontText>();
		BitmapFontText->Init(Owner);
		TextPairArray.Add(FBitmapFontTextPair(BitmapFontText));
		return BitmapFontText;
	}

	void Release(UBitmapFontText* BitmapFontText)
	{
		for (auto& Pair : TextPairArray)
		{
			if (Pair.BitmapFontText == BitmapFontText)
			{
				Pair.BitmapFontText->Reset();
				Pair.IsFree = true;
				break;
			}
		}
	}

	void AddReferencedObjects(FReferenceCollector& Collector)
	{
		for (auto& Pair : TextPairArray)
		{
			Collector.AddReferencedObject(Pair.BitmapFontText, Owner);
		}
	}
};

UBitmapFontHUDModule::UBitmapFontHUDModule(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, impl(MakeShareable(new Impl(this)))
{

}

UBitmapFontHUDModule::~UBitmapFontHUDModule()
{

}

void UBitmapFontHUDModule::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	UBitmapFontHUDModule* This = CastChecked<UBitmapFontHUDModule>(InThis);
	This->impl->AddReferencedObjects(Collector);
	Super::AddReferencedObjects(This, Collector);
}

UBitmapFontText* UBitmapFontHUDModule::Acquire()
{
	return impl->Acquire();
}

void UBitmapFontHUDModule::Release(UBitmapFontText* BitmapFontText)
{
	impl->Release(BitmapFontText);
}