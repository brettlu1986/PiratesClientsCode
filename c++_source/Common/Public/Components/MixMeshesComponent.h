// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Components/ActorComponent.h"
#include "MixMeshesComponent.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class COMMON_API UMixMeshesComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	// Sets default values for this component's properties
	UMixMeshesComponent();

	// combine meshes and textures to one or not ...
	UPROPERTY(EditAnywhere)
	int is_combine;

	UPROPERTY(EditAnywhere)
	AActor* actor_weapon;

	UPROPERTY(EditAnywhere)
	AActor* actor_base;

	UPROPERTY(EditAnywhere)
	AActor* actor_head;

	UPROPERTY(EditAnywhere)
	AActor* actor_chest;

	UPROPERTY(EditAnywhere)
	AActor* actor_hand;

	UPROPERTY(EditAnywhere)
	AActor* actor_feet;


	UTextRenderComponent* CountdownText;

	// Called when the game starts
	virtual void BeginPlay() override;

	// Called every frame
	virtual void TickComponent( float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction ) override;

	void CreateModel();



};
