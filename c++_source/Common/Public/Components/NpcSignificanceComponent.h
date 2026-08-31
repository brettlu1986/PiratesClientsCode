//// Fill out your copyright notice in the Description page of Project Settings.
//
//#pragma once
//
//#include "CoreMinimal.h"
//#include "KMSignificanceComponent.h"
//#include "NpcSignificanceComponent.generated.h"
//
///**
// * Npc重要度响应的实现
// */
//UCLASS(Blueprintable, ClassGroup="Performance", meta = (BlueprintSpawnableComponent))
//class COMMON_API UNpcSignificanceComponent : public UKMSignificanceComponent
//{
//	GENERATED_BODY()
//	
//public:
//	UNpcSignificanceComponent();
//	
//protected:
//	/** the max distance in which the npc is considered visible, 0 means using pir.NpcVisibleRange */
//	UPROPERTY(EditAnywhere)
//	float CustomSignificanceDistance; // 对重要NPC设置此值获取适合的显示距离
//
//	virtual float SignificanceFunctionImpl(UObject* InObject, const FTransform& Viewpoint) override;
//
//	virtual void PostSignificanceFunctionImpl(UObject* InObject, float InOldSignificance, float InSignificance, bool bFlag) override;
//	
//	virtual void TickSignificance(UObject* InObject, float InCurrentSignificance) override;
//
//protected:
//
//    bool bVisible;
//};
