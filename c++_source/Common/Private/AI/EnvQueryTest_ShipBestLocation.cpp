// Copyright 1998-2017 Epic Games, Inc. All Rights Reserved.

#include "AI/EnvQueryTest_ShipBestLocation.h"
#include "Common.h"
#include "AI/EnvQueryTest_ShipBestLocation.h"
#include "EnvironmentQuery/Items/EnvQueryItemType_VectorBase.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Querier.h"
#include "Components/ShipMovementComponent.h"
#include "Pawns/PiratesShipPawn.h"

//namespace
//{
//	FORCEINLINE float CalcDistance3D(const FVector& PosA, const FVector& PosB)
//	{
//		return (PosB - PosA).Size();
//	}
//
//	FORCEINLINE float CalcDistance2D(const FVector& PosA, const FVector& PosB)
//	{
//		return (PosB - PosA).Size2D();
//	}
//
//	FORCEINLINE float CalcDistanceZ(const FVector& PosA, const FVector& PosB)
//	{
//		return PosB.Z - PosA.Z;
//	}
//
//	FORCEINLINE float CalcDistanceAbsoluteZ(const FVector& PosA, const FVector& PosB)
//	{
//		return FMath::Abs(PosB.Z - PosA.Z);
//	}
//}

UEnvQueryTest_ShipBestLocation::UEnvQueryTest_ShipBestLocation(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
    Self = UEnvQueryContext_Querier::StaticClass();
	Cost = EEnvTestCost::Low;
	ValidItemType = UEnvQueryItemType_VectorBase::StaticClass();
}

void UEnvQueryTest_ShipBestLocation::RunTest(FEnvQueryInstance& QueryInstance) const
{
	UObject* QueryOwner = QueryInstance.Owner.Get();
	if (QueryOwner == nullptr)
	{
		return;
	}

	FloatValueMin.BindData(QueryOwner, QueryInstance.QueryID);
	float MinThresholdValue = FloatValueMin.GetValue();

	FloatValueMax.BindData(QueryOwner, QueryInstance.QueryID);
	float MaxThresholdValue = FloatValueMax.GetValue();

	// Get context.
	TArray<AActor*> ContextSelfShips;
	if (!QueryInstance.PrepareContext(Self, ContextSelfShips))
	{
		return;
	}

    TArray<AActor*> ContextTargetShips;
    if (!QueryInstance.PrepareContext(Target, ContextTargetShips))
    {
        return;
    }


    // Run the test for all the items.
	for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
	{
		FVector ItemLocation = GetItemLocation(QueryInstance, It.GetIndex());

        AActor* SelfActor = ContextSelfShips[0];
        AActor* TargetActor = ContextTargetShips[0];

        FVector PredictiveSelfDirection = GetPredictiveSelfDirection(SelfActor, TargetActor, ItemLocation);
        FVector PredictiveTargetDirection = GetPredictiveTargetDirection(SelfActor, TargetActor, ItemLocation);
        FVector PredictiveTargetLocation = GetPredictiveTargetLocation(SelfActor, TargetActor, ItemLocation);

        It.SetScore(TestPurpose, FilterType,
            EvaluateSituation(SelfActor, TargetActor, PredictiveSelfDirection, ItemLocation, PredictiveTargetDirection, PredictiveTargetLocation),
            MinThresholdValue, MaxThresholdValue);
/*
        float TestPointETA = FMath::Acos(SelfActor->GetActorForwardVector().CosineAngle2D(ItemLocation - SelfActor->GetActorLocation()))
            / (Cast<APiratesShipPawn>(SelfActor))->GetShipMovementComponent()->GetCurrentAngularSpeed();
              
        //SelfActor->GetComponentByClass(UShipMovementComponent::StaticClass())->GetC;
*/

        

        //It.SetScore(TestPurpose, FilterType, Distance, MinThresholdValue, MaxThresholdValue); 


		//for (int32 ContextIndex = 0; ContextIndex < ContextLocations.Num(); ContextIndex++)
		//{
		//	const float Distance = CalcDistance3D(ItemLocation, ContextLocations[ContextIndex]);
		//	It.SetScore(TestPurpose, FilterType, Distance, MinThresholdValue, MaxThresholdValue);
		//}
	}


}

FText UEnvQueryTest_ShipBestLocation::GetDescriptionTitle() const
{
    return FText();

//	FString ModeDesc;
//	switch (TestMode)
//	{
//		case EEnvTestDistance::Distance3D:
//			ModeDesc = TEXT("");
//			break;
//
//		case EEnvTestDistance::Distance2D:
//			ModeDesc = TEXT(" 2D");
//			break;
//
//		case EEnvTestDistance::DistanceZ:
//			ModeDesc = TEXT(" Z");
//			break;
//
//		default:
//			break;
//	}
//
//	return FText::FromString(FString::Printf(TEXT("%s%s: to %s"), 
//		*Super::GetDescriptionTitle().ToString(), *ModeDesc,
//		*UEnvQueryTypes::DescribeContext(DistanceTo).ToString()));
}

FText UEnvQueryTest_ShipBestLocation::GetDescriptionDetails() const
{
	//return DescribeFloatTestParams();
    return FText();
}


FVector UEnvQueryTest_ShipBestLocation::GetPredictiveSelfDirection(AActor * selfActor, AActor * targetActor, FVector itemLocation) const
{
    FVector result = itemLocation - selfActor->GetActorLocation();
    if (result.Normalize())
    {
        return result;
    }
    else
    {
        return selfActor->GetActorForwardVector();
    }
}

FVector UEnvQueryTest_ShipBestLocation::GetPredictiveTargetDirection(AActor* selfActor, AActor* targetActor, FVector itemLocation) const
{
    return targetActor->GetActorForwardVector();
}

FVector UEnvQueryTest_ShipBestLocation::GetPredictiveTargetLocation(AActor* selfActor, AActor* targetActor, FVector itemLocation) const
{
    return (itemLocation - selfActor->GetActorLocation()).Size2D() * targetActor->GetActorForwardVector() +
        targetActor->GetActorLocation();
}

float UEnvQueryTest_ShipBestLocation::EvaluateSituation(AActor * selfActor, AActor * targetActor,
    FVector selfDirection, FVector selfLocation,
    FVector targetDirection, FVector targetLocation) const
{
    float result = 0;

    FVector SelfToTarget = targetLocation - selfLocation;
    if (SelfToTarget.Normalize() && selfDirection.Normalize())
    {
        result = 1.0f - FMath::Abs(FVector::DotProduct(SelfToTarget, selfDirection));
    }

    return  result;
}

