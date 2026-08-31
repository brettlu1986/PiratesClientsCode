// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "SignificanceManager.h"
#include "KMSignificanceManager.generated.h"

/**
 * automatically ticked significance manager
 */
UCLASS()
class ENGINEEXT_API UKMSignificanceManager : public USignificanceManager
{
	GENERATED_BODY()
	
public:
	UKMSignificanceManager();
	/**
	* the ticking function will be called by ticker
	*/
	bool Tick(float InDeltaTime);

	/**
	* add to ticker if not yet
	*/
	virtual void RegisterObject(UObject* Object, FName Tag, FManagedObjectSignificanceFunction SignificanceFunction,
		EPostSignificanceType InPostSignificanceType = EPostSignificanceType::None, 
		FManagedObjectPostSignificanceFunction InPostSignificanceFunction = nullptr) override;

	/**
	* remove from ticker if all managed objects have been removed
	*/
	virtual void UnregisterObject(UObject* Object) override;
	
	/**
	* Calculate significance
	*/
	virtual void Update(TArrayView<const FTransform> Viewpoints) override;

	/**
	* get tick handle
	*/
	FDelegateHandle& GetTickHandle() { return TickHandle; }

private:
	/** handle obtained after adding to ticker */
	FDelegateHandle TickHandle;
};
