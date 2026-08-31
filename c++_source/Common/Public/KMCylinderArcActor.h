// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "ProceduralMeshComponent.h"
#include "KMCylinderArcActor.generated.h"

UCLASS(ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))
class UKMCylinderProceduralMeshComponent : public UProceduralMeshComponent
{
	GENERATED_BODY()

public:
	UKMCylinderProceduralMeshComponent(const FObjectInitializer& ObjectInitializer);

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	UMaterialInterface* ArcMaterial;

	UPROPERTY(EditAnywhere)
	int32 SliceNum = 180;

	UPROPERTY(EditAnywhere)
	float CylinderRadius = 1000.0f;

	UPROPERTY(EditAnywhere)
	float CylinderHeight = 5000.0f;

	UPROPERTY(EditAnywhere, Meta = (UIMin = "0", UIMax = "1"))
	float ArcRatio = 1.0f;
	
	UPROPERTY(VisibleInstanceOnly)
	int32 CurrentSection = 0;

public:
	void InitCylinders();
	void CreateCylinder(int32 SectionIndex, float InCylinderRadius, float InCylinderHeight, float InArcRatio, bool bCreateCollision);

public:
	virtual void BeginPlay() override;
	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;

private:
	virtual FBoxSphereBounds CalcBounds(const FTransform& LocalToWorld) const override;

private:
	void InitFadeDistance();
	void EnableSection(int32 SectionId);

private:
	TArray<FVector> Vertices;
	TArray<int32> Triangles;
	TArray<FVector> Normals;
	TArray<FVector2D> UV0;
	TArray<FProcMeshTangent> Tangents;
	float FadeDistance = 0.0f;
};

UCLASS()
class AKMCylinderArcActor : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	AKMCylinderArcActor();
	virtual void OnConstruction(const FTransform& Transform) override;

private:
	UPROPERTY(VisibleAnywhere)
	UKMCylinderProceduralMeshComponent* CylinderArcMesh;

#if WITH_EDITOR
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
#endif
};
