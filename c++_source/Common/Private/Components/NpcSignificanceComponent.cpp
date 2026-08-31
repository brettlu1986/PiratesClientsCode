//// Fill out your copyright notice in the Description page of Project Settings.
//
#include "Components/NpcSignificanceComponent.h"
#include "Common.h"
//#include "NpcSignificanceComponent.h"
//#include "KMSignificanceManager.h"
//
///** Npc可见范围的总体缩放因子 */
//float GNpcSignificanceRangeScale = 1.f;
//FAutoConsoleVariableRef CVarNpcVisibleRangeScale(
//    TEXT("pir.NpcSignificanceRangeScale"), // pir means Pirates
//    GNpcSignificanceRangeScale,
//    TEXT("Npc visible range scale factor for better performance or better visual quality. Default 1")
//);
//
///** Npc进入此范围可具有>0的重要度 */
//float GNpcSignificanceRange1 = 3000.f;
//FAutoConsoleVariableRef CVarNpcSignificanceRange1(
//    TEXT("pir.NpcSignificanceRange1"), // pir means Pirates
//    GNpcSignificanceRange1,
//    TEXT("The global setting about the level 1 distance in which npc is considered having significance. Default is 4000")
//);
//
///** Npc进入此范围可具有更高级别的重要度 */
//float GNpcSignificanceRange2 = 1500.f;
//FAutoConsoleVariableRef CVarNpcSignificanceRange2(
//    TEXT("pir.NpcSignificanceRange2"), // pir means Pirates
//    GNpcSignificanceRange2,
//    TEXT("The global setting about the level 2 distance in which npc is considered having more significance. Default is 1500")
//);
//
//UNpcSignificanceComponent::UNpcSignificanceComponent()
//	:Super()
//{
//	SignificanceTag = TEXT("NpcPlayer");
//}
//
//float UNpcSignificanceComponent::SignificanceFunctionImpl(UObject* InObject, const FTransform& Viewpoint)
//{
//	const float DistanceLevel1 = (CustomSignificanceDistance > 0.f ? CustomSignificanceDistance : GNpcSignificanceRange1) * GNpcSignificanceRangeScale;
//	check(DistanceLevel1 > 0.f);
//
//	const float DistanceLevel2 = GNpcSignificanceRange2 * GNpcSignificanceRangeScale > DistanceLevel1 ?
//		DistanceLevel1 * 0.5f :
//		GNpcSignificanceRange2 * GNpcSignificanceRangeScale;
//
//	AActor* InActor = Cast<AActor>(InObject);
//	check(InActor);
//
//	const FVector ActorLoc = InActor->GetActorLocation();
//	const float ActorViewDistance = FVector::Dist2D(ActorLoc, Viewpoint.GetLocation());
//
//	// get basic significance by distance
//	float BaseSignificance = FMath::Min(1.f / ActorViewDistance, 1.f);
//
//	// in level 1
//	if (ActorViewDistance < DistanceLevel1)
//	{
//		// if in fov
//		if (CachedManager->IsInFov(ActorLoc))
//		{
//			if (ActorViewDistance < DistanceLevel2)
//			{
//				return CachedManager->SignificanceLevels[2] + BaseSignificance * (CachedManager->SignificanceLevels[3] - CachedManager->SignificanceLevels[2]);
//			}
//			else
//			{
//				return CachedManager->SignificanceLevels[1] + BaseSignificance * (CachedManager->SignificanceLevels[2] - CachedManager->SignificanceLevels[1]);
//			}
//		}
//		else if(ActorViewDistance < DistanceLevel2)
//		{
//			return CachedManager->SignificanceLevels[0] + BaseSignificance * (CachedManager->SignificanceLevels[1] - CachedManager->SignificanceLevels[0]);
//		}
//		return 0.f + BaseSignificance * (CachedManager->SignificanceLevels[0] - 0.f);
//	}
//	else
//	{
//		return -1.f;
//	}
//	return 0;
//}
//
//void UNpcSignificanceComponent::PostSignificanceFunctionImpl(UObject* InObject, float InOldSignificance, float InSignificance, bool bFlag)
//{
//    bVisible = InSignificance > 0.f;
//}
//
//void UNpcSignificanceComponent::TickSignificance(UObject* InObject, float InCurrentSignificance)
//{
//    AActor* InActor = Cast<AActor>(InObject);
//    check(InActor);
//
//    TArray<UActorComponent*> SMCompAry = InActor->K2_GetComponentsByClass(USkeletalMeshComponent::StaticClass());
//
//    // visibility
//    /*for (auto SMComp : SMCompAry)
//    {
//        ((USkeletalMeshComponent*)SMComp)->SetVisibility(bVisible);
//    }*/
//
//    // anim uro
//
//
//    // ticking
//
//
//    // others maybe
//}
