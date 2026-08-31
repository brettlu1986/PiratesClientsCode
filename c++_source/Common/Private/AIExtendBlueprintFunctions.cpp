#include "AIExtendBlueprintFunctions.h"
#include "Common.h"
#include <vector>
#include <algorithm>
#include "AIController.h"
#include "BrainComponent.h"
#include "Perception/AIPerceptionComponent.h"
#include "Perception/AISense.h"
#include "Perception/AISenseConfig_Sight.h"
#include "AI/DestructibleObject/AIDestructibleObjectManagerRoot.h"
#include "Shell/CommonShell.h"

struct MoveTargetLocationInfo
{
	FVector Location;
	float Angle;
};

float UAIExtendBlueprintFunctions::FindDirectionAngleOutOfCrowd(const FVector &CenterLocation, const TArray<FVector> &OtherActorsLocationArray)
{
	float RetAngle = 0;
	std::vector<MoveTargetLocationInfo> LocationVec;
	for (int i = 0; i < OtherActorsLocationArray.Num(); ++i)
	{
		MoveTargetLocationInfo Info;
		Info.Location = OtherActorsLocationArray[i];
		Info.Angle = GetDirectionAngleOfTwoLocation(CenterLocation, Info.Location);
		LocationVec.push_back(Info);
	}

	std::sort(LocationVec.begin(), LocationVec.end(), [](const MoveTargetLocationInfo &LocA, const MoveTargetLocationInfo &LocB)->int{
		return LocA.Angle - LocB.Angle;
	});

	if (LocationVec.size() == 1)
	{
		RetAngle = -LocationVec[0].Angle;
	}
	else if (LocationVec.size() > 0)
	{
		float MaxAngle = 0;
		float CurrentAngle = LocationVec[LocationVec.size() - 1].Angle - 360;
		for (int i = 0; i < LocationVec.size(); ++i)
		{
			float TmpAngle = LocationVec[i].Angle - CurrentAngle;
			if (TmpAngle > MaxAngle)
			{
				MaxAngle = TmpAngle;
				RetAngle = CurrentAngle + MaxAngle / 2;
			}
			CurrentAngle = LocationVec[i].Angle;
		}
	}
	RetAngle = FRotator::NormalizeAxis(RetAngle);
	return RetAngle;
}

float UAIExtendBlueprintFunctions::GetDirectionAngleOfTwoLocation(const FVector &CenterLocation, const FVector &TargetLocation)
{
	float RetAngle = FMath::RadiansToDegrees((TargetLocation - CenterLocation).HeadingAngle());
	RetAngle = FRotator::NormalizeAxis(RetAngle);
	return RetAngle;
}

void UAIExtendBlueprintFunctions::LockAIResources(AAIController *AIController, bool bLockMovement, bool LockAILogic)
{
	if (AIController == NULL)
	{
		return;
	}
	if (bLockMovement)
	{
		auto PathFollowingComponent = AIController->GetPathFollowingComponent();
		if (PathFollowingComponent)
		{
			PathFollowingComponent->LockResource(EAIRequestPriority::HardScript);
		}
	}
	if (LockAILogic && AIController->BrainComponent)
	{
		AIController->BrainComponent->LockResource(EAIRequestPriority::HardScript);
	}
}

void UAIExtendBlueprintFunctions::UnlockAIResources(AAIController *AIController, bool bUnlockMovement, bool UnlockAILogic)
{
	if (AIController == NULL)
	{
		return;
	}
	if (bUnlockMovement && AIController->GetPathFollowingComponent())
	{
		AIController->GetPathFollowingComponent()->ClearResourceLock(EAIRequestPriority::HardScript);
	}
	if (UnlockAILogic && AIController->BrainComponent)
	{
		AIController->BrainComponent->ClearResourceLock(EAIRequestPriority::HardScript);
	}
}


bool UAIExtendBlueprintFunctions::IsInSightWithRatio(AAIController *AIController, const FVector& TargetLocation, float Ratio)
{
    FAISenseID Id = UAISense::GetSenseID(UAISense_Sight::StaticClass());
    if (!Id.IsValid() || !AIController || !AIController->GetPawn())
    {
        return false;
    }

    UAIPerceptionComponent* Perception = AIController->GetAIPerceptionComponent();
    if (Perception == nullptr)
    {
        return false;
    }


    auto Config = Perception->GetSenseConfig(Id);
    if (Config == nullptr)
    {
        return false;
    }

    auto ConfigSight = Cast<UAISenseConfig_Sight>(Config);
    float Distance = FVector::Dist2D(AIController->GetPawn()->GetActorLocation(), TargetLocation);
    return Distance <= ConfigSight->SightRadius * Ratio;
   
}

int32 UAIExtendBlueprintFunctions::QueryDoor(UObject* WorldContextObject, const FVector& Location, float Size)
{
    UAIDestructibleObjectManagerRoot* AIDestructibleObjectManagerRoot = UCommonShell::GetCommon(WorldContextObject)->GetAIDestructibleObjectManager();
    if (AIDestructibleObjectManagerRoot)
    {
        return AIDestructibleObjectManagerRoot->GetNearestDoor(Location, Size);
    }
    return -1;
}

void UAIExtendBlueprintFunctions::ConfigSightParams(UAIPerceptionComponent *PerceptionComponent, float SightDistance, float LoseSightDistance, float FOV)
{
    if (PerceptionComponent)
    {
        FAISenseID Id = UAISense::GetSenseID(UAISense_Sight::StaticClass());
        if (!Id.IsValid())
        {
            return;
        }
        auto Config = PerceptionComponent->GetSenseConfig(Id);
        if (Config == nullptr)
        {
            return;
        }

        auto ConfigSight = Cast<UAISenseConfig_Sight>(Config);
        ConfigSight->SightRadius = SightDistance;
        ConfigSight->LoseSightRadius = LoseSightDistance;
        ConfigSight->PeripheralVisionAngleDegrees = FOV;
        PerceptionComponent->ForgetAll();
        PerceptionComponent->RequestStimuliListenerUpdate();
    }
}


/////////////////////////////////////////////////////////////////////////////////////////
void UAIExtendBlueprintFunctions::GetActorLocation_NT(AActor* Actor, float& X, float& Y, float& Z)
{
    if (Actor)
    {
        FVector Location = Actor->GetActorLocation();
        X = Location.X;
        Y = Location.Y;
        Z = Location.Z;
    }
}


void UAIExtendBlueprintFunctions::GetActorRotation_NT(AActor* Actor, float& Pitch, float& Yaw, float& Roll)
{
    if (Actor)
    {
        FRotator Rotator = Actor->GetActorRotation();
        Pitch = Rotator.Pitch;
        Yaw = Rotator.Yaw;
        Roll = Rotator.Roll;
    }
}

void UAIExtendBlueprintFunctions::GetActorVelocity_NT(AActor* Actor, float& X, float& Y, float& Z)
{
    if (Actor)
    {
        FVector Velocity = Actor->GetVelocity();
        X = Velocity.X;
        Y = Velocity.Y;
        Z = Velocity.Z;
    }
}

void UAIExtendBlueprintFunctions::GetComponentLocation_NT(USceneComponent* Component, float& X, float& Y, float& Z)
{
    if (Component)
    {
        FVector Location = Component->GetComponentLocation();
        X = Location.X;
        Y = Location.Y;
        Z = Location.Z;
    }
}