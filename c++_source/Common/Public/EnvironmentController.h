// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "KMThickVolume.h"
#include "Components/TimelineComponent.h"
#include "EnvironmentController.generated.h"

UCLASS(Abstract)
class COMMON_API AEnvironmentController : public AActor
{
	GENERATED_UCLASS_BODY()
public:
	UPROPERTY(BlueprintReadOnly)
	UTimelineComponent* TransitTimeline;

	UPROPERTY(BlueprintReadOnly)
	UTimelineComponent* FogStartDistanceTimeline;

	UPROPERTY()
	UCurveFloat* TransitCurve;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool bPreviewEnvironment = true;

	UPROPERTY(BlueprintReadOnly)
	UEnvironmentParams* TransitBaseParams;		
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float FogDensityQualityScale;

	UPROPERTY(BlueprintReadOnly)
	float FogDensityRenderQuality;

public:
	// Assign volume params to environment fog
	UFUNCTION(BlueprintCallable)
	void SetEnvironmentParams(UEnvironmentParams* EnvParams, bool Immediately);

	// Revert environment fog params from start params
	UFUNCTION(BlueprintCallable)
	void RevertEnvironmentParams(UEnvironmentParams* EnvParams, bool Immediately);

	// Snap environment fog params to start params
	UFUNCTION(BlueprintCallable)
	void SnapEnvironmentParams();
	
	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable)
	void ApplyEnvironmentParams(const UEnvironmentParams* CurrentParams, const UEnvironmentParams* TargetParams = nullptr, float Factor = 0.0f);
		
	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable)
	void ApplyFogStartDistance(const UEnvironmentParams* CurrentParams, const UEnvironmentParams* TargetParams = nullptr, float Factor = 0.0f);
	
	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable)
	void TakeEnvironmentParams(UEnvironmentParams* OutParams);

	UFUNCTION(BlueprintCallable)
	void RefreshEnvironmentParams();

	UFUNCTION(BlueprintCallable)
	bool IsUsingBaseParams() const;
	
	UFUNCTION(BlueprintPure)
	bool IsBaseParams(UEnvironmentParams* InParams) const;

	UFUNCTION()
	void TransitEnvironmentParams(float Factor);	

	UFUNCTION()
	void TransitEnvironmentParamsDone(float Factor);
	
	UFUNCTION()
	void TransitFogStartDistance(float Factor);

	UFUNCTION()
	void TransitFogStartDistanceDone(float Factor);

	UFUNCTION(BlueprintCallable, Category = "EnvCtl", meta = (WorldContext = "WorldContextObject"))
	static void NotifyEnvForChangingCharacter(const UObject* WorldContextObject, bool bIsChangingToShip);

	UFUNCTION(BlueprintCallable, Category = "EnvCtl")
	static bool IsCharacterInVolume(const AActor* Character, const UShapeComponent* Shape);

public:
	static UEnvironmentParams* ConstructBPEnvironmentParams(UObject* Object, const FName& Name);
	static UEnvironmentParams* NewBPEnvironmentParams(UObject* Object);

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

	// Called every frame
	virtual void Tick(float DeltaTime) override;

private:
	void MakeDefaultTransitCurve();
	void MakeTransitTimeline();
	void MakeFogStartDistanceTimeline();
	void SetupTimeline(UTimelineComponent* Timeline, const FName& UpdateFunction, const FName& FinishedFunction);
	UEnvironmentParams* TryGetTopParams();
	bool TryPopParams(UEnvironmentParams* Params);
	void CleanupParams();
	void RevertAllVolumeParams();
	static bool ShapeEncompassesPoint(const UShapeComponent* Shape, FVector Point, float SphereRadius = 0.f, float* OutDistanceToPoint = 0);

private:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, meta = (AllowPrivateAccess = true))
	TArray<UEnvironmentParams*> ParamsQueue;

	UPROPERTY()
	UEnvironmentParams* TransitCurrentParams;

	UPROPERTY()
	UEnvironmentParams* TransitTargetParams;
	
#if WITH_EDITOR
public:
	void SetEnvironmentDirty(bool Value) { bEnvironmentDirty = Value; }
	bool IsEnvironmentDirty() const { return bEnvironmentDirty; }

private:
	bool bEnvironmentDirty = false;
#endif
};

UCLASS(BlueprintType, Blueprintable)
class UEnvironmentParams : public UActorComponent
{
	GENERATED_BODY()
public:
	virtual void BeginPlay() override;

public:
	// Assign volume params to environment fog
	UFUNCTION(BlueprintCallable)
	virtual void SetEnvironmentParams();

	// Revert environment fog params from start params
	UFUNCTION(BlueprintCallable)
	virtual void RevertEnvironmentParams();

	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable)
	void SetFogRenderQuality();

	UFUNCTION(BlueprintCallable)
	bool IsUseStartDistanceTransitTime() const;

	UFUNCTION(BlueprintCallable)
	AEnvironmentController* GetEnvironmentController() const;

public:
	void FindEnvironmentController(UWorld* World);
	TWeakObjectPtr<AEnvironmentController> GetEnvCtl() const;

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float TransitTime = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float StartDistanceTransitTime = 0.0f;

	UPROPERTY(EditDefaultsOnly)
	int32 ImportanceLevel = 0;

	bool bIsVolumeParam = false;

protected:
	// Here we use weak ptr instead of using UPROPERTY() because of issue UE-20420
	// https://issues.unrealengine.com/issue/UE-20420
	// The EnvCtl ptr might point to diffenent sub level object and GC cannot track it correctly! 
	TWeakObjectPtr<AEnvironmentController> EnvCtl;
};

UCLASS(BlueprintType, Blueprintable)
class COMMON_API AKMEnvironmentControlVolume : public AVolume
{
	GENERATED_UCLASS_BODY()

public:
	~AKMEnvironmentControlVolume();

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = EnvironmentControl, Meta = (AllowPrivateAccess = true))
	UEnvironmentParams* EnvironmentParams;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = EnvironmentControl, Meta = (AllowPrivateAccess = true))
	bool bForceApplyEnvironment = false; // Apply env params when BeginPlay, but will not transit anymore.

public: // AActor interface
	virtual void OnConstruction(const FTransform& Transform) override;
	virtual void BeginPlay() override;
	virtual void PostUnregisterAllComponents() override;
	virtual void NotifyActorBeginOverlap(AActor* OtherActor) override;
	virtual void NotifyActorEndOverlap(AActor* OtherActor) override;
	virtual FBox GetComponentsBoundingBox(bool bNonColliding = false, bool bIncludeFromChildActors = false) const override;

public:
	// Assign volume params to environment fog
	UFUNCTION(BlueprintCallable)
	virtual void SetEnvironment();

	// Revert environment fog params from start params
	UFUNCTION(BlueprintCallable)
	virtual void RevertEnvironment();

#if WITH_EDITOR
public:
	void OnObjectSelected(UObject* Object);
	void OnPreSaveWorld(uint32 SaveFlags, class UWorld* World);
	void PreviewEnvironmentParams();
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;

private:
	void RevertPreviewParams();

private:
	FString GlobalLightClassName;
#endif

public:
	static AActor* GetCurrentPlayer(const UObject* WorldContextObject);
	static AActor* GetWatchingPlayer(const UObject* WorldContextObject);

private:
	AActor* OverlappingPlayer = nullptr;
};
