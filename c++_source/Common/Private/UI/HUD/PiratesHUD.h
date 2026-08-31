// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#pragma  once

#include "Cinema/KMCinemaSubtitle.h"
#include "PiratesHUD.generated.h"


UCLASS()
class COMMON_API APiratesHUD : public AHUD
{
	GENERATED_UCLASS_BODY()

private:
	struct Impl;
	TSharedPtr<Impl> impl;

public:
	virtual ~APiratesHUD();
	virtual void BeginPlay() override;
	virtual void DrawHUD() override;
	virtual void Tick(float DeltaSeconds) override;

	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

public:

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = PiratesHUD)
	class UGestureHUDModule* GetGestureHUDModule();

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = PiratesHUD)
    class UComboHUDModule* GetComboHUDModule();

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = PiratesHUD)
    class UBattleHUDModule* GetBattleHUDModule();

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = PiratesHUD)
    class UBitmapFontHUDModule* GetBitmapFontHUDModule();

	UPROPERTY(Blueprintable, EditAnywhere)
	TSubclassOf<class UBitmapFontHUDModule> BitmapFontHUDModuleClass;
	
	UPROPERTY(Blueprintable, EditAnywhere)
	TSubclassOf<class UBattleHUDModule> BattleHUDModuleClass;

	//yangjingzhao : add for subtitle
	UPROPERTY(Blueprintable, EditAnywhere)
	TSubclassOf<class UKMSubtitleManager> SubtitleManagerClass;

	UPROPERTY()
	UKMSubtitleManager* SubtitleManager;

    UFUNCTION(BlueprintCallable, Category = PiratesHUD)
    UKMSubtitleManager* TryGetSubtitleManager();
	UFUNCTION(BlueprintCallable, Category = PiratesHUD)
	void StartPlaySubtitleforSequence(const FString& SubtitlePath);
    UFUNCTION(BlueprintCallable, Category = PiratesHUD)
    void RestartSubtittle();
    UFUNCTION(BlueprintCallable, Category = PiratesHUD)
    void StopSubtitle();
	UFUNCTION(exec)
	void TestPlaySubtitle(FString InStr);
	//subtitle end

private:
	//需要在低端设备控制海面的现实状态；目前上层只有canvas上能取得sceneview和frustum
	//暂时加在此处
	bool OceanVisible = true;

};