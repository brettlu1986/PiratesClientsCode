#pragma once

#include "PiratesPlayerGrid.generated.h"

UCLASS()
class COMMON_API UPiratesPlayerGrid : public UActorComponent
{
	GENERATED_UCLASS_BODY()
	DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnEnterGrid, AActor*, Actor, uint32, GridX, int32, GridY);
public:
	void Update(float DeltaTime);

	void Clear();

	UFUNCTION(BlueprintCallable, Category = "PriatesPlayerGrid")
	void SetUpdateInterval(float InEffetiveTime);

	UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
	void AddActor(AActor* Actor);

	UFUNCTION(BlueprintCallable, Category = "PiratesAreaTriggerManager")
	void RemoveActor(AActor* Actor);
public:
	UPROPERTY()
	FOnEnterGrid OnEnterGrid;
private:
	void Execute();

	UFUNCTION()
	void OnActorDestroyed(AActor* ActorToDestroy);
private:
	struct FActorInfo
	{
		TWeakObjectPtr<AActor> Actor;
		FVector2D GridPos;
		FActorInfo() : Actor(nullptr) {}
	};
private:
	TArray<FActorInfo> ActorInfos;
	float EffectiveTime;
	float CurrentTime;

	UPROPERTY()
	float GridSize;
};
