// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#pragma  once

#include "UI/UMG/PiratesUserWidget.h"
#include "UMG/KMCircleProgressBarSimple.h"
#include "Components/CanvasPanel.h"
#include "UIMapUserWidget.generated.h"

class UUIMapOpBase;

UCLASS()
class COMMON_API UUIMapUserWidget : public UPiratesUserWidget
{
	GENERATED_UCLASS_BODY()

protected:
	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;

public:
	UFUNCTION(BlueprintCallable, Category = "UIMapUserWidget")
	void RegisterOperation(UUIMapOpBase* pOpObj);

	UFUNCTION(BlueprintCallable, Category = "UIMapUserWidget")
	void UnregisterOperation(UUIMapOpBase* pOpObj);

	UFUNCTION(BlueprintCallable, Category = "UIMapUserWidget")
	void UnregisterAllOperation();

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	void InitMapParam(const FVector2D& In3DMapSize, const FVector2D& InUIMapValidSize,
			const FVector2D& InUIMapValidOffset, const FVector2D& In3DMapOrigin, const FVector2D& InUIMapOrigin);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, Category = "UIMapUserWidget")
	FVector2D CalculateUIMapLocation(const FVector& InWorldPos);

	FVector2D CalculateUISize(const FVector2D& InSceneSize);

	const FVector2D& GetUIMapOrigin() const;
	const FVector2D& Get3DMapOrigin() const;
	const FVector2D& Get3DMapSize() const;
	const FVector2D& GetUIMapValidSize() const;
	const FVector2D& GetUIMapValidOffset() const;
	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

private:
	
	FVector2D MapSize3D;
	FVector2D UIMapValidSize;
	FVector2D UIMapValidOffset;
	FVector2D MapOrigin3D;
	FVector2D UIMapOrigin;
	bool bUpdate;
	TArray<UUIMapOpBase*> ContentOpArray;
};
