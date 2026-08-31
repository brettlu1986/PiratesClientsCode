//// Fill out your copyright notice in the Description page of Project Settings.
//
//#pragma once
//
//#include "CoreMinimal.h"
//#include "Components/ActorComponent.h"
//#include "KMSignificanceComponent.generated.h"
//
//UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
//class ENGINEEXT_API UKMSignificanceComponent : public UActorComponent
//{
//	GENERATED_BODY()
//
//public:	
//	// Sets default values for this component's properties
//	UKMSignificanceComponent();
//
//	/** tag for grouping in the significance manager */
//	UPROPERTY(EditAnywhere, BlueprintReadWrite)
//	FName SignificanceTag;
//
//	/**
//	* calls TickSignificance
//	*/
//	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;
//
//protected:
//
//	/**
//	* register the owner to the significance manager
//	*/
//	virtual void BeginPlay() override;
//
//	/**
//	* unregister from the significance manager
//	*/
//	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
//
//	/**
//	* override this to implement your significance calculation
//	*/
//	virtual float SignificanceFunctionImpl(UObject* InObject, const FTransform& Viewpoint) { return 0.f; }
//
//	/**
//	* override this to implement your significance application.
//	* do stuff which depends on the current significance value only.
//	*/
//	virtual void PostSignificanceFunctionImpl(UObject* InObject, float InOldSignificance, float InSignificance, bool bBeingUnregistered) { }
//
//	/**
//	* called when the component ticks. override this to do some stuff that might depends on the sorting result since last frame.
//	*
//	* the significance manager will tick after all components and actors 
//	* then all tracked objects will be sorted by their significance,
//	* the sorting result since the last frame can be accessed when the component tick.
//	*/
//	virtual void TickSignificance(UObject* InObject, float InCurrentSignificance) {}
//
//protected:
//	/** cached significance since last frame */
//	float LastSignificance;
//
//	/** cached in the BeginPlay and used to see if the manager is online */
//	class UKMSignificanceManager* CachedManager;
//};
